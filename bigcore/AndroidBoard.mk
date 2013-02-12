LOCAL_PATH := $(call my-dir)

# 'dbimages' for use with Droidboot or sync_img
.PHONY: dbimages
dbimages: systemimage \
	  recoveryimage \
	  bootimage \
	  userdataimage

DBUPDATE_BLOB := $(PRODUCT_OUT)/dbupdate.bin

ifeq ($(TARGET_STAGE_DROIDBOOT),true)
dbimages: droidboot-bootimage $(DBUPDATE_BLOB)
endif

# 'allimages' to build everything that can be built
.PHONY: allimages
allimages: ota-dev dbimages liveimg

# Historical: make $(TARGET_PRODUCT) builds everything
.PHONY: $(TARGET_PRODUCT)
$(TARGET_PRODUCT): allimages

