#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'logger'

logger = Logger.new(STDOUT)
STDOUT.sync = true

def update_envkeys_in(filepaths, envkeys)
  filepaths.each do |filepath|
    str = File.read(filepath)
    str = str.gsub(/%(?!<)/, '%%')
    str = format(str, envkeys)
    File.open(filepath, "w") { |file| file << str }
  end
end

# initial setup
unless File.exist?('/run/initial_container_start')
  FileUtils.touch('/run/initial_container_start')

  # EnvKeys
  envkeys = {
    container_name: ENV.delete('CONTAINER_NAME'),
    fqdn: ENV.delete('FQDN'),
    mailname: ENV.delete('MAILNAME'),
    sysadmin_email: ENV.delete('SYSADMIN_EMAIL'),
    mysql_host: ENV.delete('MYSQL_HOST'),
    mysql_port: ENV.delete('MYSQL_PORT'),
    mysql_user: ENV.delete('MYSQL_USER'),
    mysql_password: ENV.delete('MYSQL_PASSWORD'),
    mysql_database_name: ENV.delete('MYSQL_DATABASE_NAME'),
    monit_smtp_email_name: ENV.delete('MONIT_SMTP_EMAIL_NAME'),
    monit_smtp_email_address: ENV.delete('MONIT_SMTP_EMAIL_ADDRESS'),
    monit_smtp_host: ENV.delete('MONIT_SMTP_HOST'),
    monit_smtp_port: ENV.delete('MONIT_SMTP_PORT'),
    monit_smtp_username: ENV.delete('MONIT_SMTP_USERNAME'),
    monit_smtp_password: ENV.delete('MONIT_SMTP_PASSWORD'),
    oracle_ips_allowed: ENV.delete('ORACLE_IPS_ALLOWED'),
    oracle_deflect_url: ENV.delete('ORACLE_DEFLECT_URL'),
    timezone: `cat /etc/timezone`.chomp
  }

  # rsyslog
  # imklog module is commented in rsyslog.conf because rsyslog does not
  # have privileges to run it and hence throws error on startup.
  system("sed -i '/imklog/s/^/#/' /etc/rsyslog.conf")

  # Postfix
  FileUtils.cp '/smartmachine/config/emailer/etc/postfix/main.cf', '/etc/postfix/main.cf'
  FileUtils.cp '/smartmachine/config/emailer/etc/postfix/master.cf', '/etc/postfix/master.cf'
  FileUtils.cp '/smartmachine/config/emailer/etc/postfix/mysql-sender-login-maps.cf', '/etc/postfix/mysql-sender-login-maps.cf'
  FileUtils.cp '/smartmachine/config/emailer/etc/postfix/mysql-virtual-alias-maps.cf', '/etc/postfix/mysql-virtual-alias-maps.cf'
  FileUtils.cp '/smartmachine/config/emailer/etc/postfix/mysql-virtual-email2email.cf', '/etc/postfix/mysql-virtual-email2email.cf'
  FileUtils.cp '/smartmachine/config/emailer/etc/postfix/mysql-virtual-mailbox-domains.cf', '/etc/postfix/mysql-virtual-mailbox-domains.cf'
  FileUtils.cp '/smartmachine/config/emailer/etc/postfix/mysql-virtual-mailbox-maps.cf', '/etc/postfix/mysql-virtual-mailbox-maps.cf'
  FileUtils.cp '/smartmachine/config/emailer/etc/postfix-policyd-spf-python/policyd-spf.conf', '/etc/postfix-policyd-spf-python/policyd-spf.conf'
  filepaths = [
    '/etc/postfix/main.cf',
    '/etc/postfix/mysql-sender-login-maps.cf',
    '/etc/postfix/mysql-virtual-alias-maps.cf',
    '/etc/postfix/mysql-virtual-email2email.cf',
    '/etc/postfix/mysql-virtual-mailbox-domains.cf',
    '/etc/postfix/mysql-virtual-mailbox-maps.cf'
  ]
  update_envkeys_in(filepaths, envkeys)
  system("chgrp postfix /etc/postfix/mysql-*.cf")
  system("chmod -R o-rwx /etc/postfix/mysql-*.cf")

  # Dovecot
  FileUtils.cp '/smartmachine/config/emailer/etc/dovecot/conf.d/10-auth.conf', '/etc/dovecot/conf.d/10-auth.conf'
  FileUtils.cp '/smartmachine/config/emailer/etc/dovecot/conf.d/10-mail.conf', '/etc/dovecot/conf.d/10-mail.conf'
  FileUtils.cp '/smartmachine/config/emailer/etc/dovecot/conf.d/10-master.conf', '/etc/dovecot/conf.d/10-master.conf'
  FileUtils.cp '/smartmachine/config/emailer/etc/dovecot/conf.d/10-ssl.conf', '/etc/dovecot/conf.d/10-ssl.conf'
  FileUtils.cp '/smartmachine/config/emailer/etc/dovecot/conf.d/15-mailboxes.conf', '/etc/dovecot/conf.d/15-mailboxes.conf'
  FileUtils.cp '/smartmachine/config/emailer/etc/dovecot/conf.d/20-imap.conf', '/etc/dovecot/conf.d/20-imap.conf'
  FileUtils.cp '/smartmachine/config/emailer/etc/dovecot/conf.d/20-lmtp.conf', '/etc/dovecot/conf.d/20-lmtp.conf'
  FileUtils.cp '/smartmachine/config/emailer/etc/dovecot/dovecot-sql.conf.ext', '/etc/dovecot/dovecot-sql.conf.ext'

  FileUtils.cp '/smartmachine/config/emailer/usr/local/bin/quota-warning.sh', '/usr/local/bin/quota-warning.sh'

  filepaths = [
    '/etc/dovecot/conf.d/10-ssl.conf',
    '/etc/dovecot/dovecot-sql.conf.ext',
    '/usr/local/bin/quota-warning.sh'
  ]
  update_envkeys_in(filepaths, envkeys)

  system("groupadd -g 5000 vmail")
  system("useradd -g vmail -u 5000 vmail -d /var/vmail")
  system("chown -R vmail:vmail /var/vmail")


  # Spamassassin
  FileUtils.cp '/smartmachine/config/emailer/etc/spamassassin/local.cf', '/etc/spamassassin/local.cf'
  system("adduser --gecos '' --disabled-login spamd", out: File::NULL)

  # OpenDKIM
  FileUtils.cp '/smartmachine/config/emailer/etc/opendkim.conf', '/etc/opendkim.conf'
  system("adduser postfix opendkim", out: File::NULL)
  system("chmod u=rw,go=r /etc/opendkim.conf")
  unless File.exists? '/etc/opendkim/key.table'
    FileUtils.mkdir_p '/etc/opendkim/keys'
    FileUtils.touch '/etc/opendkim/key.table'
    FileUtils.touch '/etc/opendkim/signing.table'
    FileUtils.touch '/etc/opendkim/trusted.hosts'
    key_shortname = envkeys[:mailname].gsub(/[^[:alnum:]]/, "")
    raise "Could not create key_shortname from mailname to use in opendkim." if key_shortname.match(/\A[a-zA-Z0-9]*\z/).nil?
    key_selector  = Time.now.getlocal('+05:30').strftime("%Y%m")
    raise "Could not create key_selector from Local Time to use in opendkim." if key_selector.match(/\A[0-9]*\z/).nil?
    key_filename = "#{key_shortname}_#{key_selector}"
    IO.write("/etc/opendkim/key.table",
             "#{key_shortname}     #{envkeys[:mailname]}:#{key_selector}:/etc/opendkim/keys/#{key_filename}.private\n")
    IO.write("/etc/opendkim/signing.table",
             "*@#{envkeys[:mailname]}   #{key_shortname}\n")
    IO.write("/etc/opendkim/trusted.hosts",
             "127.0.0.1\n::1\nlocalhost\n#{envkeys[:fqdn]}\n#{envkeys[:mailname]}\n")
    Dir.chdir("/etc/opendkim/keys") do
      raise "Could not create DKIM keys." unless system("opendkim-genkey -b 2048 -h rsa-sha256 -r -s #{key_selector} -d #{envkeys[:mailname]} -v")
      FileUtils.mv("#{key_selector}.private", "#{key_filename}.private")
      FileUtils.mv("#{key_selector}.txt", "#{key_filename}.txt")
    end
  end
  system("chown -R opendkim:opendkim /etc/opendkim")
  system("chmod -R go-rw /etc/opendkim/keys")
  system("mkdir /var/spool/postfix/opendkim")
  system("chown opendkim:postfix /var/spool/postfix/opendkim")

  # Haproxy
  FileUtils.mkdir_p '/var/lib/haproxy/dev'
  FileUtils.mkdir_p '/run/haproxy'
  FileUtils.cp '/smartmachine/config/emailer/etc/haproxy/haproxy.cfg', '/etc/haproxy/haproxy.cfg'
  filepaths = [
    '/etc/haproxy/haproxy.cfg'
  ]
  update_envkeys_in(filepaths, envkeys)

  # Monit
  FileUtils.cp '/smartmachine/config/emailer/etc/monit/monitrc', '/etc/monit/monitrc'
  FileUtils.cp_r '/smartmachine/config/emailer/etc/monit/conf.d/.', '/etc/monit/conf.d'
  filepaths = [
    '/etc/monit/conf.d/services.cfg',
    '/etc/monit/monitrc'
  ]
  update_envkeys_in(filepaths, envkeys)

  # Logtailer
  FileUtils.cp '/smartmachine/config/emailer/docker/logtailer.rb', '/usr/bin/logtailer.rb'
  system("chmod +x /usr/bin/logtailer.rb")

  # Command
  FileUtils.cp '/smartmachine/config/emailer/docker/command.rb', '/usr/bin/command.rb'
  system("chmod +x /usr/bin/command.rb")

  logger.info "Initial setup completed for #{envkeys[:container_name]}."
end

ARGV.empty? ? exec("/usr/bin/command.rb") : exec(*ARGV)
