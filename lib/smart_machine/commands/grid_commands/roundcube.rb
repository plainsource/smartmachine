module SmartMachine
  module Commands
    module GridCommands
      class Roundcube < SubThor
        include Utilities

        desc "install", "Install roundcube grid"
        def install
          inside_machine_dir do
            with_docker_running do
              puts "-----> Installing Roundcube"
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid roundcube installer"
              puts "-----> Roundcube Installation Complete"
            end
          end
        end

        desc "uninstall", "Uninstall roundcube grid"
        def uninstall
          inside_machine_dir do
            with_docker_running do
              puts "-----> Uninstalling Roundcube"
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid roundcube uninstaller"
              puts "-----> Roundcube Uninstallation Complete"
            end
          end
        end

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

        desc "installer", "Roundcube grid installer", hide: true
        def installer
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.roundcube.first
            roundcube = SmartMachine::Grids::Roundcube.new(name: name.to_s)
            roundcube.installer
          end
        end

        desc "uninstaller", "Roundcube grid uninstaller", hide: true
        def uninstaller
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.roundcube.first
            roundcube = SmartMachine::Grids::Roundcube.new(name: name.to_s)
            roundcube.uninstaller
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
