from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List
from app.database import get_database
from app.models.user import User
from app.models.company import Company
from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.services.auth import verify_token, get_password_hash
from datetime import datetime

router = APIRouter()
security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), 
                    db: Session = Depends(get_database)):
    """Get current authenticated user"""
    token = credentials.credentials
    payload = verify_token(token)

    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )

    return user

@router.get("/", response_model=List[UserResponse])
async def get_users(current_user: User = Depends(get_current_user), 
                   db: Session = Depends(get_database),
                   company_id: str = None):
    """Get users (filtered by company)"""
    query = db.query(User)
    
    # Filter by company if specified
    if company_id:
        query = query.filter(User.company_id == company_id)
    else:
        # Users can only see users from their own company
        query = query.filter(User.company_id == current_user.company_id)
    
    # Admin can see all users, regular users can only see active users
    if current_user.role != "admin":
        query = query.filter(User.is_active == True)
    
    users = query.all()
    return users

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, current_user: User = Depends(get_current_user), 
                  db: Session = Depends(get_database)):
    """Get specific user"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Users can only access users from their own company
    if user.company_id != current_user.company_id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    return user

@router.post("/register-driver")
async def register_as_driver(user_update: UserUpdate, 
                           current_user: User = Depends(get_current_user), 
                           db: Session = Depends(get_database)):
    """Allow users to register themselves as drivers"""
    # Users can only update their own profile
    if user_update.id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Can only update your own profile"
        )

    # Only allow updating driver status and related fields
    allowed_fields = {'is_driver', 'driver_license', 'vehicle_info', 'is_available'}
    update_data = {k: v for k, v in user_update.dict(exclude_unset=True).items() 
                   if k in allowed_fields}

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid fields to update"
        )

    # Update user fields
    for field, value in update_data.items():
        setattr(current_user, field, value)

    # Set driver status
    current_user.is_driver = True
    current_user.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(current_user)

    return {"message": "Successfully registered as driver", "user": current_user}

@router.post("/", response_model=UserResponse)
async def create_user(user: UserCreate, current_user: User = Depends(get_current_user), 
                     db: Session = Depends(get_database)):
    """Create a new user (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    # Check if user already exists
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Verify company exists
    company = db.query(Company).filter(Company.id == user.company_id).first()
    if not company:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Company not found"
        )
    
    # Create new user
    hashed_password = get_password_hash(user.password)
    db_user = User(
        name=user.name,
        email=user.email,
        phone=user.phone,
        department=user.department,
        role=user.role,
        company_id=user.company_id,
        hashed_password=hashed_password,
        is_driver=user.is_driver
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(user_id: str, user_update: UserUpdate, 
                     current_user: User = Depends(get_current_user), 
                     db: Session = Depends(get_database)):
    """Update a user"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Users can only update their own profile, admins can update any user
    if user.id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Can only update your own profile"
        )
    
    # Update fields
    update_data = user_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    
    return user

@router.delete("/{user_id}")
async def delete_user(user_id: str, current_user: User = Depends(get_current_user), 
                     db: Session = Depends(get_database)):
    """Delete a user (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Don't allow admin to delete themselves
    if user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete your own account"
        )
    
    db.delete(user)
    db.commit()
    
    return {"message": "User deleted successfully"}

@router.put("/{user_id}/toggle-status")
async def toggle_user_status(user_id: str, current_user: User = Depends(get_current_user), 
                           db: Session = Depends(get_database)):
    """Toggle user active status (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Toggle status
    user.is_active = not user.is_active
    db.commit()
    
    return {"message": f"User {'activated' if user.is_active else 'deactivated'} successfully"}
