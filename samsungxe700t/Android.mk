# make file for samsungxe700t
#

ifeq ($(TARGET_PRODUCT),samsungxe700t)
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
include $(BUILD_KEY_CHAR_MAP)

.PHONY: samsungxe700t
samsungxe700t: installer_img otapackage

#include $(LOCAL_PATH)/recovery/Android.mk

endif # TARGET_PRODUCT=samsungxe700t

