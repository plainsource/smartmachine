#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'logger'

logger = Logger.new(STDOUT)
STDOUT.sync = true

# sshd
system('service rsyslog start && service ssh start')

# fail2ban
system('fail2ban-client start')

# haproxy
# system('haproxy -W -db -f /etc/haproxy/haproxy.cfg')

# initial setup
unless File.exist?('/run/initial_container_start')
  FileUtils.touch('/run/initial_container_start')

  username       = ENV.delete('USERNAME')
  packages       = ENV.delete('PACKAGES').to_s
  password       = ENV.delete('PASSWORD')
  container_name = ENV.delete('CONTAINER_NAME')

  # apt-get
  system('apt-get update', out: File::NULL)

  # packages
  unless packages.empty?
    system("apt-get install -y --no-install-recommends #{packages}")

    logger.info 'Packages setup completed.'
  end

  # user
  unless system("id -u #{username}", [:out, :err] => File::NULL)
    system("adduser --gecos '' --disabled-login #{username}", out: File::NULL)
    system("adduser #{username} sudo", out: File::NULL)
    system("echo '#{username}:#{password}' | chpasswd")

    logger.info 'User setup completed.'
  end

  # user > ssh keys
  # TODO: Change container_name to `hostname` when hostname has been set to container_name inside the container.
  unless Dir.exist?("/home/#{username}/.ssh")
    commands = [
      "mkdir -p /home/#{username}/.ssh",
      "ssh-keygen -b 4096 -q -f /home/#{username}/.ssh/id_rsa -N '' -C '#{username}@#{container_name}'",
      "touch /home/#{username}/.ssh/authorized_keys",
      "chown -R #{username}:#{username} /home/#{username}/.ssh",
      "chmod -R 700 /home/#{username}/.ssh && chmod 600 /home/#{username}/.ssh/*"
    ]
    system(commands.join(' && '))

    logger.info 'User > SSH setup completed.'
  end

  # user > emacs
  unless Dir.exist?("/home/#{username}/.emacs.d")
    commands = [
      "mkdir -p /home/#{username}/.emacs.d",
      "cp /root/.emacs.d/* /home/#{username}/.emacs.d",
      "chown -R #{username}:#{username} /home/#{username}/.emacs.d"
    ]
    system(commands.join(' && '))

    logger.info 'User > Emacs setup completed.'
  end

  # user > asdf > ruby > smartmachine
  unless Dir.exist?("/home/#{username}/.asdf")
    user_bash = "sudo -u #{username} bash --login -c"

    commands = [
      "#{user_bash} \"git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch $(git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags https://github.com/asdf-vm/asdf.git '*.*.*' | tail --lines=1 | cut --delimiter='/' --fields=3)\"",
      "#{user_bash} 'echo -e \"\n# asdf version manager\n. \"\$HOME/.asdf/asdf.sh\"\n. \"\$HOME/.asdf/completions/asdf.bash\"\" >> ~/.profile'",
      'apt-get install -y --no-install-recommends autoconf bison patch build-essential rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev', # Dependencies for ruby from https://github.com/rbenv/ruby-build/wiki#ubuntudebianmint
      "#{user_bash} 'asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git'",
      "#{user_bash} 'asdf install ruby latest'",
      "#{user_bash} 'asdf global ruby latest'",
      "#{user_bash} 'gem install smartmachine'"
    ]
    system(commands.join(' && '))

    logger.info 'User > asdf > ruby > smartmachine setup completed.'
  end

  logger.info 'Initial setup completed.'
end

exec(*ARGV)
