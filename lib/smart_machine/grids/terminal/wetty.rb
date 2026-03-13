module SmartMachine
  class Grids
    class Terminal < SmartMachine::Base
      class Wetty
        def initialize(name:, host:, ssh_host:)
          @name = name
          @host = host
          @ssh_host = ssh_host
        end

        def uper
          raise "Error: Could not create container: #{@name}" unless system(command.compact.join(' '), out: File::NULL)
          raise "Error: Could not start container: #{@name}"  unless system("docker start #{@name}", out: File::NULL)

          puts "Created & Started container: #{@name}"
        end

        def downer
          raise "Error: Could not stop container: #{@name}"   unless system("docker stop '#{@name}'", out: File::NULL)
          raise "Error: Could not remove container: #{@name}" unless system("docker rm '#{@name}'", out: File::NULL)

          puts "Stopped & Removed container: #{@name}"
        end

        private

        def command
          [
            'docker create',
            "--name='#{@name}'",
            "--env VIRTUAL_HOST=#{@host}",
            "--env VIRTUAL_PATH=/",
            "--env LETSENCRYPT_HOST=#{@host}",
            "--env LETSENCRYPT_EMAIL=#{SmartMachine.config.sysadmin_email}",
            '--env LETSENCRYPT_TEST=false',
            "--restart='always'",
            "--network='nginx-network'",
            "wettyoss/wetty --base=/ --ssh-host=#{@ssh_host} --ssh-port=2223 --force-ssh=true --title=Terminal"
          ]
        end
      end
    end
  end
end
