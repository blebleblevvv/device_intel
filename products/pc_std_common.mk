$(call inherit-product, device/intel/products/generic.mk)

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

# audio support
PRODUCT_PACKAGES += \
	audio.primary.$(TARGET_PRODUCT) \
