module SmartMachine
  module Commands
    module GridCommands
      class Emailer < SubThor
        include Utilities

        desc "install", "Install emailer grid"
        def install
          inside_machine_dir do
            with_docker_running do
              puts "-----> Installing Emailer"
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid emailer installer"
              puts "-----> Emailer Installation Complete"
            end
          end
        end

        desc "uninstall", "Uninstall emailer grid"
        def uninstall
          inside_machine_dir do
            with_docker_running do
              puts "-----> Uninstalling Emailer"
              machine = SmartMachine::Machine.new
              machine.run_on_machine commands: "smartengine grid emailer uninstaller"
              puts "-----> Emailer Uninstallation Complete"
            end
          end
        end

        desc "up", "Take UP the emailer grid"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid emailer uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the emailer grid"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid emailer downer#{name_option}"
            end
          end
        end

        desc "installer", "Emailer grid installer", hide: true
        def installer
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.emailer.first
            emailer = SmartMachine::Grids::Emailer.new(name: name.to_s)
            emailer.installer
          end
        end

        desc "uninstaller", "Emailer grid uninstaller", hide: true
        def uninstaller
          inside_engine_machine_dir do
            name, config = SmartMachine.config.grids.emailer.first
            emailer = SmartMachine::Grids::Emailer.new(name: name.to_s)
            emailer.uninstaller
          end
        end

        desc "uper", "Emailer grid uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              emailer = SmartMachine::Grids::Emailer.new(name: options[:name])
              emailer.uper
            else
              SmartMachine.config.grids.emailer.each do |name, config|
                emailer = SmartMachine::Grids::Emailer.new(name: name.to_s)
                emailer.uper
              end
            end
          end
        end

        desc "downer", "Emailer grid downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              emailer = SmartMachine::Grids::Emailer.new(name: options[:name])
              emailer.downer
            else
              SmartMachine.config.grids.emailer.each do |name, config|
                emailer = SmartMachine::Grids::Emailer.new(name: name.to_s)
                emailer.downer
              end
            end
          end
        end
      end
    end
  end
end
