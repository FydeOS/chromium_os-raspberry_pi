#/bin/bash
cras_client=/usr/bin/cras_test_client
hdmi_fix_id=e9849cd9
dev=$(${cras_client} --dump_s |grep $hdmi_fix_id | awk '{print $2}')
${cras_client} --plug "${dev}":1
logger -t "rpi4-hdmi" "set ${dev} plugged"
