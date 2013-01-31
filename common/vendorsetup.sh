#
# Copyright (C) 2008 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This file is executed by build/envsetup.sh, and can use anything
# defined in envsetup.sh.
#
# In particular, you can add lunch options with the add_lunch_combo
# function: add_lunch_combo generic-eng

PATH=$PATH:$(gettop)/device/intel/support

# Remove sync_img function from old shell state
unset -f sync_img

# $1 : remote IP address (e.g. 192.168.42.1)
# $2 : executable name (e.g. mediaserver)
# $3 : port number     (e.g. :5678)
# $4 : process name    (e.g. mediaserver)
function gdbclient_eth()
{
   local OUT_ROOT=$(get_abs_build_var PRODUCT_OUT)
   local OUT_SYMBOLS=$(get_abs_build_var TARGET_OUT_UNSTRIPPED)
   local OUT_SO_SYMBOLS=$(get_abs_build_var TARGET_OUT_SHARED_LIBRARIES_UNSTRIPPED)
   local OUT_EXE_SYMBOLS=$(get_abs_build_var TARGET_OUT_EXECUTABLES_UNSTRIPPED)
   local PREBUILTS=$(get_abs_build_var ANDROID_PREBUILTS)
   if [ "$OUT_ROOT" -a "$PREBUILTS" ]; then
       local IPADDR="$1"
       if [ -z "$IPADDR" ]; then
           echo "Must specify remote IP address"
           return 1
       fi

       local EXE="$2"
       if [ "$EXE" ] ; then
           EXE=$2
       else
           EXE="app_process"
       fi
       if [ ! -f "$OUT_EXE_SYMBOLS/$EXE" ]; then
           echo "Unable to find executable: $OUT_EXE_SYMBOLS/$EXE"
           return 1
       fi

       local PORT="$3"
       if [ "$PORT" ] ; then
           PORT=$3
       else
           PORT=":5039"
       fi

       local PID
       local PROG="$4"
       if [ "$PROG" ] ; then
           if [[ "$PROG" =~ ^[0-9]+$ ]] ; then
               PID="$4"
           else
               PID=`pid $4`
           fi
           adb shell gdbserver $PORT --attach $PID &
           sleep 2
       else
               echo ""
               echo "If you haven't done so already, do this first on the device:"
               echo "    gdbserver $PORT /system/bin/$EXE"
                   echo " or"
               echo "    gdbserver $PORT --attach $PID"
               echo ""
       fi

       echo >|"$OUT_ROOT/gdbclient.cmds" "set solib-absolute-prefix $OUT_SYMBOLS"
       echo >>"$OUT_ROOT/gdbclient.cmds" "set solib-search-path $OUT_SO_SYMBOLS"
       echo >>"$OUT_ROOT/gdbclient.cmds" "target remote $IPADDR$PORT"
       echo >>"$OUT_ROOT/gdbclient.cmds" ""

       if [ "$(get_build_var TARGET_ARCH)" = "x86" ]; then
           GDB=i686-linux-android-gdb
       else
           GDB=arm-linux-androideabi-gdb
       fi

       $GDB -x "$OUT_ROOT/gdbclient.cmds" "$OUT_EXE_SYMBOLS/$EXE"

  else
       echo "Unable to determine build system output dir."
   fi

}

