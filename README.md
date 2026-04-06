# Learning Hub – Cultural Heritage Preservation App (CHPA)

## Project Overview

The **Learning Hub – Cultural Heritage Preservation App (CHPA)** is a platform designed to support learning, research, and preservation of cultural heritage materials. It allows users to upload, share, and explore various types of content including documents (PDF), images (PNG), audio (MP3), and video (MP4).

The system is built to serve as both:
- A **learning platform** for students and researchers  
- A **digital archive** for cultural heritage preservation  

It features a hierarchy of user roles—Viewer, Researcher, and Administrator—each with different access permissions. The goal is to create a secure, organized, and collaborative environment for both education and heritage preservation.

---

## Team Members

| Full Name            | ID              |
|----------------------|-----------------|
| Fiker Yohannes       | UGR/4617/16     |
| Amanuel Solomon      | UGR/0540/16     |
| Hermela Teklegebriel | UGR/5174/16     |
| Yohannes Gumeta      | UGR/4852/16     |
| Abel Begashaw        | ATR/8919/13     |

---

## Features

### 1. Learning & Heritage Content Management (CRUD)
- Upload learning and heritage materials (PDF, PNG, MP3, MP4)
- View and download shared resources
- Edit file metadata (title, description, tags, category)
- Delete content (based on permissions)

---

### 2. User Roles & Access Control

- **Viewer**
  - Browse and access public learning materials
  - View and download files

- **Researcher**
  - Upload new educational or heritage content
  - Edit their own uploads
  - Access extended research-related features

- **Administrator**
  - Full system control
  - Manage users and roles
  - Approve or remove content
  - Delete any file

---

### 3. Authentication & Authorization
- User registration (signup)
- Login and logout
- Delete account
- Role-based access control for all features

---

### 4. Backend (REST API)
- Provides endpoints for:
  - File management
  - User management
  - Authentication & authorization
- Runs locally (no cloud hosting)

---

### 5. Testing
- Widget testing (UI components)
- Unit testing (business logic)
- Integration testing (system workflows)

---

## Architecture

The project follows **Domain-Driven Design (DDD)** principles and is structured into the following layers:

- **Presentation Layer**
  - UI components, widgets, navigation, and state management

- **Application Layer**
  - Business logic (BLoC / use cases)

- **Domain Layer**
  - Core entities and business rules

- **Infrastructure Layer**
  - Repositories, APIs, and local database



---

## Additional Notes

- No Firebase or cloud services are used  
- All data and APIs run locally  
- Designed for both **educational use (Learning Hub)** and **cultural preservation (CHPA)**  
- Fully documented within this repository  

---

## Summary

This project combines:
- A **Learning Management System (LMS)-like platform**
- A **Cultural Heritage Archive System**

Making it a hybrid solution that supports:
- Learning
- Research
- Preservation
- Collaboration
