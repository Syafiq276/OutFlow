# Outflow 💰

**Outflow** is a modern Flutter mobile application designed to help you manage and track your recurring subscriptions effortlessly. Take control of your monthly spending and never lose track of your subscriptions again.

## 📱 Features

### Authentication & Security
- **Email & Password Registration** - Create an account with email verification
- **Google Sign-In** - Quick and secure login with your Google account
- **Email Verification** - Automatic verification email sent on signup
- **Auto-verification Check** - Real-time email verification status updates
- **User Privacy** - Each user only sees their own subscription data

### Subscription Management
- **Add Subscriptions** - Track service name, cost, billing cycle, and category
- **View All Subscriptions** - See all active subscriptions in a beautiful list
- **Edit Subscriptions** - Update subscription details anytime
- **Delete Subscriptions** - Remove subscriptions with confirmation
- **Flexible Billing Cycles** - Support for monthly and yearly subscriptions

### Dashboard & Analytics
- **Monthly Spending Summary** - See total monthly cost at a glance
- **Category Breakdown** - Understand spending by category
- **Search & Filter** - Find subscriptions by name or category
- **Empty State** - Friendly prompts when no subscriptions exist
- **Real-time Updates** - Live sync with Firebase Firestore

### User Experience
- **Material Design 3** - Modern teal-themed interface
- **Dark/Light Mode Support** - Adaptive to device settings
- **Responsive Layout** - Works on phones and tablets
- **Loading States** - Clear feedback during operations
- **Error Handling** - User-friendly error messages
- **Logout Function** - Secure logout with confirmation

## 🛠 Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase
  - Firebase Authentication (Email & Google Sign-In)
  - Cloud Firestore (Real-time database)
- **UI Framework:** Material Design 3
- **State Management:** StreamBuilder with services pattern
- **Packages:**
  - `firebase_core: ^4.4.0`
  - `firebase_auth: ^6.1.4`
  - `google_sign_in: ^6.2.1`
  - `cloud_firestore: ^6.1.2`
  - `intl: ^0.20.2`

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.7 or higher)
- Dart SDK
- Firebase Account
- Google Cloud Project (for Google Sign-In)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Syafiq276/OutFlow.git
   cd OutFlow/outflow
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   flutterfire configure
   ```
   This will generate `lib/firebase_options.dart` with your Firebase credentials.

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point & auth wrapper
├── firebase_options.dart              # Firebase configuration (*.gitignore)
├── services/
│   ├── auth_service.dart             # Authentication logic
│   └── subscription_service.dart      # Firestore CRUD operations
├── models/
│   └── subscription_model.dart        # Subscription data model
├── screens/
│   ├── login_screen.dart             # Login page
│   ├── signup_screen.dart            # Sign up page
│   ├── email_verification_screen.dart # Email verification
│   ├── dashboard_screen.dart         # Main dashboard
│   ├── add_subscription_screen.dart   # Add new subscription
│   └── edit_subscription_screen.dart  # Edit subscription
└── assets/
    └── images/
        └── outflow_logo.png          # App logo

android/
├── app/
│   ├── google-services.json          # Firebase config (*.gitignore)
│   └── src/
└── gradle/

ios/
├── Runner/
│   ├── GoogleService-Info.plist      # Firebase config (*.gitignore)
│   └── Assets.xcassets/
└── Podfile
```

## 🔐 Security

### Important: Firebase Configuration
The following files contain sensitive information and are **excluded from version control**:
- `lib/firebase_options.dart` - Firebase API keys and project ID
- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config

**For Development:**
Each developer must run `flutterfire configure` locally to generate their configuration files.

**For Production:**
Use Firebase environment configuration or CI/CD secrets management.

## 📊 Database Schema

### Subscriptions Collection
```
subscriptions/
├── documentId (auto-generated)
│   ├── userId: String
│   ├── name: String
│   ├── cost: Double
│   ├── period: String (month/year)
│   ├── category: String
│   ├── nextBillingDate: Timestamp
│   └── isActive: Boolean
```

## 🎨 UI Features

### Colors
- **Primary:** Teal (#008B8B)
- **Background:** Light Gray (#F5F5F5)
- **Text:** Dark Gray & Black

### Icons
- Material Icons for UI elements
- Custom logo for branding

## 📚 How to Use

### First Time User
1. Download and launch the app
2. Sign up with email or Google account
3. Verify your email (check inbox for verification link)
4. Add your first subscription
5. View dashboard with spending summary

### Adding a Subscription
1. Tap the **+** FAB (Floating Action Button)
2. Enter service name (e.g., "Netflix")
3. Enter monthly/yearly cost
4. Select billing cycle
5. Choose category
6. Pick next billing date
7. Tap "SAVE SUBSCRIPTION"

### Editing a Subscription
1. Tap any subscription in the list
2. Modify the details
3. Tap "UPDATE SUBSCRIPTION"

### Deleting a Subscription
1. Long-press a subscription
2. Confirm deletion in the dialog

### Viewing Analytics
- Check the monthly spending card at the top
- Filter by category using chips
- Search by subscription name

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License.

## 👨‍💻 Author

**Syafiq276**
- GitHub: [@Syafiq276](https://github.com/Syafiq276)
- Repository: [OutFlow](https://github.com/Syafiq276/OutFlow)

## 🆘 Support

For issues, questions, or suggestions, please open an issue on GitHub.

## 🔄 Future Enhancements

- [ ] Push notifications for upcoming billing dates
- [ ] Expense reports and charts
- [ ] Export to CSV/PDF
- [ ] Multi-currency support
- [ ] Subscription sharing with family members
- [ ] Dark mode UI
- [ ] Biometric authentication
- [ ] Subscription recommendations
- [ ] Bill splitting feature
- [ ] Multiple user profiles

---

**Manage your subscriptions smartly with Outflow!** 💡

