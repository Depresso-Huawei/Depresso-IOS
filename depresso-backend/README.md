# Depresso Backend Setup

This guide provides step-by-step instructions to set up and run the Depresso backend server on a Mac.

### Step 1: Install PostgreSQL

If you don't have Homebrew, install it first:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then, install PostgreSQL:
```bash
brew install postgresql
```

### Step 2: Start PostgreSQL Service

To have PostgreSQL start automatically on login:
```bash
brew services start postgresql
```

### Step 3: Create the Database and User

1.  Connect to the default `postgres` database:
    ```bash
    psql postgres
    ```

2.  Create your user and database. The credentials should match what you have in your `.env` file.
    ```sql
    CREATE ROLE elamir WITH LOGIN PASSWORD '@Amir123';
    CREATE DATABASE depresso_db OWNER elamir;
    ```

3.  Connect to your new database:
    ```sql
    \c depresso_db
    ```

4.  Run the schema file to create all the tables:
    ```sql
    \i '/Users/elamir/Desktop/Depresso project with Documentaiton/Depresso/depresso-backend/schema.sql'
    ```

5.  Exit the PostgreSQL prompt:
    ```sql
    \q
    ```

### Step 4: Install Dependencies

Navigate to the backend directory and install the Node.js dependencies:
```bash
cd '/Users/elamir/Desktop/Depresso project with Documentaiton/Depresso/depresso-backend'
npm install
```

### Step 5: Start the Development Server

Run the following command to start the local server with `nodemon`:
```bash
npm run dev
```

The server will be running at `http://localhost:3000` and will automatically restart when you save changes.
