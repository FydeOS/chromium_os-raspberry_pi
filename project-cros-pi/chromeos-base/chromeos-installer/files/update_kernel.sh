#!/bin/bash
. /usr/share/cros/update_kernel_lib.sh

main(){
  update_root_kernel $(rootdev) 
}

main $@
