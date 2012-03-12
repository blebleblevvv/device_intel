# make file for pc_std
#

ifeq ($(TARGET_PRODUCT),pc_std)
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
include $(BUILD_KEY_CHAR_MAP)

.PHONY: pc_std
pc_std: installer_img 

#include $(LOCAL_PATH)/recovery/Android.mk

endif # TARGET_PRODUCT=pc_std

