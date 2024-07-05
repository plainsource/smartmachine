require "active_support/core_ext/hash/keys"
require "erb"

module SmartMachine
  class Configuration < SmartMachine::Base

    def initialize
    end

    def config
      @config ||= OpenStruct.new(grids: grids, network: network)
    end

    private

    def grids
      @grids ||= OpenStruct.new(elasticsearch: elasticsearch, emailer: emailer, minio: minio, mysql: mysql, nextcloud: nextcloud, phpmyadmin: phpmyadmin, prereceiver: prereceiver, redis: redis, terminal: terminal)
    end

    def elasticsearch
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/elasticsearch.yml always exists
      if File.exist? "config/elasticsearch.yml"
        deserialize(IO.binread("config/elasticsearch.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/elasticsearch.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/elasticsearch.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def emailer
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/emailer.yml always exists
      if File.exist? "config/emailer.yml"
        deserialize(IO.binread("config/emailer.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/emailer.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/emailer.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def minio
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/minio.yml always exists
      if File.exist? "config/minio.yml"
        deserialize(IO.binread("config/minio.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/minio.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/minio.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def mysql
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/mysql.yml always exists
      if File.exist? "config/mysql.yml"
        deserialize(IO.binread("config/mysql.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/mysql.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/mysql.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def nextcloud
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/nextcloud.yml always exists
      if File.exist? "config/nextcloud.yml"
        deserialize(IO.binread("config/nextcloud.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/nextcloud.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/nextcloud.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def phpmyadmin
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/phpmyadmin.yml always exists
      if File.exist? "config/phpmyadmin.yml"
        deserialize(IO.binread("config/phpmyadmin.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/phpmyadmin.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/phpmyadmin.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def prereceiver
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/prereceiver.yml always exists
      if File.exist? "config/prereceiver.yml"
        deserialize(IO.binread("config/prereceiver.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/prereceiver.yml" # To ensure file exists when inside the pre-receive hook of prereceiver.
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/prereceiver.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def redis
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/redis.yml always exists
      if File.exist? "config/redis.yml"
        deserialize(IO.binread("config/redis.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/redis.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/redis.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def terminal
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/terminal.yml always exists
      if File.exist? "config/terminal.yml"
        deserialize(IO.binread("config/terminal.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/terminal.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/terminal.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def network
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/network.yml always exists
      if File.exist? "config/network.yml"
        deserialize(IO.binread("config/network.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/network.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/network.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def deserialize(config)
      YAML.load(ERB.new(config).result).presence || {}
    end
  end
end
