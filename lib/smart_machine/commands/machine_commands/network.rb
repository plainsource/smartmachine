module SmartMachine
  module Commands
    module MachineCommands
      class Network < SubThor
        include Utilities

        desc "up", "Take UP the machine network"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine machine network uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the machine network"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine machine network downer#{name_option}"
            end
          end
        end

        desc "uper", "Machine network uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              network = SmartMachine::Machines::Network.new(name: options[:name])
              network.uper
            else
              SmartMachine.config.network.each do |name, config|
                network = SmartMachine::Machines::Network.new(name: name.to_s)
                network.uper
              end
            end
          end
        end

        desc "downer", "Machine network downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              network = SmartMachine::Machines::Network.new(name: options[:name])
              network.downer
            else
              SmartMachine.config.network.each do |name, config|
                network = SmartMachine::Machines::Network.new(name: name.to_s)
                network.downer
              end
            end
          end
        end
      end
    end
  end
end
