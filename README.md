# 🩺 Resident Feedback App

> ⚠️ **Not Open Source — View Only**  
> This repository is provided **for portfolio review**. You may **view** the code to evaluate my work.  
> You may **not** use, copy, modify, or distribute any part of this project.

## 📱 Overview

The **Resident Feedback App** enables surgeons to log structured feedback for residents and fellows directly from their device.  
It provides a secure, role-based experience with admin controls, Face ID authentication, and real-time data sync.

### Core Features
- 🔐 **Face ID / Touch ID Login** – Biometric unlock via Secure Enclave–protected tokens.
- 👨‍⚕️ **Resident Management** – Add, update, or deactivate residents with automatic list refresh.
- 🧾 **Assessment Wizard** – Guided flow for new evaluations with complexity & trust ratings.
- ⚙️ **Role-Based Access** – Surgeons, Residents, and Admins have tailored permissions.
- 🌙 **Appearance Settings** – System, light, or dark mode.
- ☁️ **Full API Integration** – SwiftUI frontend powered by a TypeScript/Express + MongoDB backend.

---

## 🧩 Architecture

### App (iOS – SwiftUI)
| Layer | Key Components |
|-------|----------------|
| **UI** | `LoginView`, `RootTabView`, `SettingsView`, `ResidentsListView`, `NewAssessmentWizard` |
| **Data** | `APIClient`, `AuthStore`, `AssessmentViewModel` |
| **Security** | `Keychain`, `BiometricKeychain`, `BiometricAuth` |

### API (Server)
> [Separate repository](https://github.com/simonbalanoff/ResidentFeedback-API) – Node.js / Express / MongoDB  
> Endpoints include `/auth/login`, `/auth/register`, `/auth/refresh`, `/residents`, `/assessments`

---

## 🔒 Authentication Flow

1. **Login with Email & Password**  
   - Access & Refresh tokens stored securely via `Keychain`.
2. **Subsequent Login via Face ID**  
   - Refresh token retrieved from Secure Enclave through `BiometricKeychain`.
3. **Token Refresh**  
   - Access tokens automatically renewed via `APIClient.refresh()`.

---

## 📸 Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/8a15a4e4-9514-47c2-a1c1-9e4f6f8911f8" width="30%" alt="Login Screen" />
  <img src="https://github.com/user-attachments/assets/675fba6f-9087-4eff-8653-b4e5e4a58369" width="30%" alt="Residents List" />
  <img src="https://github.com/user-attachments/assets/432e48d8-877d-43bc-acad-778abf7828c2" width="30%" alt="Assessment Wizard" />
</p>
