require 'smart_machine/logger'
require "active_support/inflector"
require 'active_support/core_ext/string/filters'

module SmartMachine
  class Base
    include SmartMachine::Logger

    def initialize
    end

    def platform_on_machine?(os:, distro_name: nil)
      case os
      when "linux"
        command = "(uname | grep -q 'Linux')"
        command += " && (cat /etc/os-release | grep -q 'NAME=\"Debian GNU/Linux\"')" if distro_name == "debian"
      when "mac"
        command = "(uname | grep -q 'Darwin')"
      end

      machine = SmartMachine::Machine.new
      command ? machine.run_on_machine(commands: command) : false
    end

    def machine_has_engine_installed?
      machine = SmartMachine::Machine.new
      machine.run_on_machine(commands: ["which smartengine | grep -q '/smartengine'"])
    end

    def user_bash(command)
      remove_envs = %w(RUBY_MAJOR RUBY_VERSION RUBY_DOWNLOAD_SHA256 GEM_HOME BUNDLE_APP_CONFIG BUNDLE_SILENCE_ROOT_WARNING)
      'env -u ' + remove_envs.join(' -u ') + ' bash --login -c \'' + command + '\''
    end
  end
end
