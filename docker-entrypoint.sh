#!/bin/sh
set -eu
printf 'Container starting as user: '
id -un
printf 'Application: %s\n' "${APP_NAME:-docker-demo}"
printf 'Environment: %s\n' "${APP_ENV:-unknown}"
printf 'Started at: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
exec "$@"
