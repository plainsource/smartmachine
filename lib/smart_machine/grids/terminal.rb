module SmartMachine
  class Grids
    class Terminal < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.terminal.dig(name.to_sym)
        raise "terminal config for #{name} not found." unless config

        @image = "smartmachine/terminal:#{SmartMachine.version}"
        @host = config.dig(:host)
        @frontend = config.dig(:frontend)
        @packages = config.dig(:packages)
        @username = config.dig(:username)
        @password = config.dig(:password)

        @name = name.to_s
        @home_dir = File.expand_path('~')

        @wetty = Wetty.new(name: "#{@name}-wetty", host: @host, ssh_host: @name)
      end

      def installer
        unless system("docker image inspect #{@image}", [:out, :err] => File::NULL)
          puts "-----> Creating image #{@image} ... "
          command = [
            "docker image build -t #{@image}",
            "--build-arg SMARTMACHINE_VERSION=#{SmartMachine.version}",
            "-f- #{SmartMachine.config.gem_dir}/lib/smart_machine/grids/terminal",
            "<<'EOF'\n#{dockerfile}EOF"
          ]
          if system(command.join(" "), out: File::NULL)
            puts "done"
          else
            raise "Error: Could not install image: #{@image}"
          end
        else
          raise "Error: Image already installed: #{@image}. Please uninstall using 'smartmachine grids terminal uninstall' and try installing again."
        end
      end

      def uninstaller
        unless system("docker inspect -f '{{.State.Running}}' '#{@name}'", [:out, :err] => File::NULL)
          if system("docker image inspect #{@image}", [:out, :err] => File::NULL)
            puts "-----> Removing image #{@image} ... "
            if system("docker image rm #{@image}", out: File::NULL)
              puts "done"
            end
          else
            raise "Error: Terminal already uninstalled. Please install using 'smartmachine grids terminal install' and try uninstalling again."
          end
        else
          raise "Error: Terminal is currently running. Please stop the terminal using 'smartmachine grids terminal down' and try uninstalling again."
        end
      end

      def uper
        if system("docker image inspect #{@image}", [:out, :err] => File::NULL)
          FileUtils.mkdir_p("#{@home_dir}/machine/grids/terminal/#{@name}/backups")

          # Creating & Starting containers
          print "-----> Creating container #{@name} ... "

          command = [
            "docker create",
            "--name='#{@name}'",
            "--env VIRTUAL_HOST=#{@host}",
            "--env VIRTUAL_PATH=#{@frontend}",
            "--env VIRTUAL_PORT=80",
            "--env LETSENCRYPT_HOST=#{@host}",
            "--env LETSENCRYPT_EMAIL=#{SmartMachine.config.sysadmin_email}",
            "--env LETSENCRYPT_TEST=false",
            "--env CONTAINER_NAME='#{@name}'",
            "--env PACKAGES='#{@packages.join(' ')}'",
            "--env USERNAME=#{@username}",
            "--env PASSWORD=#{@password}",
            "--publish='2223:2223'", # TODO: Remove this published port and move it behind the reverse proxy when ready.
            "--volume='#{@name}-home:/home'",
            "--volume='#{@home_dir}/smartmachine/grids/terminal/#{@name}/backups:/root/backups'", # TODO: Do not volumize backups folder by default. Give option in the config file to decide what volume should be exposed from host to terminal.
            "--volume='#{@home_dir}/smartmachine/apps/containers:/mnt/smartmachine/apps/containers'", # TODO: Do not volumize containers folder by default. Give option in the config file to decide what volume should be exposed from host to terminal.
            "--init",
            "--restart='always'",
            "--network='nginx-network'",
            "#{@image}"
          ]
          if system(command.compact.join(" "), out: File::NULL)
            puts "done"
            puts "-----> Starting container #{@name} ... "
            if system("docker start #{@name}", out: File::NULL)
              puts "done"

              @wetty.uper
            else
              raise "Error: Could not start container: #{@name}"
            end
          else
            raise "Error: Could not create container: #{@name}"
          end
        else
          raise "Error: Could not find image: #{@image}"
        end
      end

      def downer
        # Stopping & Removing containers - in reverse order

        @wetty.downer

        print "-----> Stopping container #{@name} ... "
        if system("docker stop '#{@name}'", out: File::NULL)
          puts "done"
          print "-----> Removing container #{@name} ... "
          if system("docker rm '#{@name}'", out: File::NULL)
            puts "done"
          end
        end
      end

      private

      # openssh-server
      # sshd needs rsyslog to output /var/log/auth.log.
      # imklog module is commented in rsyslog.conf because rsyslog does not
      # have privileges to run it and hence throws error on startup.
      #
      # fail2ban
      # fail2ban needs sshd to output /var/log/auth.log.
      # Otherwise it cannot start the sshd jail.
      def dockerfile
        file = <<~'DOCKERFILE'
          ARG SMARTMACHINE_VERSION

	  FROM smartmachine/smartengine:$SMARTMACHINE_VERSION
	  LABEL maintainer="plainsource <plainsource@humanmind.me>"

	  RUN apt-get update && \
	      \
	      apt-get install -y --no-install-recommends sudo && \
	      \
	      apt-get install -y --no-install-recommends rsyslog openssh-server && \
	      mkdir -p /run/sshd && \
	      sed -i'.original' '/#Port 22/a Port 2223' /etc/ssh/sshd_config && \
	      sed -i '/#AddressFamily any/a AddressFamily inet' /etc/ssh/sshd_config && \
	      sed -i '/#PermitRootLogin prohibit-password/a PermitRootLogin no' /etc/ssh/sshd_config && \
	      sed -i '/imklog/s/^/#/' /etc/rsyslog.conf && \
	      \
	      apt-get install -y --no-install-recommends fail2ban sendmail-bin sendmail && \
	      cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local && \
	      cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local && \
	      sed -i'.original' 's/destemail = root@localhost/#destemail = root@localhost\ndestemail = %<sysadmin_email>s/' /etc/fail2ban/jail.local && \
              sed -i 's/action = %<percent>s(action_)s/#action = %<percent>s(action_)s\naction = %<percent>s(action_mwl)s/' /etc/fail2ban/jail.local && \
	      sed -i 's/port    = ssh/#port    = ssh\nport    = 2223/' /etc/fail2ban/jail.local && \
	      \
	      apt-get install -y --no-install-recommends haproxy && \
	      mkdir -p /run/haproxy && \
	      mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.original && \
	      \
	      apt-get install -y --no-install-recommends cmake libtool libtool-bin emacs-nox && \
	      mkdir -p /root/.emacs.d && \
	      \
	      apt-get install -y --no-install-recommends vim && \
	      \
	      rm -rf /var/lib/apt/lists/* && \
	      gem install bundler -v 2.1.4

	  COPY haproxy.cfg /etc/haproxy
	  COPY init.el /root/.emacs.d/init.el

	  COPY entrypoint.rb /usr/local/bin/entrypoint.rb
	  RUN chmod +x /usr/local/bin/entrypoint.rb
	  ENTRYPOINT ["entrypoint.rb"]

	  EXPOSE 2223 80
	  STOPSIGNAL SIGUSR1
	  CMD ["haproxy", "-W", "-db", "-f", "/etc/haproxy/haproxy.cfg"]
        DOCKERFILE

        format(file, "sysadmin_email": SmartMachine.config.sysadmin_email, "percent": '%')
      end
    end
  end
end
