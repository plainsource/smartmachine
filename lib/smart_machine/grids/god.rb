module SmartMachine
  class Grids
    class God < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.god.dig(name.to_sym)
        raise "god config for #{name} not found." unless config

        @image = "smartmachine/god:#{SmartMachine.version}"
        @config = config

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def installer
        raise "God: Already Installed." if image?
        raise "God: Could not build image #{@image}." unless build?
        puts  "God: Installed."
      end

      def uninstaller
        raise "God: Already Uninstalled." unless image?
        raise "God: Could not demolish image #{@image}." unless demolish?
        puts  "God: Uninstalled."
      end

      def uper
        raise "God: Not installed. Please install Grid." unless image?
        raise "God: Could not create container #{@name}." unless create?
        raise "God: Could not start container #{@name}." unless start?
        puts  "God: Grid is up."
      end

      def downer
        raise "God: Not installed. Please install Grid." unless image?
        raise "God: Could not stop container #{@name}." unless stop?
        raise "God: Could not remove container #{@name}." unless remove?
        puts  "God: Grid is down."
      end

      private

      def dockerfile
        file = <<~'DOCKERFILE'
          ARG SMARTMACHINE_VERSION

	  FROM smartmachine/smartengine:$SMARTMACHINE_VERSION
	  LABEL maintainer="plainsource <plainsource@humanmind.me>"

	  RUN apt-get update && \
	      rm -rf /var/lib/apt/lists/* && \
	      gem install god -v 0.13.7

	  COPY process.d /etc/god/process.d
	  COPY watch.d /etc/god/watch.d
	  COPY watch.god /etc/god/watch.god

	  COPY entrypoint.rb /usr/local/bin/entrypoint.rb
	  RUN chmod +x /usr/local/bin/entrypoint.rb
	  ENTRYPOINT ["entrypoint.rb"]

	  CMD ["god", "-c", "/etc/god/watch.god", "-D"]
        DOCKERFILE

        format(file)
      end

      def build?
        command = [
          "docker image build -t #{@image}",
          "--build-arg SMARTMACHINE_VERSION=#{SmartMachine.version}",
          "-f- #{SmartMachine.config.gem_dir}/lib/smart_machine/grids/god",
          "<<'EOF'\n#{dockerfile}EOF"
        ]
        system(command.join(" "), out: File::NULL)
      end

      def image?
        system("docker image inspect #{@image}", [:out, :err] => File::NULL)
      end

      def demolish?
        system("docker image rm #{@image}", out: File::NULL)
      end

      def create?
        command = [
          'docker create',
          "--name='#{@name}'",
          "--restart='always'",
          "--network='nginx-network'",
          "#{@image}"
        ]
        system(command.compact.join(" "), out: File::NULL)
      end

      def start?
        system("docker start #{@name}", out: File::NULL)
      end

      def running?
        system("docker inspect -f '{{.State.Running}}' '#{@name}'", [:out, :err] => File::NULL)
      end

      def stop?
        system("docker stop '#{@name}'", out: File::NULL)
      end

      def remove?
        system("docker rm '#{@name}'", out: File::NULL)
      end
    end
  end
end
