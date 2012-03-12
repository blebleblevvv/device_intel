# Superclass
$(call inherit-product, device/intel/products/pc_std.mk)

PRODUCT_NAME := lenovox220t
PRODUCT_DEVICE := lenovox220t

LOCAL_PATH := device/intel/lenovox220t

PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/init.lenovox220t.rc:root/init.lenovox220t.rc \
	$(LOCAL_PATH)/init.lenovox220t.sh:system/etc/init.lenovox220t.sh \
	$(LOCAL_PATH)/Wacom_ISDv4_E6_Finger.idc:system/usr/idc/Wacom_ISDv4_E6_Finger.idc \
	$(LOCAL_PATH)/Wacom_ISDv4_E6_Pen.idc:system/usr/idc/Wacom_ISDv4_E6_Pen.idc \

# Additional configurations needed for the platform.
# Mostly binary files (e.g. firmware)
$(call inherit-product-if-exists, vendor/intel/products/lenovox220t.mk)
