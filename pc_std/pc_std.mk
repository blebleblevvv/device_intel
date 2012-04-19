# Superclass
$(call inherit-product, device/intel/common/generic.mk)

LOCAL_PATH := device/intel/pc_std

#
# gralloc & mesa lib
#
PRODUCT_PACKAGES += \
    libGLES_mesa    \
    gralloc.$(TARGET_PRODUCT) \

#
# tinyalsa utils
#
PRODUCT_PACKAGES += \
	tinymix \
	tinyplay \
	tinycap \

# PC std common files
PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/asound.conf:system/etc/asound.conf \
	$(LOCAL_PATH)/android.conf:system/etc/dhcpcd/android.conf \
	$(LOCAL_PATH)/egl_mesa.cfg:system/lib/egl/egl.cfg \
	device/intel/common/init.harddisk.rc:root/init.harddisk.rc \
	$(LOCAL_PATH)/vold.fstab:system/etc/vold.fstab \
	$(LOCAL_PATH)/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
	$(LOCAL_PATH)/Vendor_0408_Product_3001.idc:system/usr/idc/Vendor_0408_Product_3001.idc

# for bugmailer
PRODUCT_PACKAGES += send_bug
PRODUCT_COPY_FILES += \
	system/extras/bugmailer/bugmailer.sh:system/bin/bugmailer.sh \
	system/extras/bugmailer/send_bug:system/bin/send_bug

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
        lights.pc_std \

# Start eth0 on boot (for debugging)
ifneq ($(TARGET_BUILD_VARIANT),user)
PRODUCT_PROPERTY_OVERRIDES += \
	net.eth0.startonboot=1 \
	net.eth0.ip=192.168.42.1 \
	net.eth0.netmask=255.255.255.0

PRODUCT_COPY_FILES += $(LOCAL_PATH)/init.net.eth0.sh:system/etc/init.net.eth0.sh
endif
