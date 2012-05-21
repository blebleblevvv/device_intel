# Superclass
$(call inherit-product, device/intel/common/generic.mk)

LOCAL_PATH := device/intel/pc_std


#
# gralloc & mesa lib
#
PRODUCT_PACKAGES += \
    libGLES_mesa    \
    gralloc.$(TARGET_PRODUCT) \
    camera.pc_std \

# Configre UI to use EGL/GLES mesa by default
# The variable allows to configure another EGL/GLES driver
USE_MESA_EGL_CONFIG?=yes
ifeq ($(USE_MESA_EGL_CONFIG),yes)
PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/egl_mesa.cfg:system/lib/egl/egl.cfg
endif

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
	device/intel/common/init.harddisk.rc:root/init.harddisk.rc \
	$(LOCAL_PATH)/vold.fstab:system/etc/vold.fstab \
	$(LOCAL_PATH)/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
	$(LOCAL_PATH)/Vendor_0408_Product_3001.idc:system/usr/idc/Vendor_0408_Product_3001.idc \
	$(LOCAL_PATH)/init.pc_std.rc:root/init.pc_std.rc \
	$(LOCAL_PATH)/init.pc_std.sh:system/etc/init.pc_std.sh \

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

# hwcomposer
PRODUCT_PACKAGES += \
        hwcomposer.default

# Start eth0 on boot (for debugging)
ifneq ($(TARGET_BUILD_VARIANT),user)

PRODUCT_PROPERTY_OVERRIDES += \
        net.eth0.startonboot=1 \
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

PRODUCT_COPY_FILES += $(LOCAL_PATH)/init.net.eth0.sh:system/etc/init.net.eth0.sh
endif

# For OTA Update
PRODUCT_PACKAGES += \
	Ota \
	OtaDownloader \

ifneq ($(PANEL_IGNORE_LID),)
	PRODUCT_PROPERTY_OVERRIDES += \
		init.panel_ignore_lid=$(PANEL_IGNORE_LID)
endif
