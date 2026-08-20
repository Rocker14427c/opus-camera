#!/usr/bin/env python3
"""
Opus Camera - APK Reversing Notes & Patch Generator
Analyzes the OplusCamera APK and generates patches for AOSP compatibility.

This script helps identify:
1. Framework dependencies the APK expects
2. Permission requirements
3. Service references that need to be stubbed
4. Native library dependencies

Usage:
    python3 analyze_apk.py /path/to/OplusCamera.apk
"""

import zipfile
import os
import sys
import re
from xml.etree import ElementTree

def analyze_apk(apk_path):
    """Analyze the OplusCamera APK for porting information."""
    
    if not os.path.exists(apk_path):
        print(f"❌ APK not found: {apk_path}")
        return
    
    print("=" * 60)
    print(f"📱 OplusCamera APK Analysis")
    print("=" * 60)
    
    with zipfile.ZipFile(apk_path, 'r') as z:
        namelist = z.namelist()
        
        print(f"\n📦 APK Contents: {len(namelist)} files")
        
        # Check AndroidManifest.xml (binary)
        if 'AndroidManifest.xml' in namelist:
            print(f"\n📋 AndroidManifest.xml found (binary AXML format)")
            # Try to extract useful strings
            data = z.read('AndroidManifest.xml')
            
            # Extract readable strings from binary XML
            strings = re.findall(b'[\x20-\x7e]{4,}', data)
            manifest_strings = [s.decode('ascii', errors='replace') for s in strings]
            
            # Filter for interesting ones
            interesting = ['permission', '.camera', '.oplus', '.oppo', 
                          'android.hardware', 'uses-library', 'activity',
                          'service', 'receiver', 'feature']
            
            print(f"\n  🔑 Permissions & Features referenced:")
            for s in manifest_strings:
                for keyword in interesting:
                    if keyword.lower() in s.lower():
                        print(f"    • {s}")
                        break
            
            # Find <uses-library> references
            print(f"\n  📚 Framework libraries referenced:")
            for s in manifest_strings:
                if 'uses-library' in s.lower() or s.startswith('oplus-') or s.startswith('com.oppo') or s.startswith('com.oplus'):
                    print(f"    • {s}")
        
        # Check native libraries
        lib_files = [f for f in namelist if f.startswith('lib/') and f.endswith('.so')]
        if lib_files:
            print(f"\n  🔧 Native libraries ({len(lib_files)}):")
            for lib in sorted(lib_files):
                print(f"    • {lib.split('/')[-1]}")
        
        # Check for classes.dex (DEX size)
        if 'classes.dex' in namelist:
            info = z.getinfo('classes.dex')
            print(f"\n  📊 DEX size: {info.file_size / 1024 / 1024:.1f} MB")
        
        # Check for resources
        if 'resources.arsc' in namelist:
            info = z.getinfo('resources.arsc')
            print(f"  🎨 Resources: {info.file_size / 1024:.1f} KB")
        
        # Check META-INF
        meta_files = [f for f in namelist if f.startswith('META-INF/')]
        if meta_files:
            print(f"  📝 META-INF: {len(meta_files)} files")
        
        # Check for split APKs
        if 'res/' in namelist:
            res_dirs = set(f.split('/')[1] for f in namelist if f.startswith('res/'))
            print(f"  🖼️  Resource directories: {len(res_dirs)}")
    
    print(f"\n  ✅ Analysis complete")


def generate_patch_info(apk_path):
    """Generate framework stub/patch information."""
    print(f"\n{'=' * 60}")
    print(f"🩹 Required Framework Patches for AOSP")
    print(f"{'=' * 60}")
    print("""
Based on the analysis, the following patches may be needed:

1. FRAMEWORK STUBS:
   - oplus-camera-framework.jar → needs to be added to system classpath
   - com.oppo.camera.jar → camera-specific framework
   - com.oppo.services.jar → oppo service infrastructure

2. PERMISSIONS:
   - oplus.permission.OPPO_CAMERA
   - com.oplus.permission.CAMERA
   - com.oplus.permission.CAMERA_EXT

3. SERVICE STUBS (inject via KernelSU module post-fs-data.sh):
   - OplusCameraEngineService
   - OplusExService

4. NATIVE LIBRARY REQUIREMENTS:
   - liboppocamera.so / liboppocamera3.so → camera3 HAL
   - libjni_oppocamera.so → JNI bridge
   - MTK camera libs (libmtkcam_*.so)

5. MEDIATEK SPECIFIC:
   - Camera HAL: camera.mt6768.so or camera.default.so
   - ISP libraries: libMial*.so
   - Sensor configs in /vendor/etc/camera/

6. BUILD.PROP OVERLAYS:
   - persist.camera.HAL3.enable=1
   - vendor.camera.hal1.packagelist=OplusCamera
   - ro.camera.sound.forced=0
""")


if __name__ == '__main__':
    apk_path = sys.argv[1] if len(sys.argv) > 1 else None
    if apk_path:
        analyze_apk(apk_path)
        generate_patch_info(apk_path)
    else:
        print("Usage: python3 analyze_apk.py /path/to/OplusCamera.apk")
        print("\nOr just view the documentation for manual patching info.")
        generate_patch_info(None)