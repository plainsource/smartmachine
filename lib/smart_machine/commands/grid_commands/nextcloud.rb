module SmartMachine
  module Commands
    module GridCommands
      class Nextcloud < SubThor
        include Utilities

        desc "up", "Take UP the nextcloud grid"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid nextcloud uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the nextcloud grid"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid nextcloud downer#{name_option}"
            end
          end
        end

        desc "uper", "Nextcloud grid uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              nextcloud = SmartMachine::Grids::Nextcloud.new(name: options[:name])
              nextcloud.uper
            else
              SmartMachine.config.grids.nextcloud.each do |name, config|
                nextcloud = SmartMachine::Grids::Nextcloud.new(name: name.to_s)
                nextcloud.uper
              end
            end
          end
        end

        desc "downer", "Nextcloud grid downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              nextcloud = SmartMachine::Grids::Nextcloud.new(name: options[:name])
              nextcloud.downer
            else
              SmartMachine.config.grids.nextcloud.each do |name, config|
                nextcloud = SmartMachine::Grids::Nextcloud.new(name: name.to_s)
                nextcloud.downer
              end
            end
          end
        end
      end
    end
  end
end
