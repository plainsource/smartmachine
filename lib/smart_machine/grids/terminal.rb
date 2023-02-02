module SmartMachine
  class Grids
    class Terminal < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.terminal.dig(name.to_sym)
        raise "terminal config for #{name} not found." unless config

        @image = "smartmachine/terminal:#{SmartMachine.version}"
        @host = config.dig(:host)
        @packages = config.dig(:packages)

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def installer
        unless system("docker image inspect #{@image}", [:out, :err] => File::NULL)
          puts "-----> Creating image #{@image} ... "
          command = [
            "docker image build -t #{@image}",
            "--build-arg SMARTMACHINE_VERSION=#{SmartMachine.version}",
            "-<<'EOF'\n#{dockerfile}EOF"
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
          FileUtils.mkdir_p("#{@home_dir}/machine/grids/terminal/#{@name}/home")

          # Creating & Starting containers
          print "-----> Creating container #{@name} ... "

          command = [
            "docker create",
            "--name='#{@name}'",
            "--env VIRTUAL_HOST=#{@host}",
            "--env LETSENCRYPT_HOST=#{@host}",
            "--env LETSENCRYPT_EMAIL=#{SmartMachine.config.sysadmin_email}",
            "--env LETSENCRYPT_TEST=false",
            "--volume='#{@home_dir}/smartmachine/grids/terminal/#{@name}/home:/home'",
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

      # \
      # curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
      # echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
      # apt-get install -y --no-install-recommends nodejs yarn && \
      # yarn global add wetty && \
      def dockerfile
        file = <<~'DOCKERFILE'
          ARG SMARTMACHINE_VERSION

	  FROM smartmachine/smartengine:$SMARTMACHINE_VERSION
	  LABEL maintainer="plainsource <plainsource@humanmind.me>"

	  RUN apt-get update && \
	      \
	      apt-get install -y --no-install-recommends haproxy && \
	      mkdir -p /run/haproxy && \
	      \
	      apt-get install -y --no-install-recommends %<packages>s && \
	      \
	      rm -rf /var/lib/apt/lists/* && \
	      gem install bundler -v 2.1.4

	  EXPOSE 80
	  STOPSIGNAL SIGUSR1
	  CMD ["haproxy", "-W", "-db", "-f", "/etc/haproxy/haproxy.cfg"]
        DOCKERFILE

        format(file, "packages": @packages.join(' '))
      end
    end
  end
end
