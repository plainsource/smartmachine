require 'open3'

module SmartMachine
  module Buildpackers
    class Rails < SmartMachine::Base
      def initialize(appname:, appversion:)
        @home_dir = File.expand_path('~')
        @appname = appname
        @appversion = appversion
        @container_path = "#{@home_dir}/machine/apps/containers/#{@appname}"
      end

      def package
        return unless File.exist? "#{@container_path}/releases/#{@appversion}/bin/rails"

        logger.formatter = proc do |severity, datetime, progname, message|
          severity_text = { "DEBUG" => "\u{1f527} #{severity}:", "INFO" => " \u{276f}", "WARN" => "\u{2757} #{severity}:",
                           "ERROR" => "\u{274c} #{severity}:", "FATAL" => "\u{2b55} #{severity}:", "UNKNOWN" => "\u{2753} #{severity}:"
                          }
          "\t\t\t\t#{severity_text[severity]} #{message}\n"
        end

        logger.info "Ruby on Rails application detected."
        logger.info "Packaging Application ..."

        # Setup rails env
        env_path = "#{@container_path}/env"
        system("grep -q '^## Rails' #{env_path} || echo '## Rails' >> #{env_path}")
        system("grep -q '^MALLOC_ARENA_MAX=' #{env_path} || echo '# MALLOC_ARENA_MAX=2' >> #{env_path}")
        system("grep -q '^RAILS_ENV=' #{env_path} || echo 'RAILS_ENV=production' >> #{env_path}")
        system("grep -q '^RACK_ENV=' #{env_path} || echo 'RACK_ENV=production' >> #{env_path}")
        system("grep -q '^RAILS_LOG_TO_STDOUT=' #{env_path} || echo 'RAILS_LOG_TO_STDOUT=enabled' >> #{env_path}")
        system("grep -q '^RAILS_SERVE_STATIC_FILES=' #{env_path} || echo 'RAILS_SERVE_STATIC_FILES=enabled' >> #{env_path}")
        system("grep -q '^LANG=' #{env_path} || echo 'LANG=en_US.UTF-8' >> #{env_path}")
        system("grep -q '^RAILS_MASTER_KEY=' #{env_path} || echo 'RAILS_MASTER_KEY=yourmasterkey' >> #{env_path}")
        logger.warn "Please set your RAILS_MASTER_KEY env var for this rails app." if system("grep -q '^RAILS_MASTER_KEY=yourmasterkey' #{env_path}")

        # Setup app folders needed for volumes. If this is not created then docker will create it while running the container,
        # but the folder will have root user assigned instead of the current user.
        FileUtils.mkdir_p("#{@container_path}/app/vendor/bundle")
        FileUtils.mkdir_p("#{@container_path}/app/public/assets")
        FileUtils.mkdir_p("#{@container_path}/app/public/packs")
        FileUtils.mkdir_p("#{@container_path}/app/node_modules")
        FileUtils.mkdir_p("#{@container_path}/app/storage")
        FileUtils.mkdir_p("#{@container_path}/asdf")
        FileUtils.mkdir_p("#{@container_path}/releases/#{@appversion}/vendor/bundle")
        FileUtils.mkdir_p("#{@container_path}/releases/#{@appversion}/public/assets")
        FileUtils.mkdir_p("#{@container_path}/releases/#{@appversion}/public/packs")
        FileUtils.mkdir_p("#{@container_path}/releases/#{@appversion}/node_modules")
        FileUtils.mkdir_p("#{@container_path}/releases/#{@appversion}/storage")

        # Creating a valid docker app image.
        container = SmartMachine::Apps::Container.new(name: "#{@appname}-#{@appversion}-packed", appname: @appname, appversion: @appversion)
        if container.commit_app_image!
          logger.formatter = nil
          return true
        end

        logger.formatter = nil
        return false
      end

      def packer
        set_logger_formatter_arrow

        # TODO: The exec of final process should be done only in the Manager#containerize_process! and should be removed from here.
        # This method should only pack a fully functioning container and do nothing else.
        if File.exist? "tmp/smartmachine/packed"
          begin
            pid = File.read('tmp/smartmachine/packed').to_i
            Process.kill('QUIT', pid)
          rescue Errno::ESRCH # No such process
          end
          exec(user_bash("bundle exec puma --config config/puma.rb"))
        else
          if initial_setup? && bundle_install? && precompile_assets? && db_migrate? && test_web_server?
            logger.formatter = nil

            exit 0
          else
            logger.error "Could not continue ... Launch Failed."
            logger.formatter = nil

            exit 1
          end
        end
      end

      private

      # Perform initial_setup
      def initial_setup?
        logger.info "Performing initial setup ..."

        set_logger_formatter_tabs

        # Fix for mysql2 gem to support sha256_password, until it is fixed in main mysql2 gem.
        # https://github.com/brianmario/mysql2/issues/1023
        unless system("mkdir -p ./lib/mariadb && ln -s /usr/lib/mariadb/plugin ./lib/mariadb/plugin")
          logger.error "Could not setup fix for mysql2 mariadb folders."
          return false
        end

        # Install asdf
        system("echo '\n# asdf version manager\nif [ -f \"$HOME/.asdf/asdf.sh\" ]; then\n    . \"$HOME/.asdf/asdf.sh\"\nfi\nif [ -f \"$HOME/.asdf/completions/asdf.bash\" ]; then\n    . \"$HOME/.asdf/completions/asdf.bash\"\nfi' >> ~/.profile", out: File::NULL)
        unless system(user_bash("asdf --version"), [:out, :err] => File::NULL)
          asdf_version = `git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags https://github.com/asdf-vm/asdf.git '*.*.*' | tail --lines=1 | cut --delimiter='/' --fields=3`.strip
          logger.info "Installing asdf #{asdf_version}...\n"

          # Clear all files inside .asdf dir including dot files.
          system("rm -rf ~/.asdf/..?* ~/.asdf/.[!.]* ~/.asdf/*")
          Open3.popen2e(user_bash("git -c advice.detachedHead=false clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch #{asdf_version}")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end

          unless system(user_bash("asdf --version"), [:out, :err] => File::NULL)
            logger.error "Could not install asdf.\n"
            return false
          end
        end
        logger.info "Using asdf " + `#{user_bash("asdf --version")}`.strip + "\n"

        # Install ruby
        ruby_version = `sed -n '/RUBY VERSION/{n;p}' Gemfile.lock`.strip.split(" ").last&.split("p")&.first
        if ruby_version.nil? || ruby_version.empty?
          logger.error "Could not find ruby version. Have you specified it explicitly in Gemfile and run bundle install?\n"
          return false
        end

        unless `#{user_bash('ruby -e "puts RUBY_VERSION"')}`.strip == ruby_version
          logger.info "Installing ruby v#{ruby_version}\n"

          Open3.popen2e(user_bash("asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end
          Open3.popen2e(user_bash("asdf plugin update ruby")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end
          Open3.popen2e(user_bash("asdf install ruby #{ruby_version}")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end
          Open3.popen2e(user_bash("asdf local ruby #{ruby_version}")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end

          unless `#{user_bash('ruby -e "puts RUBY_VERSION"')}`.strip == ruby_version
            logger.error "Could not install ruby with version #{ruby_version}. Please try another valid version that asdf supports.\n"
            return false
          end
        end
        logger.info "Using ruby v" + `#{user_bash('ruby -e "puts RUBY_VERSION"')}`.strip + "\n"

        # Install bundler
        bundler_version = `sed -n '/BUNDLED WITH/{n;p}' Gemfile.lock`.strip
        if bundler_version.nil? || bundler_version.empty?
          logger.error "Could not find bundler version. Please ensure BUNDLED_WITH section is present in your Gemfile.lock.\n"
          return false
        end

        unless system(user_bash("gem list -i '^bundler$' --version #{bundler_version}"), out: File::NULL)
          logger.info "Installing bundler v#{bundler_version}\n"

          Open3.popen2e(user_bash("gem install --no-document bundler -v #{bundler_version}")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end

          unless system(user_bash("gem list -i '^bundler$' --version #{bundler_version}"), out: File::NULL)
            logger.error "Could not install bundler with version #{bundler_version}.\n"
            return false
          end
        end
        system("alias bundle='bundle _#{bundler_version}_'")
        system("alias bundler='bundler _#{bundler_version}_'")
        logger.info "Using bundler v" + bundler_version + "\n"

        # Install nodejs
        nodejs_version = `sed -n '/node/{p;n}' package.json`.strip.split(":").last&.strip&.delete_prefix('"')&.delete_suffix(',')&.delete_suffix('"')
        if nodejs_version.nil? || nodejs_version.empty?
          logger.error "Could not find nodejs version. Have you specified it explicitly in package.json with engines field and run yarn install?\n"
          return false
        end

        unless system(user_bash("node -v"), [:out, :err] => File::NULL) && `#{user_bash('node -v')}`.strip&.delete_prefix('v') == nodejs_version
          logger.info "Installing nodejs v#{nodejs_version}\n"

          Open3.popen2e(user_bash("asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end
          Open3.popen2e(user_bash("asdf plugin update nodejs")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end
          Open3.popen2e(user_bash("asdf install nodejs #{nodejs_version}")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end
          Open3.popen2e(user_bash("asdf local nodejs #{nodejs_version}")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end

          unless `#{user_bash('node -v')}`.strip&.delete_prefix('v') == nodejs_version
            logger.error "Could not install nodejs with version #{nodejs_version}. Please try another valid version that asdf supports.\n"
            return false
          end
        end
        logger.info "Using nodejs v" + `#{user_bash('node -v')}`.strip&.delete_prefix('v') + "\n"

        # Install yarn
        yarn_version = `sed -n '/yarn/{p;n}' package.json`.strip.split(":").last&.strip&.delete_prefix('"')&.delete_suffix(',')&.delete_suffix('"')
        if yarn_version.nil? || yarn_version.empty?
          logger.error "Could not find yarn version. Have you specified it explicitly in package.json with engines field and run yarn install?\n"
          return false
        end

        unless system(user_bash("yarn -v"), [:out, :err] => File::NULL) && `#{user_bash('yarn -v')}`.strip == yarn_version
          logger.info "Installing yarn v#{yarn_version}\n"

          Open3.popen2e(user_bash("asdf plugin add yarn https://github.com/twuni/asdf-yarn.git")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end
          Open3.popen2e(user_bash("asdf plugin update yarn")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end
          Open3.popen2e(user_bash("asdf install yarn #{yarn_version}")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end
          Open3.popen2e(user_bash("asdf local yarn #{yarn_version}")) do |stdin, stdout_and_stderr, wait_thr|
            stdout_and_stderr.each { |line| logger.info "#{line}" }
          end

          unless `#{user_bash('yarn -v')}`.strip == yarn_version
            logger.error "Could not install yarn with version #{yarn_version}. Please try another valid version that asdf supports.\n"
            return false
          end
        end
        logger.info "Using yarn v" + `#{user_bash('yarn -v')}`.strip + "\n"

        set_logger_formatter_arrow

        return true
      end

      # Perform bundle install
      def bundle_install?
        logger.info "Performing bundle install ..."

        set_logger_formatter_tabs

        unless system(user_bash("bundle config set --local deployment 'true' && bundle config set --local clean 'true'"))
          logger.error "Could not complete bundle config setting."
          return false
        end

        exit_status = nil
        Open3.popen2e(user_bash("bundle install")) do |stdin, stdout_and_stderr, wait_thr|
          stdout_and_stderr.each { |line| logger.info "#{line}" }
          exit_status = wait_thr.value.success?
        end
        set_logger_formatter_arrow

        if exit_status
          return true
        else
          logger.error "Could not complete bundle install."
          return false
        end
      end

      # Perform pre-compiling of assets
      def precompile_assets?
        logger.info "Installing Javascript dependencies & pre-compiling assets ..."

        set_logger_formatter_tabs
        exit_status = nil
        Open3.popen2e(user_bash("bundle exec rails assets:precompile")) do |stdin, stdout_and_stderr, wait_thr|
          stdout_and_stderr.each { |line| logger.info "#{line}" }
          exit_status = wait_thr.value.success?
        end
        set_logger_formatter_arrow

        if exit_status
          return true
        else
          logger.error "Could not install Javascript dependencies or pre-compile assets."
          return false
        end
      end

      # Perform db_migrate
      def db_migrate?
        return true # remove this line when you want to start using db_migrate?

        logger.info "Performing database migrations ..."

        set_logger_formatter_tabs
        exit_status = nil
        Open3.popen2e(user_bash("bundle exec rails db:migrate")) do |stdin, stdout_and_stderr, wait_thr|
          stdout_and_stderr.each { |line| logger.info "#{line}" }
          exit_status = wait_thr.value.success?
        end
        set_logger_formatter_arrow

        if exit_status
          return true
        else
          logger.error "Could not complete database migrations."
          return false
        end
      end

      # Perform testing of web server
      def test_web_server?
        logger.info "Setting up Web Server ..."

        # tmp folders
        FileUtils.mkdir_p("tmp/pids")
        FileUtils.mkdir_p("tmp/smartmachine")
        FileUtils.rm_f("tmp/smartmachine/packed")

        # Spawn Process
        pid = Process.spawn(user_bash("bundle exec puma --config config/puma.rb"), out: File::NULL)
        Process.detach(pid)

        # Sleep
        sleep 5

        # Check PID running
        status = nil
        begin
          Process.kill(0, pid)
          system("echo '#{pid}' > tmp/smartmachine/packed")
          status = true
        rescue Errno::ESRCH # No such process
          logger.info "Web Server could not start"
          status = false
        end

        # Return status
        return status
      end

      def set_logger_formatter_arrow
        logger.formatter = proc do |severity, datetime, progname, message|
          severity_text = { "DEBUG" => "\u{1f527} #{severity}:", "INFO" => " \u{276f}", "WARN" => "\u{2757} #{severity}:",
                           "ERROR" => "\u{274c} #{severity}:", "FATAL" => "\u{2b55} #{severity}:", "UNKNOWN" => "\u{2753} #{severity}:"
                          }
          "\t\t\t\t#{severity_text[severity]} #{message}\n"
        end
      end

      def set_logger_formatter_tabs
        logger.formatter = proc do |severity, datetime, progname, message|
          "\t\t\t\t       #{message}"
        end
      end
    end
  end
end
