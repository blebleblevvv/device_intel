# Superclass
$(call inherit-product, device/intel/pc_std/pc_std.mk)

PRODUCT_NAME := samsungxe700t
PRODUCT_DEVICE := samsungxe700t

LOCAL_PATH := device/intel/samsungxe700t

PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/init.samsungxe700t.rc:root/init.samsungxe700t.rc \
	$(LOCAL_PATH)/init.samsungxe700t.sh:system/etc/init.samsungxe700t.sh \
	$(LOCAL_PATH)/Atmel_Atmel_maXTouch_Digitizer.idc:system/usr/idc/Atmel_Atmel_maXTouch_Digitizer.idc \
	$(LOCAL_PATH)/Wacom_ISDv4_EC_Pen.idc:system/usr/idc/Wacom_ISDv4_EC_Pen.idc \
	device/intel/common/intel_initlogo_1366x768.rle:root/initlogo.rle \

# Additional configurations needed for the platform.
# Mostly binary files (e.g. firmware)
$(call inherit-product-if-exists, vendor/intel/samsungxe700t/samsungxe700t.mk)
