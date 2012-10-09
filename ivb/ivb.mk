# Superclass
$(call inherit-product, device/intel/bigcore/bigcore.mk)

PRODUCT_NAME := ivb
PRODUCT_DEVICE := ivb

# For device identification to apps
PRODUCT_MANUFACTURER := Intel
PRODUCT_MODEL := Ivy Bridge

LOCAL_PATH := device/intel/ivb

PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/init.ivb.rc:root/init.$(TARGET_PRODUCT).rc \
	$(LOCAL_PATH)/init.ivb.sh:system/etc/init.ivb.sh \

PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)

# Additional configurations needed for the platform.
# Mostly binary files (e.g. firmware)
$(call inherit-product-if-exists, vendor/intel/ivb/ivb.mk)
