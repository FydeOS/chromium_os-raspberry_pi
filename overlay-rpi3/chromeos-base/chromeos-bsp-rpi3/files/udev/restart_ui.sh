#!/bin/sh
log=/tmp/drm_change.log
info() {
  echo $@ >> $log
}
ui_state=$(/sbin/status ui |grep running)
#info "drm: $@" 
if [ -z "${ui_state}" ]; then
#    info "start ui..."    
    start ui
fi
