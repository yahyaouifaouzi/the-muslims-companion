#!/bin/sh
# Flatpak launcher. The Flutter engine resolves lib/ and data/ relative to
# the executable, so the bundle lives in /app/lib/rafiq and this wrapper
# execs the real binary from there.
exec /app/lib/rafiq/the_muslims_companion "$@"
