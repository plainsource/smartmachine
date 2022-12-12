module SmartMachine
  class Grids
    class Wireguard < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.wireguard.dig(name.to_sym)
        raise "wireguard config for #{name} not found." unless config

        @image = config.dig(:image)
        @host = config.dig(:host)
        @peers = config.dig(:peers)

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def uper
        # Creating networks
        unless system("docker network inspect #{@name}-network", [:out, :err] => File::NULL)
          print "-----> Creating network #{@name}-network ... "
          if system("docker network create #{@name}-network", out: File::NULL)
            puts "done"
          end
        end

        FileUtils.mkdir_p("#{@home_dir}/machine/grids/wireguard/#{@name}/config")

        # Creating & Starting containers
        print "-----> Creating container #{@name} ... "
        command = [
          "docker create",
          "--name='#{@name}'",
          "--env VIRTUAL_HOST=#{@host}",
          "--env LETSENCRYPT_HOST=#{@host}",
          "--env LETSENCRYPT_EMAIL=#{SmartMachine.config.sysadmin_email}",
          "--env LETSENCRYPT_TEST=false",
          "--env PUID=`id -u`",
          "--env PGID=`id -g`",
          "--env TZ=Etc/UTC",
          # "--env SERVERURL=wireguard.domain.com",
          # "--env SERVERPORT=51820",
          @peers.blank? ? nil : "--env PEERS=#{@peers}",
          # "--env PEERDNS=auto",
          # "--env INTERNAL_SUBNET=10.13.13.0",
          # "--env ALLOWEDIPS=0.0.0.0/0",
          # "--env LOG_CONFS=true",
          "--user `id -u`:`id -g`",
          "--cap-add=NET_ADMIN",
          "--cap-add=SYS_MODULE",
          "--sysctl net.ipv4.conf.all.src_valid_mark=1",
          "--volume='#{@home_dir}/smartmachine/grids/wireguard/#{@name}/config:/config'",
          # "--volume='#{@home_dir}/smartmachine/grids/wireguard/#{@name}/lib/modules:/lib/modules'",
          "--restart='always'",
          "--network='#{@name}-network'",
          "#{@image}"
        ]
        if system(command.compact.join(" "), out: File::NULL)
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
        # Stopping & Removing containers - in reverse order
        print "-----> Stopping container #{@name} ... "
        if system("docker stop '#{@name}'", out: File::NULL)
          puts "done"
          print "-----> Removing container #{@name} ... "
          if system("docker rm '#{@name}'", out: File::NULL)
            puts "done"
          end
        end

        # Removing networks
        print "-----> Removing network #{@name}-network ... "
        if system("docker network rm #{@name}-network", out: File::NULL)
          puts "done"
        end
      end
    end
  end
end
