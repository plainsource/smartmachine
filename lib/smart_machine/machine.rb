# coding: utf-8
require "net/ssh"

module SmartMachine
  class Machine < SmartMachine::Base
    def initialize
    end

    # Create a new smartmachine
    #
    # Example:
    #   >> Machine.create("qw21334q")
    #   => "New machine qw21334q has been created."
    #
    # Arguments:
    #   name: (String)
    #   dev: (Boolean)
    def create(name:, dev:)
      raise "Please specify a machine name" if name.blank?

      pathname = File.expand_path "./#{name}"

      if Dir.exist?(pathname)
        puts "A machine with this name already exists. Please use a different name."
        return
      end

      FileUtils.mkdir pathname
      FileUtils.cp_r "#{SmartMachine.config.gem_dir}/lib/smart_machine/templates/dotsmartmachine/.", pathname
      FileUtils.chdir pathname do
        credentials = SmartMachine::Credentials.new
        credentials.create

        File.write("Gemfile", File.open("Gemfile",&:read).gsub("replace_ruby_version", "#{SmartMachine.ruby_version}"))
        File.write(".ruby-version", SmartMachine.ruby_version)
        if dev
          File.write("Gemfile", File.open("Gemfile",&:read).gsub("\"~> replace_smartmachine_version\"", "path: \"../\""))
        else
          File.write("Gemfile", File.open("Gemfile",&:read).gsub("replace_smartmachine_version", "#{SmartMachine.version}"))
        end
        system("mv gitignore-template .gitignore")

        # Here BUNDLE_GEMFILE is needed as it may be already set due to usage of bundle exec (which may not be correct in this case)
        bundle_gemfile = "#{pathname}/Gemfile"
        system("BUNDLE_GEMFILE='#{bundle_gemfile}' bundle install && BUNDLE_GEMFILE='#{bundle_gemfile}' bundle binstubs smartmachine")

        system("git init && git add . && git commit -m 'initial commit by SmartMachine #{SmartMachine.version}'")
      end

      puts "New machine #{name} has been created."
    end

    def run_on_machine(commands:)
      commands = Array(commands).flatten
      ssh = SmartMachine::SSH.new
      status = ssh.run commands

      status[:exit_code] == 0
    end

    def setup
      getting_started
      securing_your_server
      setup_services
    end

    private

    def getting_started
    end

    def securing_your_server
      # apt update && apt upgrade
      # puts 'When updating some packages, you may be prompted to use updated configuration files. If prompted, it is typically safer to keep the locally installed version.'

      # apt install locales-all
      # puts 'You may be prompted to make a menu selection when the Grub package is updated on Ubuntu. If prompted, select keep the local version currently installed.'

      # dpkg-reconfigure tzdata
      # debconf-set-selections <<EOF
      # tzdata tzdata/Areas select Asia
      # tzdata tzdata/Areas seen true
      # tzdata tzdata/Zones/Asia select Kolkata
      # tzdata tzdata/Zones/Asia seen true
      # EOF
      # dpkg-reconfigure -fnoninteractive tzdata
      # date

      # hostnamectl set-hostname SmartMachine.credentials.machine[:name]

      # The value you assign as your system’s FQDN should have an “A” record in DNS pointing to your Linode’s IPv4 address. For IPv6, you should also set up a DNS “AAAA” record pointing to your Linode’s IPv6 address.
      # Add DNS records for IPv4 and IPv6 for ip addresses and their fully qualified domain names FQDN
      # /etc/hosts
      # 203.0.113.10 SmartMachine.credentials.machine[:name].example.com SmartMachine.credentials.machine[:name]
      # 2600:3c01::a123:b456:c789:d012 SmartMachine.credentials.machine[:name].example.com SmartMachine.credentials.machine[:name]

      # adduser example_user
      # adduser example_user sudo

      # mkdir -p ~/.ssh && sudo chmod -R 700 ~/.ssh/
      # scp ~/.ssh/id_rsa.pub example_user@203.0.113.10:~/.ssh/authorized_keys
      # sudo chmod -R 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys

      # sudo nano /etc/ssh/sshd_config
      # PermitRootLogin no
      # PasswordAuthentication no
      # echo 'AddressFamily inet' | sudo tee -a /etc/ssh/sshd_config
      # sudo systemctl restart sshd

      # sudo apt update && sudo apt upgrade -y

      # sudo apt install ufw
      # sudo ufw default allow outgoing
      # sudo ufw default deny incoming
      # sudo ufw allow SmartMachine.credentials.machine[:port]/tcp
      # sudo ufw enable
      # sudo ufw logging on

      # sudo apt install fail2ban
      # sudo apt install sendmail
      # sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
      # sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
      # Change destmail
      # Change action = %(action_mwl)s
      # sudo fail2ban-client reload
      # sudo fail2ban-client status

      # Send email to show that there is a need for pending updates to be completed
      # apt install apticron
      # /usr/lib/apticron/apticron.conf
      # EMAIL="root@example.com"

      # Automatic Updates
      # apt install unattended-upgrades
      # sudo systemctl enable unattended-upgrades
      # sudo systemctl start unattended-upgrades
      # nano /etc/apt/apt.conf.d/50unattended-upgrades
      # Unattended-Upgrade::Mail "destemail@domain.com";
      # Unattended-Upgrade::SyslogEnable "true";
      # Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
      # Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
      # Unattended-Upgrade::Remove-Unused-Dependencies "true";
      # nano /etc/apt/apt.conf.d/20auto-upgrades
      # APT::Periodic::Update-Package-Lists "1";
      # APT::Periodic::Unattended-Upgrade "1";
      # APT::Periodic::AutocleanInterval "7";
    end

    def setup_services
      run_on_machine(commands: "sudo apt update && sudo apt upgrade")

      sysctl_lines = []
      # sysctl_lines.push('# KVM uses this.')
      # sysctl_lines.push('# These lines should only be activated for VM hosts and not for VM guests.')
      # sysctl_lines.push('# When getting a VM from a service provider, you will get a VM guest and not a VM host and hence these lines should not be added.')
      # sysctl_lines.push('# Prevent bridged traffic from being processed by iptables rules.')
      # sysctl_lines.push('net.bridge.bridge-nf-call-ip6tables=0')
      # sysctl_lines.push('net.bridge.bridge-nf-call-iptables=0')
      # sysctl_lines.push('net.bridge.bridge-nf-call-arptables=0')
      sysctl_lines.push('# Redis uses this.')
      sysctl_lines.push('vm.overcommit_memory=1')
      sysctl_lines.push('# Elasticsearch uses this.')
      sysctl_lines.push('vm.max_map_count=262144')
      commands = [
        "sudo touch /etc/sysctl.d/99-smartmachine.conf",
        "echo -e '#{sysctl_lines.join('\n')}' | sudo tee /etc/sysctl.d/99-smartmachine.conf",
        "sudo sysctl -p /etc/sysctl.d/99-smartmachine.conf"
      ]
      run_on_machine(commands: commands)
    end

    # These swapfile methods can be used (after required modification), when you need to make swapfile for more memory.
    # def self.create_swapfile
    # 	# Creating swapfile for bundler to work properly
    # 	unless system("sudo swapon -s | grep -ci '/swapfile'", out: File::NULL)
    # 		print "-----> Creating swap swapfile ... "
    # 		system("sudo install -o root -g root -m 0600 /dev/null /swapfile", out: File::NULL)
    # 		system("sudo dd if=/dev/zero of=/swapfile bs=1k count=2048k", [:out, :err] => File::NULL)
    # 		system("sudo mkswap /swapfile", out: File::NULL)
    # 		system("sudo sh -c 'echo \"/swapfile       none    swap    sw      0       0\" >> /etc/fstab'", out: File::NULL)
    # 		system("echo 10 | sudo tee /proc/sys/vm/swappiness", out: File::NULL)
    # 		system("sudo sed -i '/^vm.swappiness = /d' /etc/sysctl.conf", out: File::NULL)
    # 		system("echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf", out: File::NULL)
    # 		system("echo 50 | sudo tee /proc/sys/vm/vfs_cache_pressure", out: File::NULL)
    # 		system("sudo sed -i '/^vm.vfs_cache_pressure = /d' /etc/sysctl.conf", out: File::NULL)
    # 		system("echo vm.vfs_cache_pressure = 50 | sudo tee -a /etc/sysctl.conf", out: File::NULL)
    # 		puts "done"
    #
    # 		print "-----> Starting swap swapfile ... "
    # 		if system("sudo swapon /swapfile", out: File::NULL)
    # 			puts "done"
    # 		end
    # 	end
    # end
    #
    # def self.destroy_swapfile
    # 	if system("sudo swapon -s | grep -ci '/swapfile'", out: File::NULL)
    # 		print "-----> Stopping swap swapfile ... "
    # 		if system("sudo swapoff /swapfile", out: File::NULL)
    # 			system("sudo sed -i '/^vm.swappiness = /d' /etc/sysctl.conf", out: File::NULL)
    # 		 	system("echo 100 | sudo tee /proc/sys/vm/vfs_cache_pressure", out: File::NULL)
    # 			system("echo 60 | sudo tee /proc/sys/vm/swappiness", out: File::NULL)
    # 			puts "done"
    #
    # 			print "-----> Removing swap swapfile ... "
    # 			system("sudo sed -i '/^\\/swapfile/d' /etc/fstab", out: File::NULL)
    # 			if system("sudo rm /swapfile", out: File::NULL)
    # 				puts "done"
    # 			end
    # 		end
    # 	end
    # end
  end
end
