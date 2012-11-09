# Board has its own custom Wifi HAL
BOARD_CUSTOM_WIFI_HAL_SRC := device/intel/bigcore/wifi/wifi.c
ADDITIONAL_DEFAULT_PROPERTIES += wifi.interface=wlan0

# Must be set to enable WPA supplicant build. WEXT is the driver for generic
# linux wireless extensions. NL80211 supercedes it.
# This variable is used by external/wpa_supplicant/Android.mk
BOARD_WPA_SUPPLICANT_DRIVER=NL80211
WPA_SUPPLICANT_VERSION:=VER_0_8_X
