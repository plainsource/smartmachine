#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'logger'
require 'cgi'

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
    timezone: `cat /etc/timezone`.chomp,
    roundcubemail_request_path: ENV.delete('ROUNDCUBEMAIL_REQUEST_PATH'),
    roundcubemail_plugins_password_database_type: ENV.delete('ROUNDCUBEMAIL_PLUGINS_PASSWORD_DATABASE_TYPE'),
    roundcubemail_plugins_password_database_host: ENV.delete('ROUNDCUBEMAIL_PLUGINS_PASSWORD_DATABASE_HOST'),
    roundcubemail_plugins_password_database_user: CGI.escape(ENV.delete('ROUNDCUBEMAIL_PLUGINS_PASSWORD_DATABASE_USER')),
    roundcubemail_plugins_password_database_pass: CGI.escape(ENV.delete('ROUNDCUBEMAIL_PLUGINS_PASSWORD_DATABASE_PASS')),
    roundcubemail_plugins_password_database_name: ENV.delete('ROUNDCUBEMAIL_PLUGINS_PASSWORD_DATABASE_NAME')
  }

  # Config
  FileUtils.cp '/smartmachine/config/roundcube/etc/apache2/sites-available/000-default.conf', '/etc/apache2/sites-available/000-default.conf'
  FileUtils.cp '/smartmachine/config/roundcube/usr/local/etc/php/conf.d/zzz_roundcube-custom.ini', '/usr/local/etc/php/conf.d/zzz_roundcube-custom.ini'
  FileUtils.cp '/smartmachine/config/roundcube/var/roundcube/config/config.custom.inc.php', '/var/roundcube/config/config.custom.inc.php'
  filepaths = [
    '/etc/apache2/sites-available/000-default.conf'
  ]
  update_envkeys_in(filepaths, envkeys)

  # Plugins
  FileUtils.cp '/smartmachine/config/roundcube/var/www/html/plugins/password/config.inc.php', '/var/www/html/plugins/password/config.inc.php'
  filepaths = [
    '/var/www/html/plugins/password/config.inc.php'
  ]
  update_envkeys_in(filepaths, envkeys)
  system("chown root:www-data /var/www/html/plugins/password/config.inc.php")
  system("chmod u=rw,g=r,o= /var/www/html/plugins/password/config.inc.php")

  logger.info "Initial setup completed for #{envkeys[:container_name]}."
end

exec(*ARGV)
