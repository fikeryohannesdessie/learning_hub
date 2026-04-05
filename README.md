# Cultural Heritage Preservation App (CHPA)

## Project Overview

The Cultural Heritage Preservation App (CHPA) is a platform designed to help users upload, share, and explore various cultural and heritage files, including documents (PDF), images (PNG), audio (MP3), and video (MP4). The application supports a hierarchy of user roles—Viewer, Researcher, and Administrator—each with different access permissions. The goal is to facilitate the preservation and dissemination of cultural heritage materials in a secure, organized, and collaborative environment.

## Team Members

| Full Name           | ID  |
|---------------------|------------------|
|                     |                  |
|                     |                  |
|                     |                  |



## Features

### 1. Heritage File Management (CRUD)
- Upload heritage files (PDF, PNG, MP3, MP4)
- View/download files uploaded by others
- Edit file metadata (title, description, tags, etc.)
- Delete files (with appropriate permissions)

### 2. User Roles & Access Control
- **Viewer:** Can browse and view/download public heritage files
- **Researcher:** Can upload new files, edit their own uploads, and access additional research features
- **Administrator:** Full access, including managing users, approving uploads, and deleting any file

### 3. Authentication & Authorization
- User signup, login, and logout
- Delete account
- Role-based access to features and screens

### 4. Backend (REST API)
- Serves the frontend with endpoints for file management, user management, and authentication/authorization
- Runs locally (not hosted on the internet)

### 5. Testing
- Widget, unit, and integration testing for both frontend and backend components

## Architecture

The project follows Domain-Driven Design (DDD) principles and is structured according to the recommended architecture:

- **Presentation Layer:** Widgets, UI, navigation, and state management
- **Application Layer:** BLoCs (Business Logic Components) or use cases
- **Domain Layer:** Entities, value objects, and business logic
- **Infrastructure Layer:** Repositories, data providers, API, and local database

See the DDD Architecture [here](https://resocoder.com/wp-content/uploads/2020/03/DDD-Flutter1-Diagram-v3.svg).

## Additional Notes
- The project does **not** use Firebase/Firestore or any cloud backend for authentication or data storage.
- The REST API and database run locally.
- All features and requirements are documented in this README.

---
