# NewsByte 📰

**NewsByte** is a modern, immersive news reading application tailored for the Bengali audience. Inspired by the engaging interactions of TikTok and the clean aesthetics of top-tier news apps, NewsByte delivers a seamless, vertical-swipe news experience.

![NewsByte Logo](assets/icon/newsbyte_logo.png)

## 🚀 Key Features

*   **Immersive News Feed**: TikTok-style vertical scrolling for browsing news articles effortlessly.
*   **Smart Gestures**: Tuned swipe sensitivity (80px threshold) ensures deliberate navigation, preventing accidental skips while reading.
*   **Reliable Push Notifications**:
    *   Subscribes to multiple topics (`news`, `all`, `general`) for guaranteed delivery.
    *   Robust background and terminated state handling.
    *   Deep linking support to open specific articles directly from notifications.
*   **Offline-Ready**: Intelligent image caching ensures a smooth experience even with spotty internet.
*   **Bangla-First**: Optimized typography and layout for Bengali content (using `GoogleFonts.hindSiliguri`).
*   **Interactivity**: Like, Share, and "Read More" functionalities seamlessly integrated.

## 🛠 Tech Stack

Built with ❤️ using **Flutter** and **Dart**.

*   **State Management**: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) (2.6.1) for robust and testable state.
*   **Navigation**: [go_router](https://pub.dev/packages/go_router) for declarative routing and deep link handling.
*   **Backend**: **Firebase**
    *   **Cloud Firestore**: Real-time news data.
    *   **Firebase Messaging (FCM)**: Push notifications.
*   **Local Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences) for user settings (e.g., tutorial completion, last read index).
*   **UI/UX**: Custom `PageView` physics, Lottie animations, and Shimmer effects.

## 📱 Installation & Setup

### Prerequisites
*   Flutter SDK (3.10.x or later)
*   Dart SDK
*   Android Studio / VS Code
*   A Firebase project with `google-services.json` placed in `android/app/`.

### Steps

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/morshedkoli/newsapp.git
    cd newsapp
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the app**:
    ```bash
    flutter run
    ```

4.  **Build Release APK**:
    ```bash
    flutter build apk --release --split-per-abi
    ```

## 🏗 Architecture

The project follows a **Feature-First Clean Architecture**:

```
lib/
├── core/               # Global utilities, services, constants, and theme
│   ├── services/       # FCM, Preferences, etc.
│   └── utils/          # Router, Formatters
├── features/           # Feature-based modules
│   ├── news/           # News feature (Data, Domain, Presentation)
│   ├── auth/           # Authentication feature
│   └── notifications/  # Notification logic
└── main.dart           # Entry point
```

## 🔧 Key Implementation Details

### Robust Push Notifications
We solved the common Android background notification issue by:
1.  Registering the `onBackgroundMessage` handler at the **top-level** in `main.dart` (before `runApp`).
2.  Ensuring topic subscriptions occur immediately upon app launch.
3.  Explicitly requesting `POST_NOTIFICATIONS` permissions for Android 13+.

### Swipe Physics
To prevent accidental swipes while reading long articles, we disabled the default `PageView` gesture and implemented a custom `OverscrollNotification` listener. A page transition is only triggered after an accumulated drag distance of **80 logical pixels**, providing a substantial and "heavy" feel.

## 🤝 Contributing

Contributions are welcome! Please follow these steps:
1.  Fork the repo.
2.  Create a feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
*Developed by [Morshed Koli](https://github.com/morshedkoli)*
