# CarbonGurukulam Store - POS System

A comprehensive Point of Sale (POS) and Store Management system built with Flutter and Firebase. Designed to handle store operations safely, transparently, and cleanly, ensuring robust offline/online functionality.

## 🚀 Key Features

### 🛒 Point of Sale (POS)
*   **Intuitive POS Interface:** A clean, easy-to-use cashier interface for processing daily transactions.
*   **Advanced Payment Modes:** Support for `Cash`, `Wallet`, and `Mixed` payment options, allowing students to pay partially in cash and draw the rest from their student wallet/debt.
*   **Transaction Voiding:** Dedicated functionality to securely Cancel/Void transactions, complete with reason logging to ensure financial accuracy.
*   **Receipt Generation:** Creates structured transaction receipts for every purchase.

### 👥 Student & Account Management
*   **Digital Wallets:** Securely track student balances and debts, functioning as an integrated ledger.
*   **Student Admissions:** Manage student information seamlessly.
*   **Dynamic Room Sharing Allocation:** Allows administrators to dictate custom room capacities to accommodate varying occupancy requirements across the platform.

### 📦 Inventory Management
*   **Real-time Stock Tracking:** Keep track of store products, costs, and availability.
*   **Stock Interventions:** Monitor when items are stocked into the store inventory. 

### 💸 Expenses Tracking
*   **Expense Logging:** Seamlessly add ad-hoc or standard product expenses, retaining details about cost, quantity, and dates.
*   **Granular History:** View a complete history of store expenditures directly integrated into accounting modules.

### 📊 Analytics & Reporting
*   **Detailed Analytics Dashboard:** Visualize store performance over time using interactive charts (`fl_chart`).
*   **Profit & Loss Reporting:** Advanced Profit and Loss metric tracking.
*   **CSV Exports:** Generate well-structured CSV exports that include comprehensive monthly breakdowns of expenses, sales, and total profit/loss margins for offline review and record keeping.

### 🔐 Audit Trail & Security
*   **Comprehensive Audit Logs:** Every critical action (`sale`, `recharge`, `edit`, `stock_in`, `expense`) is rigorously logged into an Audit collection. Tracks user operations, timestamps, and metadata to guarantee system accountability.
*   **Firebase Authentication:** Secure login system with role-based routing.
*   **Session Persistence:** Keeps the web and mobile sessions alive seamlessly across app restarts and browser refreshes.

### 🌐 Network Resilience
*   **Offline Global Overlay:** A premium, fully responsive "No Internet Connection" overlay seamlessly blocks interactions when the network drops, protecting against asynchronous data loss or corrupted POS states.

## 🛠 Tech Stack

*   **Frontend Framework:** Flutter (`^3.10.4`)
*   **Backend & Database:** Firebase (Cloud Firestore, Firebase Authentication, Firebase Core)
*   **State Management:** Riverpod (`flutter_riverpod`)
*   **Charting:** `fl_chart`
*   **Export/Sharing Utilities:** `csv`, `pdf`, `printing`, `share_plus`
*   **Connectivity:** `connectivity_plus`, `internet_connection_checker_plus`

## 🏗 Getting Started

### Prerequisites
*   Flutter SDK installed
*   Firebase project configured along with the necessary Firestore rules

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yaseen615/carbon-stores.git
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Initialize Firebase (Ensure the `firebase_options.dart` is correctly set up for Web/Mobile).
4. Run the project:
   ```bash
   flutter run
   ```
