#!/system/bin/sh

# ============================================
# Opus Camera - Service.sh (V2)
# Enhanced boot service with better error handling
# ============================================

# Wait for boot to finish
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# Small delay for system to settle
sleep 2

LOG_TAG="OpusCamera"

# Fix SELinux context for camera files
chcon -R u:object_r:system_file:s0 /system/app/OplusCamera 2>/dev/null
chcon -R u:object_r:system_file:s0 /system/app/OplusEngineerCamera 2>/dev/null
chcon -R u:object_r:system_file:s0 /system/framework/oplus-camera-framework.jar 2>/dev/null

# Set correct permissions
chmod 755 /system/app/OplusCamera 2>/dev/null
chmod 755 /system/app/OplusEngineerCamera 2>/dev/null
chmod 644 /system/app/OplusCamera/OplusCamera.apk 2>/dev/null
chmod 644 /system/app/OplusEngineerCamera/OplusEngineerCamera.apk 2>/dev/null
chmod 644 /system/framework/oplus-camera-framework.jar 2>/dev/null

# Set SELinux to permissive for camera (debug only - remove for daily use)
# echo 0 > /sys/fs/selinux/enforce

# Try to start camera engine service
if [ -f /system/app/OplusEngineerCamera/OplusEngineerCamera.apk ]; then
    pm install -r /system/app/OplusEngineerCamera/OplusEngineerCamera.apk 2>/dev/null
    am startservice com.oplus.camera/.engine.CameraEngineService 2>/dev/null
    log -t $LOG_TAG "Camera engine service started"
fi

# Clear camera app cache to avoid stale data
pm clear com.oplus.camera 2>/dev/null

log -t $LOG_TAG "Opus Camera port module loaded successfully"

exit 0