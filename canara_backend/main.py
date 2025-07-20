from fastapi import FastAPI, Depends, HTTPException, Header, Request, Query
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from database import SessionLocal, engine
from models import Base, User, RhythmSample
from passlib.context import CryptContext
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
import uuid
from fastapi import Body
from sqlalchemy.exc import IntegrityError
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.exceptions import NotFittedError
import traceback
import jwt
from datetime import datetime, timedelta
import os

# Optional email imports
try:
    import aiosmtplib
    from email.mime.text import MIMEText
    from email.mime.multipart import MIMEMultipart
    EMAIL_AVAILABLE = True
except ImportError:
    EMAIL_AVAILABLE = False
    print("Warning: Email functionality not available. Install aiosmtplib for email notifications.")


# Initialize FastAPI app
app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to specific domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create database tables
Base.metadata.create_all(bind=engine)

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

JWT_SECRET = "your_secret_key_here"  # Change this to a secure random value in production
JWT_ALGORITHM = "HS256"
JWT_EXP_DELTA_SECONDS = 3600  # 1 hour

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Pydantic models
class RhythmSampleData(BaseModel):
    intervals: List[int]
    label: Optional[str] = 'valid_user'

class SignUpData(BaseModel):
    username: str
    email: EmailStr
    password: str
    rhythm_samples: List[RhythmSampleData]  # List of rhythm samples
    secret_button: str  # The user's selected button

class LoginData(BaseModel):
    username: str
    password: str

from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi import Security

security = HTTPBearer()

def get_current_user_id(credentials: HTTPAuthorizationCredentials = Security(security)):
    print("DEBUG: get_current_user_id called")
    try:
        token = credentials.credentials
        print("DEBUG: Token received:", token)
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        print("DEBUG: Payload decoded:", payload)
        return payload["user_id"]
    except jwt.ExpiredSignatureError:
        print("Token expired")
        raise HTTPException(status_code=401, detail="Token expired")
    except Exception as e:
        print("JWT decode error:", e)
        raise HTTPException(status_code=401, detail="Invalid token")

# Utility functions
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def extract_features(intervals):
    arr = np.array(intervals)
    return [
        np.sum(arr),                # total duration
        np.mean(arr),               # average interval
        np.std(arr),                # std deviation
        np.var(arr),                # variance
        len(arr),                   # number of taps
        np.min(arr),                # min interval
        np.max(arr),                # max interval
    ]

def to_py(val):
    import numpy as np
    if isinstance(val, np.generic):
        return val.item()
    if isinstance(val, list):
        return [to_py(x) for x in val]
    if isinstance(val, dict):
        return {k: to_py(v) for k, v in val.items()}
    return val

def auto_unlock_if_time_passed(user, db, minutes=5):
    if user.is_locked and user.locked_at:
        from datetime import datetime, timedelta
        if datetime.utcnow() - user.locked_at >= timedelta(minutes=minutes):
            user.is_locked = False
            user.locked_at = None
            user.lockout_reason = None
            user.pin_failed_attempts = 0
            user.rhythm_failed_attempts = 0
            user.last_pin_failure = None
            user.last_rhythm_failure = None
            db.commit()
            print(f"User {user.username} auto-unlocked after {minutes} minutes.")

def reset_failed_attempts(user: User, success_type: str, db: Session):
    """Reset failed attempts when user succeeds"""
    if success_type == "pin":
        user.pin_failed_attempts = 0
        user.last_pin_failure = None
    elif success_type == "rhythm":
        user.rhythm_failed_attempts = 0
        user.last_rhythm_failure = None
    db.commit()

def check_and_handle_txn_lockout(user: User, failure_type: str, db: Session):
    from datetime import datetime, timedelta
    max_attempts = 3
    # Auto-unlock if 5 minutes have passed
    if user.txn_locked_at and user.txn_locked_at is not None:
        if datetime.utcnow() - user.txn_locked_at >= timedelta(minutes=5):
            user.txn_pin_failed_attempts = 0
            user.txn_rhythm_failed_attempts = 0
            user.txn_locked_at = None
            user.txn_lockout_reason = None
            db.commit()
    # If still locked, return lockout
    if user.txn_locked_at:
        return True, f"Transaction locked due to multiple failed {user.txn_lockout_reason} attempts at {user.txn_locked_at.strftime('%Y-%m-%d %H:%M:%S')}", 0
    # Increment counters
    if failure_type == "pin":
        user.txn_pin_failed_attempts += 1
        if user.txn_pin_failed_attempts >= max_attempts:
            user.txn_locked_at = datetime.utcnow()
            user.txn_lockout_reason = "pin"
            db.commit()
            return True, "Transaction locked due to multiple failed PIN attempts. Please try again after 5 minutes.", 0
        db.commit()
        return False, None, max_attempts - user.txn_pin_failed_attempts
    elif failure_type == "rhythm":
        user.txn_rhythm_failed_attempts += 1
        if user.txn_rhythm_failed_attempts >= max_attempts:
            user.txn_locked_at = datetime.utcnow()
            user.txn_lockout_reason = "rhythm"
            db.commit()
            return True, "Transaction locked due to multiple failed rhythm attempts. Please try again after 5 minutes.", 0
        db.commit()
        return False, None, max_attempts - user.txn_rhythm_failed_attempts
    db.commit()
    return False, None, max_attempts

def check_and_handle_lockout(user: User, failure_type: str, db: Session):
    from datetime import datetime
    max_attempts = 3
    if failure_type == "pin":
        user.pin_failed_attempts += 1
        user.last_pin_failure = datetime.utcnow()
        if user.pin_failed_attempts >= max_attempts:
            user.is_locked = True
            user.locked_at = datetime.utcnow()
            user.lockout_reason = "pin_failed"
            db.commit()
            return True, "Account locked due to multiple failed PIN attempts"
    elif failure_type == "rhythm":
        user.rhythm_failed_attempts += 1
        user.last_rhythm_failure = datetime.utcnow()
        if user.rhythm_failed_attempts >= max_attempts:
            user.is_locked = True
            user.locked_at = datetime.utcnow()
            user.lockout_reason = "rhythm_failed"
            db.commit()
            return True, "Account locked due to multiple failed rhythm attempts"
    db.commit()
    return False, None

def reset_txn_failed_attempts(user: User, success_type: str, db: Session):
    if success_type == "pin":
        user.txn_pin_failed_attempts = 0
    elif success_type == "rhythm":
        user.txn_rhythm_failed_attempts = 0
    db.commit()

@app.get("/")
def root():
    return {"message": "Canara Backend Running!"}

@app.post("/signup")
def signup(user: SignUpData, db: Session = Depends(get_db)):
    print(f"DEBUG: Received signup data: {user}")
    # Validate secret_button
    if not user.secret_button or not user.secret_button.strip():
        print("DEBUG: secret_button missing or empty!")
        raise HTTPException(status_code=422, detail="Secret button must be set")
    # Validate rhythm_samples
    if not user.rhythm_samples or not all(isinstance(s.intervals, list) and all(isinstance(i, int) for i in s.intervals) for s in user.rhythm_samples):
        print("DEBUG: rhythm_samples missing or invalid!")
        raise HTTPException(status_code=422, detail="Each rhythm sample must be a list of integers")

    # Check for existing user
    existing_user = db.query(User).filter(User.username == user.username).first()
    if existing_user:
        print("DEBUG: Username already exists!")
        raise HTTPException(status_code=400, detail="Username already exists")

    # Hash password and create user
    hashed_password = get_password_hash(user.password)
    db_user = User(
        username=user.username,
        email=user.email,
        password=hashed_password,
        secret_button=user.secret_button
    )
    print(f"DEBUG: Creating db_user: {db_user}")
    try:
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        print(f"DEBUG: db_user after commit: id={db_user.id}, secret_button={db_user.secret_button}")

        # Add rhythm samples
        for sample in user.rhythm_samples:
            print(f"DEBUG: Adding rhythm sample: {sample}")
            try:
                db_sample = RhythmSample(
                    user_id=db_user.id,
                    intervals=sample.intervals,
                    label=sample.label or 'valid_user'
                )
                db.add(db_sample)
            except Exception as sample_exc:
                print(f"DEBUG: Exception adding sample: {sample_exc}")
        db.commit()

        # Debug: print count of rhythm samples for this user
        count = db.query(RhythmSample).filter(RhythmSample.user_id == db_user.id).count()
        print(f"DEBUG: Rhythm samples in DB for user_id={db_user.id}: {count}")

        return {"message": "User signed up successfully"}
    except Exception as e:
        db.rollback()
        print("⚠️ Signup failed:", str(e))
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal Server Error")

@app.post("/login")
def login(data: LoginData, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == data.username).first()
    
    # Check if user exists
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # Auto-unlock if 5 minutes have passed
    auto_unlock_if_time_passed(user, db)
    
    # Check if account is locked
    if user.is_locked:
        lockout_message = f"Account locked due to multiple failed {user.lockout_reason} attempts"
        if user.locked_at:
            lockout_message += f" at {user.locked_at.strftime('%Y-%m-%d %H:%M:%S')}"
        raise HTTPException(status_code=423, detail=lockout_message)
    
    # Check password
    if not verify_password(data.password, user.password):
        # Track failed login attempt (treat as PIN failure)
        is_locked, lockout_message = check_and_handle_lockout(user, "pin", db)
        if is_locked:
            raise HTTPException(status_code=423, detail=lockout_message)
        
        # Return remaining attempts
        remaining_attempts = 3 - user.pin_failed_attempts
        raise HTTPException(
            status_code=401, 
            detail=f"Invalid credentials. {remaining_attempts} attempts remaining before account lockout."
        )

    # Reset failed attempts on successful login
    reset_failed_attempts(user, "pin", db)

    payload = {
        "user_id": user.id,
        "exp": datetime.utcnow() + timedelta(seconds=JWT_EXP_DELTA_SECONDS)
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

    return {
        "message": "Login successful",
        "access_token": token,
        "token_type": "bearer"
    }

@app.get("/api/user/me")
def get_current_user(user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    print(f"DEBUG: /api/user/me called with user_id={user_id}")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        print(f"DEBUG: User not found for user_id={user_id}")
        raise HTTPException(status_code=404, detail="User not found")
    rhythm_samples = [
        {"intervals": s.intervals, "label": s.label} for s in user.rhythm_samples
    ]
    print(f"DEBUG: Returning user info for user_id={user_id}, username={user.username}")
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "rhythm_samples": rhythm_samples,
        "secret_button": user.secret_button
    }

@app.post("/verify-tap")
def verify_tap_rhythm(
    tap_rhythm_attempt: List[int] = Body(...),
    button: str = Body(...),
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    try:
        print(f"DEBUG: user_id from JWT: {user_id}")
        user = db.query(User).filter(User.id == user_id).first()
        
        # Auto-unlock if 5 minutes have passed
        auto_unlock_if_time_passed(user, db)
        
        # Check if account is locked
        if user.is_locked:
            lockout_message = f"Account locked due to multiple failed {user.lockout_reason} attempts"
            if user.locked_at:
                lockout_message += f" at {user.locked_at.strftime('%Y-%m-%d %H:%M:%S')}"
            raise HTTPException(status_code=423, detail=lockout_message)
        
        if not user or not user.rhythm_samples:
            raise HTTPException(status_code=400, detail="No stored rhythm samples to compare")
        if button != user.secret_button:
            raise HTTPException(status_code=401, detail="Incorrect button selected for rhythm verification")

        # Get all samples
        valid_samples = [s.intervals for s in user.rhythm_samples if s.label == 'valid_user']
        impostor_samples = [s.intervals for s in user.rhythm_samples if s.label == 'impostor']
        if not valid_samples:
            raise HTTPException(status_code=400, detail="No valid_user rhythm samples found")

        # Prepare training data
        X = [extract_features(s) for s in valid_samples]
        y = [1] * len(valid_samples)
        if impostor_samples:
            X += [extract_features(s) for s in impostor_samples]
            y += [0] * len(impostor_samples)
        else:
            # If no impostor samples, use noisy versions of valid samples as negative class
            for s in valid_samples:
                noisy = np.array(s) + np.random.randint(-150, 150, size=len(s))
                X.append(extract_features(noisy.tolist()))
                y.append(0)

        # Train classifier
        clf = RandomForestClassifier(n_estimators=50, random_state=42)
        clf.fit(X, y)

        # Predict for attempt
        attempt_features = extract_features(tap_rhythm_attempt)
        pred = clf.predict([attempt_features])[0]
        proba = clf.predict_proba([attempt_features])[0][1]  # probability of valid_user
        threshold = 0.5  # Stricter ML threshold

        # Require minimum rhythm length
        if not tap_rhythm_attempt or len(tap_rhythm_attempt) < 3:
            # Count as a failed attempt
            is_locked, lockout_message = check_and_handle_lockout(user, "rhythm", db)
            if is_locked:
                raise HTTPException(status_code=423, detail=lockout_message)
            remaining_attempts = 3 - user.rhythm_failed_attempts
            raise HTTPException(status_code=400, detail=f"Rhythm attempt too short or empty. {remaining_attempts} attempts remaining before account lockout.")

        # Require the attempt to have the same number of intervals as stored samples
        expected_length = len(valid_samples[0])
        if len(tap_rhythm_attempt) != expected_length:
            # Count as a failed attempt
            is_locked, lockout_message = check_and_handle_lockout(user, "rhythm", db)
            if is_locked:
                raise HTTPException(status_code=423, detail=lockout_message)
            remaining_attempts = 3 - user.rhythm_failed_attempts
            raise HTTPException(status_code=400, detail=f"Rhythm attempt must have {expected_length} intervals. {remaining_attempts} attempts remaining before account lockout.")

        # Tolerance-based fallback
        def is_within_tolerance(stored, attempt, tolerance=100):
            print(f"DEBUG: Comparing stored={stored} to attempt={attempt} with tolerance={tolerance}")
            if len(stored) != len(attempt):
                print("DEBUG: Length mismatch")
                return False
            result = all(abs(a - b) <= tolerance for a, b in zip(stored, attempt))
            print(f"DEBUG: Result for this sample: {result}")
            return result

        match = proba > threshold
        fallback = False
        if not match:
            for s in valid_samples:
                if is_within_tolerance(s, tap_rhythm_attempt):
                    print("DEBUG: Fallback matched!")
                    match = True
                    fallback = True
                    break

        # Handle failed rhythm verification
        if not match:
            # Track failed rhythm attempt
            is_locked, lockout_message = check_and_handle_lockout(user, "rhythm", db)
            print(f"DEBUG: rhythm_failed_attempts={user.rhythm_failed_attempts}, is_locked={user.is_locked}")
            if is_locked:
                print(f"DEBUG: User {user.username} locked out due to rhythm failures at {user.locked_at}")
                raise HTTPException(status_code=423, detail=lockout_message)
            
            # Return remaining attempts
            remaining_attempts = 3 - user.rhythm_failed_attempts
            raise HTTPException(
                status_code=401, 
                detail=f"Rhythm verification failed. {remaining_attempts} attempts remaining before account lockout."
            )

        # Only reset failed attempts on successful rhythm verification
        if match:
            reset_failed_attempts(user, "rhythm", db)

        # If match is True, store the attempt as a new valid sample (if not already very close to an existing one)
        if match:
            # Only add if not already within 50ms of an existing sample
            is_duplicate = False
            for s in valid_samples:
                if len(s) == len(tap_rhythm_attempt) and all(abs(a - b) <= 50 for a, b in zip(s, tap_rhythm_attempt)):
                    is_duplicate = True
                    break
            if not is_duplicate:
                db.add(RhythmSample(user_id=user_id, intervals=tap_rhythm_attempt, label='valid_user'))
                db.commit()

        return {
            "match": bool(match),
            "probability": float(proba),
            "features": [float(x) for x in attempt_features],
            "valid_samples": [to_py(s) for s in valid_samples],
            "impostor_samples": [to_py(s) for s in impostor_samples],
            "note": "Matched by tolerance fallback" if fallback else "Matched by ML"
        }
    except Exception as e:
        print("Exception in /verify-tap:", e)
        raise

# Admin endpoint to unlock user account
@app.post("/admin/unlock-account")
def unlock_user_account(username: str, admin_password: str, db: Session = Depends(get_db)):
    """Admin endpoint to unlock a user account"""
    # Simple admin authentication (in production, use proper admin authentication)
    ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin123")
    
    if admin_password != ADMIN_PASSWORD:
        raise HTTPException(status_code=401, detail="Invalid admin credentials")
    
    user = db.query(User).filter(User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if not user.is_locked:
        return {"message": "Account is not locked"}
    
    # Unlock the account
    user.is_locked = False
    user.locked_at = None
    user.lockout_reason = None
    user.pin_failed_attempts = 0
    user.rhythm_failed_attempts = 0
    user.last_pin_failure = None
    user.last_rhythm_failure = None
    
    db.commit()
    
    return {
        "message": f"Account unlocked successfully for user {username}",
        "username": username,
        "unlocked_at": datetime.utcnow().isoformat()
    }

# Endpoint to get user lockout status
@app.get("/api/user/lockout-status")
def get_lockout_status(user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """Get current lockout status for the authenticated user"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "is_locked": user.is_locked,
        "locked_at": user.locked_at.isoformat() if user.locked_at else None,
        "lockout_reason": user.lockout_reason,
        "pin_failed_attempts": user.pin_failed_attempts,
        "rhythm_failed_attempts": user.rhythm_failed_attempts,
        "remaining_pin_attempts": max(0, 3 - user.pin_failed_attempts),
        "remaining_rhythm_attempts": max(0, 3 - user.rhythm_failed_attempts)
    }

class TransactionPinVerifyRequest(BaseModel):
    pin: str

class TransactionRhythmVerifyRequest(BaseModel):
    tap_rhythm_attempt: List[int]
    button: str

@app.post("/api/transaction/verify-pin")
def transaction_verify_pin(request: TransactionPinVerifyRequest, user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    # Check for transaction lockout
    is_locked, lockout_message, attempts_left = check_and_handle_txn_lockout(user, "pin", db)
    if is_locked:
        return {"success": False, "locked": True, "message": lockout_message, "attempts_left": 0}
    # Check PIN
    if not verify_password(request.pin, user.password):
        return {"success": False, "locked": False, "message": f"Incorrect PIN. {attempts_left} attempts left.", "attempts_left": attempts_left}
    # Success: reset PIN attempts
    reset_txn_failed_attempts(user, "pin", db)
    return {"success": True, "locked": False, "message": "PIN verified.", "attempts_left": 3}

@app.post("/api/transaction/verify-rhythm")
def transaction_verify_rhythm(request: TransactionRhythmVerifyRequest, user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    # Check for transaction lockout
    is_locked, lockout_message, attempts_left = check_and_handle_txn_lockout(user, "rhythm", db)
    if is_locked:
        return {"success": False, "locked": True, "message": lockout_message, "attempts_left": 0}
    # Rhythm verification logic (reuse from /verify-tap)
    valid_samples = [s.intervals for s in user.rhythm_samples if s.label == 'valid_user']
    if not valid_samples:
        return {"success": False, "locked": False, "message": "No valid_user rhythm samples found.", "attempts_left": attempts_left}
    expected_length = len(valid_samples[0])
    if not request.tap_rhythm_attempt or len(request.tap_rhythm_attempt) != expected_length:
        return {"success": False, "locked": False, "message": f"Rhythm attempt must have {expected_length} intervals. {attempts_left} attempts left.", "attempts_left": attempts_left}
    # ML verification
    X = [extract_features(s) for s in valid_samples]
    y = [1] * len(valid_samples)
    clf = RandomForestClassifier(n_estimators=50, random_state=42)
    clf.fit(X, y)
    attempt_features = extract_features(request.tap_rhythm_attempt)
    threshold = 0.5
    # Robust probability/match logic
    if len(clf.classes_) == 1:
        # Only one class present, so just check if prediction matches that class
        match = clf.predict([attempt_features])[0] == clf.classes_[0]
    else:
        proba = clf.predict_proba([attempt_features])[0][1]
        match = proba > threshold
    if not match:
        return {"success": False, "locked": False, "message": f"Wrong rhythm. {attempts_left} attempts left.", "attempts_left": attempts_left}
    # Success: reset rhythm attempts
    reset_txn_failed_attempts(user, "rhythm", db)
    return {"success": True, "locked": False, "message": "Rhythm verified.", "attempts_left": 3}

@app.get("/check-availability")
def check_availability(username: str = Query(None), email: str = Query(None), db: Session = Depends(get_db)):
    if username:
        user = db.query(User).filter(User.username == username).first()
        if user:
            return {"available": False, "field": "username"}
    if email:
        user = db.query(User).filter(User.email == email).first()
        if user:
            return {"available": False, "field": "email"}
    return {"available": True}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
