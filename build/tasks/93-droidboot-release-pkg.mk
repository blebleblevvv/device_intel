# This generates a zip file containing the necessary images
# and executables for the droidboot release package

# if make receives a RELAESE_PACKAGE_NAME parameter, that one will be set as
# the zip name, otherwise we are using a default value
ifeq ($(RELEASE_PACKAGE_NAME),)
RELEASE_PACKAGE_NAME := droidboot-release-package
endif
DROIDBOOT_RELEASE_PACKAGE := $(PRODUCT_OUT)/$(RELEASE_PACKAGE_NAME).zip
DROIDBOOT_RELEASE_DIR := $(call intermediates-dir-for,PACKAGING,droidboot-release-package)

drpkg_platform_files := $(ANDROID_BUILD_TOP)/device/intel/support/flash-pc \
	$(DROIDBOOT_BOOTIMAGE) \

# With the necessary files, pack them
$(DROIDBOOT_RELEASE_PACKAGE): \
		$(drpkg_platform_files) \
		$(INSTALLED_BOOTLOADER_MODULE) \
		$(INSTALLED_SYSTEMIMAGE) \
		$(INSTALLED_RECOVERYIMAGE_TARGET) \
		$(INSTALLED_BOOTIMAGE_TARGET) \
		$(BUILT_USERDATAIMAGE_TARGET) \
		$(INSTALLED_SYSTEM_MAP) \

	$(hide) rm -rf $(DROIDBOOT_RELEASE_PACKAGE) $(DROIDBOOT_RELEASE_DIR)
	@echo "Droidboot Release Package: $@"
	$(hide) mkdir -p $(DROIDBOOT_RELEASE_DIR)/$(RELEASE_PACKAGE_NAME)
	$(hide) $(ACP) -p \
		$(drpkg_platform_files) \
		$(INSTALLED_BOOTLOADER_MODULE) \
		$(INSTALLED_SYSTEMIMAGE) \
		$(INSTALLED_RECOVERYIMAGE_TARGET) \
		$(INSTALLED_BOOTIMAGE_TARGET) \
		$(BUILT_USERDATAIMAGE_TARGET) \
		$(ANDROID_HOST_OUT)/bin/adb \
		$(ANDROID_HOST_OUT)/bin/fastboot \
		$(INSTALLED_SYSTEM_MAP) \
		$(DROIDBOOT_RELEASE_DIR)/$(RELEASE_PACKAGE_NAME)
	$(hide) (cd $(DROIDBOOT_RELEASE_DIR) && zip -qr $(RELEASE_PACKAGE_NAME).zip $(RELEASE_PACKAGE_NAME))
	$(hide) $(ACP) $(DROIDBOOT_RELEASE_DIR)/$(RELEASE_PACKAGE_NAME).zip $(DROIDBOOT_RELEASE_PACKAGE)


.PHONY: droidboot-release-package
droidboot-release-package: $(DROIDBOOT_RELEASE_PACKAGE)
