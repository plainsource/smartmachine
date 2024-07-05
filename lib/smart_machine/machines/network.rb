module SmartMachine
  class Machines
    class Network < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.network.dig(name.to_sym)
        raise "network config for #{name} not found." unless config

        @driver = config.dig(:driver)

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def uper
        raise "Error: Could not create network: #{@name}" unless system(command.compact.join(' '), out: File::NULL)

        puts "Created network: #{@name}"
      end

      def downer
        raise "Error: Could not remove network: #{@name}" unless system("docker network rm '#{@name}'", out: File::NULL)

        puts "Removed network: #{@name}"
      end

      private

      def command
        [
          'docker network create',
          "--driver=#{@driver}",
          @name
        ]
      end
    end
  end
end
