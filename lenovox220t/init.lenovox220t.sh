#!/system/bin/sh

# This script is started from /init.rc.
# Put any "late initialization" in here.
# Sleeps are ok... but don't put anything in this file that
# could possibly go into init.<platform>.rc

echo 1 > /sys/power/wake_lock

# Bring up Ethernet (over USB) interface, for testing/debugging.
case `getprop ro.build.type` in
eng)
    # if kernel command line has a parameter like ip=<ip>:<netmask> then use that
    # as static eth0 setting
    # else use dhcp
    use_static=N
    for f in `cat /proc/cmdline`; do
          case $f in
          ip=*)
            eval $f
            use_static=Y
            netmask=${ip##*:}
            addr=${ip%%:*}
          ;;
          esac
    done

    case $use_static in
    Y)
        ifconfig eth0 $addr $netmask up
        ;;
    N)
        # Bring up eth0 using netcfg with dhcp.
        # If the ethernet cable is not plugged in, this could hang for a long time.
        # So do it in a background shell.
        netcfg eth0 dhcp &
        ;;
    esac # use_static
    ;;
esac # ro.build.type

exit 0
