# Superclass
$(call inherit-product, device/intel/bigcore/bigcore.mk)

PRODUCT_NAME := core_mesa
PRODUCT_DEVICE := core_mesa

# For device identification to apps
PRODUCT_MANUFACTURER := Intel
PRODUCT_MODEL := core_mesa

LOCAL_PATH := device/intel/core_mesa

PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/init.core_mesa.rc:root/init.core_mesa.rc \
	$(LOCAL_PATH)/init.core_mesa.sh:system/etc/init.core_mesa.sh \

PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)

# Additional configurations needed for the platform.
# Mostly binary files (e.g. firmware)
$(call inherit-product-if-exists, vendor/intel/core_mesa/core_mesa.mk)
