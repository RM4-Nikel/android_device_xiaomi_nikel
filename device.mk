$(call inherit-product-if-exists, vendor/xiaomi/nikel/nikel-vendor.mk)

# Display and boot animation.
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxhdpi
TARGET_SCREEN_HEIGHT := 1920
TARGET_SCREEN_WIDTH := 1080

# Feature declarations shared by the Nikel stock ROM and CM13.
NIKEL_FEATURE_XML := \
    android.hardware.bluetooth.xml \
    android.hardware.bluetooth_le.xml \
    android.hardware.camera.xml \
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
