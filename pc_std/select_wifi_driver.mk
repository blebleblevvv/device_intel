# Copyright (C) 2012 The Android Open-Source Project
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

# Determine what kernel version we are using and use that to derive the wifi
# driver module name.  Rules:
#
# If forcing build of kernel:
#   look in the kernel source dir
# elsif prebuilt is present:
#   look in the prebuilt binary
# else:
#   look in the kernel source dir
#
# Once you decide where to look, presence of "iwlwifi" determines that this is
# the driver modle basename, otherwise it is "iwlagn".
#
# Result goes into the "wifi_driver_basename" variable
#

# Various variables that determine where things are.  We use these locally
# computed ones rather than some of the "normal" ones since the "normal" ones
# involve TARGET_PREBUILT_TAG which is not known at the time this file is
# processed.  The place where TARGET_PREBUILT_TAG would be inserted is replaced
# with the hard-coded value "android-x86" below.  This would eventually cause
# problems, so ought to be repaired if/when we move to a single kernel version.
prebuilt_root := $(TARGET_KERNEL_SOURCE)-prebuilt/android-x86/kernel
prebuilt_variant := $(prebuilt_root)/$(TARGET_PRODUCT)-$(TARGET_BUILD_VARIANT)

# Additional pieces that may or may not be present.  If not present, then they
# evaluate to empty strings.
the_image := $(wildcard $(prebuilt_variant)/$(notdir kernel))
the_sysmap := $(wildcard $(prebuilt_variant)/$(notdir System.map))
the_modules := $(wildcard $(prebuilt_variant)/$(notdir kernelmod.tar.gz))

# begin diagnostic
ifneq ($(CALLED_FROM_SETUP),true)
  $(info WIFI: processing the select_wifi_driver makefile)
  $(info WIFI: based on the following variables:)
  $(info WIFI: BUILD_KERNEL is "$(BUILD_KERNEL)")
  $(info WIFI: the_image is "$(the_image)")
  $(info WIFI: the_sysmap is "$(the_sysmap)")
  $(info WIFI: the_modules is "$(the_modules)")
  $(info WIFI: TARGET_KERNEL_SOURCE is "$(TARGET_KERNEL_SOURCE)")
endif
# end diagnostic

ifneq ($(BUILD_KERNEL),)
  look_for_it_in := kernel_src
else ifneq ($(and $(the_image),$(the_sysmap)),)
  look_for_it_in := prebuilt
else
  look_for_it_in := kernel_src
endif
ifneq ($(CALLED_FROM_SETUP),true)
  $(info WIFI: using "$(look_for_it_in)" to determine driver module)
endif

ifeq ($(look_for_it_in),kernel_src)
  ifneq ($(shell grep 'config  *IWLWIFI *$$' $(TARGET_KERNEL_SOURCE)/drivers/net/wireless/iwlwifi/Kconfig),)
    wifi_driver_basename := iwlwifi
  else
    wifi_driver_basename := iwlagn
  endif
else  # look in prebuilt
  ifneq ($(shell gunzip -c $(the_modules) | tar -t | grep 'modules/iwlwifi\.ko'),)
    wifi_driver_basename := iwlwifi
  else
    wifi_driver_basename := iwlagn
  endif
endif
ifneq ($(CALLED_FROM_SETUP),true)
  $(info WIFI: using driver module basename "$(wifi_driver_basename)")
endif
