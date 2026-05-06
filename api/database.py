from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Config your MySQL database connection here
# Format: "mysql+pymysql://<username>:<password>@<host>:<port>/<database_name>"
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:1234@localhost:3306/nihongo_learning"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency to get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
