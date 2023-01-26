# TODO: This is a placeholder for creating the Redmine grid.
# Modify this code as needed with the latest code structure
# and make the redmine grid functional.

# # The main SmartCloud Grids Redmine driver
# module SmartCloud
#   class Grids
#     class Redmine < SmartCloud::Base
#       def initialize
#       end

#       def self.up
#         if SmartCloud::Docker.running?
#           # Creating & Starting containers
#           print "-----> Creating container redmine ... "
#           if system("docker create \
# 		--name='redmine' \
# 		--env VIRTUAL_HOST=redmine.#{SmartCloud.config.apps_domain} \
# 		--env LETSENCRYPT_HOST=redmine.#{SmartCloud.config.apps_domain} \
# 		--env LETSENCRYPT_EMAIL=#{SmartCloud.config.sysadmin_email} \
# 		--env LETSENCRYPT_TEST=false \
# 		--env REDMINE_SECRET_KEY_BASE=#{SmartCloud.credentials.redmine[:secret_key_base]} \
# 		--env REDMINE_DB_MYSQL=#{SmartCloud.credentials.redmine[:database_host]} \
# 		--env REDMINE_DB_PORT=#{SmartCloud.credentials.redmine[:database_port]} \
# 		--env REDMINE_DB_USERNAME=#{SmartCloud.credentials.redmine[:database_username]} \
# 		--env REDMINE_DB_PASSWORD=#{SmartCloud.credentials.redmine[:database_password]} \
# 		--env REDMINE_DB_DATABASE=#{SmartCloud.credentials.redmine[:database_name]} \
# 		--env REDMINE_PLUGINS_MIGRATE=#{SmartCloud.credentials.redmine[:plugins_migrate]} \
# 		--volume='#{SmartCloud.config.user_home_path}/.smartcloud/apps/repositories:/repositories:ro' \
# 		--volume='#{SmartCloud.config.user_home_path}/.smartcloud/grids/redmine/files:/usr/src/redmine/files' \
# 		--restart='always' \
# 		--network='nginx-network' \
# 		redmine:4.0.5-alpine", out: File::NULL)

#             system("docker network connect mysql-network redmine")

#             puts "done"
#             print "-----> Starting container redmine ... "
#             if system("docker start redmine", out: File::NULL)
#               puts "done"
#             end
#           end
#         end
#       end

#       def self.down
#         if SmartCloud::Docker.running?
#           # Stopping & Removing containers - in reverse order
#           print "-----> Stopping container redmine ... "
#           if system("docker stop 'redmine'", out: File::NULL)
#             puts "done"
#             print "-----> Removing container redmine ... "
#             if system("docker rm 'redmine'", out: File::NULL)
#               puts "done"
#             end
#           end
#         end
#       end
#     end
#   end
# end
