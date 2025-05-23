require 'smart_machine/commands/grid_commands/sub_thor'
require 'smart_machine/commands/grid_commands/elasticsearch'
require 'smart_machine/commands/grid_commands/emailer'
require 'smart_machine/commands/grid_commands/minio'
require 'smart_machine/commands/grid_commands/mysql'
require 'smart_machine/commands/grid_commands/nextcloud'
require 'smart_machine/commands/grid_commands/nginx'
require 'smart_machine/commands/grid_commands/phpmyadmin'
require 'smart_machine/commands/grid_commands/prereceiver'
require 'smart_machine/commands/grid_commands/redis'
require 'smart_machine/commands/grid_commands/roundcube'
require 'smart_machine/commands/grid_commands/terminal'

module SmartMachine
  module Commands
    class Grid < Thor
      include Utilities

      desc "elasticsearch", "Run elasticsearch grid commands"
      subcommand "elasticsearch", GridCommands::Elasticsearch

      desc "emailer", "Run emailer grid commands"
      subcommand "emailer", GridCommands::Emailer

      desc "minio", "Run minio grid commands"
      subcommand "minio", GridCommands::Minio

      desc "mysql", "Run mysql grid commands"
      subcommand "mysql", GridCommands::Mysql

      desc "nextcloud", "Run nextcloud grid commands"
      subcommand "nextcloud", GridCommands::Nextcloud

      desc "nginx", "Run nginx grid commands"
      subcommand "nginx", GridCommands::Nginx

      desc "phpmyadmin", "Run phpmyadmin grid commands"
      subcommand "phpmyadmin", GridCommands::Phpmyadmin

      desc "prereceiver", "Run prereceiver grid commands"
      subcommand "prereceiver", GridCommands::Prereceiver

      desc "redis", "Run redis grid commands"
      subcommand "redis", GridCommands::Redis

      desc "roundcube", "Run roundcube grid commands"
      subcommand "roundcube", GridCommands::Roundcube

      desc "terminal", "Run terminal grid commands"
      subcommand "terminal", GridCommands::Terminal
    end
  end
end
