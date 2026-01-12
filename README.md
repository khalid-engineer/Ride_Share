# UniRide

UniRide is a comprehensive ride-sharing application built with Flutter, designed to connect university students and commuters for safe, affordable, and convenient transportation. The app leverages Firebase for backend services, including authentication, real-time database, cloud storage, and push notifications.

## Features

- **User Authentication**: Secure login and signup using Firebase Authentication.
- **Ride Sharing**: Offer or find rides with detailed ride information, including pickup/dropoff locations, time, and pricing.
- **Real-time Chat**: In-app messaging between riders and drivers for coordination.
- **Push Notifications**: Receive notifications for ride updates, messages, and important alerts using Firebase Cloud Messaging.
- **Payment Integration**: Secure payment processing for ride fares.
- **Profile Management**: Create and manage user profiles with personal details and ride history.
- **Onboarding**: Smooth onboarding experience for new users.
- **Audio Recording**: Integrated audio recording for voice messages in chat.
- **Location Services**: GPS-based location tracking for accurate ride matching.

## Screenshots

### Onboarding Screens
![Onboarding 1](assets/images/onboard1.jpg)
![Onboarding 2](assets/images/onboard2.jpg)
![Onboarding 3](assets/images/onboard3.jpg)

### Authentication
![Login Screen](assets\screenshots\login_screen.png)
![Signup Screen](assets/screenshots/signUp_screen.png)

### Home Screens
![Home Screen](/assets/screenshots/home_screen.png)
![Find Ride Screen](assets/screenshots/find_ride_screen.png)
![Offer Ride Screen](assets/screenshots/offer_ride_screen.png)

### Ride Details and Chat
![Ride Details Screen](assets/screenshots/ride_details_screen.png)
![Chat Screen](assets/screenshots/chat_screen.png)

### Profile and Payments
![Profile Screen](assets/screenshots/profile_screen.png)
![Payment Screen](assets/screenshots/payment_screen.png)



## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication, Storage, Functions, Messaging)
- **State Management**: Provider (implied from code structure)
- **Notifications**: Firebase Cloud Messaging + Flutter Local Notifications
- **Audio**: Record and Audioplayers packages
- **Permissions**: Permission Handler
- **Other**: Shared Preferences, Intl for localization

