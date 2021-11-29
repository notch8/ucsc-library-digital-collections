#!/bin/bash

# `/sbin/setuser memcache` runs the given command as the user `memcache`.
# If you omit that part, the command will be run as root.

exec /bin/bash -l -c 'cd /app/samvera/hyrax-webapp && bundle exec sidekiq'


