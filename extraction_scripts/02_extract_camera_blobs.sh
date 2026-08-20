#!/bin/bash
# ======================================================
# Opus Camera - Step 2: Extract Camera Blobs
# Copies camera-related files from extracted partitions
# into the KernelSU module structure
# ======================================================
set -e

SUPER_DIR="$HOME/rmx3430_firmware/super_extracted"
MODULE_DIR="$(dirname "$0")/../kernelSU_module"

echo "📷 Opus Camera — Step 2/2: Extract Camera Blobs"
echo "===================================================="

# --- Verify super extract dir ---
if [ ! -d "$SUPER_DIR" ]; then
    echo "❌ super_extracted not found at $SUPER_DIR"
    echo "   Run 01_download_and_extract_super.sh first"
    exit 1
fi

echo "Source: $SUPER_DIR"
echo "Target: $MODULE_DIR"
echo ""

# --- Determine mount points ---
# The partitions from super.img might be named: system.img, vendor.img, product.img, etc.
# Or they could be raw images we need to mount
MOUNT_BASE="/tmp/rmx3430_mnt"
mkdir -p "$MOUNT_BASE"

mount_partition() {
    local IMG="$1"
    local MNT="$2"
    local NAME="$3"

    if [ ! -f "$IMG" ]; then
        echo "   ⚠️ $IMG not found, skipping"
        return 1
    fi

    mkdir -p "$MNT"

    # Check if already mounted
    mount | grep -q "$MNT" && { echo "   ✓ $NAME already mounted"; return 0; }

    # Try mounting (may need simg2img first if sparse)
    local IMG_TO_MOUNT="$IMG"
    if file "$IMG" | grep -qi "sparse"; then
        echo "   Converting sparse $NAME image..."
        simg2img "$IMG" "${IMG}.raw" 2>/dev/null
        IMG_TO_MOUNT="${IMG}.raw"
    fi

    mount -o ro "$IMG_TO_MOUNT" "$MNT" 2>/dev/null && {
        echo "   ✓ $NAME mounted"
        return 0
    } || {
        echo "   ⚠️ Could not mount $NAME (might need simg2img)"
        return 1
    }
}

# Mount system, vendor, product, odm
mount_partition "$SUPER_DIR/system.img" "$MOUNT_BASE/system" "system"
mount_partition "$SUPER_DIR/vendor.img" "$MOUNT_BASE/vendor" "vendor"
mount_partition "$SUPER_DIR/product.img" "$MOUNT_BASE/product" "product"
mount_partition "$SUPER_DIR/odm.img" "$MOUNT_BASE/odm" "odm"

echo ""

# --- Function to copy files with structure ---
copy_with_structure() {
    local SRC="$1"
    local DST="$2"
    local DESC="$3"

    if [ -f "$SRC" ]; then
        mkdir -p "$(dirname "$DST")"
        cp -v "$SRC" "$DST"
        echo "   ✓ $DESC"
    elif [ -d "$SRC" ]; then
        mkdir -p "$DST"
        cp -rv "$SRC"/* "$DST/" 2>/dev/null && echo "   ✓ $DESC" || echo "   ⚠️ $DESC - empty or error"
    else
        echo "   ⚠️ Missing: $DESC"
    fi
}

echo "📱 Extracting camera files..."
echo ""

# ==========================================
# 1. Camera APK
# ==========================================
echo "[1/8] Camera APK..."

# Try various possible locations
CAM_APK_SRC=""
for try in \
    "$MOUNT_BASE/system/system/app/OplusCamera/OplusCamera.apk" \
    "$MOUNT_BASE/system/app/OplusCamera/OplusCamera.apk" \
    "$MOUNT_BASE/system/system/app/OppoCamera/OppoCamera.apk" \
    "$MOUNT_BASE/system/app/OppoCamera/OppoCamera.apk" \
    "$MOUNT_BASE/system/system/priv-app/OplusCamera/OplusCamera.apk" \
    "$MOUNT_BASE/system/priv-app/OplusCamera/OplusCamera.apk"; do
    if [ -f "$try" ]; then
        CAM_APK_SRC="$try"
        break
    fi
done

if [ -n "$CAM_APK_SRC" ]; then
    mkdir -p "$MODULE_DIR/system/app/OplusCamera"
    cp -v "$CAM_APK_SRC" "$MODULE_DIR/system/app/OplusCamera/"
    echo "   ✓ OplusCamera.apk"
else
    echo "   ⚠️ OplusCamera.apk NOT FOUND!"
fi

# OppoEngineerCamera
for try in \
    "$MOUNT_BASE/system/system/app/OplusEngineerCamera/OplusEngineerCamera.apk" \
    "$MOUNT_BASE/system/app/OplusEngineerCamera/OplusEngineerCamera.apk"; do
    if [ -f "$try" ]; then
        mkdir -p "$MODULE_DIR/system/app/OplusEngineerCamera"
        cp -v "$try" "$MODULE_DIR/system/app/OplusEngineerCamera/"
        echo "   ✓ OplusEngineerCamera.apk"
        break
    fi
done

# ==========================================
# 2. Framework Jars
# ==========================================
echo "[2/8] Framework jars..."

FRAMEWORK_JARS="
oplus-camera-framework.jar
com.oppo.camera.jar
com.oppo.services.jar
com.oppo.os.jar
oplus-framework.jar
oplus-aps-framework.jar
"

for jar in $FRAMEWORK_JARS; do
    found=0
    for try in "$MOUNT_BASE/system/system/framework/$jar" "$MOUNT_BASE/system/framework/$jar"; do
        if [ -f "$try" ]; then
            cp -v "$try" "$MODULE_DIR/system/framework/"
            found=1
            break
        fi
    done
    if [ "$found" = "0" ]; then
        echo "   ⚠️ Not found: $jar"
    fi
done

# ==========================================
# 3. System Libraries (64-bit)
# ==========================================
echo "[3/8] System libraries (64-bit)..."

SYSTEM_LIBS="
libcamera_client.so
libcameracustom.so
libcameraprofile.so
libcameraservice.so
liboppocamera.so
liboppocamera3.so
libjni_oppocamera.so
libjni_camera3.so
libjni_opotouch.so
libMial.so
libMialcontent.so
libMialdrv.so
libMialpipe.so
libMialscenario.so
libMialutility.so
libcam.halsensor.so
"

for lib in $SYSTEM_LIBS; do
    found=0
    for try in "$MOUNT_BASE/system/system/lib64/$lib" "$MOUNT_BASE/system/lib64/$lib"; do
        if [ -f "$try" ]; then
            cp -v "$try" "$MODULE_DIR/system/lib64/"
            found=1
            break
        fi
    done
    # Also try 32-bit
    if [ "$found" = "0" ]; then
        for try in "$MOUNT_BASE/system/system/lib/$lib" "$MOUNT_BASE/system/lib/$lib"; do
            if [ -f "$try" ]; then
                cp -v "$try" "$MODULE_DIR/system/lib/"
                found=1
                break
            fi
        done
    fi
    if [ "$found" = "0" ]; then
        echo "   ⚠️ Not found: $lib"
    fi
done

# ==========================================
# 4. Vendor Camera HAL Libraries
# ==========================================
echo "[4/8] Vendor camera HAL libraries..."

VENDOR_LIBS="
camera.default.so
camera.mt6768.so
camera.mt6789.so
camera.mtk.so
libcamera2ndk.so
libcamdrv.so
libcamera_client.so
libmtkcamera.so
libmtkcamera_client.so
libmtk_jni_camera.so
libmtkcamera_metadata.so
libcamera_mtk.so
libmipc_camera.so
libcameranode.so
libcamera_custom_hwnode.so
"

for lib in $VENDOR_LIBS; do
    found=0
    for try in "$MOUNT_BASE/vendor/lib64/$lib" "$MOUNT_BASE/vendor/lib/$lib"; do
        if [ -f "$try" ]; then
            TARGET="vendor/lib64"
            echo "$try" | grep -q "/lib/" && TARGET="vendor/lib"
            cp -v "$try" "$MODULE_DIR/$TARGET/"
            found=1
            break
        fi
    done
    if [ "$found" = "0" ]; then
        echo "   ⚠️ Not found (vendor): $lib"
    fi
done

# ==========================================
# 5. Vendor Camera Config Files
# ==========================================
echo "[5/8] Vendor camera configs..."

if [ -d "$MOUNT_BASE/vendor/etc/camera" ]; then
    mkdir -p "$MODULE_DIR/vendor/etc/camera"
    cp -rv "$MOUNT_BASE/vendor/etc/camera/"* "$MODULE_DIR/vendor/etc/camera/" 2>/dev/null
    echo "   ✓ Camera configs copied"
    echo "   Files: $(ls "$MODULE_DIR/vendor/etc/camera/" 2>/dev/null | wc -l)"
fi

# Also check odm
if [ -d "$MOUNT_BASE/odm/etc/camera" ]; then
    mkdir -p "$MODULE_DIR/vendor/etc/camera"
    cp -rv "$MOUNT_BASE/odm/etc/camera/"* "$MODULE_DIR/vendor/etc/camera/" 2>/dev/null
    echo "   ✓ ODM camera configs merged"
fi

# ==========================================
# 6. Permissions XML
# ==========================================
echo "[6/8] Permissions XMLs..."

for perm in \
    "privapp-permissions-oppo.xml" \
    "oplus-camera-permissions.xml" \
    "oplus.software.features.xml" \
    "oplus.framework.xml"; do
    found=0
    for try in \
        "$MOUNT_BASE/system/system/etc/permissions/$perm" \
        "$MOUNT_BASE/system/etc/permissions/$perm" \
        "$MOUNT_BASE/vendor/etc/permissions/$perm"; do
        if [ -f "$try" ]; then
            cp -v "$try" "$MODULE_DIR/system/etc/permissions/"
            found=1
            break
        fi
    done
    if [ "$found" = "0" ]; then
        echo "   ⚠️ Not found: $perm"
    fi
done

# ==========================================
# 7. Camera Props from build.prop
# ==========================================
echo "[7/8] Camera properties from build.prop..."

BUILD_PROPS="$MOUNT_BASE/system/system/build.prop"
if [ ! -f "$BUILD_PROPS" ]; then
    BUILD_PROPS="$MOUNT_BASE/system/build.prop"
fi

if [ -f "$BUILD_PROPS" ]; then
    grep -i "camera\|persist.camera\|vendor.camera\|media.camera\|oplus.camera" "$BUILD_PROPS" > "$MODULE_DIR/../camera_props/camera_prop_overlay.prop" 2>/dev/null || true
    echo "   ✓ Camera props extracted ($(wc -l < "$MODULE_DIR/../camera_props/camera_prop_overlay.prop") lines)"
fi

# ==========================================
# 8. TODO: Build and verify
# ==========================================
echo "[8/8] Summary..."

echo ""
echo "===================================="
echo "✅ Extraction complete!"
echo "===================================="
echo ""
echo "📁 Module directory: $MODULE_DIR"
echo ""
echo "   Files extracted:"
find "$MODULE_DIR" -type f 2>/dev/null | head -50
echo ""
echo "   If key files are missing (shown as ⚠️), you may need to:"
echo "   1. Check the actual partition layout in $SUPER_DIR"
echo "   2. Update this script's file paths"
echo "   3. Run: ls $MOUNT_BASE/system/system/app/ | grep -i camera"
echo "      to find the actual camera app name"
echo ""

# --- Cleanup mounts ---
echo "🧹 Cleaning up..."
for mnt in "$MOUNT_BASE/system" "$MOUNT_BASE/vendor" "$MOUNT_BASE/product" "$MOUNT_BASE/odm"; do
    mount | grep -q "$mnt" && umount "$mnt" && echo "   Unmounted $mnt"
done
rm -rf "$MOUNT_BASE"

echo ""
echo "➡️  Next: cd kernelSU_module && zip -r ../OplusCamera-Port.zip ./*"