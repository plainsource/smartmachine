require 'smart_machine/commands/machine_commands/sub_thor'
require 'smart_machine/commands/machine_commands/kvm'

module SmartMachine
  module Commands
    class Machine < Thor
      include Utilities

      desc "kvm", "Run kvm machine commands"
      subcommand "kvm", MachineCommands::Kvm

      desc "setup", "Initial setup of the machine"
      def setup
        inside_machine_dir do
          machine = SmartMachine::Machine.new
          machine.setup
        end
      end

      desc "ssh", "SSH into the machine"
      def ssh
        inside_machine_dir do
          ssh = SmartMachine::SSH.new
          ssh.login
        end
      end

      desc "run [COMMAND]", "Run commands on the machine"
      map ["run"] => :runner
      def runner(*args)
        inside_machine_dir do
          machine = SmartMachine::Machine.new
          machine.run_on_machine(commands: "#{args.join(' ')}")
        end
      end
    end
  end
end
