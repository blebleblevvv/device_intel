# Superclass
$(call inherit-product, device/intel/pc_std/pc_std.mk)

# The Superclass may include PRODUCT_COPY_FILES directives that this subclass
# may want to override.  For PRODUCT_COPY_FILES directives the Android Build
# System ignores subsequent copies that lead to the same destination.  So for
# subclass PRODUCT_COPY_FILES to override properly, the right thing to do is to
# prepend them instead of appending them as usual.  This is done using the
# pattern:
#
# OVERRIDE_COPIES := <the list>
# PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)

PRODUCT_NAME := lenovox220t
PRODUCT_DEVICE := lenovox220t

# For device identification to apps
PRODUCT_MANUFACTURER := Lenovo
PRODUCT_MODEL := X220T

LOCAL_PATH := device/intel/lenovox220t

OVERRIDE_COPIES := \
	$(LOCAL_PATH)/init.lenovox220t.rc:root/init.lenovox220t.rc \
	$(LOCAL_PATH)/init.lenovox220t.sh:system/etc/init.lenovox220t.sh \
	$(LOCAL_PATH)/Wacom_ISDv4_E6_Finger.idc:system/usr/idc/Wacom_ISDv4_E6_Finger.idc \
	$(LOCAL_PATH)/Wacom_ISDv4_E6_Pen.idc:system/usr/idc/Wacom_ISDv4_E6_Pen.idc \
	device/intel/common/intel_initlogo_1366x768.rle:root/initlogo.rle \
	frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
	$(LOCAL_PATH)/ueventd.lenovox220t.rc:root/ueventd.lenovox220t.rc \

PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)

# tp_smapi is needed for accelerometer through HDAPS
EXTERNAL_KERNEL_MODULES += external/tp_smapi

# Additional configurations needed for the platform.
# Mostly binary files (e.g. firmware)
$(call inherit-product-if-exists, vendor/intel/lenovox220t/lenovox220t.mk)

# support for sensors on Lenovo X220t
PRODUCT_PACKAGES += \
	sensors.lenovox220t \

# end of file
