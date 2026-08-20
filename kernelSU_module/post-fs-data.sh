#!/system/bin/sh

# ============================================
# Opus Camera - Post-fs-data.sh
# Runs early in boot, before system is fully up
# ============================================

# Set camera-related properties early
setprop persist.camera.HAL3.enable 1
setprop persist.vendor.camera.HAL3.enable 1
setprop persist.camera.preview.ubwc 0
setprop persist.vendor.camera.preview.ubwc 0

# Allow camera app to use more memory
setprop persist.camera.max.preview.fps 30

# MTK specific camera props
setprop vendor.camera.hal1.packagelist OplusCamera
setprop vendor.camera.mdp.cz.enable 1
setprop vendor.camera.isp_nr3dc_enable 1

# Camera2 API enable
setprop persist.camera2.global.debug 1

exit 0