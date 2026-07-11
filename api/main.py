from fastapi import FastAPI
from database import engine, Base
from dotenv import load_dotenv


load_dotenv()


import models
from models import shadowing_topic, shadowing_segment, shadowing_result, lesson, user_progress, category, segment_topic


Base.metadata.create_all(bind=engine)


from routers import shadowing_topic as router_topic
from routers import shadowing_result as router_result
from routers import lesson as router_lesson
from routers import vocabulary as router_vocabulary
from routers import evaluation as router_evaluation
from routers import tts as router_tts
from routers import user_progress as router_progress
from routers import dictionary as router_dictionary
from routers import roleplay as router_roleplay
from routers import admin as router_admin
from routers import upload as router_upload
from routers import category as router_category
from routers import segments as router_segments
from routers import segment_topic as router_segment_topic
from routers import user_profile as router_profile

app = FastAPI(
    title="Japanese Learning Backend API",
    description="API for Japanese Learning App using FastAPI and MySQL",
    version="1.0.0"
)

from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

import os
os.makedirs("static/uploads", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(router_topic.router)
app.include_router(router_result.router)
app.include_router(router_lesson.router)
app.include_router(router_vocabulary.router)
app.include_router(router_evaluation.router)
app.include_router(router_tts.router)
app.include_router(router_progress.router)
app.include_router(router_dictionary.router)
app.include_router(router_roleplay.router)
app.include_router(router_admin.router)
app.include_router(router_upload.router)
app.include_router(router_category.router)
app.include_router(router_segments.router)
app.include_router(router_segment_topic.router)
app.include_router(router_profile.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Japanese Learning API"}