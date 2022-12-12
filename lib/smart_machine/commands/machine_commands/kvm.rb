module SmartMachine
  module Commands
    module MachineCommands
      class Kvm < SubThor
        include Utilities

        desc "install", "Install KVM on the machine"
        def install
          inside_machine_dir do
            kvm = SmartMachine::Machine::Kvm.new
            kvm.install
          end
        end
      end
    end
  end
end
