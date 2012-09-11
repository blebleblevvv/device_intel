PC_STD_LOCAL_PATH := $(call my-dir)
include $(call all-subdir-makefiles)
LOCAL_PATH := $(PC_STD_LOCAL_PATH)

include $(CLEAR_VARS)
LOCAL_MODULE := init.net.eth0.sh
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT_ETC)
LOCAL_SRC_FILES := $(LOCAL_MODULE)
include $(BUILD_PREBUILT)

ifneq ($(BOARD_HAS_FSTAB),true)
FSTAB_SYMLINK := $(TARGET_ROOT_OUT)/fstab.$(TARGET_PRODUCT)
$(FSTAB_SYMLINK):
	$(hide) echo "Symlink: $@ -> fstab.common"
	$(hide) mkdir -p $(dir $@)
	$(hide) rm -rf $@
	$(hide) ln -sf fstab.common $@

ALL_DEFAULT_INSTALLED_MODULES += $(FSTAB_SYMLINK)
endif

# end of file
