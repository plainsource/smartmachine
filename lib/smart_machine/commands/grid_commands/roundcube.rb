module SmartMachine
  module Commands
    module GridCommands
      class Roundcube < SubThor
        include Utilities

        desc "up", "Take UP the roundcube grid"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid roundcube uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the roundcube grid"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid roundcube downer#{name_option}"
            end
          end
        end

        desc "uper", "Roundcube grid uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              roundcube = SmartMachine::Grids::Roundcube.new(name: options[:name])
              roundcube.uper
            else
              SmartMachine.config.grids.roundcube.each do |name, config|
                roundcube = SmartMachine::Grids::Roundcube.new(name: name.to_s)
                roundcube.uper
              end
            end
          end
        end

        desc "downer", "Roundcube grid downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              roundcube = SmartMachine::Grids::Roundcube.new(name: options[:name])
              roundcube.downer
            else
              SmartMachine.config.grids.roundcube.each do |name, config|
                roundcube = SmartMachine::Grids::Roundcube.new(name: name.to_s)
                roundcube.downer
              end
            end
          end
        end
      end
    end
  end
end
