module SmartMachine
  module Commands
    module MachineCommands
      class SubThor < Thor
        def self.banner(command, namespace = nil, subcommand = false)
          "#{basename} machine #{subcommand_prefix} #{command.usage}"
        end

        def self.subcommand_prefix
          self.name.gsub(%r{.*::}, '').gsub(%r{^[A-Z]}) { |match| match[0].downcase }.gsub(%r{[A-Z]}) { |match| "-#{match[0].downcase}" }
        end
      end
    end
  end
end
