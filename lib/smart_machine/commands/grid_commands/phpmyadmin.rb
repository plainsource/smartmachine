module SmartMachine
  module Commands
    module GridCommands
      class Phpmyadmin < SubThor
        include Utilities

        desc "up", "Take UP the phpmyadmin grid"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid phpmyadmin uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the phpmyadmin grid"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid phpmyadmin downer#{name_option}"
            end
          end
        end

        desc "uper", "Phpmyadmin grid uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              phpmyadmin = SmartMachine::Grids::Phpmyadmin.new(name: options[:name])
              phpmyadmin.uper
            else
              SmartMachine.config.grids.phpmyadmin.each do |name, config|
                phpmyadmin = SmartMachine::Grids::Phpmyadmin.new(name: name.to_s)
                phpmyadmin.uper
              end
            end
          end
        end

        desc "downer", "Phpmyadmin grid downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              phpmyadmin = SmartMachine::Grids::Phpmyadmin.new(name: options[:name])
              phpmyadmin.downer
            else
              SmartMachine.config.grids.phpmyadmin.each do |name, config|
                phpmyadmin = SmartMachine::Grids::Phpmyadmin.new(name: name.to_s)
                phpmyadmin.downer
              end
            end
          end
        end
      end
    end
  end
end
