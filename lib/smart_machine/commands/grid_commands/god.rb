module SmartMachine
  module Commands
    module GridCommands
      class God < SubThor
        include Utilities

        desc "install", "Install god grid"
        def install
          inside_machine_dir do
            with_docker_running do
              puts "-----> Installing God"
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid god installer"
              puts "-----> God Installation Complete"
            end
          end
        end

        desc "uninstall", "Uninstall god grid"
        def uninstall
          inside_machine_dir do
            with_docker_running do
              puts "-----> Uninstalling God"
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid god uninstaller"
              puts "-----> God Uninstallation Complete"
            end
          end
        end

        desc "up", "Take UP the god grid"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid god uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the god grid"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid god downer#{name_option}"
            end
          end
        end

        desc "installer", "God grid installer", hide: true
        def installer
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.god.first
            god = SmartMachine::Grids::God.new(name: name.to_s)
            god.installer
          end
        end

        desc "uninstaller", "God grid uninstaller", hide: true
        def uninstaller
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.god.first
            god = SmartMachine::Grids::God.new(name: name.to_s)
            god.uninstaller
          end
        end

        desc "uper", "God grid uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              god = SmartMachine::Grids::God.new(name: options[:name])
              god.uper
            else
              SmartMachine.config.grids.god.each do |name, config|
                god = SmartMachine::Grids::God.new(name: name.to_s)
                god.uper
              end
            end
          end
        end

        desc "downer", "God grid downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              god = SmartMachine::Grids::God.new(name: options[:name])
              god.downer
            else
              SmartMachine.config.grids.god.each do |name, config|
                god = SmartMachine::Grids::God.new(name: name.to_s)
                god.downer
              end
            end
          end
        end
      end
    end
  end
end
