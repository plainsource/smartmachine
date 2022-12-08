module SmartMachine
  module Commands
    module GridCommands
      class Elasticsearch < SubThor
        include Utilities

        desc "up", "Take UP the elasticsearch grid"
        option :name, type: :string
        def up
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid elasticsearch uper#{name_option}"
            end
          end
        end

        desc "down", "Take DOWN the elasticsearch grid"
        option :name, type: :string
        def down
          inside_machine_dir do
            with_docker_running do
              machine = SmartMachine::Machine.new
              name_option = options[:name] ? " --name=#{options[:name]}" : ""
              machine.run_on_machine commands: "smartengine grid elasticsearch downer#{name_option}"
            end
          end
        end

        desc "uper", "Elasticsearch grid uper", hide: true
        option :name, type: :string
        def uper
          inside_engine_machine_dir do
            if options[:name]
              elasticsearch = SmartMachine::Grids::Elasticsearch.new(name: options[:name])
              elasticsearch.uper
            else
              SmartMachine.config.grids.elasticsearch.each do |name, config|
                elasticsearch = SmartMachine::Grids::Elasticsearch.new(name: name.to_s)
                elasticsearch.uper
              end
            end
          end
        end

        desc "downer", "Elasticsearch grid downer", hide: true
        option :name, type: :string
        def downer
          inside_engine_machine_dir do
            if options[:name]
              elasticsearch = SmartMachine::Grids::Elasticsearch.new(name: options[:name])
              elasticsearch.downer
            else
              SmartMachine.config.grids.elasticsearch.each do |name, config|
                elasticsearch = SmartMachine::Grids::Elasticsearch.new(name: name.to_s)
                elasticsearch.downer
              end
            end
          end
        end
      end
    end
  end
end
