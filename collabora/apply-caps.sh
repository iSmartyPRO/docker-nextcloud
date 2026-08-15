#!/bin/sh
# Re-apply file capabilities after extracting coolmount.real from a new image
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$ROOT/coolmount.real" ]; then
  cid=$(docker create collabora/code:latest)
  docker cp "$cid:/usr/bin/coolmount" "$ROOT/coolmount.real"
  docker rm "$cid"
fi
if [ ! -f "$ROOT/busybox" ]; then
  cp /bin/busybox "$ROOT/busybox" 2>/dev/null || cp "$(command -v busybox)" "$ROOT/busybox"
fi
chmod +x "$ROOT/coolmount" "$ROOT/coolmount.real" "$ROOT/busybox"
setcap cap_sys_admin,cap_sys_chroot,cap_dac_override+ep "$ROOT/coolmount.real"
getcap "$ROOT/coolmount.real"
