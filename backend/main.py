import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from app.database import engine, Base
from app.api import api_router
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create database tables (with retry logic)
def create_tables():
    max_retries = 5
    retry_delay = 2
    
    for attempt in range(max_retries):
        try:
            Base.metadata.create_all(bind=engine)
            logger.info("Database tables created successfully")
            break
        except Exception as e:
            if attempt < max_retries - 1:
                logger.warning(f"Database connection attempt {attempt + 1} failed: {e}")
                logger.info(f"Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
            else:
                logger.error(f"Failed to create database tables after {max_retries} attempts: {e}")
                raise

# Insert sample data if needed
def insert_sample_data():
    try:
        from sqlalchemy import text
        with engine.connect() as conn:
            # Call the function to insert sample data
            result = conn.execute(text("SELECT insert_sample_data_if_needed()"))
            conn.commit()
            logger.info("Sample data check completed")
    except Exception as e:
        logger.warning(f"Could not insert sample data: {e}")
        # This is not critical, so we just log a warning

# Import time module
import time

# Create database tables
create_tables()

# Insert sample data
insert_sample_data()

# Create FastAPI app
app = FastAPI(
    title="Corporate RideShare API",
    description="Multi-tenant corporate ride sharing platform API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files for web admin
if os.path.exists("../web-admin/static"):
    app.mount("/static", StaticFiles(directory="../web-admin/static"), name="static")

# Templates for web admin
if os.path.exists("../web-admin/templates"):
    templates = Jinja2Templates(directory="../web-admin/templates")

# Include API routes
app.include_router(api_router, prefix="/api/v1")

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "message": "Corporate RideShare API is running"}

# Root endpoint
@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Corporate RideShare API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }

# Web admin home page
@app.get("/admin", response_class=HTMLResponse)
async def admin_home(request: Request):
    """Admin dashboard home page"""
    try:
        return templates.TemplateResponse("admin/index.html", {"request": request})
    except Exception as e:
        return HTMLResponse(content=f"<h1>Admin Dashboard</h1><p>Web admin not configured. API is running at <a href='/docs'>/docs</a></p>")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
