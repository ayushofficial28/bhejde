<div align="center">

# 🚀 BhejDe

### Blazing-fast, offline peer-to-peer file sharing for Android

**BhejDe** is a high-speed, offline file-sharing application built with **Flutter and native Android integrations**. It uses Google's **Nearby Connections API** to establish local, high-bandwidth connections for transferring files, media, and APKs without requiring an internet connection.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter\&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart\&logoColor=white)](https://dart.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android\&logoColor=white)](https://www.android.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**[Features](#-features) • [Architecture](#-architecture) • [Under the Hood](#-under-the-hood) • [Installation](#-installation) • [Permissions](#-permissions) • [Contributing](#-contributing)**

</div>

---


## ✨ Features

### ⚡ High-Speed Offline Transfers

* Transfer files without an active internet connection.
* Uses **Google Nearby Connections** for local device-to-device communication.
* Automatically leverages high-bandwidth Wi-Fi for large file transfers.
* No mobile data is consumed during transfers.

### 🔗 Native Android Share Sheet

BhejDe integrates directly with the Android sharing system.

Files can be shared from:

* Gallery applications
* File managers
* Document providers
* Other Android applications

Users can send files directly to BhejDe without manually opening the application first.

### 📦 Split-APK Support

BhejDe can share installed Android applications, including applications distributed as **Split APKs**.

The native Android integration handles:

* APK extraction
* Multi-part APK handling
* Transfer of application packages
* APK installation on the receiving device

> **APK compatibility:** Applications installed through Google Play may contain device-specific APK splits, including ABI-specific native libraries. BhejDe transfers the APKs available on the source device. As a result, an application extracted from one device may not be installable on a receiving device with an incompatible ABI or configuration.

### 🔋 OEM-Resilient Connectivity

Android OEMs can introduce aggressive background restrictions and customized networking behavior.

BhejDe uses the **`P2P_STAR` topology** to provide a centralized hub-and-spoke connection model, reducing connection conflicts and improving reliability across customized Android environments.

### 🔄 Reactive Transfer State

The Flutter UI is decoupled from the underlying native networking layer.

**Riverpod** manages:

* Device discovery state
* Connection state
* Transfer progress
* Transfer completion
* Errors and cancellations

Native transfer events are converted into reactive state updates and reflected in the UI in real time.

---

## 🏗️ Architecture

```text
┌──────────────────────────────────────────┐
│               Flutter UI                 │
│                                          │
│        Widgets / Screens / UI            │
└────────────────────┬─────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│              Riverpod State              │
│                                          │
│  Discovery • Connection • Transfer State │
└────────────────────┬─────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│          Dart ↔ Native Bridge            │
│                                          │
│       Flutter Method/Event Channels      │
└────────────────────┬─────────────────────┘
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
┌───────────────────┐  ┌───────────────────┐
│ Nearby Connections│  │  Android Native   │
│       API         │  │    Integrations   │
└─────────┬─────────┘  └─────────┬─────────┘
          │                      │
          ▼                      ▼
   Local Wi-Fi / P2P       MediaStore /
                           Package Manager /
                           Android Intents
```

---

## 🔬 Under the Hood

BhejDe is designed as a systems-level application rather than a purely Flutter-based file-transfer wrapper.

### 1. `P2P_STAR` Network Topology

BhejDe uses Google's Nearby Connections API with the **`P2P_STAR`** strategy.

Instead of establishing a direct peer-to-peer relationship between every device, the topology follows a **hub-and-spoke model**:

```text
              ┌───────────┐
              │    Hub    │
              │   Device  │
              └─────┬─────┘
           ┌─────────┼─────────┐
           │         │         │
           ▼         ▼         ▼
       Device A  Device B  Device C
```

This provides a predictable connection model and can help reduce connection conflicts during Wi-Fi establishment on heavily customized Android devices.

Nearby Connections handles the underlying transition between discovery and higher-bandwidth local connectivity.

---

### 2. Cold-Boot Share Intent Handling

BhejDe supports Android's native `SEND` and `SEND_MULTIPLE` sharing intents.

This allows users to select a file from another application and share it directly with BhejDe.

The application handles both:

* **Warm-start intents** — BhejDe is already running.
* **Cold-start intents** — BhejDe is launched specifically to handle the incoming share request.

Incoming content is retained until the Flutter engine and UI are ready, after which it is routed into the transfer pipeline.

```text
Android Share Sheet
        │
        ▼
ACTION_SEND / ACTION_SEND_MULTIPLE
        │
        ▼
Native Intent Handler
        │
        ▼
Pending Share Payload
        │
        ▼
Flutter Engine
        │
        ▼
Riverpod Transfer Queue
        │
        ▼
Nearby Connections
```

---

### 3. Native Android Bridges

Some operations cannot be implemented efficiently using Flutter alone.

BhejDe therefore uses custom native Android integrations through **Method Channels**.

#### `apks_manager`

Handles Android application package operations such as:

* APK extraction
* Split-APK handling
* Application archiving
* Installation

[`apks_manager`](https://pub.dev/packages/apks_manager)

#### `android_document_fetcher`

Provides optimized access to locally stored documents through Android's **MediaStore API**, including paginated document retrieval.

[`android_document_fetcher`](https://pub.dev/packages/android_document_fetcher)

---

## 🛠️ Tech Stack

| Layer              | Technology                    |
| ------------------ | ----------------------------- |
| Frontend           | Flutter                       |
| Language           | Dart                          |
| State Management   | Riverpod                      |
| Networking         | Google Nearby Connections API |
| Native Bridge      | Flutter Method Channels       |
| Native Language    | Java / Kotlin                 |
| File Discovery     | Android MediaStore            |
| APK Management     | Android Package Manager       |
| System Integration | Android Intents               |
| Platform           | Android                       |

---

## 📂 Project Structure

```text
bhejde/
│
├── android/
│   └── Native Android integrations
│
├── lib/
│   ├── core/
│   ├── features/
│   ├── providers/
│   ├── services/
│   ├── screens/
│   └── main.dart
│
├── assets/
├── screenshots/
├── test/
│
├── pubspec.yaml
└── README.md
```

---

## 🚀 Installation

### Option 1 — Install the Release APK

The easiest way to try BhejDe is to download a pre-built APK from the project's **GitHub Releases**.

For most modern Android phones, download:

```text
BhejDe-v1.0.0-arm64-v8a.apk
```

Architecture-specific builds are provided because BhejDe is an Android application with native components.

Available release variants may include:

```text
BhejDe-v1.0.0-arm64-v8a.apk
BhejDe-v1.0.0-armeabi-v7a.apk
BhejDe-v1.0.0-x86_64.apk
BhejDe-v1.0.0.apk
```

The **universal APK** contains binaries for multiple architectures and is larger. The architecture-specific APK is recommended when the device architecture is known.

After downloading:

1. Install BhejDe on the Android device.
2. Grant the requested permissions.
3. Install BhejDe on a second Android device.
4. Enable Wi-Fi and Bluetooth on both devices.
5. Start discovery and test a transfer.

> **Note:** BhejDe's file-transfer functionality works independently of the CPU architectures of the two devices. However, **APK installation compatibility depends on the APKs being transferred and the receiving device's supported ABI/configuration.**

---

### Option 2 — Build from Source

#### Prerequisites

* [Flutter SDK](https://flutter.dev/)
* [Android Studio](https://developer.android.com/studio)
* Android SDK
* Android SDK Platform 21 or newer
* A physical Android device
* A second Android device for testing transfers

#### 1. Clone the repository

```bash
git clone https://github.com/yourusername/bhejde.git
cd bhejde
```

#### 2. Install dependencies

```bash
flutter pub get
```

#### 3. Check connected devices

```bash
flutter devices
```

#### 4. Build a release APK

For a universal release APK:

```bash
flutter build apk --release
```

The generated APK will be available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

To generate architecture-specific APKs:

```bash
flutter build apk --release --split-per-abi
```

This produces APKs for the supported target ABIs under:

```text
build/app/outputs/flutter-apk/
```

### 🧪 Development

For development and debugging:

```bash
flutter run
```

This launches BhejDe in **debug mode** and is intended for development rather than normal distribution.

---

## 🔄 Transfer Flow

```text
┌──────────────┐
│ Select Files │
└──────┬───────┘
       │
       ▼
┌────────────────────┐
│ Start Discovery    │
│ Nearby Connections │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Discover Receiver  │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Connection Request │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Establish Local    │
│ High-Bandwidth Link│
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Transfer Payload   │
│ + Progress Events  │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Atomic File Write  │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Transfer Complete  │
└────────────────────┘
```

---

## 🔐 Permissions

BhejDe integrates with several Android system capabilities.

### Bluetooth

Required for device discovery and Nearby Connections:

```text
BLUETOOTH
BLUETOOTH_ADMIN

BLUETOOTH_SCAN
BLUETOOTH_ADVERTISE
BLUETOOTH_CONNECT
```

### Wi-Fi

```text
NEARBY_WIFI_DEVICES
```

### Location

Depending on Android version and the underlying discovery APIs:

```text
ACCESS_FINE_LOCATION
ACCESS_COARSE_LOCATION
```

### Storage

Storage permissions vary across Android versions and are handled according to the platform's storage model.

```text
READ_EXTERNAL_STORAGE
WRITE_EXTERNAL_STORAGE
MANAGE_EXTERNAL_STORAGE
```

> Permissions and runtime behavior vary across Android versions. BhejDe requests the permissions required by the relevant platform capabilities.

---

## 🎯 Design Goals

### Reliability

Handle Android lifecycle events, connection failures, and interrupted transfers gracefully.

### Performance

Use local high-bandwidth connectivity rather than routing files through the internet.

### Platform Integration

Leverage Android's native APIs where Flutter abstractions are insufficient.

### User Experience

Make file sharing as simple as selecting a file and choosing BhejDe from the Android share sheet.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome.

1. Fork the repository.
2. Create a feature branch:

```bash
git checkout -b feature/AmazingFeature
```

3. Commit your changes:

```bash
git commit -m "Add AmazingFeature"
```

4. Push the branch:

```bash
git push origin feature/AmazingFeature
```

5. Open a Pull Request.

---

## 📄 License

BhejDe is distributed under the **MIT License**.

See [`LICENSE`](LICENSE) for more information.

---

<div align="center">

### 🚀 Built with Flutter + Android Native

**BhejDe — Share. Offline. Fast.**

</div>
