#! /bin/bash
set -e
set -v
echo "fixing uids"
/usr/local/bin/fixuid
exec "$@"
