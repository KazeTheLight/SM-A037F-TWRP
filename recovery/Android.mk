#
# Copy crypto-only runtime libraries that the linker needs into the recovery
# ramdisk. TW_INCLUDE_CRYPTO makes the recovery binary link libresetprop, but
# the module installs to system/lib64, not TARGET_RECOVERY_ROOT_OUT.
#
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := twrp_libresetprop
LOCAL_MODULE_TAGS := optional
ifeq ($(TW_INCLUDE_CRYPTO), true)
LOCAL_REQUIRED_MODULES := libresetprop
endif
LOCAL_POST_INSTALL_CMD := \
    if [ -f $(TARGET_OUT)/lib64/libresetprop.so ]; then \
        mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/system/lib64; \
        cp -f $(TARGET_OUT)/lib64/libresetprop.so $(TARGET_RECOVERY_ROOT_OUT)/system/lib64/libresetprop.so; \
    elif [ ! -f $(TARGET_RECOVERY_ROOT_OUT)/system/lib64/libresetprop.so ]; then \
        echo "ERROR: libresetprop.so was not built or installed" >&2; \
        exit 1; \
    fi
include $(BUILD_PHONY_PACKAGE)
