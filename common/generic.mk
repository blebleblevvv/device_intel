# This should be included for device with telephony hardware.
$(call inherit-product, device/intel/common/generic_no_telephony.mk)
$(call inherit-product, build/target/product/telephony.mk)
