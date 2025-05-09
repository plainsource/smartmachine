module SmartMachine
  class Grids
    class Roundcube < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.roundcube.dig(name.to_sym)
        raise "roundcube config for #{name} not found." unless config

        @fqdn = config.dig(:fqdn)
        @image = "smartmachine/roundcube:#{SmartMachine.version}"
        @sysadmin_email = config.dig(:sysadmin_email)
        @networks = config.dig(:networks)
        @database_type = config.dig(:database_type)
        @database_host = config.dig(:database_host)
        @database_port = config.dig(:database_port)
        @database_user = config.dig(:database_user)
        @database_pass = config.dig(:database_pass)
        @database_name = config.dig(:database_name)
        @mail_host = config.dig(:mail_host)
        @mail_port = config.dig(:mail_port)
        @smtp_host = config.dig(:smtp_host)
        @smtp_port = config.dig(:smtp_port)
        @request_path = config.dig(:request_path)
        @plugins = config.dig(:plugins)
        @plugins_password_database_type = config.dig(:plugins_password_database_type)
        @plugins_password_database_host = config.dig(:plugins_password_database_host)
        @plugins_password_database_user = config.dig(:plugins_password_database_user)
        @plugins_password_database_pass = config.dig(:plugins_password_database_pass)
        @plugins_password_database_name = config.dig(:plugins_password_database_name)
        @skin = config.dig(:skin)
        @upload_max_filesize = config.dig(:upload_max_filesize)
        @aspell_dictionaries = config.dig(:aspell_dictionaries)

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def installer
        unless system("docker image inspect #{@image}", [:out, :err] => File::NULL)
          puts "-----> Creating image #{@image} ... "
          command = [
            "docker image build -t #{@image}",
            "--build-arg SMARTMACHINE_VERSION=#{SmartMachine.version}",
            "-f- #{SmartMachine.config.gem_dir}/lib/smart_machine/grids/roundcube",
            "<<'EOF'\n#{dockerfile}EOF"
          ]
          if system(command.join(" "), out: File::NULL)
            puts "done"
          else
            raise "Error: Could not install image: #{@image}"
          end
        else
          raise "Error: Image already installed: #{@image}. Please uninstall using 'smartmachine grids roundcube uninstall' and try installing again."
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
            raise "Error: Roundcube already uninstalled. Please install using 'smartmachine grids roundcube install' and try uninstalling again."
          end
        else
          raise "Error: Roundcube is currently running. Please stop the roundcube using 'smartmachine grids roundcube down' and try uninstalling again."
        end
      end

      def uper
        if system("docker image inspect #{@image}", [:out, :err] => File::NULL)
          FileUtils.mkdir_p("#{@home_dir}/machine/grids/roundcube/#{@name}/backups")
          FileUtils.mkdir_p("#{@home_dir}/machine/grids/roundcube/#{@name}/data/html")
          FileUtils.mkdir_p("#{@home_dir}/machine/grids/roundcube/#{@name}/data/roundcube-temp")

          # Setting entrypoint permission.
          system("chmod +x #{@home_dir}/machine/config/roundcube/docker/custom-docker-entrypoint.sh")
          system("chmod +x #{@home_dir}/machine/config/roundcube/docker/entrypoint.rb")

          # Creating & Starting containers
          print "-----> Creating container #{@name} ... "

          command = [
            "docker create",
            "--name='#{@name}'",
            "--env VIRTUAL_HOST=#{@fqdn}",
            "--env VIRTUAL_PATH='#{@request_path}'",
            "--env LETSENCRYPT_HOST=#{@fqdn}",
            "--env LETSENCRYPT_EMAIL=#{@sysadmin_email}",
            "--env LETSENCRYPT_TEST=false",
            "--env CONTAINER_NAME='#{@name}'",
            "--env FQDN='#{@fqdn}'",
            "--env ROUNDCUBEMAIL_DEFAULT_HOST='#{@mail_host}'",
            "--env ROUNDCUBEMAIL_DEFAULT_PORT='#{@mail_port}'",
            "--env ROUNDCUBEMAIL_SMTP_SERVER='#{@smtp_host}'",
            "--env ROUNDCUBEMAIL_SMTP_PORT='#{@smtp_port}'",
            "--env ROUNDCUBEMAIL_USERNAME_DOMAIN=''",
            "--env ROUNDCUBEMAIL_REQUEST_PATH='#{@request_path}'",
            "--env ROUNDCUBEMAIL_PLUGINS='#{@plugins.join(',')}'",
            "--env ROUNDCUBEMAIL_PLUGINS_PASSWORD_DATABASE_TYPE='#{@plugins_password_database_type}'",
            "--env ROUNDCUBEMAIL_PLUGINS_PASSWORD_DATABASE_HOST='#{@plugins_password_database_host}'",
            "--env ROUNDCUBEMAIL_PLUGINS_PASSWORD_DATABASE_USER='#{@plugins_password_database_user}'",
            "--env ROUNDCUBEMAIL_PLUGINS_PASSWORD_DATABASE_PASS='#{@plugins_password_database_pass}'",
            "--env ROUNDCUBEMAIL_PLUGINS_PASSWORD_DATABASE_NAME='#{@plugins_password_database_name}'",
            "--env ROUNDCUBEMAIL_INSTALL_PLUGINS='1'",
            "--env ROUNDCUBEMAIL_SKIN='#{@skin}'",
            "--env ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE='#{@upload_max_filesize}'",
            "--env ROUNDCUBEMAIL_SPELLCHECK_URI=''",
            "--env ROUNDCUBEMAIL_ASPELL_DICTS='#{@aspell_dictionaries.join(',')}'",
            "--env ROUNDCUBEMAIL_DB_TYPE='#{@database_type}'",
            "--env ROUNDCUBEMAIL_DB_HOST='#{@database_host}'",
            "--env ROUNDCUBEMAIL_DB_PORT='#{@database_port}'",
            "--env ROUNDCUBEMAIL_DB_USER='#{@database_user}'",
            "--env ROUNDCUBEMAIL_DB_PASSWORD='#{@database_pass}'",
            "--env ROUNDCUBEMAIL_DB_NAME='#{@database_name}'",
            "--volume='#{@home_dir}/smartmachine/config/roundcube:/smartmachine/config/roundcube:ro'",
            "--volume='#{@home_dir}/smartmachine/grids/roundcube/#{@name}/data/html:/var/www/html'",
            "--volume='#{@home_dir}/smartmachine/grids/roundcube/#{@name}/data/roundcube-temp:/tmp/roundcube-temp'",
            "--tmpfs /run/tmpfs",
            "--init",
            "--restart='always'",
            "--network='nginx-network'",
            "#{@image}"
          ]
          if system(command.compact.join(" "), out: File::NULL)
            @networks.each do |network|
              system("docker network connect #{network} #{@name}")
            end

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
        # Disconnecting networks
        @networks.reverse.each do |network|
          system("docker network disconnect #{network} #{@name}")
        end

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

	  FROM roundcube/roundcubemail:1.6.8-apache
	  LABEL maintainer="plainsource <plainsource@humanmind.me>"

	  RUN apt-get update && \
              apt-get install -y --no-install-recommends \
	      ruby-full build-essential zlib1g-dev \
	      dovecot-common && \
	      rm -rf /var/lib/apt/lists/*

	  ENTRYPOINT ["/smartmachine/config/roundcube/docker/custom-docker-entrypoint.sh"]
	  CMD ["apache2-foreground"]
        DOCKERFILE

        format(file, "mailname": @mailname)
      end
    end
  end
end
