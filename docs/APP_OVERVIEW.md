# PurraMedics - Advanced Pet Healthcare App

## 📋 Project Objective
**PurraMedics** is a comprehensive mobile application designed to bridge the gap between pet owners and veterinary professionals. The primary objective is to provide a centralized digital ecosystem for:
1.  **Pet Health Management:** Accessible and organized medical records.
2.  **Emergency Response:** Immediate access to critical care resources.
3.  **Community Engagement:** Information on vaccination drives and adoption events.
4.  **Symptom Triage:** AI-assisted preliminary health assessments.

## 🚀 Target Audience
-   **Pet Owners (Fur Parents):** Seeking reliable health tracking, appointment management, and care tips.
-   **Veterinarians:** Needing a streamlined patient management system and communication channel.

## 📱 Key Features & Modules

### 1. Unified Authentication System
-   **Single Entry Point:** User-friendly `LoginPage` and `SignUpPage`.
-   **Role-Based Access Control (RBAC):**
    -   **Pet Owners:** Access to personal pet records, appointments, and tips.
    -   **Veterinarians:** Access to `VetDashboard`, patient lists, and medical record editing privileges.

### 2. Home Dashboard (Fur Parent View)
-   **Upcoming Drives (Priority):** A prominent carousel displaying community events like vaccination camps and adoption drives.
-   **Daily Insights:** A feed of curated pet care tips (Nutrition, Safety, Dental) with interactive details.
-   **Quick Navigation:** Fast access to Health, Visits, Pets, and SOS features.

### 3. Pet Management (`PetsPage`)
-   **Digital Health Record:** Displays Age, Weight, Breed, and Chronic Conditions.
-   **Read-Only Mode:** Pet owners can view but not alter medical records (ensuring data integrity).
-   **Vet Privileges:** Verified veterinarians can Add, Edit, or Delete pet profiles.

### 4. Appointment Scheduling (`AppointmentsPage`)
-   **Visit Tracking:** View upcoming confirmed appointments and past history.
-   **Booking System:** Request new appointments with preferred clinics.
-   **Status Indicators:** Visual tags for 'Confirmed', 'Pending', or 'Completed' visits.

### 5. AI Symptom Checker (`SymptomsPage`)
-   **Digital Triage:** Users select symptoms tags (e.g., Vomiting, Lethargy) and add notes.
-   **AI Analysis:** (Mock/Integrated) Generates a preliminary report with:
    -   Triage Assessment (Emergency vs. Monitor).
    -   Veterinary Action Plan.
    -   Immediate Home Care advice.

### 6. Emergency Resource (`EmergencyPage`)
-   **SOS Actions:** One-tap "Call Vet" and "Navigate to Clinic".
-   **First Aid Library:** Offline-accessible guides for CPR, Choking, and Wound care.

## 🛠️ Technical Architecture

### Tech Stack
-   **Framework:** Flutter (Dark/Material Design)
-   **Language:** Dart
-   **State Management:** Provider / SetState (Hybrid)
-   **Local Database:** Hive (NoSQL) for offline persistence of Events and Pets.
-   **Navigation:** Google Nav Bar (`google_nav_bar`).
-   **Animations:** `flutter_animate` for smooth UI transitions.

### File Structure
-   `lib/pages`:  UI Screens (Home, Login, Pets, etc.)
-   `lib/services`: Logic layers (AuthService, DatabaseService).
-   `lib/models`: Data classes (Pet, Event).
-   `lib/widgets`: Reusable UI components.

## 🔧 Setup & Compilation
1.  **Dependencies:** Run `flutter pub get` to install packages (`hive`, `provider`, `url_launcher`, etc.).
2.  **Assets:** Ensure `lib/images/` contains required assets (logos, hero banners).
3.  **Run:** Execute `flutter run` on Android/iOS Emulator or Web.
