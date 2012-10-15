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
# Once you decide where to look, driver to load is determined in
# the following order:
# 1. iwldvm
# 2. iwlwifi
# 3. iwlagn
#
# Result goes into the "wifi_driver_basename" variable
#

# Print some diagnostic info about wifi configuration:
#debug_wifi_build := true

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

ifeq ($(debug_wifi_build),true)
ifneq ($(CALLED_FROM_SETUP),true)
  $(info WIFI: processing the select_wifi_driver makefile)
  $(info WIFI: based on the following variables:)
  $(info WIFI: BUILD_KERNEL is "$(BUILD_KERNEL)")
  $(info WIFI: the_image is "$(the_image)")
  $(info WIFI: the_sysmap is "$(the_sysmap)")
  $(info WIFI: the_modules is "$(the_modules)")
  $(info WIFI: TARGET_KERNEL_SOURCE is "$(TARGET_KERNEL_SOURCE)")
endif
endif

ifneq ($(BUILD_KERNEL),)
  look_for_it_in := kernel_src
else ifneq ($(and $(the_image),$(the_sysmap)),)
  look_for_it_in := prebuilt
else
  look_for_it_in := kernel_src
endif
ifeq ($(debug_wifi_build),true)
ifneq ($(CALLED_FROM_SETUP),true)
  $(info WIFI: using "$(look_for_it_in)" to determine driver module)
endif
endif

ifeq ($(look_for_it_in),kernel_src)
  ifneq ($(shell grep 'config  *IWLDVM *$$' $(TARGET_KERNEL_SOURCE)/drivers/net/wireless/iwlwifi/Kconfig),)
    wifi_driver_basename := iwldvm
  else
    ifneq ($(shell grep 'config  *IWLWIFI *$$' $(TARGET_KERNEL_SOURCE)/drivers/net/wireless/iwlwifi/Kconfig),)
      wifi_driver_basename := iwlwifi
      wifi_driver_parameters := \
              plcp_check=N \
              11n_disable=1 \

    else
      wifi_driver_basename := iwlagn
      wifi_driver_parameters := \
              plcp_check=N \
              11n_disable=1 \

    endif
  endif
else  # look in prebuilt
  ifneq ($(shell gunzip -c $(the_modules) | tar -t | grep 'modules/iwldvm\.ko'),)
    wifi_driver_basename := iwldvm
  else
    ifneq ($(shell gunzip -c $(the_modules) | tar -t | grep 'modules/iwlwifi\.ko'),)
      wifi_driver_basename := iwlwifi
      wifi_driver_parameters := \
              plcp_check=N \
              11n_disable=1 \

    else
      wifi_driver_basename := iwlagn
      wifi_driver_parameters := \
              plcp_check=N \
              11n_disable=1 \

    endif
  endif
endif
ifeq ($(debug_wifi_build),true)
ifneq ($(CALLED_FROM_SETUP),true)
  $(info WIFI: using driver module basename "$(wifi_driver_basename)")
endif
endif

# Tells Android HAL how to load WIFI driver.
# See hardware/libhardware_legacy/wifi/{Android.mk,wifi.c}
WIFI_DRIVER_PROBE_PATH := /system/lib/modules/
WIFI_DRIVER_MODULE_NAME := $(wifi_driver_basename)

# Workarounds for excessive errors that interfere with proper wifi
# operation in the IWLWIFI driver:
#
# plcp_check=N  Works around excessive PLCP health-check failures
#               that cause continuous resetting of RF
# 11n_disable=1 Works around excessive tx retransmits while 11n
#               is enabled, symptom: name-resolve failure
IWLWIFI_PARMLIST := $(wifi_driver_parameters)

WIFI_DRIVER_MODULE_ARG = "$(strip $(IWLWIFI_PARMLIST))"
ADDITIONAL_DEFAULT_PROPERTIES += wifi.interface=wlan0

# Must be set to enable WPA supplicant build. WEXT is the driver for generic
# linux wireless extensions. NL80211 supercedes it.
# This variable is used by external/wpa_supplicant/Android.mk
BOARD_WPA_SUPPLICANT_DRIVER=NL80211
WPA_SUPPLICANT_VERSION:=VER_0_8_X

