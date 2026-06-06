# Web-Based Capstone Project Monitoring System

A web-based system to monitor capstone projects, classify them into common domains, and provide role-based views for Admin, Adviser, and Student.

## Getting Started

This repository contains a Flutter front-end prototype for the Capstone Project Monitoring System. It demonstrates a simple home screen with roles and a classification list.

A few resources to get you started if you want to run or extend the project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Backend (Node.js)

A minimal Express backend is included at `backend/server.js`. It provides simple in-memory storage for sample projects and a `/classify` endpoint that returns a guessed domain.

To run the backend (requires Node.js):

```bash
cd backend
npm install
npm start
```

The backend listens on port `3000` by default. The Flutter front-end expects it at `http://localhost:3000`.

## Run the Flutter front-end (web)

From the project root:

```bash
flutter pub get
flutter run -d chrome
```

Notes:
- If you run the frontend on web you may need to allow CORS for the backend (the included backend enables `cors`).
- This prototype uses a simple keyword-based classifier on the backend; replace it with your own ML/service when ready.
