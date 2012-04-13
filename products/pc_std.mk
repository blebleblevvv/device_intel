# Superclass
$(call inherit-product, device/intel/products/pc_std_common.mk)

PRODUCT_NAME := pc_std
PRODUCT_DEVICE := pc_std

LOCAL_PATH := device/intel/pc_std

PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/android.conf:system/etc/dhcpcd/android.conf \
	$(LOCAL_PATH)/init.pc_std.rc:root/init.pc_std.rc \
	$(LOCAL_PATH)/init.pc_std.sh:system/etc/init.pc_std.sh \
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

