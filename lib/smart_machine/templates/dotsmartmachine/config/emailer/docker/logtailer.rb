#!/usr/bin/env ruby
# frozen_string_literal: true

STDOUT.sync = true

require 'fileutils'

class Logtailer
  def initialize
    @tailers = {
      "/var/log/monit.log"    => 1,
      "/var/log/haproxy.log"  => 1,
      "/var/log/mail.log"     => 1,
      "/home/spamd/spamd.log" => 1
    }
  end

  def start
    set_start_from_line

    pids = []
    @tailers.each do |path, start_from_line|
      pid = Process.spawn("tail", "--lines=+#{start_from_line}", "-q", "-F", "#{path}", [:out, :err] => "/proc/1/fd/1")
      Process.detach(pid)
      pids.push(pid)
    end
    IO.write("/run/tmpfs/logtailer.pid", "#{pids.join(' ')}\n")

    puts "Started Logtailer with PIDs " + `cat /run/tmpfs/logtailer.pid`.chomp + "."
  end

  def stop
    pids = `cat /run/tmpfs/logtailer.pid`.chomp.split(" ")
    pids.each do |pid|
      system("/bin/kill --signal SIGTERM #{pid}")
    end
    save_start_from_line

    puts "Stopped Logtailer with PIDs " + `cat /run/tmpfs/logtailer.pid`.chomp + "."
    FileUtils.rm("/run/tmpfs/logtailer.pid")
  end

  def flush
    set_start_from_line
    @tailers.each do |path, start_from_line|
      system("tail --lines=+#{start_from_line} -q #{path} >> /proc/1/fd/1")
    end
    save_start_from_line
  end

  private

  def set_start_from_line
    if File.exist?('/run/logtailer.lines')
      lines = IO.read('/run/logtailer.lines').split("\n")
      lines.each do |line|
        previous_line_no, path = line.split(" ")
        @tailers[path] = previous_line_no.to_i + 1
      end
    end
  end

  def save_start_from_line
    str = `wc -l #{@tailers.keys.join(' ')} | head --lines=-1`
    IO.write("/run/logtailer.lines", "#{str}")
  end
end

if ARGV[0] == "start"
  Logtailer.new.start
elsif ARGV[0] == "stop"
  Logtailer.new.stop
elsif ARGV[0] == "flush"
  Logtailer.new.flush
end
