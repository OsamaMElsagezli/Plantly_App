# 🌿 Plantly

### AI-Powered Plant Disease Detection App

Plantly is a Flutter app designed to help users explore plant health through leaf photographs. Capture a leaf image or choose one from your gallery, submit it for AI analysis, and browse information about plant diseases, symptoms, and care.

Built as a graduation project, Plantly brings plant disease classification research into a practical mobile interface.

> 🚧 **Development status:** The app’s interface, image upload, and disease library are implemented. Prediction integration and the connection to detailed results and scan history are still being completed.

## 📱 App Features

### 📷 Scan a Leaf
Take a photograph using the camera or select an existing image from the gallery and upload it for analysis.

### 📚 Explore Plant Diseases
Browse disease information, including symptoms, overviews, and management guidance. The current library contains tomato and potato entries, with pepper content planned.

### 👤 Profile and Account Screens
Create a local demonstration account, log in, and view your profile. The app can restore the last saved session.

### 🕘 History and Notifications
Dedicated screens are included for saved scan summaries and in-app notifications. Connecting these features to the active scan flow is pending.

## 🔄 Current Scan Flow

1. Open Plantly and log in or create a demonstration account.
2. Select **Scan Leaf** from the home screen.
3. Capture a photograph or choose one from your gallery.
4. The app uploads the image to the prediction server.
5. The scan screen displays the server response.

A separate result screen has been designed to display the diagnosis, confidence, plant-care guidance, and a **Save to History** action. Its integration is in progress.

## 🧠 AI Behind the App

Plantly includes backend model bundles for **EfficientNetB3** and **MobileNetV2**. Their label definitions cover **15 classes** across:

- 🍅 Tomato
- 🥔 Potato
- 🫑 Bell pepper

These classes include healthy leaves, plant diseases, and pest damage.

Image analysis is intended to run through a Python prediction server. On-device inference is a future development goal.

### Research Performance

The accompanying research reports these results for EfficientNetB3:

| Evaluation | Accuracy |
|---|---:|
| Test set | 99.75% |
| Validation set | 99.81% |
| PlantDoc testing | 96.96% |

These figures describe the research model evaluation, rather than the current app’s end-to-end performance.

## 🛠️ Built With

| Component | Technology |
|---|---|
| App interface | Flutter and Dart |
| Camera and gallery | Image Picker |
| API communication | HTTP multipart upload |
| Local storage | Shared Preferences |
| Prediction server | FastAPI and Python |
| AI models | PyTorch and timm |

## 🚀 Run the App

### Requirements

- Flutter **3.35+**
- Dart **3.9+**
- Platform development tools and a connected device or emulator

From the repository root:

```bash
flutter pub get
flutter run
```

### Prediction Server

The scan screen currently targets:

```text
http://10.0.2.2:8000/predict
```

This address is intended for the standard Android emulator. Other devices require a reachable server address.

**The included backend needs integration fixes before inference works with the supplied model bundles**, including checkpoint loading, configuration parsing, preprocessing, and response formatting.

## 📁 Repository Overview

```text
├── lib/          # Flutter app screens and logic
├── server/       # Prediction API and AI model bundles
├── android/      # Android project
├── ios/          # iOS project
├── web/          # Web project
├── windows/      # Windows project
├── macos/        # macOS project
├── linux/        # Linux project
└── test/         # Test scaffold
```

Flutter platform projects are included, but functionality has not been verified across every platform.

## 🗺️ Planned Improvements

- [ ] Complete prediction-server integration.
- [ ] Connect detailed results, history, and notifications.
- [ ] Complete disease information for every supported class.
- [ ] Add secure account management.
- [ ] Improve loading states and upload error handling.
- [ ] Validate camera, permissions, and networking across platforms.
- [ ] Explore offline, on-device analysis.

## 📌 Project Notes

Account management currently serves demonstration purposes and stores credentials locally in plain preferences. It is not ready for production authentication.

Plantly is an educational application. Its predictions and plant-care information should support further inspection and consultation with an agricultural specialist.
