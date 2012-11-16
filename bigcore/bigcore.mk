# Superclass
$(call inherit-product, device/intel/common/generic_no_telephony.mk)
$(call inherit-product-if-exists, device/intel/common/multimedia.mk)

# The Superclass may include PRODUCT_COPY_FILES directives that this subclass
# may want to override.  For PRODUCT_COPY_FILES directives the Android Build
# System ignores subsequent copies that lead to the same destination.  So for
# subclass PRODUCT_COPY_FILES to override properly, the right thing to do is to
# prepend them instead of appending them as usual.  This is done using the
# pattern:
#
# OVERRIDE_COPIES := <the list>
# PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)

LOCAL_PATH := device/intel/bigcore

PRODUCT_NAME := bigcore
PRODUCT_DEVICE := bigcore

# For device identification to apps
PRODUCT_MANUFACTURER := Generic-IA
PRODUCT_MODEL := Generic-IA

#
# gralloc & mesa lib
#
PRODUCT_PACKAGES += \
    libGLES_mesa    \
    gralloc.$(TARGET_PRODUCT) \
    camera.bigcore \

#
# tinyalsa utils
#
PRODUCT_PACKAGES += \
	tinymix \
	tinyplay \
	tinycap \

# PC std common files
OVERRIDE_COPIES := \
	$(LOCAL_PATH)/asound.conf:system/etc/asound.conf \
	$(LOCAL_PATH)/android.conf:system/etc/dhcpcd/android.conf \
	$(LOCAL_PATH)/vold.fstab:system/etc/vold.fstab \
	$(LOCAL_PATH)/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
	$(LOCAL_PATH)/init.bigcore.rc:root/init.bigcore.rc \
	$(LOCAL_PATH)/init.bigcore.sh:system/etc/init.bigcore.sh \
	device/intel/common/fstab.common:root/fstab.common \
	$(LOCAL_PATH)/modules.blacklist:system/etc/modules.blacklist \
	$(LOCAL_PATH)/ueventd.bigcore.rc:root/ueventd.$(TARGET_PRODUCT).rc \

# copy idc files
IDC_FILES := $(wildcard $(LOCAL_PATH)/idc/*.idc)

OVERRIDE_COPIES += \
	$(foreach Item, $(IDC_FILES), $(Item):system/usr/idc/$(notdir $(Item)))

PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)
# for bugmailer
PRODUCT_PACKAGES += send_bug
OVERRIDE_COPIES := \
	system/extras/bugmailer/bugmailer.sh:system/bin/bugmailer.sh \
	system/extras/bugmailer/send_bug:system/bin/send_bug \

PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)

# audio support
PRODUCT_PACKAGES += \
	audio.primary.$(TARGET_PRODUCT) \

# a2dp support
PRODUCT_PACKAGES += \
         audio.a2dp.default \

# bluetooth config
PRODUCT_PACKAGES += \
         hciconfig \

# backlight control
PRODUCT_PACKAGES += \
        lights.bigcore \

# hwcomposer
PRODUCT_PACKAGES += \
        hwcomposer.$(TARGET_PRODUCT) \
        hwcomposer.default

# Ethernet
PRODUCT_PACKAGES += init.net.eth0.sh

PRODUCT_PROPERTY_OVERRIDES += \
        ro.opengles.version = 131072

# Setup eth0 for debugging - settings only take effect when ro.debuggable=1
PRODUCT_PROPERTY_OVERRIDES += \
        net.eth0.netmask=255.255.255.0

ifeq ($(ETH0_IP),)
# Use default IP
PRODUCT_PROPERTY_OVERRIDES += \
        net.eth0.ip=192.168.42.1
else
ifneq ($(ETH0_IP),dhcp)
# Use user defined static IP if not dhcp
PRODUCT_PROPERTY_OVERRIDES += \
	net.eth0.ip=$(ETH0_IP)
endif
# Otherwise net.eth0.ip is not set to enable dhcp
endif

# For OTA Update
PRODUCT_PACKAGES += \
	Ota \
	OtaDownloader \

ifneq ($(PANEL_IGNORE_LID),)
	PRODUCT_PROPERTY_OVERRIDES += \
		init.panel_ignore_lid=$(PANEL_IGNORE_LID)
endif

# sensor support
PRODUCT_PACKAGES += \
	sensors.$(TARGET_PRODUCT) \

# systemtap support
PRODUCT_PACKAGES += \
	stap \
	staprun \
	stapio \

# include firmware binaries for Intel Wifi adapters
$(call inherit-product-if-exists, vendor/intel/iwlwifi/iwlwifi.mk)
# include third-party-apps
$(call inherit-product-if-exists, vendor/third-party-apps/third-party-apps.mk)

$(call inherit-product-if-exists, external/sep/sep.mk)

# end of file
