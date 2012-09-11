# Superclass
$(call inherit-product, device/intel/bigcore/bigcore.mk)

# The Superclass may include PRODUCT_COPY_FILES directives that this subclass
# may want to override.  For PRODUCT_COPY_FILES directives the Android Build
# System ignores subsequent copies that lead to the same destination.  So for
# subclass PRODUCT_COPY_FILES to override properly, the right thing to do is to
# prepend them instead of appending them as usual.  This is done using the
# pattern:
#
# OVERRIDE_COPIES := <the list>
# PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)

PRODUCT_NAME := samsungxe700t
PRODUCT_DEVICE := samsungxe700t

# For device identification to apps
PRODUCT_MANUFACTURER := Samsung
PRODUCT_MODEL := XE700T

LOCAL_PATH := device/intel/samsungxe700t

OVERRIDE_COPIES := \
	$(LOCAL_PATH)/init.samsungxe700t.rc:root/init.samsungxe700t.rc \
	$(LOCAL_PATH)/init.samsungxe700t.sh:system/etc/init.samsungxe700t.sh \
	$(LOCAL_PATH)/ueventd.samsungxe700t.rc:root/ueventd.samsungxe700t.rc \

PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)

# Additional configurations needed for the platform.
# Mostly binary files (e.g. firmware)
$(call inherit-product-if-exists, vendor/intel/samsungxe700t/samsungxe700t.mk)
