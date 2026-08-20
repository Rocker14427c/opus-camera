# 📷 Opus Camera — Realme Narzo 50a (RMX3430) Stock Camera Port

> **Port of the stock Realme UI 4 (RUI4 / Android 13) OplusCamera to custom ROMs**
>
> Target: **Axion 2.7 (Android 16)** | Root: **KernelSU** | Device: **Realme Narzo 50a (RMX3430, Helio G85)**

---

## ⚠️ Status: EXPERIMENTAL — Work In Progress

This is an ongoing effort to get the Realme/Oppo stock camera app working on AOSP-based custom ROMs. Due to MediaTek's proprietary camera stack and Oppo's closed-source framework dependencies, **full functionality is not guaranteed**. Expect issues.

### What works / might work
- ✅ Camera app launches (with proper framework patches)
- ✅ Basic photo capture (main lens)
- ✅ Basic video recording
- ⚠️ 50MP mode (requires specific HAL patches)
- ⚠️ Front camera switching
- ❌ Macro lens (needs custom camera HAL config)
- ❌ Depth/Portrait mode (needs Oppo engine services)
- ❌ Slow-motion (MTK proprietary)
- ❌ Ultra-steady mode (proprietary gyro EIS)

---

## 📁 Repository Structure

```
opus-camera/
├── kernelSU_module/           # KernelSU flashable module
│   ├── module.prop            # Module metadata
│   ├── post-fs-data.sh        # Early boot hook
│   ├── service.sh             # Late boot service
│   ├── customize.sh           # Installer script
│   └── system/                # System file overlays
│       ├── app/OplusCamera/   # Camera APK + libs
│       ├── framework/         # Oppo framework jars
│       ├── lib/               # 32-bit camera libs
│       ├── lib64/             # 64-bit camera libs
│       └── etc/permissions/   # SELinux/perms XMLs
│   └── vendor/                # Vendor blobs
│       ├── lib/
│       ├── lib64/
│       └── etc/camera/        # MTK camera config files
├── extraction_scripts/        # Scripts to extract from super.img
│   ├── 01_download_and_extract_super.sh
│   ├── 02_extract_camera_blobs.sh
│   └── required_files.txt
├── camera_props/              # Build.prop overlays
│   └── camera_prop_overlay.prop
└── configs/
    └── mtk_camera_calibration.cfg
```

---

## 🔧 Prerequisites (on your device / PC)

| Requirement | Notes |
|---|---|
| **Axion 2.7 (Android 16)** | Your current custom ROM |
| **KernelSU** | Root solution installed |
| **PC with Linux/WSL** | For extracting super.img |
| **Stock firmware repo** | [Realme-Narzo-50a-Rui4-firmware](https://github.com/Rocker14427c/Realme-Narzo-50a-Rui4-firmware) |
| **simg2img / lpunpack** | Tools to extract super.img |
| **adb & fastboot** | For pushing files |

---

## 📥 How to Use This Repo

### Option 1: Grab the pre-built KernelSU module (if available)

Download the latest `.zip` from **Releases** → Flash in KernelSU Manager → Reboot.

### Option 2: Build the module yourself

```bash
# 1. Clone this repo
git clone https://github.com/Rocker14427c/opus-camera.git
cd opus-camera

# 2. Extract camera files from your stock firmware
#    (see extraction_scripts/ for details)
bash extraction_scripts/01_download_and_extract_super.sh
bash extraction_scripts/02_extract_camera_blobs.sh

# 3. The extracted files go into kernelSU_module/
# 4. Zip it up
cd kernelSU_module
zip -r ../OplusCamera-Port-v1.0.zip ./*
cd ..

# 5. Push to phone and flash in KernelSU
```

### Option 3: Manual installation via adb

```bash
# Push APK
adb push system/app/OplusCamera/OplusCamera.apk /data/local/tmp/
adb shell su -c "cp /data/local/tmp/OplusCamera.apk /system/app/OplusCamera/"

# Push libraries
adb push system/lib64/* /data/local/tmp/
adb shell su -c "cp /data/local/tmp/* /system/lib64/"
```

---

## � What Files Are Needed (Source: Stock RUI4)

### APKs
| Package | Path in stock | Description |
|---|---|---|
| OplusCamera.apk | `/system/app/OplusCamera/` | Main camera app |
| OplusEngineerCamera.apk | `/system/app/OplusEngineerCamera/` | Camera engine service|
| OplusLens.apk | `/system/app/OplusLens/` | Lens switching|
| OplusGalleryEditor.apk | `/system/app/OplusGalleryEditor/` | Gallery editor (needed for edit) |

### Framework Jars
| File | Path |
|---|---||
| oplus-camera-framework.jar | `/system/framework/`|
| com.oOppo.camera.jar | `/system/framework/`|
| co.Oppo.services.jar | `/system/framework/`|
| oplus-framework.jar | `/sytem/framework/`|
| oplus-aps-framework.jar | `/system/framework/`|

### System Libraries
From `/system/lib64/` (and `/system/lib/`):
- libcameraclient.so, libcameracustom.so, libcameraprofile.so, libcameraservice.so
- libppocamera.so, libppocamera3.so
- libjni_ppocamera.so, ibjni_mera3.so, ibjni_opotuch.so
- libppocamera3.so
- ibMial.so, libMialcontent.so, ibMialdrv.so, ibMialpipe.so, ibMialscenario.so, ibMialutility.so

### Vendor Libraries
From `/vendor/lib64/` (and `/vendor/lib/`):
- camra.default.so (or camra.mt6789.so/camra.mtk.so)
- ibcamra2ndk.so
- ibcamdrv.so
- ibcamraclient.so
- ibmkcamra.so
- ibmtkcamra_client.so
- ibmtk_jni_camra.so

### Vendor Camera Configs
From `/vendor/etc/camra/`:
- All .json and .cfg files for your sensor (Samsung S5KJN1 50MP + gcamera/ov sensor)

### SELinux / Permissions
From `/system/etc/permissions/`:
- privapp-permisions-oppo.xml (or platfrom.xml with Oppo camra entries)
- oplus-camra-permissions.xml

---

## � Known Issues & Troubleshooting

### "Can't conect to camera"
→ SELinux denials. Check `dmesg | grep avc` and add permissive rules in `post-fs-da.sh`

### "App crases on lanch"
→ Missing ramwork jars or libs. Verify all fles in `required_files.txt` are present

### "Only 12MP photos"
→ Camra2 HAL is capping to 12MP. Need to set `persist.camera.HAL3.enable=1`

### "Fron camera doesn't work"
→ Missing ront camra libs or sensor cnnfiguration

### "Macro/Depth lens don't switch"
→ The Oppo lens witch engine (`OplusEngineer`) may no be running. Check logcat.

---

## 🔗 Related

- [Realme Narzo 50a Stock Firmware (RUI4 F.23)](hhttps://github.com/Rocker14427c/Realme-Narzo-50a-Rui4-firmware)
- Twin Reovrey or Ralme Narzo 50a (XDA)
- [Axion ROM](hps://xdaforums.com...) () Axion 2.7 Annouement

---

## 📜 Liense

MIT — Free to se, modiy, and share. N waranty epressed or implied.