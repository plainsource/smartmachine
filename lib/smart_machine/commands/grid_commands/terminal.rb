module SmartMachine
  module Commands
    module GridCommands
      class Terminal < SubThor
        include Utilities

        desc "install", "Install terminal grid"
        def install
          inside_machine_dir do
            with_docker_running do
              puts "-----> Installing Terminal"
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid terminal installer"
              puts "-----> Terminal Installation Complete"
            end
          end
        end

        desc "uninstall", "Uninstall terminal grid"
        def uninstall
          inside_machine_dir do
            with_docker_running do
              puts "-----> Uninstalling Terminal"
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid terminal uninstaller"
              puts "-----> Terminal Uninstallation Complete"
            end
          end
        end

        desc "up", "Take UP the terminal grid"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid terminal uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the terminal grid"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid terminal downer#{name_option}"
            end
          end
        end

        desc "installer", "Terminal grid installer", hide: true
        def installer
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.terminal.first
            terminal = SmartMachine::Grids::Terminal.new(name: name.to_s)
            terminal.installer
          end
        end

        desc "uninstaller", "Terminal grid uninstaller", hide: true
        def uninstaller
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.terminal.first
            terminal = SmartMachine::Grids::Terminal.new(name: name.to_s)
            terminal.uninstaller
          end
        end

        desc "uper", "Terminal grid uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              terminal = SmartMachine::Grids::Terminal.new(name: options[:name])
              terminal.uper
            else
              SmartMachine.config.grids.terminal.each do |name, config|
                terminal = SmartMachine::Grids::Terminal.new(name: name.to_s)
                terminal.uper
              end
            end
          end
        end

        desc "downer", "Terminal grid downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              terminal = SmartMachine::Grids::Terminal.new(name: options[:name])
              terminal.downer
            else
              SmartMachine.config.grids.terminal.each do |name, config|
                terminal = SmartMachine::Grids::Terminal.new(name: name.to_s)
                terminal.downer
              end
            end
          end
        end
      end
    end
  end
end
