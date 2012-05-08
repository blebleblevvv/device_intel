# Multimedia components to be used with Intel products.
# Each component should be listed here to be included in
# the final image
#
# Contact sean.v.kelley@intel.com to add/remove components

$(call inherit-product-if-exists, hardware/intel/wrs_omxil_core/wrs_omxil_core.mk)
$(call inherit-product-if-exists, hardware/intel/omx-components/omx-components.mk)
$(call inherit-product-if-exists, external/intel-driver/intel-driver.mk)

