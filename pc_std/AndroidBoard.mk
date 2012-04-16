LOCAL_PATH := $(call my-dir)

# 'dbimages' for use with Droidboot or sync_img
.PHONY: dbimages
dbimages: systemimage \
	  recoveryimage \
	  syslinux-image \
	  bootimage \
	  userdataimage

ifeq ($(TARGET_STAGE_DROIDBOOT),true)
dbimages: droidboot-bootimage
endif

# 'allimages' to build everything that can be built
.PHONY: allimages
allimages: installer_img ota-dev dbimages

# Historical: make $(TARGET_PRODUCT) builds everything
.PHONY: $(TARGET_PRODUCT)
$(TARGET_PRODUCT): allimages

