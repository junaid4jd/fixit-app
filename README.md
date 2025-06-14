# 🔧 FixIt Oman - Complete Handyman Services Platform

A comprehensive handyman services marketplace app for Oman built with Flutter and Firebase,
featuring complete user, service provider, and admin functionality.

## 🌟 Complete Feature Set

### 👤 **User Features**

- ✅ **Account Management**
   - Email/Password authentication
   - Profile management with photo upload
   - City selection and preferences
   - Phone number verification

- ✅ **Service Discovery**
   - Browse service categories (dynamically loaded)
   - City-based handyman search
   - Filter by ratings, experience, price
   - View detailed handyman profiles

- ✅ **Booking System**
   - Schedule services with date/time selection
   - Real-time availability checking
   - Service cost estimation
   - Address and contact information
   - Booking confirmation and tracking

- ✅ **Communication**
   - In-app chat with handymen
   - Real-time messaging
   - Push notifications for updates
   - Booking status notifications

- ✅ **Payment & Reviews**
   - Integrated payment processing
   - Multiple payment methods support
   - Rate and review handymen
   - View service history

- ✅ **Notifications**
   - Push notifications for booking updates
   - In-app notification center
   - Email notifications for important updates

### 🔨 **Service Provider (Handyman) Features**

- ✅ **Account Management**
   - Email/Password authentication
   - Profile management with photo upload
   - City selection and preferences
   - Phone number verification
   - Logout functionality with role selection

- ✅ **Professional Profile**
   - Complete profile setup with photos
   - Skills and specialties management
   - Experience and hourly rate settings
   - Service area selection

- ✅ **Identity Verification**
   - Document upload (ID, business license)
   - Admin verification process
   - Verified badge system

- ✅ **Booking Management**
   - View incoming service requests
   - Accept/reject bookings with reasons
   - Track booking status (New → Accepted → In Progress → Completed)
   - Calendar view of scheduled jobs

- ✅ **Schedule Management**
   - Interactive calendar interface
   - Availability management
   - Time slot blocking
   - Multiple bookings per day

- ✅ **Communication**
   - Chat with customers
   - Send updates and photos
   - Receive instant notifications

- ✅ **Analytics Dashboard**
   - Earnings tracking
   - Job completion statistics
   - Customer ratings overview
   - Monthly performance metrics

- ✅ **Profile Customization**
   - Photo gallery of completed work
   - Service descriptions
   - Pricing management
   - Availability settings

- ✅ **Logout Functionality**
   - Dashboard Header (Popup Menu) with logout option
   - Profile Page (Settings Section) with logout option
   - Confirmation dialog with warning message
   - Red color scheme for destructive action
   - Loading indicator during logout process
   - Success/error messages with SnackBars
   - Redirects to Role Selection Screen after logout

### 👨‍💼 **Admin Features**

- ✅ **Platform Management**
   - User and service provider management
   - Account verification and approval
   - Content moderation

- ✅ **Service Categories**
   - Add/edit/delete service categories
   - Category icons and colors
   - Order management
   - Activate/deactivate categories

- ✅ **Location Management**
   - Add/edit/delete cities
   - Service area management
   - Geographic coverage control

- ✅ **Analytics & Reports**
   - Platform usage statistics
   - Revenue tracking and reports
   - User growth metrics
   - Booking success rates
   - Top performing handymen
   - Customer satisfaction metrics

- ✅ **Identity Verification**
   - Review handyman applications
   - Document verification
   - Approve/reject with feedback
   - Verification status tracking

- ✅ **Content Moderation**
   - Review management
   - User report handling
   - Content filtering
   - Quality control

## 🏗️ **Technical Architecture**

### **Frontend - Flutter**

- Material Design 3 components
- Responsive UI for all screen sizes
- Custom animations and transitions
- Dark/light theme support
- Offline capability with local caching

### **Backend - Firebase**

- **Authentication**: Email/password, phone verification
- **Firestore**: Real-time database for all app data
- **Storage**: Image and document uploads
- **Cloud Messaging**: Push notifications
- **Cloud Functions**: Server-side logic and triggers
- **Analytics**: User behavior tracking

### **Key Firebase Collections**
```
users/
├── User profiles and preferences
├── Service provider details
└── Admin accounts

bookings/
├── Service requests and appointments
├── Status tracking and history
└── Payment information

categories/
├── Service categories
├── Icons and styling
└── Admin-controlled content

cities/
├── Available service locations
└── Geographic boundaries

reviews/
├── Customer feedback
├── Ratings and comments
└── Service quality metrics

notifications/
├── In-app notifications
├── Push notification logs
└── User preferences

identity_verifications/
├── Document submissions
├── Verification status
└── Admin review process
```

## 📱 **App Flow & User Experience**

### **User Journey**

1. **Onboarding**: Role selection → Registration → Profile setup
2. **Discovery**: Browse categories → Select city → View handymen
3. **Booking**: Choose handyman → Schedule service → Enter details → Confirm
4. **Service**: Track status → Chat with handyman → Receive updates
5. **Completion**: Service delivery → Payment → Rate & review

### **Service Provider Journey**

1. **Registration**: Profile setup → Document upload → Verification wait
2. **Onboarding**: Complete profile → Set availability → Go live
3. **Operations**: Receive requests → Accept jobs → Manage schedule
4. **Service**: Communicate with customers → Update status → Complete work
5. **Growth**: Build reputation → Increase rates → Expand service areas
6. **Logout**: Secure logout → Role selection screen

### **Admin Operations**

1. **Setup**: Configure categories → Add cities → Set up verification
2. **Management**: Review applications → Verify documents → Approve handymen
3. **Monitoring**: Track platform metrics → Handle issues → Generate reports
4. **Growth**: Analyze performance → Optimize features → Scale operations

## 🚀 **Getting Started**

### **Prerequisites**

- Flutter SDK 3.24.0+
- Dart 3.5.0+
- Firebase CLI
- Android Studio / VS Code
- Firebase project setup

### **Installation**

```bash
# Clone the repository
git clone https://github.com/your-repo/fixit-oman.git

# Navigate to project directory
cd fixit-oman

# Install dependencies
flutter pub get

# Configure Firebase
flutter packages pub run build_runner build

# Run the app
flutter run
```

### **Firebase Setup**

1. Create Firebase project at https://console.firebase.google.com
2. Enable Authentication (Email/Password)
3. Set up Firestore Database
4. Configure Storage rules
5. Set up Cloud Messaging
6. Add app configurations for iOS/Android

### **Environment Configuration**

```yaml
# pubspec.yaml - Key dependencies
dependencies:
  firebase_core: ^3.7.1
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
  firebase_storage: ^12.3.6
  firebase_messaging: ^15.1.5
  flutter_local_notifications: ^18.0.1
  image_picker: ^1.1.2
  table_calendar: ^3.1.2
```

## 📊 **Performance & Scalability**

### **Optimization Features**

- **Lazy Loading**: On-demand data fetching
- **Image Caching**: Optimized image loading and storage
- **Offline Support**: Local data caching and sync
- **Real-time Updates**: Efficient Firebase listeners
- **Search Optimization**: Indexed queries and filters

### **Security Measures**

- **Authentication**: Secure user verification
- **Data Validation**: Client and server-side validation
- **Privacy**: GDPR-compliant data handling
- **Document Security**: Encrypted file storage
- **API Security**: Protected backend endpoints

## 🎯 **Business Model**

### **Revenue Streams**

- **Commission**: Percentage from completed bookings
- **Premium Subscriptions**: Enhanced features for handymen
- **Advertising**: Promoted listings and featured services
- **Verification Fees**: Professional certification charges

### **Key Metrics**

- **User Acquisition**: Registration and retention rates
- **Booking Success**: Completion and satisfaction rates
- **Revenue Growth**: Monthly recurring revenue tracking
- **Quality Assurance**: Average ratings and reviews

## 🔮 **Future Enhancements**

### **Planned Features**

- **Multi-language Support**: Arabic and English
- **Advanced Search**: AI-powered recommendations
- **Service Packages**: Bundled service offerings
- **Loyalty Program**: Points and rewards system
- **Enterprise Solutions**: B2B service management
- **IoT Integration**: Smart home service integration

### **Technical Roadmap**

- **Performance**: Advanced caching and optimization
- **Analytics**: Machine learning insights
- **Automation**: Smart scheduling and routing
- **Integration**: Third-party service connections
- **Expansion**: Multi-country support

## 📝 **API Documentation**

### **Core Services**

- **AuthService**: User authentication and management
- **BookingService**: Booking lifecycle management
- **NotificationService**: Push and in-app notifications
- **ChatService**: Real-time messaging system

### **Firebase Security Rules**

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data access control
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Booking access control
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         request.auth.uid == resource.data.handymanId);
    }
  }
}
```

## 🤝 **Contributing**

### **Development Guidelines**

1. Follow Flutter best practices
2. Write comprehensive tests
3. Document all public APIs
4. Use semantic versioning
5. Maintain code quality standards

### **Code Style**

- Follow Dart style guide
- Use meaningful variable names
- Add comments for complex logic
- Implement proper error handling
- Write unit and widget tests

## 📞 **Support & Contact**

### **Technical Support**

- **Documentation**: Available in `/docs` folder
- **Issue Tracking**: GitHub Issues
- **Community**: Discord server for developers
- **Email**: support@fixit-oman.com

### **Business Inquiries**

- **Partnerships**: partners@fixit-oman.com
- **Enterprise Sales**: enterprise@fixit-oman.com
- **Media**: press@fixit-oman.com

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## 🙏 **Acknowledgments**

- Flutter team for the amazing framework
- Firebase team for the backend infrastructure
- Material Design team for the design system
- Open source contributors and community

---

**Built with ❤️ for the people of Oman**

*Connecting skilled handymen with customers who need quality home services - making life easier, one
service at a time.*

# fixit-app
