#!/bin/bash
# ======================================================
# Opus Camera - Step 1: Download & Extract super.img
# Extracts the stock RUI4 firmware super.img
# ======================================================
set -e

FIRMWARE_REPO="https://github.com/Rocker14427c/Realme-Narzo-50a-Rui4-firmware"
WORK_DIR="$HOME/rmx3430_firmware"
SUPER_DIR="$WORK_DIR/super_extracted"

echo "📦 Opus Camera — Step 1/2: Download & Extract Super"
echo "===================================================="

# --- Create working dirs ---
mkdir -p "$WORK_DIR" "$SUPER_DIR"
cd "$WORK_DIR"

# --- Download the super.img parts from GitHub Release ---
echo "🌐 Downloading firmware info..."
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Rocker14427c/Realme-Narzo-50a-Rui4-firmware/releases/latest" | grep '"tag_name"' | head -1 | cut -d'"' -f4)

if [ -z "$LATEST_RELEASE" ]; then
    echo "❌ Could not find latest release"
    echo "   Download manualy from: $FIRMWARE_REPO/releases"
    exit 1
fi

echo "   Latest release: $LATEST_RELEASE"

# Download all super.part* files
echo "⬇️  Downloading super.img parts (this is ~9.5 GB)..."
for PART_URL in $(curl -s "https://api.github.com/repos/Rocker14427c/Realme-Narzo-50a-Rui4-firmware/releases/tags/$LATEST_RELEASE" | grep '"browser_download_url"' | grep 'super.part' | cut -d'"' -f4); do
    FILENAME=$(basename "$PART_URL")
    if [ ! -f "$FILENAME" ]; then
        echo "   Downloading $FILENAME..."
        wget -q --show-progress "$PART_URL" -O "$FILENAME"
    else
        echo "   ✓ $FILENAME already downloaded"
    fi
done

# --- Reassemble super.img ---
echo "🔗 Reassembling super.img..."
if ls super.part* 1>/dev/null 2>&1; then
    cat super.part* > super.img 2>/dev/null || {
        echo "❌ Failed to concatenate super parts"
        echo "   Try: cat super.part* > super.img"
        exit 1
    }
    echo "   ✓ super.img created ($(du -h super.img | cut -f1))"
else
    echo "❌ No super.part* files found"
    echo "   Download them first from: $FIRMWARE_REPO/releases"
    exit 1
fi

# --- Check SHA256 ---
if [ -f SHA256SUMS ]; then
    echo "🔐 Verifying checksum..."
    sha256sum -c SHA256SUMS 2>/dev/null && echo "   ✓ Checksum OK" || echo "   ⚠️ Checksum mismatch!"
fi

# --- Extract super.img using lpunpack ---
echo "📂 Extracting logical partitions from super.img..."
if command -v lpunpack &>/dev/null; then
    lpunpack super.img "$SUPER_DIR/" 2>&1
elif command -v simg2img &>/dev/null; then
    echo "   Using simg2img + custom extraction..."
    # Check if it's sparse
    file super.img | grep -qi sparse && simg2img super.img super_raw.img && mv super_raw.img super.img
    # Try to use lpunpack from a known location
    if [ -f /usr/lib/android-sdk/platform-tools/lpunpack ]; then
        /usr/lib/android-sdk/platform-tools/lpunpack super.img "$SUPER_DIR/"
    else
        echo "❌ lpunpack not found. Install it:"
        echo "   sudo apt install android-sdk-libsparse android-sdk-liblp"
        echo "   Or download from: https://github.com/omnirom/android_system_tools_lp"
        exit 1
    fi
else
    echo "❌ Neither lpunpack nor simg2img found"
    echo "   Install them:"
    echo "   sudo apt install android-sdk-libsparse android-sdk-liblp"
    exit 1
fi

echo ""
echo "✅ Extraction complete! Partitions extracted to: $SUPER_DIR"
ls -lh "$SUPER_DIR/"
echo ""
echo "➡️  Next: Run 02_extract_camera_blobs.sh"