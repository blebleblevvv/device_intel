ota_package := $(PRODUCT_OUT)/ota-dev.zip

$(ota_package): $(BUILT_TARGET_FILES_PACKAGE) $(OTATOOLS)
	@echo "Package OTA: $@"
	$(hide) ./build/tools/releasetools/ota_from_target_files \
	   --no_prereq --aslr_mode off --verbose \
	   --path $(HOST_OUT) \
           $(BUILT_TARGET_FILES_PACKAGE) $@

.PHONY: ota-dev
ota-dev: $(ota_package)
