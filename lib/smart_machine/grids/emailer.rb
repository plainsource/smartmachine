module SmartMachine
  class Grids
    class Emailer < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.emailer.dig(name.to_sym)
        raise "emailer config for #{name} not found." unless config

        @image = "smartmachine/emailer:#{SmartMachine.version}"
        @host = config.dig(:host)
        @frontend = config.dig(:frontend)

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def installer
        unless system("docker image inspect #{@image}", [:out, :err] => File::NULL)
          puts "-----> Creating image #{@image} ... "
          command = [
            "docker image build -t #{@image}",
            "--build-arg SMARTMACHINE_VERSION=#{SmartMachine.version}",
            "-f- #{SmartMachine.config.gem_dir}/lib/smart_machine/grids/emailer",
            "<<'EOF'\n#{dockerfile}EOF"
          ]
          if system(command.join(" "), out: File::NULL)
            puts "done"
          else
            raise "Error: Could not install image: #{@image}"
          end
        else
          raise "Error: Image already installed: #{@image}. Please uninstall using 'smartmachine grids emailer uninstall' and try installing again."
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
            raise "Error: Emailer already uninstalled. Please install using 'smartmachine grids emailer install' and try uninstalling again."
          end
        else
          raise "Error: Emailer is currently running. Please stop the emailer using 'smartmachine grids emailer down' and try uninstalling again."
        end
      end

      def uper
        if system("docker image inspect #{@image}", [:out, :err] => File::NULL)
          FileUtils.mkdir_p("#{@home_dir}/machine/grids/emailer/#{@name}/backups")

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
            # "--publish='587:587'",
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

      def dockerfile
        file = <<~'DOCKERFILE'
          ARG SMARTMACHINE_VERSION

	  FROM smartmachine/smartengine:$SMARTMACHINE_VERSION
	  LABEL maintainer="plainsource <plainsource@humanmind.me>"

	  RUN apt-get update && \
	      \
	      apt-get install -y --no-install-recommends haproxy && \
	      mkdir -p /run/haproxy && \
	      mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.original && \
	      \
	      rm -rf /var/lib/apt/lists/*

	  COPY haproxy.cfg /etc/haproxy

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
