#!/usr/bin/env sh

# Create a file as if this were the services config file

SETTINGS_PATH="./settings.txt"
ENV_OPTS=""

if [ $ENV_PROTECTION ]; then
    ENV_OPTS="env -i"
fi

# Render settings files
env > $SETTINGS_PATH

# Set file self destruct if applicable
# TODO: This breaks the service if there's more than 1 worker
if [ $FILE_PROTECTION ]; then
    inotifywait -qq --event close $SETTINGS_PATH && rm $SETTINGS_PATH &
fi

# Start service process (gunicorn in this case)
exec $ENV_OPTS gunicorn --workers 1 --bind 0.0.0.0:5000 "service:CodeExecService('$SETTINGS_PATH')"
