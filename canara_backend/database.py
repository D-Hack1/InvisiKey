from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Use Neon connection string with only sslmode=require
SQLALCHEMY_DATABASE_URL = "postgresql://neondb_owner:npg_5q6JaPZDlYvV@ep-solitary-credit-a9fbcrqn-pooler.gwc.azure.neon.tech/neondb?sslmode=require"

engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Import RhythmSample to ensure table creation
try:
    from models import RhythmSample
except ImportError:
    pass
