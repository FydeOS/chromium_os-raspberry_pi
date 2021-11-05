# The class to append/remove flags to/from /etc/chrome_dev.conf
RDEPEND="chromeos-base/chromeos-login"
DEPEND="${RDEPEND}"
#the flags need be added"
#CHROME_DEV_FLAGS=""
#the flags need be removed"
#CHROME_REMOVE_FLAGS=""
CHROME_TMP_CONFIG="chrome_dev.conf"

S=${WORKDIR}

check_file() {
  if [ ! -f $1 ]; then 
     eerror "$1 doesn't exist."
  fi
}

append_flags() {
    local chrome_dev=$CHROME_TMP_CONFIG
    for flag in $@; do
      if [ -z "`grep -e $flag $chrome_dev`" ]; then
        echo $flag >> $chrome_dev
      fi
    done  
}

remove_flags() {
    local chrome_dev=$CHROME_TMP_CONFIG
    for flag in $@; do
        sed -i "/${flag}/d" $chrome_dev
    done
}

src_compile() {
    check_file ${ROOT}/etc/chrome_dev.conf
    cat ${ROOT}/etc/chrome_dev.conf > $CHROME_TMP_CONFIG
    if [ -n "$CHROME_DEV_FLAGS" ]; then
      einfo "append flags: ${CHROME_DEV_FLAGS}"
      append_flags "$CHROME_DEV_FLAGS"
    fi
    if [ -n "$CHROME_REMOVE_FLAGS" ]; then
      einfo "remove flags: ${CHROME_DEV_FLAGS}"
      remove_flags "$CHROME_REMOVE_FLAGS"
    fi
}

src_install() {
    insinto /etc
    doins $CHROME_TMP_CONFIG
}
