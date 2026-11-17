$(call inherit-product-if-exists, vendor/xiaomi/nikel/nikel-vendor.mk)

ifneq ($(wildcard vendor/xiaomi/nikel/nikel-vendor.mk),)
PRODUCT_PACKAGES += libcurl libtinyxml
PRODUCT_PACKAGES += libtinycompress librilutils
PRODUCT_PACKAGES += \
    libandroid \
    libinput \
    libjpeg \
    libpowermanager \
    libsqlite
PRODUCT_PACKAGES += \
    libgatekeeper \
    libjnigraphics \
    libkeymaster1 \
    libkeymaster_messages \
    libkeystore_binder \
    libsoftkeymaster \
    libsoftkeymasterdevice
endif

# Display and boot animation.
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxhdpi
TARGET_SCREEN_HEIGHT := 1920
TARGET_SCREEN_WIDTH := 1080
DEVICE_PACKAGE_OVERLAYS += device/xiaomi/nikel/overlay

# Feature declarations shared by the Nikel stock ROM and CM13.
NIKEL_FEATURE_XML := \
    android.hardware.bluetooth.xml \
    android.hardware.bluetooth_le.xml \
    android.hardware.camera.xml \
    android.hardware.camera.flash-autofocus.xml \
    android.hardware.camera.front.xml \
    android.hardware.consumerir.xml \
    android.hardware.fingerprint.xml \
    android.hardware.location.gps.xml \
    android.hardware.sensor.accelerometer.xml \
    android.hardware.sensor.compass.xml \
    android.hardware.sensor.gyroscope.xml \
    android.hardware.sensor.light.xml \
    android.hardware.sensor.proximity.xml \
    android.hardware.telephony.gsm.xml \
    android.hardware.touchscreen.multitouch.jazzhand.xml \
    android.hardware.usb.accessory.xml \
    android.hardware.usb.host.xml \
    android.hardware.wifi.xml \
    android.hardware.wifi.direct.xml \
    handheld_core_hardware.xml

PRODUCT_COPY_FILES += $(foreach file,$(NIKEL_FEATURE_XML),\
    frameworks/native/data/etc/$(file):system/etc/permissions/$(file))

# MTK keypad and wired headset buttons.
PRODUCT_COPY_FILES += \
    device/xiaomi/nikel/keylayout/mtk-kpd.kl:system/usr/keylayout/mtk-kpd.kl \
    device/xiaomi/nikel/keylayout/ACCDET.kl:system/usr/keylayout/ACCDET.kl

# MediaTek audio policy and device routing.
PRODUCT_COPY_FILES += \
    device/xiaomi/nikel/audio/audio_policy.conf:system/etc/audio_policy.conf \
    device/xiaomi/nikel/audio/audio_device.xml:system/etc/audio_device.xml

# Stagefright codec lists and the MediaTek OMX registry.
NIKEL_MEDIA_CONFIGS := \
    media_codecs.xml \
    media_codecs_performance.xml \
    media_codecs_mediatek_audio.xml \
    media_codecs_mediatek_video.xml \
    media_codecs_google_audio.xml \
    media_codecs_google_video_le.xml \
    mtk_omx_core.cfg

PRODUCT_COPY_FILES += $(foreach file,$(NIKEL_MEDIA_CONFIGS),\
    device/xiaomi/nikel/configs/$(file):system/etc/$(file))

# Wi-Fi supplicant configs for the MediaTek connectivity driver.
PRODUCT_PACKAGES += hostapd wpa_supplicant
PRODUCT_PACKAGES += FMRadio
PRODUCT_COPY_FILES += \
    device/xiaomi/nikel/wifi/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
    device/xiaomi/nikel/wifi/wpa_supplicant_overlay.conf:system/etc/wifi/wpa_supplicant_overlay.conf \
    device/xiaomi/nikel/wifi/p2p_supplicant_overlay.conf:system/etc/wifi/p2p_supplicant_overlay.conf

# SUPL profiles consumed by the MediaTek A-GPS stack.
PRODUCT_COPY_FILES += \
    device/xiaomi/nikel/gps/agps_profiles_conf2.xml:system/etc/agps_profiles_conf2.xml

# Stock MediaTek thermal policy.
PRODUCT_COPY_FILES += \
    device/xiaomi/nikel/configs/thermal.conf:system/etc/.tp/thermal.conf

# Android 6 init and ueventd load these files by ro.hardware.
PRODUCT_COPY_FILES += \
    device/xiaomi/nikel/rootdir/fstab.mt6797:root/fstab.mt6797 \
    device/xiaomi/nikel/rootdir/init.mt6797.rc:root/init.mt6797.rc \
    device/xiaomi/nikel/rootdir/init.mt6797.services.rc:root/init.mt6797.services.rc \
    device/xiaomi/nikel/rootdir/init.mt6797.modem.rc:root/init.mt6797.modem.rc \
    device/xiaomi/nikel/rootdir/init.mt6797.fingerprint.rc:root/init.mt6797.fingerprint.rc \
    device/xiaomi/nikel/rootdir/ueventd.mt6797.rc:root/ueventd.mt6797.rc
