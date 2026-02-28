# 🚀 MarketMind Elite — Complete Setup & Deployment Guide

---

## PART 1: Firebase Project Setup (Free Spark Plan)

### Step 1 — Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click **"Add Project"** → Name it `MarketMind Elite`
3. Disable Google Analytics (not needed)
4. Wait for project creation

### Step 2 — Add Android App
1. Click **Android icon** on project overview
2. Package name: `com.yourname.marketmind_elite`  ← Keep consistent
3. App nickname: `MarketMind Elite`
4. Download **`google-services.json`**
5. Place it at: `android/app/google-services.json`

### Step 3 — Enable Firestore
1. Firestore Database → **Create Database**
2. Choose **Production mode** (we'll set rules next)
3. Select region closest to your users (e.g., `europe-west1`)

### Step 4 — Enable Firebase Storage
1. Storage → **Get Started**
2. Start in **Production mode**
3. Same region as Firestore

### Step 5 — Enable Cloud Messaging (FCM)
1. Project Settings → **Cloud Messaging tab**
2. Copy your **Server Key** (you'll need this for the Cloud Function)
3. Note the **Sender ID**

### Step 6 — Apply Security Rules

**Firestore Rules** (Firestore → Rules tab):
```
Copy the contents of `firebase_security_rules.txt` (Firestore section)
```

**Storage Rules** (Storage → Rules tab):
```
Copy the contents of `firebase_security_rules.txt` (Storage section — uncomment it)
```

### Step 7 — Create Initial Firestore Data
In Firestore, manually create:

**Collection: `config` → Document: `app_config`**
```json
{
  "shamCashId":    "09XXXXXXXXX",
  "payeerAddress": "YOUR_TRC20_ADDRESS",
  "telegramLink":  "https://t.me/+YourPrivateGroupLink",
  "supportHandle": "https://t.me/YourSupportUsername",
  "packagePrices": {
    "monthly":   29.99,
    "quarterly": 74.99,
    "yearly":    199.99
  }
}
```

**Collection: `admins` → Document: `{your_firebase_uid}`**
```json
{ "isAdmin": true }
```
> Get your UID after signing in via the Firebase Auth console.

---

## PART 2: Flutter Project Setup

### Step 1 — Install Flutter
```bash
# Install Flutter SDK from https://docs.flutter.dev/get-started/install
flutter doctor  # Verify all checks pass
```

### Step 2 — Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### Step 3 — Configure Firebase
```bash
cd marketmind_elite
flutterfire configure \
  --project=your-firebase-project-id \
  --platforms=android
```
This generates `lib/firebase_options.dart` automatically.

### Step 4 — Install Dependencies
```bash
flutter pub get
```

### Step 5 — Customize Constants
Edit `lib/utils/app_theme.dart`:
```dart
static const String masterPassword = 'YourSecureAdminPassword123!';
static const String telegramHandle = '@YourSupportHandle';
```

---

## PART 3: APK Signing (Production Build)

### Step 1 — Generate Keystore
```bash
keytool -genkey -v \
  -keystore ~/marketmind_keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias marketmind_key

# You'll be prompted for:
# - Keystore password (save this SECURELY)
# - Key password (save this SECURELY)
# - Name, organization, country
```

### Step 2 — Create key.properties
Create `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=marketmind_key
storeFile=/full/path/to/marketmind_keystore.jks
```

⚠️ **Add to `.gitignore`**:
```
android/key.properties
*.jks
```

### Step 3 — Configure android/app/build.gradle
Add before `android {}` block:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Inside `android { ... }` replace `buildTypes` with:
```groovy
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### Step 4 — Build the APK
```bash
# Fat APK (works on all architectures)
flutter build apk --release

# Smaller split APKs (recommended for distribution)
flutter build apk --split-per-abi --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   ← Use this for modern Android
```

---

## PART 4: Push Notification Cloud Function

To send push notifications on approval, add this **Cloud Function**:

### Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
firebase init functions  # Choose TypeScript
```

### functions/src/index.ts
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const onDeviceApproved = functions.firestore
  .document('approved_devices/{uuid}')
  .onCreate(async (snap) => {
    const uuid = snap.id;

    // Find FCM token from payment request
    const qs = await admin.firestore()
      .collection('payment_requests')
      .where('deviceUUID', '==', uuid)
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    if (qs.empty) return;

    const fcmToken = qs.docs[0].data()['fcmToken'];
    if (!fcmToken) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: '✅ VIP Access Approved! 🎉',
        body: 'Your payment has been confirmed. Tap to join the VIP Telegram now!',
      },
      android: {
        notification: {
          sound: 'default',
          channelId: 'high_importance_channel',
          priority: 'high',
        },
      },
    });
  });
```

```bash
firebase deploy --only functions
```

---

## PART 5: FCM Android Channel Setup

Create `android/app/src/main/res/raw/` and add default sound if desired.

In `android/app/src/main/kotlin/.../MainActivity.kt`:
```kotlin
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onStart() {
        super.onStart()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "high_importance_channel",
                "VIP Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "MarketMind Elite VIP approvals"
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }
}
```

---

## PART 6: Admin Workflow Guide

### How to Approve a User (Step-by-Step)
1. Open the app on your phone
2. **Tap the MarketMind Elite logo 10 times rapidly** (within 10 seconds)
3. Enter your Master Password
4. You're now in the Ghost Admin Panel
5. Tap **"Pending"** tab — see all payment requests
6. Review the receipt image (tap to enlarge)
7. Verify Transaction ID against your Sham Cash / Payeer account
8. Tap **"APPROVE"** → User instantly gets:
   - Telegram VIP link unlocked on their device
   - Push notification sent

### How to Update Payment Info
1. Access admin panel (same as above)
2. Tap **"Settings"** tab
3. Update any field (Sham Cash number, wallet, prices, Telegram link)
4. Tap **"SAVE & PUSH LIVE"**
5. All users see changes instantly (no app update needed)

---

## PART 7: Security Checklist ✅

| Feature | Status | Implementation |
|---------|--------|----------------|
| Screenshot Block | ✅ | `FlutterWindowManager.FLAG_SECURE` |
| Screen Recording Block | ✅ | Same flag (applies to both) |
| Device UUID Binding | ✅ | Android hardware ID + SharedPreferences |
| Image Compression | ✅ | `FlutterImageCompress` at 60% quality |
| Firestore Rules | ✅ | Whitelist-based, admin-only writes |
| Storage Rules | ✅ | Size limit + content-type validation |
| Admin Hidden Access | ✅ | 10-tap + master password |
| Paywall Lock | ✅ | Real-time Firestore approval check |

---

## PART 8: Troubleshooting

**`google-services.json` missing error:**
→ Place the file at `android/app/google-services.json`

**`firebase_options.dart` missing:**
→ Run `flutterfire configure` again

**Screenshot still works in debug mode:**
→ This is normal. FLAG_SECURE only works in release builds on real devices.

**FCM notifications not received:**
→ Check Cloud Function logs in Firebase Console → Functions → Logs

**Build failed with minification errors:**
→ Add ProGuard rules:
```
android/app/proguard-rules.pro
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
```

---

## File Structure Summary

```
marketmind_elite/
├── lib/
│   ├── main.dart                    # App entry + security init
│   ├── firebase_options.dart        # Auto-generated by FlutterFire CLI
│   ├── models/
│   │   └── models.dart              # All data models
│   ├── services/
│   │   ├── firebase_service.dart    # Firestore + Storage + FCM
│   │   ├── device_service.dart      # UUID + Screenshot block
│   │   └── market_service.dart      # Ticker + Whale + Paper trading data
│   ├── screens/
│   │   ├── home_screen.dart         # Main paywall + features
│   │   ├── payment_screen.dart      # Sham Cash + Payeer forms
│   │   ├── paper_trading_screen.dart # Simulator
│   │   └── admin_screen.dart        # Ghost admin panel
│   ├── widgets/
│   │   └── shimmer_card.dart        # Gold cards, ticker, padlock, whale
│   └── utils/
│       └── app_theme.dart           # Deep Obsidian theme + constants
├── android/
│   └── app/
│       ├── google-services.json     # ← YOU ADD THIS
│       └── src/main/
│           └── AndroidManifest.xml
├── firebase_security_rules.txt      # Copy to Firebase console
├── pubspec.yaml
└── SETUP_GUIDE.md                   # This file
```
