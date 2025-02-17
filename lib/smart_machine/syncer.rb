module SmartMachine
  class Syncer < SmartMachine::Base
    def initialize
    end

    def sync(initial: false)
      puts "-----> Syncing SmartMachine"

      push if initial

      # Uncomment this if you want to implement pull in sync.
      # Ideally please remove this functionality in favour of entire server folder backup feature.
      #pull
      push

      puts "-----> Syncing SmartMachine Complete"
    end

    def rsync(*args)
      exec "rsync #{args.join(' ')}"
    end

    private

    def pull
      puts "-----> Syncer pulling ... "
      if system("#{rsync_command(pull_files_list)} #{SmartMachine.credentials.machine[:username]}@#{SmartMachine.credentials.machine[:address]}:~/machine/ .")
        puts "done"
      else
        raise "Syncer error while pulling..."
      end
    end

    def push
      puts "-----> Syncer pushing ... "
      if system("#{rsync_command(push_files_list)} ./ #{SmartMachine.credentials.machine[:username]}@#{SmartMachine.credentials.machine[:address]}:~/machine")
        puts "done"
      else
        raise "Syncer error while pushing..."
      end
    end

    def rsync_command(files_list)
      command = [
        "rsync -azumv",
        "-e 'ssh -p #{SmartMachine.credentials.machine[:port]}'",
        "--rsync-path='smartengine syncer rsync'",
        "--delete",
        files_list.map { |regex| "--include='#{regex}'" }.join(" "),
        "--exclude=*"
      ]

      command.join(" ")
    end

    def pull_files_list
      files = [
        'apps/***',

        'bin/***',

        'grids',

        'grids/elasticsearch',
        'grids/elasticsearch/***',

        'grids/emailer',
        'grids/emailer/***',

        'grids/minio',
        'grids/minio/***',

        'grids/mysql',
        'grids/mysql/***',

        'grids/nextcloud',
        'grids/nextcloud/***',

        'grids/nginx',
        'grids/nginx/certificates/***',

        'grids/prereceiver',
        'grids/prereceiver/***',

        'grids/redis',
        'grids/redis/***',

        'grids/solr',
        'grids/solr/solr/***',

        'grids/terminal',
        'grids/terminal/***',
      ]
      files
    end

    def push_files_list
      files = [
        'apps',
        'apps/containers',
        'apps/containers/.keep',
        'apps/repositories',
        'apps/repositories/.keep',

        'bin',
        'bin/smartmachine',

        'config',
        'config/emailer',
        'config/emailer/***',
        'config/mysql',
        'config/mysql/schedule.rb',
        'config/phpmyadmin',
        'config/phpmyadmin/***',
        'config/roundcube',
        'config/roundcube/***',
        'config/credentials.yml.enc',
        'config/emailer.yml',
        'config/engine.yml',
        'config/environment.rb',
        'config/elasticsearch.yml',
        'config/minio.yml',
        'config/mysql.yml',
        'config/network.yml',
        'config/nextcloud.yml',
        'config/phpmyadmin.yml',
        'config/prereceiver.yml',
        'config/redis.yml',
        'config/roundcube.yml',
        'config/terminal.yml',

        'grids',

        'grids/nginx',
        'grids/nginx/certificates',
        'grids/nginx/certificates/.keep',
        'grids/nginx/htpasswd/***',
        'grids/nginx/fastcgi.conf',
        'grids/nginx/nginx.tmpl',

        'grids/solr',
        'grids/solr/solr',
        'grids/solr/solr/.keep',

        'tmp/***',
      ]
      files
    end
  end
end
