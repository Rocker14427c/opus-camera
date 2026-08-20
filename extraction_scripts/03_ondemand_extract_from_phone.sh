#!/system/bin/sh
# ======================================================
# Opus Camera - On-Device Camera Blob Extractor
# Run this on your Narzo 50a WITH ROOT (KernelSU/Magisk)
# It will extract camera APK + libs from the running ROM
# and prepare them for the KernelSU module
# ======================================================

echo "📷 Opus Camera — On-Device Extractor"
echo "===================================="
echo ""

MODULE_DIR="/data/local/tmp/opus-camera/kernelSU_module"
OUTPUT_ZIP="/data/local/tmp/OplusCamera-Port.zip"

# Create module directory structure
mkdir -p "$MODULE_DIR/system/app/OplusCamera"
mkdir -p "$MODULE_DIR/system/app/OplusEngineerCamera"
mkdir -p "$MODULE_DIR/system/etc/permissions"
mkdir -p "$MODULE_DIR/system/framework"
mkdir -p "$MODULE_DIR/system/lib"
mkdir -p "$MODULE_DIR/system/lib64"
mkdir -p "$MODULE_DIR/vendor/lib"
mkdir -p "$MODULE_DIR/vendor/lib64"
mkdir -p "$MODULE_DIR/vendor/etc/camera"
mkdir -p "$MODULE_DIR/vendor/etc/permissions"

echo "✅ Directory structure created"
echo ""

# ========== 1. Extract Camera APK ==========
echo "[1/6] Extracting Camera APK..."

# Try multiple possible locations for the camera app
CAM_APK_SRC=""
for try in \
    /system/app/OplusCamera/OplusCamera.apk \
    /system/app/OppoCamera/OppoCamera.apk \
    /system/priv-app/OplusCamera/OplusCamera.apk \
    /system/system/app/OplusCamera/OplusCamera.apk \
    /product/app/OplusCamera/OplusCamera.apk \
    /my_product/app/OplusCamera/OplusCamera.apk \
    /my_stock/app/OplusCamera/OplusCamera.apk; do
    if [ -f "$try" ]; then
        CAM_APK_SRC="$try"
        break
    fi
done

if [ -n "$CAM_APK_SRC" ]; then
    cp -v "$CAM_APK_SRC" "$MODULE_DIR/system/app/OplusCamera/"
    echo "  ✅ OplusCamera.apk extracted"
else
    echo "  ⚠️ OplusCamera.apk NOT found! Searching..."
    find /system /product /vendor /my_product /my_stock /odm -name "*Camera*.apk" -o -name "*camera*.apk" 2>/dev/null | head -10
fi

# OppoEngineerCamera
for try in \
    /system/app/OplusEngineerCamera/OplusEngineerCamera.apk \
    /system/priv-app/OplusEngineerCamera/OplusEngineerCamera.apk; do
    if [ -f "$try" ]; then
        cp -v "$try" "$MODULE_DIR/system/app/OplusEngineerCamera/"
        echo "  ✅ OplusEngineerCamera.apk"
        break
    fi
done

# ========== 2. Extract Framework Jars ==========
echo ""
echo "[2/6] Extracting framework jars..."

for jar in \
    oplus-camera-framework.jar \
    com.oppo.camera.jar \
    com.oppo.services.jar \
    oplus-framework.jar \
    oplus-aps-framework.jar; do
    for dir in /system/framework /product/framework /my_product/framework; do
        if [ -f "$dir/$jar" ]; then
            cp -v "$dir/$jar" "$MODULE_DIR/system/framework/"
            break
        fi
    done
done

# ========== 3. Extract System Camera Libraries ==========
echo ""
echo "[3/6] Extracting system camera libraries..."

# 64-bit first
for lib in \
    libcamera_client.so \
    libcameracustom.so \
    libcameraprofile.so \
    libcameraservice.so \
    liboppocamera.so \
    liboppocamera3.so \
    libjni_oppocamera.so \
    libjni_camera3.so \
    libjni_opotouch.so; do
    for dir in /system/lib64 /product/lib64 /my_product/lib64; do
        if [ -f "$dir/$lib" ]; then
            cp -v "$dir/$lib" "$MODULE_DIR/system/lib64/" 2>/dev/null
            break
        fi
    done
    # Also check 32-bit
    for dir in /system/lib /product/lib; do
        if [ -f "$dir/$lib" ]; then
            cp -v "$dir/$lib" "$MODULE_DIR/system/lib/" 2>/dev/null
            break
        fi
    done
done

# ========== 4. Extract Vendor Camera HAL Libs ==========
echo ""
echo "[4/6] Extracting vendor camera HAL libraries..."

# Find all camera-related vendor libraries
for lib_pattern in \
    "camera.default.so" \
    "camera.mt6768.so" \
    "camera.mtk*" \
    "libcamdrv*" \
    "libmtkcam*" \
    "libcamera2ndk*" \
    "liboplus*" \
    "liboppo*" \
    "libMial*"; do
    for dir in /vendor/lib64 /vendor/lib; do
        found_libs=$(find "$dir" -name "$lib_pattern" 2>/dev/null)
        for lib in $found_libs; do
            # Determine target dir (lib64 vs lib)
            tgt_dir="vendor/lib64"
            echo "$lib" | grep -q "/vendor/lib/" && tgt_dir="vendor/lib"
            cp -v "$lib" "$MODULE_DIR/$tgt_dir/" 2>/dev/null
        done
    done
done

# ========== 5. Extract Camera Configs ==========
echo ""
echo "[5/6] Extracting vendor camera configs..."

# Camera sensor tuning files
for dir in /vendor/etc/camera /odm/etc/camera /vendor/etc/calibration; do
    if [ -d "$dir" ]; then
        echo "  Copying from $dir..."
        cp -rv "$dir/"* "$MODULE_DIR/vendor/etc/camera/" 2>/dev/null
    fi
done

# Permissions
for perm in \
    /system/etc/permissions/privapp-permissions-oppo.xml \
    /system/etc/permissions/oplus-camera-permissions.xml \
    /system/etc/permissions/oplus.framework.xml \
    /vendor/etc/permissions/android.hardware.camera.xml; do
    if [ -f "$perm" ]; then
        cp -v "$perm" "$MODULE_DIR/system/etc/permissions/" 2>/dev/null
    fi
done

# ========== 6. Extract Camera Props ==========
echo ""
echo "[6/6] Extracting camera system properties..."

getprop | grep -i "camera\|oplus.camera\|persist.camera\|vendor.camera" > "$MODULE_DIR/../camera_props/device_props.txt"
echo "  ✅ $(wc -l < "$MODULE_DIR/../camera_props/device_props.txt") camera props saved"

# ========== BUILD MODULE ==========
echo ""
echo "===================================="
echo "📦 Building KernelSU module..."
echo "===================================="

cd /data/local/tmp
if [ -f "$OUTPUT_ZIP" ]; then
    rm "$OUTPUT_ZIP"
fi

cd opus-camera
zip -r "$OUTPUT_ZIP" kernelSU_module/ -x "*/\.*"
echo ""
echo "✅ Module created: $OUTPUT_ZIP"
echo "   Size: $(ls -lh "$OUTPUT_ZIP" | awk '{print $5}')"
echo ""
echo "📱 To install:"
echo "   1. Open KernelSU Manager"
echo "   2. Modules → Install from storage"
echo "   3. Select $OUTPUT_ZIP"
echo "   4. Reboot"
echo ""
echo "📋 Or push to PC:"
echo "   adb pull $OUTPUT_ZIP ."
echo ""

# Show summary
echo "===================================="
echo "📊 Extraction Summary:"
echo "===================================="
echo "APK files:     $(find $MODULE_DIR -name '*.apk' | wc -l)"
echo "Framework:     $(find $MODULE_DIR/system/framework -name '*.jar' | wc -l)"
echo "System libs:   $(find $MODULE_DIR/system/lib* -name '*.so' | wc -l)"
echo "Vendor libs:   $(find $MODULE_DIR/vendor/lib* -name '*.so' | wc -l)"
echo "Camera configs: $(find $MODULE_DIR/vendor/etc/camera -type f | wc -l)"
echo "Permissions:   $(find $MODULE_DIR/system/etc/permissions -name '*.xml' | wc -l)"
echo "Total files:   $(find $MODULE_DIR -type f | wc -l)"
echo "===================================="