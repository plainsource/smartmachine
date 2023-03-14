# The main SmartMachine Engine driver
module SmartMachine
  class Engine < SmartMachine::Base
    def initialize
      @scp = SmartMachine::SCP.new
      @grids_nginx = SmartMachine::Grids::Nginx.new
      @syncer = SmartMachine::Syncer.new
      @machine = SmartMachine::Machine.new

      @gem_cache_dir = Gem::Specification.find_by_name("smartmachine").cache_dir

      if platform_on_machine?(os: "linux", distro_name: "debian")
        @docker_gid = "getent group docker | cut -d: -f3"
        @docker_gname = "docker"
        @docker_socket_path = "/var/run/docker.sock"
        @remote_smartmachine_dir = "/home/`whoami`/smartmachine"
      else
        raise("OS not supported to set docker_gid, docker_gname and docker_socket_path")
      end
    end

    def install
      puts "-----> Installing SmartMachine Engine"

      if @machine.run_on_machine commands: "mkdir -p #{@remote_smartmachine_dir}/tmp/engine"
        @scp.upload!(local_path: "#{@gem_cache_dir}/smartmachine-#{SmartMachine.version}.gem", remote_path: "~/smartmachine/tmp/engine")
      end

      puts "-----> Creating image for Engine ... "
      command = [
        "docker image build --quiet --tag #{engine_image_name_with_version}",
        "--build-arg SMARTMACHINE_MASTER_KEY=#{SmartMachine::Credentials.new.read_key}",
        "--build-arg USER_NAME=`id -un`",
        "--build-arg USER_UID=`id -u`",
        "--build-arg DOCKER_GID=`#{@docker_gid}`",
        "--build-arg DOCKER_GNAME=#{@docker_gname}",
        "-f- #{@remote_smartmachine_dir}/tmp/engine",
        "<<'EOF'\n#{dockerfile}EOF"
      ]
      @machine.run_on_machine commands: command.join(" ")
      puts "done"

      puts "-----> Adding Engine to PATH ... "
      commands = [
        "mkdir -p #{@remote_smartmachine_dir}/bin && touch #{@remote_smartmachine_dir}/bin/smartengine",
        "echo '#{smartengine_binary_template}' > #{@remote_smartmachine_dir}/bin/smartengine",
        "chmod +x #{@remote_smartmachine_dir}/bin/smartengine",
        "sudo ln -sf #{@remote_smartmachine_dir}/bin/smartengine /usr/local/bin/smartengine",
        "rm -r #{@remote_smartmachine_dir}/tmp/engine",
        "smartengine --version"
      ]
      @machine.run_on_machine(commands: commands)
      puts "done"

      @grids_nginx.create_htpasswd_files

      @syncer.sync(initial: true)

      puts "-----> SmartMachine Engine Installation Complete"
    end

    def uninstall
      puts "-----> Uninstalling SmartMachine Engine"

      commands = [
        "sudo rm /usr/local/bin/smartengine",
        "sudo rm #{@remote_smartmachine_dir}/bin/smartengine",
        "docker rmi $(docker images -q #{engine_image_name})"
      ]
      @machine.run_on_machine(commands: commands)

      puts "-----> SmartMachine Engine Uninstallation Complete"
    end

    private

    def smartengine_binary_template
      <<~BASH
        #!/bin/bash

        docker run -i --rm \
        -e INSIDE_ENGINE="yes" \
        -v "#{@remote_smartmachine_dir}:/home/`whoami`/machine" \
        -v "#{@docker_socket_path}:/var/run/docker.sock" \
        -w "/home/`whoami`/machine" \
        -u `id -u` \
        --entrypoint "smartmachine" \
        #{engine_image_name_with_version} "$@"
      BASH
    end

    def engine_image_name_with_version
      "#{engine_image_name}:#{SmartMachine.version}"
    end

    def engine_image_name
      "smartmachine/smartengine"
    end

    def dockerfile
      file = <<~'DOCKERFILE'
        FROM ruby:2.7.7-bullseye
	LABEL maintainer="plainsource <plainsource@humanmind.me>"

	# User
	# --- Fix to change docker gid to 998 (if it is in use) so that addgroup is free to create a group with docker gid.
	ARG USER_NAME
	ARG USER_UID
	ARG DOCKER_GID
	ARG DOCKER_GNAME
	RUN sed -i "s/$DOCKER_GID/998/" /etc/group && \
	    adduser --disabled-password --gecos "" --uid "$USER_UID" "$USER_NAME" && \
	    addgroup --gid "$DOCKER_GID" "$DOCKER_GNAME" && adduser "$USER_NAME" "$DOCKER_GNAME"

	# Add docker repository for debian
	RUN apt-get update && apt-get install -y --no-install-recommends lsb-release && \
            mkdir -p /etc/apt/keyrings && \
            curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
            apt-get update

	# Essentials
	RUN apt-get update && \
            apt-get install -y --no-install-recommends \
                docker-ce-cli \
                rsync && \
            rm -rf /var/lib/apt/lists/*

	# smartmachine gem
	COPY ./smartmachine-%<smartmachine_version>s.gem ./smartmachine-%<smartmachine_version>s.gem
	RUN gem install --no-document ./smartmachine-%<smartmachine_version>s.gem && \
	    rm ./smartmachine-%<smartmachine_version>s.gem

	# SmartMachine master key
	ARG SMARTMACHINE_MASTER_KEY
	ENV SMARTMACHINE_MASTER_KEY=$SMARTMACHINE_MASTER_KEY
      DOCKERFILE

      format(file, "smartmachine_ruby_version": SmartMachine.ruby_version, "smartmachine_version": SmartMachine.version)
    end
  end
end
