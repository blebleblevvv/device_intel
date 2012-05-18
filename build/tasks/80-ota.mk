ota_package := $(PRODUCT_OUT)/ota-dev.zip

$(ota_package): $(BUILT_TARGET_FILES_PACKAGE) $(OTATOOLS)
	@echo "Package OTA: $@"
	$(hide) ./build/tools/releasetools/ota_from_target_files \
	   --no_prereq --aslr_mode off --verbose \
	   --path $(HOST_OUT) \
           $(BUILT_TARGET_FILES_PACKAGE) $@

.PHONY: ota-dev
ota-dev: $(ota_package)


# If OTA_INCREMENTA_FROM is specified as make parameter, then otapackage will
# also create an incremental package from the file specified by the value of
# this parameter.
# For example:
#  make ... ota-dev-inc OTA_INCREMENTAL_FROM=/path/to/previous-target-files-package.zip
ifdef OTA_INCREMENTAL_FROM

ota_inc_name := $(TARGET_PRODUCT)
ifeq ($(TARGET_BUILD_TYPE),debug)
  ota_inc_name := $(ota_inc_name)_debug
endif
ota_inc_name := $(ota_inc_name)-ota-$(FILE_NAME_TAG)

INTERNAL_OTA_INCREMENTAL_TARGET := $(PRODUCT_OUT)/$(ota_inc_name)-inc.zip
$(INTERNAL_OTA_INCREMENTAL_TARGET): KEY_CERT_PAIR := $(DEFAULT_KEY_CERT_PAIR)
$(INTERNAL_OTA_INCREMENTAL_TARGET): $(BUILT_TARGET_FILES_PACKAGE) $(OTATOOLS)
	@echo "Package incremental OTA: $@"
	$(hide) ./build/tools/releasetools/ota_from_target_files \
	   --aslr_mode off --verbose \
	   --path $(HOST_OUT) \
	   --incremental_from $(OTA_INCREMENTAL_FROM) \
	   $(BUILT_TARGET_FILES_PACKAGE) $@

ota-dev: $(INTERNAL_OTA_INCREMENTAL_TARGET)

endif # ifdef OTA_INCREMENTAL_FROM
