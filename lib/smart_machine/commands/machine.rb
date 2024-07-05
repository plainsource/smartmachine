require 'smart_machine/commands/machine_commands/sub_thor'
require 'smart_machine/commands/machine_commands/network'

module SmartMachine
  module Commands
    class Machine < Thor
      include Utilities

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

      desc "network", "Run machine network commands"
      subcommand "network", MachineCommands::Network
    end
  end
end
