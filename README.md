# PrototypeBank

PrototypeBank is a modern, experimental banking app that uses rhythm-based authentication and a secret button as a second factor, built with Flutter (frontend) and FastAPI (Python backend). It features secure login, PIN and rhythm-based transaction verification, and a Postgres (Neon) backend.

## Features
- **Rhythm-based authentication**: Users tap a rhythm on a secret button as part of login and transaction verification.
- **Secret button**: During signup, users select a button; only tapping the correct button with the correct rhythm allows access.
- **PIN verification**: PIN required for sensitive actions (e.g., transfers).
- **Account lockout**: After 3 failed attempts (PIN or rhythm), the account is locked for security.
- **Email notification**: (Recommended) Notify users if their account is locked due to failed attempts.
- **Modern Flutter UI**: Clean, user-friendly, and secure.

## Security Features

### Account Lockout Mechanism
The app implements a comprehensive security system to prevent brute-force attacks:

#### **1. Rhythm Verification: 3 Attempts, Then Lock**
- Users are allowed 3 attempts to verify their rhythm
- After 3 failures, the account is locked
- Lockout reason is tracked as "rhythm_failed"

#### **2. PIN Entry: 3 Attempts, Then Lock**
- Users are allowed 3 attempts to enter their PIN
- After 3 failures, the account is locked
- Lockout reason is tracked as "pin_failed"

#### **3. Account Lockout and Email Notification**
- When an account is locked, the user receives an email notification
- The account remains locked until the lockout period expires or support unlocks it
- Lockout timestamp and reason are recorded
- Failed attempt counters are tracked separately for PIN and rhythm

## Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI (Python)
- **Database**: PostgreSQL (Neon)
- **ML**: scikit-learn (for rhythm verification)
- **Email**: aiosmtplib (for lockout notifications)

## Getting Started

### Prerequisites
- Python 3.8+
- Flutter 3.0+
- PostgreSQL database (Neon or local)

### Backend Setup (FastAPI)
1. Navigate to `canara_backend/`:
   ```sh
   cd canara_backend
   ```
2. Install dependencies:
   ```sh
   pip install -r requirements.txt
   ```
3. Set up your environment variables in a `.env` file:
   ```env
   DATABASE_URL=postgresql://user:password@host:port/dbname
   JWT_SECRET=your_secret_key
   SMTP_USERNAME=your_email@gmail.com
   SMTP_PASSWORD=your_app_password
   ```
4. Run database migration to add lockout fields:
   ```sh
   python migrate_lockout_fields.py
   ```
5. Start the backend:
   ```sh
   uvicorn main:app --reload
   ```

### Frontend Setup (Flutter)
1. Navigate to the project root:
   ```sh
   cd prototypebank
   ```
2. Install Flutter dependencies:
   ```sh
   flutter pub get
   ```
3. Run the app:
   ```sh
   flutter run -d windows  # or your target device
   ```

### Database Setup
- The backend expects a PostgreSQL database. You can use [Neon](https://neon.tech/) or a local Postgres instance.
- Tables are auto-created by SQLAlchemy on first run, but migrations are recommended for production.

## Environment Variables
- `DATABASE_URL`: Your Postgres connection string
- `JWT_SECRET`: Secret key for JWT tokens
- `SMTP_USERNAME`: Gmail address for sending lockout notifications
- `SMTP_PASSWORD`: Gmail app password (not regular password)

## API Endpoints

### Authentication
- `POST /login` - User login with lockout protection
- `POST /signup` - User registration
- `GET /api/user/me` - Get current user info

### Security
- `POST /verify-tap` - Rhythm verification with lockout tracking
- `GET /api/user/lockout-status` - Get user lockout status

## Security Best Practices Implemented

1. **Rate Limiting**: 3 attempts maximum for both PIN and rhythm verification
2. **Account Lockout**: Automatic lockout after failed attempts
3. **Email Notifications**: Users are notified when their account is locked
4. **Audit Trail**: All lockout events are logged with timestamps
5. **Separate Counters**: PIN and rhythm failures are tracked independently
6. **JWT Authentication**: Secure token-based session management

## How to Use

### For Users
1. **Signup**: Create account with username, email, password, and rhythm samples
2. **Login**: Enter credentials, then tap rhythm on secret button
3. **Security**: If you fail 3 times, your account will be locked
4. **Recovery**: Contact support if your account is locked

## How to Contribute
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License
This project is licensed under the MIT License.
