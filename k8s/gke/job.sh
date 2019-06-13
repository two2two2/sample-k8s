#!/bin/sh

set -ex

echo "start migration"
sleep 2s
trap "touch /tmp/pod/terminated && echo 'terminated file was created'" EXIT
bundle exec rails db:create
bundle exec rails db:migrate
echo "finished migration"
