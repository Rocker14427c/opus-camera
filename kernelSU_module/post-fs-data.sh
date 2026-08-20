#!/system/bin/sh

# ============================================
# Opus Camera - Post-fs-data.sh (V2)
# Enhanced with correct props from RUI4 F.23
# ============================================

# Set camera-related properties early
setprop persist.camera.HAL3.enable 1
setprop persist.vendor.camera.HAL3.enable 1
setprop persist.camera.preview.ubwc 0
setprop persist.vendor.camera.preview.ubwc 0

# MTK specific camera props from stock build.prop
setprop vendor.camera.hal1.packagelist OplusCamera
setprop vendor.camera.mdp.cz.enable 1
setprop vendor.camera.isp_nr3dc_enable 1

# Video recording
setprop persist.camera.max.preview.fps 30
setprop persist.vendor.camera.max.preview.fps 30
setprop media.camera.ts.monotonic 1

# Oplus specific
setprop ro.oplus.camera.use_subsystem 1
setprop persist.vendor.oplus.camera.support_ai_scene 1
setprop persist.vendor.oplus.camera.support_hdr 1

# Image quality
setprop persist.camera.dedicated.feedback 0
setprop persist.vendor.camera.dedicated.feedback 0

# Memory
setprop persist.vendor.camera.mem.size 32
setprop persist.vendor.camera.ion.size 16

# RMX3430 Sensor info
setprop persist.vendor.camera.sensor.back 50mp_s5kjn1
setprop persist.vendor.camera.sensor.front 8mp_gc8034
setprop persist.vendor.camera.sensor.macro 2mp_gc02m1
setprop persist.vendor.camera.sensor.depth 2mp_ov02b

exit 0