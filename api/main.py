from fastapi import FastAPI
from database import engine, Base
from dotenv import load_dotenv

# Tải các biến môi trường từ file .env
load_dotenv()

# Import all models here so SQLAlchemy knows them before create_all
import models 
from models import shadowing_topic, shadowing_segment, shadowing_result, lesson

# Create all database tables
Base.metadata.create_all(bind=engine)

# Import routers
from routers import shadowing_topic as router_topic
from routers import shadowing_result as router_result
from routers import lesson as router_lesson
from routers import evaluation as router_evaluation
from routers import tts as router_tts

app = FastAPI(
    title="Japanese Learning Backend API",
    description="API for Japanese Learning App using FastAPI and MySQL",
    version="1.0.0"
)

from fastapi.middleware.cors import CORSMiddleware

# Cấu hình CORS để cho phép Flutter Web (và các client khác) truy cập API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Cho phép mọi truy cập (Có thể thay bằng danh sách host cụ thể khi deploy)
    allow_credentials=True,
    allow_methods=["*"],  # Cho phép tất cả các method (GET, POST, PUT, DELETE,...)
    allow_headers=["*"],  # Cho phép tất cả các header
)

# Include separated routers
app.include_router(router_topic.router)
app.include_router(router_result.router)
app.include_router(router_lesson.router)
app.include_router(router_evaluation.router)
app.include_router(router_tts.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Japanese Learning API"}
