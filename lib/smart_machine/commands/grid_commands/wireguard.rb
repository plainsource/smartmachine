module SmartMachine
  module Commands
    module GridCommands
      class Wireguard < SubThor
        include Utilities

        desc "up", "Take UP the wireguard grid"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid wireguard uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the wireguard grid"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid wireguard downer#{name_option}"
            end
          end
        end

        desc "uper", "Wireguard grid uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              wireguard = SmartMachine::Grids::Wireguard.new(name: options[:name])
              wireguard.uper
            else
              SmartMachine.config.grids.wireguard.each do |name, config|
                wireguard = SmartMachine::Grids::Wireguard.new(name: name.to_s)
                wireguard.uper
              end
            end
          end
        end

        desc "downer", "Wireguard grid downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              wireguard = SmartMachine::Grids::Wireguard.new(name: options[:name])
              wireguard.downer
            else
              SmartMachine.config.grids.wireguard.each do |name, config|
                wireguard = SmartMachine::Grids::Wireguard.new(name: name.to_s)
                wireguard.downer
              end
            end
          end
        end
      end
    end
  end
end
