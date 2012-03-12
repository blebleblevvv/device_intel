#!/bin/bash

function wait_for_adb {
    while [ -z "$(adb devices | awk 'NR==2{print}')" ]; do
        sleep 1
    done
}


echo "Waiting for device..."
wait_for_adb
echo "Setting root permissions..."
adb root
sleep 1
wait_for_adb

adb shell stop logcat-main
adb shell stop logcat-radio
adb shell stop logcat-kernel
adb shell stop logcat-system
adb shell stop logcat-events

