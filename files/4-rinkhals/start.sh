function log() {
    echo "${*}"
    echo "`date`: ${*}" >> /useremain/rinkhals/.current/rinkhals.log
}
function kill_by_port() {
    XPORT=`printf "%04X" ${*}`
    INODE=`cat /proc/net/tcp | grep 00000000:$XPORT | awk '/.*:.*:.*/{print $10;}'` # Port 2222
    if [[ "$INODE" != "" ]]; then
        PID=`ls -l /proc/*/fd/* 2> /dev/null | grep "socket:\[$INODE\]" | awk -F'/' '{print $3}'`
        CMDLINE=`cat /proc/$PID/cmdline`

        log "Killing $PID ($CMDLINE)"
        kill $PID
    fi
}
function check_by_name() {
    for i in `ls /proc/*/cmdline 2> /dev/null`; do
        CMDLINE=`cat $i` 2>/dev/null

        if echo "$CMDLINE" | grep -q "${*}"; then
            return
        fi
    done

    log "/!\ ${*} should be running but it's not"
    exit 1
}

export TZ=UTC
ntpclient -s -h pool.ntp.org > /dev/null # Try to sync local time before starting

log
log Starting Rinkhals...

echo
echo "          ██████████              "
echo "        ██          ██            "
echo "        ██            ██          "
echo "      ██  ██      ██  ██          "
echo "      ██  ██      ██  ░░██        "
echo "      ██              ░░██        "
echo "        ██░░░░░░░░░░░░██          "
echo "          ██████████████          "
echo "      ████    ██    ░░████        "
echo "    ██      ██      ░░██░░██      "
echo "  ██    ██░░░░░░░░░░██  ░░░░██    "
echo "  ██░░    ██████████    ░░██░░██  "
echo "  ██░░                  ░░██░░██  "
echo "    ██░░░░░░░░░░░░░░░░░░████░░██  "
echo "      ██████████████████    ██    "
echo

export KOBRA_VERSION=`cat /userdata/app/gk/version_log.txt | grep version | awk '{print $2}'`
export RINKHALS_VERSION=`cat .version`
export RINKHALS_ROOT=`pwd`

log " --------------------------------------------------"
log "| Kobra firmware: $KOBRA_VERSION"
log "| Rinkhals version: $RINKHALS_VERSION"
log "| Rinkhals root: $RINKHALS_ROOT"
log " --------------------------------------------------"
echo

if [[ "$KOBRA_VERSION" != "2.3.5.3" ]]; then
    log This Rinkhals version is only compatible with Kobra firmware 2.3.5.3, stopping startup
    exit 1
fi

export INTERPRETER=$RINKHALS_ROOT/lib/ld-linux-armhf.so.3


################
log "> Fixing permissions..."

chmod +x ./*.sh 2> /dev/null
chmod +x $INTERPRETER 2> /dev/null
chmod +x ./bin/* 2> /dev/null
chmod +x ./sbin/* 2> /dev/null
chmod +x ./usr/bin/* 2> /dev/null
chmod +x ./usr/sbin/* 2> /dev/null
chmod +x ./usr/libexec/* 2> /dev/null
chmod +x ./usr/share/scripts/* 2> /dev/null


################
log "> Starting SSH..."

kill_by_port 2222

umount /usr/libexec 2> /dev/null
mount --bind $RINKHALS_ROOT/usr/share/scripts /usr/libexec

LD_LIBRARY_PATH=$RINKHALS_ROOT/lib:$RINKHALS_ROOT/usr/lib \
    $INTERPRETER ./usr/sbin/dropbear -F -E -a -p 2222 -P /tmp/dropbear_debug.pid -r ./etc/dropbear/dropbear_rsa_host_key \
    1>> ./dropbear_debug.log 2>> ./dropbear_debug.log &
sleep 1

if [[ "$(cat /proc/net/tcp | grep 00000000:08AE)" == "" ]]; then # 2222 = x8AE
    log "/!\ SSH backup did not start properly"
    exit 1
fi

if [[ "$(cat /proc/net/tcp | grep 00000000:0016)" != "" ]]; then # 22 = x16
    log "/!\ SSH is already running"
else
    LD_LIBRARY_PATH=$RINKHALS_ROOT/lib:$RINKHALS_ROOT/usr/lib \
        $INTERPRETER ./usr/sbin/dropbear -F -E -a -p 22 -P /tmp/dropbear.pid -r ./etc/dropbear/dropbear_rsa_host_key \
        1>> ./dropbear.log 2>> ./dropbear.log &

    sleep 1
    if [[ "$(cat /proc/net/tcp | grep 00000000:0016)" == "" ]]; then # 22 = x16
        log "/!\ SSH did not start properly"
        exit 1
    fi
fi


################
log "> Starting ADB..."

if [[ "$(cat /proc/net/tcp | grep 00000000:15B3)" != "" ]]; then # 5555 = x15B3
    log "/!\ ADB is already running"
else
    /usr/bin/adbd >> ./adbd.log &
    sleep 1

    if [[ "$(cat /proc/net/tcp | grep 00000000:08AE)" == "" ]]; then # 5555 = x15B3
        log "/!\ ADB did not start properly"
        exit 1
    fi
fi


################
log "> Stopping Klipper..."

killall gklib 2> /dev/null
killall gkapi 2> /dev/null
killall K3SysUi 2> /dev/null


################
log "> Preparing chroot..."

# TODO: Clean mounts
mkdir -p ./proc
mkdir -p ./sys
mkdir -p ./dev
mkdir -p ./run
mkdir -p ./tmp
umount ./proc 2> /dev/null
umount ./sys 2> /dev/null
umount ./dev 2> /dev/null
umount ./run 2> /dev/null
umount ./tmp 2> /dev/null
mount -t proc /proc ./proc
mount -t sysfs /sys ./sys
mount --rbind /dev ./dev
mount --rbind /run ./run
mount --bind /tmp ./tmp

mkdir -p ./userdata
mkdir -p ./useremain
umount ./userdata 2> /dev/null
umount ./useremain 2> /dev/null
mount --bind /userdata ./userdata
mount --bind /useremain ./useremain

# Moonraker uses /userdata/app/gk/printer_data
# Here we replace /userdata/app/gk/printer_data with ./home/rinkhals/printer_data
mkdir -p /userdata/app/gk/printer_data
umount /userdata/app/gk/printer_data 2> /dev/null
mount --bind ./home/rinkhals/printer_data /userdata/app/gk/printer_data

# But we keep gcodes in /useremain/app/gk/gcodes
umount /userdata/app/gk/printer_data/gcodes 2> /dev/null
mount --bind /useremain/app/gk/gcodes /userdata/app/gk/printer_data/gcodes

# We keep Moonraker database in /useremain/app/gk/database
mkdir -p /useremain/app/gk/database
umount /userdata/app/gk/printer_data/database 2> /dev/null
mount --bind /useremain/app/gk/database /userdata/app/gk/printer_data/database

# And we expose default config to users
mkdir -p /userdata/app/gk/printer_data/config/default
umount /userdata/app/gk/printer_data/config/default 2> /dev/null
mount --bind /userdata/app/gk /userdata/app/gk/printer_data/database

chmod +x chroot-start.sh
chroot $(pwd) /bin/ash chroot-start.sh


################
log "> Restarting Klipper..."

cd /userdata/app/gk

LD_LIBRARY_PATH=/userdata/app/gk:$LD_LIBRARY_PATH \
    /userdata/app/gk/gklib -a /tmp/unix_uds1 /userdata/app/gk/printer_data/config/printer.cfg \
    &> $RINKHALS_ROOT/gklib.log &

sleep 2

LD_LIBRARY_PATH=/userdata/app/gk:$LD_LIBRARY_PATH \
    /userdata/app/gk/gkapi \
    &> $RINKHALS_ROOT/gkapi.log &

sleep 2

LD_LIBRARY_PATH=/userdata/app/gk:$LD_LIBRARY_PATH \
    /userdata/app/gk/K3SysUi \
    &> $RINKHALS_ROOT/gkui.log &


check_by_name gklib
check_by_name gkapi


################
log "> Cleaning up..."

kill_by_port 2222


echo
log "Rinkhals started"
