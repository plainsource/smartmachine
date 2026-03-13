module SmartMachine
  class Docker < SmartMachine::Base
    def initialize
      @machine = SmartMachine::Machine.new
    end

    # Installing Docker!
    #
    # Example:
    #   => Installation Complete
    #
    # Arguments:
    #   none
    def install
      puts "-----> Installing Docker"
      if platform_on_machine?(os: "linux", distro_name: "debian")
        install_on_linuxos(distro_name: "debian", arch: "amd64")
      # elsif platform_on_machine?(os: "mac")
      #   install_on_macos
      else
        raise "Installation of docker is currently supported on Debian GNU/Linux."
      end
      puts "-----> Docker Installation Complete"
    end

    # Uninstalling Docker!
    #
    # Example:
    #   => Uninstallation Complete
    #
    # Arguments:
    #   none
    def uninstall
      puts "-----> Uninstalling Docker"
      if platform_on_machine?(os: "linux", distro_name: "debian")
        uninstall_on_linuxos(distro_name: "debian", arch: "amd64")
      # elsif platform_on_machine?(os: "mac")
      #   uninstall_on_macos
      else
        raise "Uninstallation of docker is currently supported on Debian GNU/Linux."
      end
      puts "-----> Docker Uninstallation Complete"
    end

    private

    def install_on_linuxos(distro_name:, arch:)

      commands = [
        "sudo apt-get update",
        "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
        "sudo mkdir -p /etc/apt/keyrings",
        "sudo rm -f /etc/apt/keyrings/docker.gpg",
        "curl -fsSL https://download.docker.com/linux/#{distro_name}/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
        "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/#{distro_name} $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
        "sudo apt-get update",
        "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
        "sudo usermod -aG docker $USER",
        "docker run --rm hello-world",
        "docker rmi hello-world"
      ]
      @machine.run_on_machine(commands: commands)

      puts '-----> Add the following rules to the end of the file /etc/ufw/after.rules and reload ufw using - sudo ufw reload'
      puts '# BEGIN UFW AND DOCKER
	    *filter
	    :ufw-user-forward - [0:0]
	    :DOCKER-USER - [0:0]
	    -A DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	    -A DOCKER-USER -m conntrack --ctstate INVALID -j DROP
	    -A DOCKER-USER -i eth0 -j ufw-user-forward
	    -A DOCKER-USER -i eth0 -j DROP
	    COMMIT
	    # END UFW AND DOCKER'

      # puts "-----> Adding UFW rules for Docker"
      # interface_name = system("ip route show | sed -e 's/^default via [0-9.]* dev \(\w\+\).*/\1/'")
      # puts interface_name

      # system("sed '/^# BEGIN UFW AND DOCKER/,/^# END UFW AND DOCKER/d' '/etc/ufw/after.rules'")
      # system("sudo tee -a '/etc/ufw/after.rules' > /dev/null <<EOT
      # # BEGIN UFW AND DOCKER
      # *filter
      # :ufw-user-forward - [0:0]
      # :DOCKER-USER - [0:0]
      # -A DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
      # -A DOCKER-USER -m conntrack --ctstate INVALID -j DROP
      # -A DOCKER-USER -i eth0 -j ufw-user-forward
      # -A DOCKER-USER -i eth0 -j DROP
      # COMMIT
      # # END UFW AND DOCKER
      # EOT")
      # system("sudo ufw reload")
    end

    def uninstall_on_linuxos(distro_name:, arch:)

      commands = [
        "sudo apt-get purge -y docker-ce docker-ce-cli containerd.io",
        "sudo apt-get autoremove -y",
        "sudo rm -rf /var/lib/docker",
        "sudo rm -rf /var/lib/containerd"
      ]
      @machine.run_on_machine(commands: commands)

      puts '-----> Remove the following rules at the end of the file /etc/ufw/after.rules and reload ufw using - sudo ufw reload'
      puts '# BEGIN UFW AND DOCKER
	    *filter
	    :ufw-user-forward - [0:0]
	    :DOCKER-USER - [0:0]
	    -A DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	    -A DOCKER-USER -m conntrack --ctstate INVALID -j DROP
	    -A DOCKER-USER -i eth0 -j ufw-user-forward
	    -A DOCKER-USER -i eth0 -j DROP
	    COMMIT
	    # END UFW AND DOCKER'

      # puts "-----> Removing UFW rules for Docker"
      # system("sed '/^# BEGIN UFW AND DOCKER/,/^# END UFW AND DOCKER/d' '/etc/ufw/after.rules'")
      # system("sudo ufw reload")
    end

    # def install_on_macos
    #   commands = [
    #     "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
    #     "brew install homebrew/cask/docker",
    #     "brew install bash-completion",
    #     "brew install docker-completion",
    #     "open /Applications/Docker.app",
    #     # The docker app asks for permission after opening gui. if that can be automated then the next two statements can be uncommented and automated. Until then can't execute automatically.
    #     # "docker run --rm hello-world",
    #     # "docker rmi hello-world"
    #   ]
    #   @machine.run_on_machine(commands: commands)
    # end

    # def uninstall_on_macos
    #   commands = [
    #     "brew uninstall docker-completion",
    #     "brew uninstall bash-completion",
    #     "brew uninstall --zap homebrew/cask/docker"
    #   ]
    #   @machine.run_on_machine(commands: commands)
    # end
  end
end
