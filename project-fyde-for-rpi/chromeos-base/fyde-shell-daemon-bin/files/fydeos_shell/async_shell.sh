#!/bin/bash
[ $# -lt 2 ] && exit 1

. /usr/share/fydeos_shell/shell_lib.sh
ON_CLOSED=2
ON_ERROR=3

code_to_str() {
  if [ $1 -eq $ON_CLOSED ];then
    echo "OnClosed"
  else
    echo "OnError"
  fi
}

key=$1
shift
command=$1
shift
$command "$@"
if [ $? -ne 0 ]; then
  returncode=$ON_ERROR
else
  returncode=$ON_CLOSED
fi
emit_event $NOTIFY_TYPE_COMMAND $key $returncode "$(code_to_str $returncode)"
