# ArrowFlow - Release APK & Signing Credentials

## 📦 Release APK Summary
- **APK File Location**: `builds/ArrowFlow_v1.0.0.apk`
- **Absolute Path**: `/Users/dws-mac001/amaze-go!/builds/ArrowFlow_v1.0.0.apk`
- **File Size**: ~56 MB
- **Package ID (Application ID)**: `com.arrowflow.puzzle`
- **Version Code**: `1`
- **Version Name**: `1.0.0`
- **Screen Orientation**: Portrait Only (`android:screenOrientation="portrait"`)
- **Target SDK**: `36` (Android 15)
- **Min SDK**: `24` (Android 7.0+)
- **Supported Architectures**: `arm64-v8a`, `armeabi-v7a`
- **Signature Schemes**: APK Signature Scheme v2 (Yes), v3 (Yes)

---

## 🔑 Release Keystore Credentials
Keep these credentials safe for future updates and Google Play Console publishing:

| Property | Value |
| :--- | :--- |
| **Keystore File** | `/Users/dws-mac001/amaze-go!/release.keystore` |
| **Keystore Password** | `amazegorelease2026` |
| **Key Alias** | `amazego` |
| **Key Password** | `amazegorelease2026` |
| **Key Algorithm** | RSA 2048-bit |
| **Validity** | 10,000 days (approx. 27 years) |
| **Distinguished Name (DN)** | `CN=AmazeGo, OU=MobileGames, O=OakEver, L=SanFrancisco, ST=California, C=US` |

---

## 🛡️ Certificate Fingerprints
Use these fingerprints when configuring Firebase, Google AdMob, or Google Play App Signing:

- **SHA-256**:
  ```
  9D:32:AB:58:59:96:CF:AF:CF:13:3C:60:F2:79:D0:C7:16:A8:15:DA:C0:52:F9:19:41:61:00:58:BA:D4:6C:F7
  ```
- **SHA-1**:
  ```
  3C:8E:CD:90:EF:AA:43:70:AE:AA:B9:82:13:CC:6D:FA:27:62:DF:87
  ```
- **MD5**:
  ```
  67:46:5B:FC:3B:49:4A:AA:70:DA:7C:91:93:6C:25:12
  ```

---

## 📲 How to Rebuild Release APK
To rebuild the release APK at any time from command line:
```bash
/Users/dws-mac001/Downloads/Godot.app/Contents/MacOS/Godot --headless --export-release "Android" builds/ArrowFlow_v1.0.0.apk
```

To verify the signed APK:
```bash
/Users/dws-mac001/Library/Android/sdk/build-tools/36.0.0/apksigner verify --verbose --print-certs builds/ArrowFlow_v1.0.0.apk
```
