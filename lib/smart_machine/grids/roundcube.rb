module SmartMachine
  class Grids
    class Roundcube < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.roundcube.dig(name.to_sym)
        raise "roundcube config for #{name} not found." unless config

        @fqdn = config.dig(:fqdn)
        @image = config.dig(:image)
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
        @skin = config.dig(:skin)
        @upload_max_filesize = config.dig(:upload_max_filesize)
        @aspell_dictionaries = config.dig(:aspell_dictionaries)

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def uper
        FileUtils.mkdir_p("#{@home_dir}/machine/grids/roundcube/#{@name}/backups")
        FileUtils.mkdir_p("#{@home_dir}/machine/grids/roundcube/#{@name}/data/html")
        FileUtils.mkdir_p("#{@home_dir}/machine/grids/roundcube/#{@name}/data/roundcube-temp")

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
          "--volume='#{@home_dir}/smartmachine/config/roundcube/etc/apache2/sites-available/000-default.conf:/etc/apache2/sites-available/000-default.conf:ro'",
          "--volume='#{@home_dir}/smartmachine/config/roundcube/usr/local/etc/php/conf.d/zzz_roundcube-custom.ini:/usr/local/etc/php/conf.d/zzz_roundcube-custom.ini:ro'",
          "--volume='#{@home_dir}/smartmachine/config/roundcube/var/roundcube/config:/var/roundcube/config:ro'",
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
    end
  end
end
