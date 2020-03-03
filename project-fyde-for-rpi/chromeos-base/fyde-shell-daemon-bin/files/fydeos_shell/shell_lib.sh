#!/bin/bash
NOTIFY_TYPE_SYSTEM=0
NOTIFY_TYPE_COMMAND=1
NOTIFY_TYPE_CUSTOM=2

emit_event() {
  [ $# -ne 4 ] && return 1
  local type=$1
  local handler=$2
  local state=$3
  local msg=$4
  dbus-send --system --type=method_call \
   --dest=io.fydeos.ShellDaemon \
   /io/fydeos/ShellDaemon \
   io.fydeos.ShellInterface.EmitNotification \
   int32:$type \
   int32:$handler \
   int32:$state \
   string:"${msg}"
}
