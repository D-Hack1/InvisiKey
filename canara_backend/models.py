from sqlalchemy import Column, Integer, String, JSON, ForeignKey, Boolean, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    secret_button = Column(String, nullable=True)  # Store the user's selected button
    
    # Lockout fields
    is_locked = Column(Boolean, default=False)
    locked_at = Column(DateTime, nullable=True)
    lockout_reason = Column(String, nullable=True)  # 'pin_failed' or 'rhythm_failed'
    
    # Failed attempt counters
    pin_failed_attempts = Column(Integer, default=0)
    rhythm_failed_attempts = Column(Integer, default=0)
    
    # Last failed attempt timestamps
    last_pin_failure = Column(DateTime, nullable=True)
    last_rhythm_failure = Column(DateTime, nullable=True)

    # Transaction lockout fields
    txn_pin_failed_attempts = Column(Integer, default=0)
    txn_rhythm_failed_attempts = Column(Integer, default=0)
    txn_locked_at = Column(DateTime, nullable=True)
    txn_lockout_reason = Column(String, nullable=True)

    # Relationship to rhythm samples
    rhythm_samples = relationship('RhythmSample', back_populates='user', cascade='all, delete-orphan')

class RhythmSample(Base):
    __tablename__ = 'rhythm_samples'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    intervals = Column(JSON, nullable=False)  # List of tap intervals (ms)
    label = Column(String, default='valid_user')  # 'valid_user' or 'impostor'

    user = relationship('User', back_populates='rhythm_samples')
