#!/sbin/sh

# ============================================
# Opus Camera - Customize.sh (KernelSU)
# ============================================

ui_print ""
ui_print "📷 Opus Camera - OplusCamera Port"
ui_print "===================================="
ui_print "Device: Realme Narzo 50a (RMX3430)"
ui_print "Target: AOSP Custom ROMs (Axion 2.7+)"
ui_print ""

# Detect architecture
ARCH=$(getprop ro.product.cpu.abi)
ui_print "Architecture: $ARCH"

if [ "$ARCH" != "arm64-v8a" ]; then
    ui_print "⚠️ Warning: Expected arm64-v8a, got $ARCH"
fi

# Detect Android version
SDK=$(getprop ro.build.version.sdk)
ui_print "Android SDK: $SDK"

# Verify we have the required files
REQUIRED_FILES="system/app/OplusCamera/OplusCamera.apk"

for f in $REQUIRED_FILES; do
    if [ ! -f "$MODPATH/$f" ]; then
        ui_print "⚠️ Missing: $f"
        ui_print "   The camera app may not work without this file."
    fi
done

ui_print ""
ui_print "✅ Installation paths:"
ui_print "   Camera APK  → /system/app/OplusCamera/"
ui_print "   Framework   → /system/framework/"
ui_print "   Libs        → /system/lib64/"
ui_print "   Vendor blobs → /vendor/lib64/"
ui_print ""

# Camera2 API check
CAM2=$(getprop persist.camera.HAL3.enable)
if [ "$CAM2" != "1" ]; then
    ui_print "⚠️ Camera2 API HAL3 not enabled in props"
    ui_print "   post-fs-data.sh will set it on next boot"
fi

ui_print "📸 Flash complete! Reboot to apply."
ui_print ""