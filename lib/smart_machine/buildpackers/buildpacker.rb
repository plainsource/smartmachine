module SmartMachine
  module Buildpackers
    class Buildpacker < SmartMachine::Base
      def initialize(packname:)
        @packname = packname
      end

      def installer
        if @packname == "rails"
          unless system("docker image inspect #{rails_image_name}", [:out, :err] => File::NULL)
            print "-----> Creating image #{rails_image_name} ... "
            command = [
              "docker image build -t #{rails_image_name}",
              "--build-arg SMARTMACHINE_VERSION=#{SmartMachine.version}",
              "--build-arg USER_UID=`id -u`",
              "--build-arg USER_NAME=`id -un`",
              "-<<'EOF'\n#{dockerfile_rails}EOF"
            ]
            if system(command.join(" "), out: File::NULL)
              puts "done"
            end
          end
        else
          raise "Error: Pack with name #{name} not supported."
        end
      end

      def uninstaller
        if @packname == "rails"
          if system("docker image inspect #{rails_image_name}", [:out, :err] => File::NULL)
            print "-----> Removing image #{rails_image_name} ... "
            if system("docker image rm #{rails_image_name}", out: File::NULL)
              puts "done"
            end
          end
        else
          raise "Error: Pack with name #{name} not supported."
        end
      end

      def packer
        if @packname == "rails" && File.exist?("bin/rails")
          rails = SmartMachine::Buildpackers::Rails.new(appname: nil, appversion: nil)
          rails.packer
        else
          raise "Error: Pack with name #{@packname} not supported."
        end
      end

      private

      def rails_image_name
        "smartmachine/buildpackers/rails:#{SmartMachine.version}"
      end

      def dockerfile_rails
        file = <<~'DOCKERFILE'
	  ARG SMARTMACHINE_VERSION

	  FROM smartmachine/smartengine:$SMARTMACHINE_VERSION
	  LABEL maintainer="plainsource <plainsource@humanmind.me>"

	  RUN apt-get update && \
	      apt-get install -y --no-install-recommends \
	        # dependencies for ruby from https://github.com/rbenv/ruby-build/wiki#ubuntudebianmint
                autoconf \
                bison \
                patch \
                build-essential \
                rustc \
                libssl-dev \
                libyaml-dev \
                libreadline6-dev \
                zlib1g-dev \
                libgmp-dev \
                libncurses5-dev \
                libffi-dev \
                libgdbm6 \
                libgdbm-dev \
                libdb-dev \
                uuid-dev && \
              # ruby on rails
              curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
	      echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
	      apt-get update && \
	      apt-get install -y --no-install-recommends \
		  tzdata \
		  nodejs \
		  yarn \
		  libmariadb-dev \
		  libvips42 \
		  ffmpeg \
		  mupdf \
		  mupdf-tools \
		  poppler-utils && \
              rm -rf /var/lib/apt/lists/* && \
              # ImageMagick 7. Remove this after its dependency is gone from ruby on rails.
              cd /opt && wget https://download.imagemagick.org/archive/releases/ImageMagick-7.1.1-29.tar.gz && \
                tar xvzf ImageMagick-7.1.1-29.tar.gz && \
                cd ImageMagick-7.1.1-29 && \
                ./configure && \
                make && \
                make install && \
                ldconfig /usr/local/lib && \
                magick -version

	  CMD ["smartmachine", "buildpacker", "packer", "rails"]
        DOCKERFILE

        format(file)
      end

      # These swapfile methods can be used (after required modification), when you need to make swapfile for more memory.
      # def self.create_swapfile
      # 	# Creating swapfile for bundler to work properly
      # 	unless system("sudo swapon -s | grep -ci '/swapfile'", out: File::NULL)
      # 		print "-----> Creating swap swapfile ... "
      # 		system("sudo install -o root -g root -m 0600 /dev/null /swapfile", out: File::NULL)
      # 		system("sudo dd if=/dev/zero of=/swapfile bs=1k count=2048k", [:out, :err] => File::NULL)
      # 		system("sudo mkswap /swapfile", out: File::NULL)
      # 		system("sudo sh -c 'echo \"/swapfile       none    swap    sw      0       0\" >> /etc/fstab'", out: File::NULL)
      # 		system("echo 10 | sudo tee /proc/sys/vm/swappiness", out: File::NULL)
      # 		system("sudo sed -i '/^vm.swappiness = /d' /etc/sysctl.conf", out: File::NULL)
      # 		system("echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf", out: File::NULL)
      # 		system("echo 50 | sudo tee /proc/sys/vm/vfs_cache_pressure", out: File::NULL)
      # 		system("sudo sed -i '/^vm.vfs_cache_pressure = /d' /etc/sysctl.conf", out: File::NULL)
      # 		system("echo vm.vfs_cache_pressure = 50 | sudo tee -a /etc/sysctl.conf", out: File::NULL)
      # 		puts "done"
      #
      # 		print "-----> Starting swap swapfile ... "
      # 		if system("sudo swapon /swapfile", out: File::NULL)
      # 			puts "done"
      # 		end
      # 	end
      # end
      #
      # def self.destroy_swapfile
      # 	if system("sudo swapon -s | grep -ci '/swapfile'", out: File::NULL)
      # 		print "-----> Stopping swap swapfile ... "
      # 		if system("sudo swapoff /swapfile", out: File::NULL)
      # 			system("sudo sed -i '/^vm.swappiness = /d' /etc/sysctl.conf", out: File::NULL)
      # 			system("echo 60 | sudo tee /proc/sys/vm/swappiness", out: File::NULL)
      # 			puts "done"
      #
      # 			print "-----> Removing swap swapfile ... "
      # 			system("sudo sed -i '/^\\/swapfile/d' /etc/fstab", out: File::NULL)
      # 			if system("sudo rm /swapfile", out: File::NULL)
      # 				puts "done"
      # 			end
      # 		end
      # 	end
      # end
    end
  end
end
