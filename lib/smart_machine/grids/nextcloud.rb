module SmartMachine
  class Grids
    class Nextcloud < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.nextcloud.dig(name.to_sym)
        raise "nextcloud config for #{name} not found." unless config

        @image = config.dig(:image)
        @host = config.dig(:host)
        @admin_user = config.dig(:admin_user)
        @admin_password = config.dig(:admin_password)
        @mysql_host = config.dig(:mysql_host)
        @mysql_port = config.dig(:mysql_port)
        @mysql_user = config.dig(:mysql_user)
        @mysql_password = config.dig(:mysql_password)
        @mysql_database_name = config.dig(:mysql_database_name)
        @redis_host = config.dig(:redis_host)
        @redis_port = config.dig(:redis_port)
        @redis_password = config.dig(:redis_password)

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def uper
        FileUtils.mkdir_p("#{@home_dir}/machine/grids/nextcloud/#{@name}/html")

        # Creating & Starting containers
        print "-----> Creating container #{@name} ... "

        command = [
          "docker create",
          "--name='#{@name}'",
          "--env VIRTUAL_HOST=#{@host}",
          "--env LETSENCRYPT_HOST=#{@host}",
          "--env LETSENCRYPT_EMAIL=#{SmartMachine.config.sysadmin_email}",
          "--env LETSENCRYPT_TEST=false",
          "--env NEXTCLOUD_TRUSTED_DOMAINS=#{@host}",
          "--env NEXTCLOUD_ADMIN_USER=#{@admin_user}",
          "--env NEXTCLOUD_ADMIN_PASSWORD=#{@admin_password}",
          "--env OVERWRITEPROTOCOL=https",
          "--env MYSQL_HOST=#{@mysql_host}:#{@mysql_port}",
          "--env MYSQL_USER=#{@mysql_user}",
          "--env MYSQL_PASSWORD=#{@mysql_password}",
          "--env MYSQL_DATABASE=#{@mysql_database_name}",
          "--env REDIS_HOST=#{@redis_host}",
          "--env REDIS_HOST_PORT=#{@redis_port}",
          "--env REDIS_HOST_PASSWORD=#{@redis_password}",
          "--user `id -u`:`id -g`",
          "--sysctl net.ipv4.ip_unprivileged_port_start=0",
          "--volume='#{@home_dir}/smartmachine/grids/nextcloud/#{@name}/html:/var/www/html'",
          "--restart='always'",
          "--network='nginx-network'",
          "#{@image}"
        ]
        if system(command.compact.join(" "), out: File::NULL)
          system("docker network connect #{@mysql_host}-network #{@name}")

          puts "done"
          puts "-----> Starting container #{@name} ... "
          if system("docker start #{@name}", out: File::NULL)
            puts "done"
          else
            raise "Error: Could not start the created #{@name} container"
          end
        else
          raise "Error: Could not create #{@name} container"
        end
      end

      def downer
        # Disconnecting networks
        system("docker network disconnect nginx-network #{@name}")
        system("docker network disconnect #{@mysql_host}-network #{@name}")

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
