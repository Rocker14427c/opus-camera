#!/system/bin/sh

# ============================================
# Opus Camera - Service.sh
# Runs after boot completes
# ============================================

# Wait for boot to finish
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# Fix SELinux context for camera files
chcon -R u:object_r:system_file:s0 /system/app/OplusCamera
chcon -R u:object_r:system_file:s0 /system/framework/oplus-camera-framework.jar

# Set correct permissions
chmod 755 /system/app/OplusCamera
chmod 644 /system/app/OplusCamera/OplusCamera.apk
chmod 644 /system/framework/oplus-camera-framework.jar

# Try to start camera service if OppoEngineer is present
if [ -f /system/app/OplusEngineerCamera/OplusEngineerCamera.apk ]; then
    am startservice com.oplus.camera/.engine.CameraEngineService 2>/dev/null
fi

# Log that we ran
log -t OpusCamera "Opus Camera port module loaded successfully"

exit 0