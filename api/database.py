import os

from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from sqlalchemy.orm import declarative_base, sessionmaker
from dotenv import load_dotenv


load_dotenv()

MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "1234")
MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")
MYSQL_PORT = int(os.getenv("MYSQL_PORT", "3306"))
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "nihongo_learning1")
DATABASE_BACKEND = os.getenv("DATABASE_BACKEND", "auto").lower()
SQLITE_DATABASE = os.getenv(
    "SQLITE_DATABASE",
    os.path.join(os.path.dirname(__file__), "nihongo_learning1.db"),
)


def _server_url() -> URL:
    return URL.create(
        "mysql+pymysql",
        username=MYSQL_USER,
        password=MYSQL_PASSWORD or None,
        host=MYSQL_HOST,
        port=MYSQL_PORT,
    )


def _database_url() -> URL:
    return _server_url().set(database=MYSQL_DATABASE)


def _bootstrap_database() -> bool:
    bootstrap_engine = create_engine(_server_url(), isolation_level="AUTOCOMMIT")
    try:
        with bootstrap_engine.connect() as connection:
            connection.execute(
                text(
                    f"CREATE DATABASE IF NOT EXISTS `{MYSQL_DATABASE}` "
                    "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
                )
            )
        return True
    except Exception as exc:
        print(f"[database] MySQL is unavailable: {exc}")
        return False
    finally:
        bootstrap_engine.dispose()


def _sqlite_url() -> str:
    return f"sqlite:///{SQLITE_DATABASE.replace(os.sep, '/')}"


def _create_engine():
    if DATABASE_BACKEND == "sqlite":
        print(f"[database] Using SQLite database at {SQLITE_DATABASE}")
        return create_engine(_sqlite_url(), connect_args={"check_same_thread": False})

    if DATABASE_BACKEND == "mysql" or _bootstrap_database():
        return create_engine(_database_url(), pool_pre_ping=True)

    print(f"[database] Falling back to SQLite database at {SQLITE_DATABASE}")
    return create_engine(_sqlite_url(), connect_args={"check_same_thread": False})


engine = _create_engine()
SQLALCHEMY_DATABASE_URL = str(engine.url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
