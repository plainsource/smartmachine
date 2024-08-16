module SmartMachine
  class Grids
    class Emailer < SmartMachine::Base
      def initialize(name:)
        config = SmartMachine.config.grids.emailer.dig(name.to_sym)
        raise "emailer config for #{name} not found." unless config

        @image = "smartmachine/emailer:#{SmartMachine.version}"
        @fqdn = config.dig(:fqdn)
        @mailname = config.dig(:mailname)
        @sysadmin_email = config.dig(:sysadmin_email)
        @networks = config.dig(:networks)
        @mysql_host = config.dig(:mysql_host)
        @mysql_port = config.dig(:mysql_port)
        @mysql_user = config.dig(:mysql_user)
        @mysql_password = config.dig(:mysql_password)
        @mysql_database_name = config.dig(:mysql_database_name)
        @monit_smtp_email_name = config.dig(:monit_smtp_email_name)
        @monit_smtp_email_address = config.dig(:monit_smtp_email_address)
        @monit_smtp_host = config.dig(:monit_smtp_host)
        @monit_smtp_port = config.dig(:monit_smtp_port)
        @monit_smtp_username = config.dig(:monit_smtp_username)
        @monit_smtp_password = config.dig(:monit_smtp_password)
        @oracle_ips_allowed = config.dig(:oracle_ips_allowed)
        @oracle_deflect_url = config.dig(:oracle_deflect_url)

        @name = name.to_s
        @home_dir = File.expand_path('~')
      end

      def installer
        unless system("docker image inspect #{@image}", [:out, :err] => File::NULL)
          puts "-----> Creating image #{@image} ... "
          command = [
            "docker image build -t #{@image}",
            "--build-arg SMARTMACHINE_VERSION=#{SmartMachine.version}",
            "-f- #{SmartMachine.config.gem_dir}/lib/smart_machine/grids/emailer",
            "<<'EOF'\n#{dockerfile}EOF"
          ]
          if system(command.join(" "), out: File::NULL)
            puts "done"
          else
            raise "Error: Could not install image: #{@image}"
          end
        else
          raise "Error: Image already installed: #{@image}. Please uninstall using 'smartmachine grids emailer uninstall' and try installing again."
        end
      end

      def uninstaller
        unless system("docker inspect -f '{{.State.Running}}' '#{@name}'", [:out, :err] => File::NULL)
          if system("docker image inspect #{@image}", [:out, :err] => File::NULL)
            puts "-----> Removing image #{@image} ... "
            if system("docker image rm #{@image}", out: File::NULL)
              puts "done"
            end
          else
            raise "Error: Emailer already uninstalled. Please install using 'smartmachine grids emailer install' and try uninstalling again."
          end
        else
          raise "Error: Emailer is currently running. Please stop the emailer using 'smartmachine grids emailer down' and try uninstalling again."
        end
      end

      def uper
        if system("docker image inspect #{@image}", [:out, :err] => File::NULL)
          FileUtils.mkdir_p("#{@home_dir}/machine/grids/emailer/#{@name}/backups")
          FileUtils.mkdir_p("#{@home_dir}/machine/grids/emailer/#{@name}/data/vmail")
          FileUtils.mkdir_p("#{@home_dir}/machine/grids/emailer/#{@name}/data/opendkim")

          # Setting entrypoint permission.
          system("chmod +x #{@home_dir}/machine/config/emailer/docker/entrypoint.rb")

          # Creating & Starting containers
          print "-----> Creating container #{@name} ... "

          command = [
            "docker create",
            "--name='#{@name}'",
            "--env VIRTUAL_HOST=#{@fqdn}",
            "--env LETSENCRYPT_HOST=#{@fqdn}",
            "--env LETSENCRYPT_EMAIL=#{@sysadmin_email}",
            "--env LETSENCRYPT_TEST=false",
            "--env CONTAINER_NAME='#{@name}'",
            "--env FQDN='#{@fqdn}'",
            "--env MAILNAME='#{@mailname}'",
            "--env SYSADMIN_EMAIL='#{@sysadmin_email}'",
            "--env MYSQL_HOST='#{@mysql_host}'",
            "--env MYSQL_PORT='#{@mysql_port}'",
            "--env MYSQL_USER='#{@mysql_user}'",
            "--env MYSQL_PASSWORD='#{@mysql_password}'",
            "--env MYSQL_DATABASE_NAME='#{@mysql_database_name}'",
            "--env MONIT_SMTP_EMAIL_NAME='#{@monit_smtp_email_name}'",
            "--env MONIT_SMTP_EMAIL_ADDRESS='#{@monit_smtp_email_address}'",
            "--env MONIT_SMTP_HOST='#{@monit_smtp_host}'",
            "--env MONIT_SMTP_PORT='#{@monit_smtp_port}'",
            "--env MONIT_SMTP_USERNAME='#{@monit_smtp_username}'",
            "--env MONIT_SMTP_PASSWORD='#{@monit_smtp_password}'",
            "--env ORACLE_IPS_ALLOWED='#{@oracle_ips_allowed.join(' ')}'",
            "--env ORACLE_DEFLECT_URL='#{@oracle_deflect_url}'",
            "--expose='80'",
            "--publish='25:25'",
            # "--publish='465:465'",
            "--publish='587:587'",
            # "--publish='110:110'",
            "--publish='995:995'",
            # "--publish='143:143'",
            "--publish='993:993'",
            "--volume='#{@home_dir}/smartmachine/grids/nginx/certificates/#{@fqdn}:/etc/letsencrypt/live/#{@fqdn}:ro'",
            "--volume='#{@home_dir}/smartmachine/config/emailer:/smartmachine/config/emailer:ro'",
            "--volume='#{@home_dir}/smartmachine/grids/emailer/#{@name}/data/vmail:/var/vmail'",
            "--volume='#{@home_dir}/smartmachine/grids/emailer/#{@name}/data/opendkim:/etc/opendkim'",
            "--entrypoint='/smartmachine/config/emailer/docker/entrypoint.rb'",
            "--tmpfs /run/tmpfs",
            "--init",
            "--restart='always'",
            "--network='nginx-network'",
            "#{@image}"
          ]
          if system(command.compact.join(" "), out: File::NULL)
            @networks.each do |network|
              system("docker network connect --alias #{@fqdn} #{network} #{@name}")
            end

            puts "done"
            puts "-----> Starting container #{@name} ... "
            if system("docker start #{@name}", out: File::NULL)
              puts "done"
            else
              raise "Error: Could not start container: #{@name}"
            end
          else
            raise "Error: Could not create container: #{@name}"
          end
        else
          raise "Error: Could not find image: #{@image}"
        end
      end

      def downer
        # Disconnecting networks
        @networks.reverse.each do |network|
          system("docker network disconnect #{network} #{@name}")
        end

        # Stopping & Removing containers - in reverse order
        print "-----> Stopping container #{@name} ... "
        if system("docker stop '#{@name}'", out: File::NULL)
          puts "done"
          print "-----> Removing container #{@name} ... "
          if system("docker rm '#{@name}'", out: File::NULL)
            puts "done"
          end
        end
      end

      private

      def dockerfile
        file = <<~'DOCKERFILE'
          ARG SMARTMACHINE_VERSION

	  FROM smartmachine/smartengine:$SMARTMACHINE_VERSION
	  LABEL maintainer="plainsource <plainsource@humanmind.me>"

	  SHELL ["/bin/bash", "-c"]

	  RUN apt-get update && \
	      \
	      debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'" && \
              debconf-set-selections <<< "postfix postfix/mailname string %<mailname>s" && \
	      apt-get install -y --no-install-recommends \
	          rsyslog \
	          postfix postfix-mysql \
	          dovecot-managesieved dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql \
	          spamassassin spamc \
	          opendkim opendkim-tools \
                  postfix-policyd-spf-python postfix-pcre \
	          haproxy monit && \
	      rm -rf /var/lib/apt/lists/*
        DOCKERFILE

        format(file, "mailname": @mailname)
      end
    end
  end
end
