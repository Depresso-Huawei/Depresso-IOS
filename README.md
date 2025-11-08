[README.md](https://github.com/user-attachments/files/23434347/README.md)

# Depresso

<p align="center">
  <img width="1024" height="1024" alt="dark_depresso_logo" src="https://github.com/user-attachments/assets/72e94903-6420-41e2-8e4c-a855c130c1c7" />
</p>

<p align="center">
  <strong>A mental wellness companion for the modern age.</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

---

## Introduction

Depresso is a comprehensive iOS application designed to be a supportive companion for individuals navigating the complexities of mental wellness. It provides a suite of tools to help users track their mood, understand their emotional patterns, and connect with a supportive community. By leveraging cutting-edge technology, from on-device machine learning to a robust backend infrastructure, Depresso offers a personalized and data-driven approach to mental self-care.

## Features

*   **AI-Powered Journaling:** A private and secure journal where users can express their thoughts and feelings. An integrated AI companion offers supportive and empathetic responses, helping users to reflect and reframe their thoughts.
*   **Comprehensive Dashboard:** A holistic overview of the user's mental wellness journey. The dashboard displays:
    *   **Today's Vitals:** At-a-glance metrics for steps, active energy, and heart rate.
    *   **Mood Trend:** A chart of the user's daily PHQ-8 assessment scores, providing a visual representation of their mood over time.
    *   **Weekly Activity Charts:** Detailed charts for weekly steps, active energy, and heart rate.
*   **Daily Assessments:** Users can complete a daily PHQ-8 questionnaire to track their mood and generate a "Mood Trend" score.
*   **Supportive Community:** A safe and anonymous space for users to share their experiences, offer support, and connect with others who are on a similar journey.
*   **Wellness Tasks:** A curated list of wellness tasks to help users build healthy habits and improve their mental well-being.
*   **Support Resources:** A collection of helpful articles, videos, and hotlines for users who need additional support.

## Tech Stack

### iOS App (Frontend)

*   **SwiftUI:** For building a modern, declarative, and responsive user interface.
*   **The Composable Architecture (TCA):** A state management library that provides a consistent and predictable way to build complex applications.
*   **SwiftData:** For on-device persistence of chat history, posts, and other data.
*   **HealthKit:** To access health and activity data from the user's device.
*   **CoreMotion:** To collect motion data for behavioral analysis.
*   **Charts:** To create beautiful and informative charts for the dashboard.

### Backend

*   **Node.js & Express:** For building a fast, scalable, and reliable REST API.
*   **PostgreSQL:** A powerful, open-source object-relational database system.
*   **pg:** A Node.js module for interfacing with the PostgreSQL database.
*   **dotenv:** For managing environment variables.
*   **axios:** For making HTTP requests to the AI service.

### AI Service

*   **Huawei/Qwen:** A large language model used to power the AI companion in the journaling feature.

## Getting Started

To get the Depresso project up and running on your local machine, follow these steps.

### Prerequisites

*   **macOS:** With Xcode installed.
*   **Homebrew:** The missing package manager for macOS.
*   **Node.js:** A JavaScript runtime built on Chrome's V8 JavaScript engine.
*   **PostgreSQL:** A powerful, open-source object-relational database system.

### 1. Clone the Repository

```bash
git clone https://github.com/Depresso-Huawei/Depresso-IOS
cd <your-repository-directory>
```

### 2. Set up the Database

1.  **Install and start PostgreSQL using Homebrew:**
    ```bash
    brew install postgresql
    brew services start postgresql
    ```

2.  **Create the database:**
    ```bash
    createdb depresso_db
    ```

3.  **Create a user and grant privileges:**
    ```bash
    psql depresso_db
    ```
    In the `psql` shell, run:
    ```sql
    CREATE USER your_username WITH PASSWORD 'your_password';
    GRANT ALL PRIVILEGES ON DATABASE depresso_db TO your_username;
    \q
    ```

4.  **Create the database schema and seed the data:**
    ```bash
    psql -U your_username -d depresso_db -f "Depresso/depresso-backend/schema.sql"
    psql -U your_username -d depresso_db -f "Depresso/depresso-backend/seed.sql"
    ```

### 3. Set up the Backend

1.  **Navigate to the backend directory:**
    ```bash
    cd "Depresso/depresso-backend"
    ```

2.  **Install the dependencies:**
    ```bash
    npm install
    ```

3.  **Create a `.env` file:**
    Create a file named `.env` in the `depresso-backend` directory and add the following, replacing the values with your own:
    ```
    DB_USER=your_username
    DB_HOST=localhost
    DB_DATABASE=depresso_db
    DB_PASSWORD=your_password
    DB_PORT=5432
    QWEN_API_KEY=your_qwen_api_key
    ```

4.  **Start the backend server:**
    ```bash
    npm start
    ```
    The server should now be running on `http://localhost:3000`.

### 4. Set up the iOS App

1.  **Configure the API client:**
    Open the `Depresso` project in Xcode. In the file `Depresso/Features/Dashboard/Core/Network/APIClient.swift`, update the `baseURL` to point to your local machine's IP address. This is necessary for running the app on a physical device.
    ```swift
    // In APIClient.swift
    enum APIConfig {
        // When testing on physical device, use your Mac's IP:
        static let baseURL = "http://your_mac_ip_address:3000/api/v1"
    }
    ```

2.  **Run the app:**
    Select your target device and run the app from Xcode.

## Screenshots

*Add some screenshots of your app here to showcase the UI.*

| Dashboard | Journal | Community |
| :---: | :---: | :---: |
| ![IMG_6408](https://github.com/user-attachments/assets/698066df-5220-4d9e-a500-9cd58de3254d)| ![IMG_6409](https://github.com/user-attachments/assets/69cb7ee3-d303-4394-8b74-2f2ecad186f2) |  ![IMG_6410](https://github.com/user-attachments/assets/f0666225-5882-4400-95c2-65377024c7b0) |


## Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
