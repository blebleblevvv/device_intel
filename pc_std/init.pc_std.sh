#!/system/bin/sh

# This script is started from /init.rc.
# Put any "late initialization" in here.
# Sleeps are ok... but don't put anything in this file that
# could possibly go into init.<platform>.rc

echo 1 > /sys/power/wake_lock

lid=`getprop init.panel_ignore_lid`
[ "$lid" != "" ] && echo $lid > /sys/module/i915/parameters/panel_ignore_lid

exit 0
