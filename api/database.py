from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Config your database connection here
# Cho môi trường Laragon: user mặc định là root, mật khẩu để trống.
# Bạn hãy chắc chắn đã bấm "Start All" trên Laragon và tạo database tên là "nihongo_learning" trong HeidiSQL nhé!
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:@localhost:3306/nihongo_learning"

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
