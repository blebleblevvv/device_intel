#
# For Intel Core-based (specifically Sandy Bridge and later) devices,
# utilizing Mesa for 3D graphics.
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
include $(BUILD_KEY_CHAR_MAP)

include device/intel/bigcore/AndroidBoard.mk
