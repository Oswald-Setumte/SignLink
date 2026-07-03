# SignLink — Flutter App

Real-time sign language to text translation.  
**Mobile (Flutter)** · **AI/CV** · **WebSocket backend integration**

---

## Project Setup

### 1. Create the Flutter project

```bash
flutter create --org com.signlink --project-name signlink signlink
cd signlink
```

Then **replace** the generated files with everything in this package.  
The folder structure must be:

```
signlink/
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/com/signlink/app/MainActivity.kt
│   │       └── res/
│   │           ├── values/colors.xml
│   │           ├── values/styles.xml
│   │           └── xml/network_security_config.xml
│   ├── build.gradle
│   ├── gradle.properties
│   └── settings.gradle
├── ios/
│   └── Runner/
│       └── Info.plist
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── router/app_router.dart
│   │   ├── services/
│   │   │   ├── backend_service.dart
│   │   │   └── preferences_service.dart
│   │   └── theme/app_theme.dart
│   └── features/
│       ├── permission/camera_permission_screen.dart
│       ├── settings/
│       │   ├── bloc/settings_bloc.dart
│       │   └── settings_sheet.dart
│       ├── shared/widgets/signlink_wordmark.dart
│       ├── splash/splash_screen.dart
│       └── translation/
│           ├── bloc/translation_bloc.dart
│           ├── camera_translation_screen.dart
│           └── widgets/landmark_painter.dart
├── assets/
│   ├── images/   ← drop logo.png here
│   └── icons/
├── pubspec.yaml
└── analysis_options.yaml
```

---

### 2. Install dependencies

```bash
flutter pub get
```

---

### 3. Android — minimum SDK check

Open `android/app/build.gradle` and confirm:

```groovy
minSdk 21
```

The `camera` package requires SDK 21+. This is already set.

---

### 4. iOS — Podfile setup

```bash
cd ios
pod install
cd ..
```

Make sure your `ios/Podfile` has at minimum:

```ruby
platform :ios, '13.0'
```

---

### 5. Backend URL

Open `lib/core/services/backend_service.dart` and replace:

```dart
static const String wsUrl = 'ws://YOUR_BACKEND_HOST:8000/ws/translate';
```

with your actual backend WebSocket address.

**Development shortcuts:**
- Android emulator → `ws://10.0.2.2:8000/ws/translate`
- iOS simulator   → `ws://127.0.0.1:8000/ws/translate`
- Physical device → `ws://192.168.x.x:8000/ws/translate`

> The backend is **optional for running the UI**. If the WebSocket can't connect,
> the app falls back to "Offline mode" — camera still works, no translation output.

---

### 6. Run the app

```bash
# List connected devices
flutter devices

# Run on Android
flutter run -d <android-device-id>

# Run on iOS simulator
flutter run -d <ios-simulator-id>

# Run in release mode
flutter run --release
```

---

## App Flow

```
Launch
  │
  ▼
Splash Screen (3 seconds)
  │
  ├── First launch?  ─── YES ──▶ Camera Permission Screen
  │                                     │
  │                              Allow Camera Access
  │                                     │
  └── Already granted ──────────────────┘
                                        │
                                        ▼
                             Camera Translation Screen
                             (live camera + AI translation)
```

---

## Backend Integration Protocol

The app sends **JPEG frames** over WebSocket and expects **JSON responses**.

### Frame (Client → Server)
```
Binary WebSocket message: raw JPEG bytes
Query param: ?lang=ASL  (or GSL, BSL, etc.)
Rate: ~10 fps (one frame every 100ms)
```

### Response (Server → Client)
```json
{
  "text": "Hello",
  "confidence": 0.94,
  "landmarks": [
    [0.42, 0.61, 0.01],
    [0.45, 0.55, 0.02],
    ...
  ]
}
```

- `text` — the recognised sign word/phrase
- `confidence` — float 0.0–1.0 (drives the confidence bar)
- `landmarks` — 21 × [x, y, z] normalised 0.0–1.0 (drives the hand skeleton overlay)

The `landmarks` array is optional. If omitted, no skeleton is drawn.

---

## Settings Behaviour

| Setting | Effect |
|---|---|
| **Camera Power** OFF | Releases the camera completely (free for other apps). Sends `dispose()` to `CameraController`. |
| **Camera Power** ON | Re-initialises the camera with current direction setting. |
| **Front / Back** toggle | Switches `CameraDescription`, reinitialises controller. |
| **Language** | Changes the `?lang=` param on next WebSocket connect. |
| **Text Size** | Adjusts `fontSize` on the translation output (Small=16, Medium=20, Large=24). |
| **Show Confidence Bar** | Shows/hides the vertical teal bar on the right edge of feed. |
| **Show Landmark Overlay** | Shows/hides the MediaPipe skeleton drawn over hands. |
| **Show Frame Guide** | Shows/hides the dashed rectangle guide (fades when hands detected). |
| **Haptic Feedback** | Reserved — trigger `HapticFeedback.lightImpact()` on sign detected. |

---

## Fonts Used

All loaded via `google_fonts` package — no manual asset downloading needed.

| Font | Usage |
|---|---|
| **Sora** | Wordmark, headlines, settings titles |
| **Hanken Grotesk** | Body text, descriptions, captions |
| **JetBrains Mono** | Translation output, FPS label, status labels |

---

## Permissions Summary

| Platform | Permission | Why |
|---|---|---|
| Android | `CAMERA` | Live camera feed for sign capture |
| Android | `INTERNET` | WebSocket connection to CV/ML backend |
| Android | `VIBRATE` | Haptic feedback on sign detection |
| iOS | `NSCameraUsageDescription` | Live camera feed |
| iOS | `NSMicrophoneUsageDescription` | Required by iOS when camera is used |

---

## Connecting Your ML Model (Backend Team)

The app is fully backend-agnostic. Plug in any server that:

1. Accepts a WebSocket connection at `/ws/translate?lang=<LANG>`
2. Receives binary JPEG frames
3. Returns JSON with `text`, `confidence`, and optionally `landmarks`

Recommended backend stack: **Python + FastAPI + MediaPipe + TFLite/PyTorch**

```python
# Minimal FastAPI WebSocket handler skeleton
from fastapi import FastAPI, WebSocket
import mediapipe as mp

app = FastAPI()
mp_hands = mp.solutions.hands.Hands()

@app.websocket("/ws/translate")
async def translate(ws: WebSocket, lang: str = "ASL"):
    await ws.accept()
    while True:
        jpeg_bytes = await ws.receive_bytes()
        # 1. Decode JPEG → frame
        # 2. Run MediaPipe hand detection
        # 3. Extract 21 landmarks
        # 4. Run sign classifier on landmarks
        # 5. Send result
        await ws.send_json({
            "text": "Hello",
            "confidence": 0.94,
            "landmarks": [[x, y, z], ...]  # 21 points
        })
```

---

## Build for Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```

### iOS (requires macOS + Xcode)
```bash
flutter build ios --release
```

---

*SignLink v1.0.0 MVP · Team SignLink · 2025*
