# make file for lenovox220t
#

ifeq ($(TARGET_PRODUCT),lenovox220t)
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
include $(BUILD_KEY_CHAR_MAP)

.PHONY: lenovox220t
lenovox220t: installer_img otapackage

#include $(LOCAL_PATH)/recovery/Android.mk

endif # TARGET_PRODUCT=lenovox220t

