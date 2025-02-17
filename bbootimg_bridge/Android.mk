LOCAL_PATH:= $(call my-dir)
include $(CLEAR_VARS)

LOCAL_C_INCLUDES += \
    system/extras/libbootimg/include \

LOCAL_SRC_FILES:= \
    bbootimg_bridge.c \

LOCAL_MODULE:= bbootimg_bridge
LOCAL_MODULE_TAGS := eng

LOCAL_MODULE_PATH := $(TARGET_ROOT_OUT)
LOCAL_UNSTRIPPED_PATH := $(TARGET_ROOT_OUT_UNSTRIPPED)
LOCAL_FORCE_STATIC_EXECUTABLE := true

LOCAL_CFLAGS := -DDEBUG_KMSG
LOCAL_STATIC_LIBRARIES := libc libbootimg libcutils

include $(BUILD_EXECUTABLE)
