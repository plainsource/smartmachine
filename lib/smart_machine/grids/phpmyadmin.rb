module SmartMachine
  class Grids
    class Phpmyadmin < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.phpmyadmin.dig(name.to_sym)
        raise "phpmyadmin config for #{name} not found." unless config

        @image = config.dig(:image)
        @command = config.dig(:command)
        @host = config.dig(:host)
        @networks = Array(config.dig(:networks))

        @pma_controlhost = config.dig(:pma_controlhost)
        mysql_config = SmartMachine.config.grids.mysql.dig(@pma_controlhost&.to_sym)
        raise "phpmyadmin | mysql config for #{@pma_controlhost} not found." unless mysql_config
        @pma_controlport = mysql_config.dig(:port)
        @pma_controluser = mysql_config.dig(:username)
        @pma_controlpass = mysql_config.dig(:password)

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def uper
        raise "Error: Could not create container: #{@name}"  unless system(command.compact.join(' '), out: File::NULL)
        raise "Error: Could not start container: #{@name}"   unless system("docker start #{@name}", out: File::NULL)
        @networks.each do |network|
          raise "Error: Could not connect container: #{network} - #{@name}" unless system("docker network connect #{network} #{@name}", out: File::NULL)
        end

        puts "Created, Started & Connected container: #{@name}"
      end

      def downer
        @networks.each do |network|
          raise "Error: Could not disconnect container: #{network} - #{@name}" unless system("docker network disconnect #{network} #{@name}", out: File::NULL)
        end
        raise "Error: Could not stop container: #{@name}"   unless system("docker stop '#{@name}'", out: File::NULL)
        raise "Error: Could not remove container: #{@name}" unless system("docker rm '#{@name}'", out: File::NULL)

        puts "Disconnected, Stopped & Removed container: #{@name}"
      end

      private

      def command
        [
          'docker create',
          "--name='#{@name}'",
          "--env VIRTUAL_HOST=#{@host}",
          "--env LETSENCRYPT_HOST=#{@host}",
          "--env LETSENCRYPT_EMAIL=#{SmartMachine.config.sysadmin_email}",
          '--env LETSENCRYPT_TEST=false',
          "--env PMA_CONTROLHOST=#{@pma_controlhost}",
          "--env PMA_CONTROLPORT=#{@pma_controlport}",
          "--env PMA_CONTROLUSER=#{@pma_controluser}",
          "--env PMA_CONTROLPASS=#{@pma_controlpass}",
          '--env PMA_PMADB=phpmyadmin',
          '--env PMA_QUERYHISTORYDB=true',
          '--env HIDE_PHP_VERSION=true',
          '--env PMA_ARBITRARY=1',
          volumes,
          "--restart='always'",
          "--network='#{@networks.shift}'",
          @image,
          @command
        ]
      end

      def volumes
        volumes = []

        if File.exist?("#{@home_dir}/machine/config/phpmyadmin/#{@name}/config.user.inc.php")
          volumes.push("--volume='#{@home_dir}/smartmachine/config/phpmyadmin/#{@name}/config.user.inc.php:/etc/phpmyadmin/config.user.inc.php'")
        end

        volumes.join(" ")
      end
    end
  end
end
