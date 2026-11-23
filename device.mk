#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 The TWRP Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# VNDK
PRODUCT_TARGET_VNDK_VERSION := 31

# API (SM-A037F shipped with Android 11 / API 30)
PRODUCT_SHIPPING_API_LEVEL := 30

# Display density reported by the device
PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=300

# Dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_ENFORCE_PRODUCT_PARTITION_INTERFACE := true
PRODUCT_PRODUCT_VNDK_VERSION := current

# bootctrl
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl \
    android.hardware.boot@1.2-impl.recovery

# Health Hal
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-impl.recovery \
    android.hardware.health@2.1-service
