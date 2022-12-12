module SmartMachine
  class Machines
    class Kvm < SmartMachine::Base
      def initialize
        @home_dir = File.expand_path('~')
      end

      def install
        commands = [
          "sudo apt install --no-install-recommends qemu-system libvirt-clients libvirt-daemon-system virtinst qemu-utils bridge-utils",
          "sudo apt install --no-install-recommends libosinfo-bin libguestfs-tools",
          "adduser #{@username} libvirt",
          "virt-install --name vm1 --autostart --location /home/#{@username}/debian-11.5.0-amd64-DVD-1.iso --os-variant debian10 --disk size=80 --memory 1024 --graphics none --console pty,target_type=serial --extra-args 'console=ttyS0'",
          "virsh list --all"
        ]
        # run_on_machine(commands: commands)
      end
    end
  end
end
