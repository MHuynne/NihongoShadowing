from fastapi import FastAPI
from database import engine, Base

# Import all models here so SQLAlchemy knows them before create_all
import models 
from models import shadowing_topic, shadowing_segment, shadowing_result, lesson

# Create all database tables
Base.metadata.create_all(bind=engine)

# Import routers
from routers import shadowing_topic as router_topic
from routers import shadowing_result as router_result
from routers import lesson as router_lesson

app = FastAPI(
    title="Japanese Learning Backend API",
    description="API for Japanese Learning App using FastAPI and MySQL",
    version="1.0.0"
)

# Include separated routers
app.include_router(router_topic.router)
app.include_router(router_result.router)
app.include_router(router_lesson.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Japanese Learning API"}
