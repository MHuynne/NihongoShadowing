from fastapi import FastAPI
from dotenv import load_dotenv
import os

# Tải file .env lên hệ thống trước khi nạp database & routers
load_dotenv()

from database import engine, Base

# Import all models here so SQLAlchemy knows them before create_all
import models 
from models import shadowing_topic, shadowing_segment, shadowing_result, lesson, roleplay

# Create all database tables
Base.metadata.create_all(bind=engine)

def seed_roleplay_scenarios():
    from database import SessionLocal
    from models.roleplay import RoleplayScenario
    db = SessionLocal()
    try:
        scenarios = db.query(RoleplayScenario).all()
        if not scenarios:
            print("Seeding default Roleplay Scenarios...")
            default_scenarios = [
                RoleplayScenario(
                    title="Phỏng vấn xin việc (面接)",
                    description="Bạn là một ứng viên phần mềm đang tham gia phỏng vấn tại một công ty IT Nhật Bản. Hãy thể hiện mình là một người chuyên nghiệp.",
                    icon_url="https://cdn-icons-png.flaticon.com/512/942/942748.png"
                ),
                RoleplayScenario(
                    title="Xin lỗi vì đi làm muộn (遅刻の謝罪)",
                    description="Bạn đi làm muộn do tàu điện bị trễ. Bạn cần báo cáo và xin lỗi sếp lớn tại công ty một cách lịch sự.",
                    icon_url="https://cdn-icons-png.flaticon.com/512/942/942751.png"
                ),
                RoleplayScenario(
                    title="Gọi món tại nhà hàng (レストラン)",
                    description="Bạn đang ở một nhà hàng Nhật Bản. Bạn muốn hỏi nhân viên về các món đặc biệt và gọi món.",
                    icon_url="https://cdn-icons-png.flaticon.com/512/942/942766.png"
                )
            ]
            db.add_all(default_scenarios)
            db.commit()
    finally:
        db.close()

seed_roleplay_scenarios()

# Import routers
from routers import shadowing_topic as router_topic
from routers import shadowing_result as router_result
from routers import lesson as router_lesson
from routers import roleplay as router_roleplay

app = FastAPI(
    title="Japanese Learning Backend API",
    description="API for Japanese Learning App using FastAPI and MySQL",
    version="1.0.0"
)

# Include separated routers
app.include_router(router_topic.router)
app.include_router(router_result.router)
app.include_router(router_lesson.router)
app.include_router(router_roleplay.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Japanese Learning API"}
