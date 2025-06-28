# AIPSQS - AI-Powered Smart Quiz System

AIPSQS (AI-Powered Smart Quiz System for Enhanced Learning) is a Flutter-based mobile and web application that leverages AI and Natural Language Processing (NLP) to dynamically generate personalized quizzes, provide real-time feedback, and track learner performance across various educational levels.

---

## 📱 Features

- 🔐 Secure user authentication (Student & Teacher roles)
- 🧠 AI-powered quiz generation using Cloudflare Workers AI
- 📊 Real-time feedback and performance analytics
- 🔄 Retake quizzes and review attempts
- 📂 Role-based dashboards for students and teachers
- 🎨 Clean, responsive UI built with Flutter
- ☁️ Firebase for authentication, storage, and real-time updates

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter |
| Backend | Firebase (Auth, Firestore) |
| AI Integration | Workers AI (Cloudflare) |
| Architecture | MVC (Model-View-Controller) |

---

## 📸 Screenshots

- Student Dashboard
- Teacher Dashboard
- Quiz Generation & Submission
- Quiz Feedback & History
- Profile Management

(*See `/screens/` directory or documentation for visual examples.*)

---

## 🧪 Testing

The system was tested using:
- ✅ Black Box Testing (Input/Output validation, error messages)
- ✅ White Box Testing (Controller logic, AI integration)
- ✅ User Acceptance Testing (Google Form responses)

> **Test coverage includes:** registration, login, quiz creation, participation, feedback, profile updates, and analytics.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Firebase Project (Authentication, Firestore)
- Cloudflare Workers AI API access

### Installation
```bash
git clone https://github.com/fqmes/aipsqs.git
cd aipsqs
flutter pub get

