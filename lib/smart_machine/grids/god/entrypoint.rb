#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'logger'

logger = Logger.new(STDOUT)
STDOUT.sync = true

# haproxy
# system('haproxy -W -db -f /etc/haproxy/haproxy.cfg')

# initial setup
unless File.exist?('/run/initial_container_start')
  FileUtils.touch('/run/initial_container_start')

  container_name = ENV.delete('CONTAINER_NAME')

  logger.info "Initial setup completed for #{container_name}."
end

exec(*ARGV)
