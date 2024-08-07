#!/usr/bin/env ruby
# frozen_string_literal: true

STDOUT.sync = true

class Services
  def initialize
    @services = %w(rsyslog haproxy spamassassin spamassassin.update opendkim postfix dovecot)
  end

  def start
    puts "Starting Services..."
    @services.each { |service| system("monit start #{service}") }
    system("monit")

    puts "Starting Logtailer..."
    system("/usr/bin/logtailer.rb start")
  end

  def stop(signo)
    puts "Stopping Logtailer..."
    system("/usr/bin/logtailer.rb stop")

    puts "Stopping Services... SIGNAL: SIG#{Signal.signame(signo)}."
    system("monit quit")
    sleep(3)
    @services.reverse.each { |service| system("monit stop #{service}") }

    puts "Flushing Logtailer..."
    system("/usr/bin/logtailer.rb flush")

    exit
  end
end

trap('SIGINT') do |signo|
  Services.new.stop(signo)
end

trap('SIGTERM') do |signo|
  Services.new.stop(signo)
end

at_exit do
  # Clean up.
end

Services.new.start

sleep
