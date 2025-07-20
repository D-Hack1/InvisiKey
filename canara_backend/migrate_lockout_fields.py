#!/usr/bin/env python3
"""
Migration script to add lockout fields to existing user tables.
Run this script after updating the models to add the new lockout-related columns.
"""

import os
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from database import SQLALCHEMY_DATABASE_URL

def migrate_lockout_fields():
    """Add lockout fields to existing user table"""
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    
    with engine.connect() as connection:
        # Check if columns already exist
        result = connection.execute(text("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users' 
            AND column_name IN ('is_locked', 'locked_at', 'lockout_reason', 'pin_failed_attempts', 'rhythm_failed_attempts', 'last_pin_failure', 'last_rhythm_failure')
        """))
        
        existing_columns = [row[0] for row in result.fetchall()]
        
        # Add missing columns
        if 'is_locked' not in existing_columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN is_locked BOOLEAN DEFAULT FALSE"))
            print("Added is_locked column")
        
        if 'locked_at' not in existing_columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN locked_at TIMESTAMP"))
            print("Added locked_at column")
        
        if 'lockout_reason' not in existing_columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN lockout_reason VARCHAR"))
            print("Added lockout_reason column")
        
        if 'pin_failed_attempts' not in existing_columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN pin_failed_attempts INTEGER DEFAULT 0"))
            print("Added pin_failed_attempts column")
        
        if 'rhythm_failed_attempts' not in existing_columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN rhythm_failed_attempts INTEGER DEFAULT 0"))
            print("Added rhythm_failed_attempts column")
        
        if 'last_pin_failure' not in existing_columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN last_pin_failure TIMESTAMP"))
            print("Added last_pin_failure column")
        
        if 'last_rhythm_failure' not in existing_columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN last_rhythm_failure TIMESTAMP"))
            print("Added last_rhythm_failure column")
        
        if 'txn_pin_failed_attempts' not in existing_columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN txn_pin_failed_attempts INTEGER DEFAULT 0"))
            print("Added txn_pin_failed_attempts column")
        if 'txn_rhythm_failed_attempts' not in existing_columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN txn_rhythm_failed_attempts INTEGER DEFAULT 0"))
            print("Added txn_rhythm_failed_attempts column")
        if 'txn_locked_at' not in existing_columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN txn_locked_at TIMESTAMP"))
            print("Added txn_locked_at column")
        if 'txn_lockout_reason' not in existing_columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN txn_lockout_reason VARCHAR"))
            print("Added txn_lockout_reason column")
        
        connection.commit()
        print("Migration completed successfully!")

if __name__ == "__main__":
    try:
        migrate_lockout_fields()
    except Exception as e:
        print(f"Migration failed: {e}")
        sys.exit(1) 