#!/bin/sh

function log() {
    echo "${*}"
    echo "`date`: ${*}" >> /useremain/rinkhals/.current/rinkhals.log
}
function kill_by_name() {
    for i in `ls /proc/*/cmdline 2> /dev/null`; do
        PID=`echo $i | awk -F'/' '{print $3}'`
        CMDLINE=`cat $i` 2>/dev/null

        if echo "$CMDLINE" | grep -q "${*}"; then
            log "Killing $PID ($CMDLINE)"
            kill $PID
        fi
    done
}


if [ ! -d /useremain/rinkhals/.current ]; then
    echo Rinkhals has not started
    exit 1
fi


################
log "> Stopping everything..."

kill_by_name ntpclient.sh
kill_by_name moonraker.py
kill_by_name moonraker-proxy.py
kill_by_name nginx
kill_by_name mjpg_streamer


################
log "> Cleaning chroot..."

cd /useremain/rinkhals/.current

umount -f ./proc 2> /dev/null
umount -f ./sys 2> /dev/null
umount -f ./dev 2> /dev/null
umount -f ./run 2> /dev/null
umount -f ./tmp 2> /dev/null
umount -f ./userdata 2> /dev/null
umount -f ./useremain 2> /dev/null

# rm -rf ./proc
# rm -rf ./sys
# rm -rf ./dev
# rm -rf ./run
# rm -rf ./userdata
# rm -rf ./useremain


################
log "> Restarting default environment..."

rm -rf /useremain/rinkhals/.current

touch /useremain/rinkhals/.disable-rinkhals

cd /userdata/app/gk
./restart_k3c.sh

rm /useremain/rinkhals/.disable-rinkhals
