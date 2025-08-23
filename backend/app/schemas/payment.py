from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class PaymentMethod(str, Enum):
    CREDIT_CARD = "credit_card"
    DEBIT_CARD = "debit_card"
    BANK_TRANSFER = "bank_transfer"
    DIGITAL_WALLET = "digital_wallet"
    CORPORATE_ACCOUNT = "corporate_account"

class PaymentStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"

class PaymentCreate(BaseModel):
    amount: Optional[float] = Field(None, description="Payment amount (auto-calculated if not provided)")
    currency: str = Field(default="USD", description="Payment currency")
    description: Optional[str] = Field(None, description="Payment description")
    payment_method: PaymentMethod = Field(default=PaymentMethod.CORPORATE_ACCOUNT, description="Payment method")

class PaymentResponse(BaseModel):
    payment_id: str = Field(..., description="Unique payment identifier")
    status: PaymentStatus = Field(..., description="Payment status")
    amount: float = Field(..., description="Payment amount")
    currency: str = Field(..., description="Payment currency")
    transaction_id: str = Field(..., description="Transaction identifier")
    created_at: datetime = Field(..., description="Payment creation timestamp")
    updated_at: datetime = Field(..., description="Payment last update timestamp")
    error_message: Optional[str] = Field(None, description="Error message if payment failed")

class RefundCreate(BaseModel):
    payment_id: str = Field(..., description="Payment ID to refund")
    amount: float = Field(..., description="Refund amount")
    reason: str = Field(..., description="Refund reason")

class RefundResponse(BaseModel):
    refund_id: str = Field(..., description="Unique refund identifier")
    payment_id: str = Field(..., description="Original payment ID")
    amount: float = Field(..., description="Refund amount")
    status: str = Field(..., description="Refund status")
    reason: str = Field(..., description="Refund reason")
    created_at: datetime = Field(..., description="Refund creation timestamp")

class PaymentHistory(BaseModel):
    payment_id: str = Field(..., description="Payment identifier")
    ride_id: Optional[str] = Field(None, description="Associated ride ID")
    amount: float = Field(..., description="Payment amount")
    currency: str = Field(..., description="Payment currency")
    status: PaymentStatus = Field(..., description="Payment status")
    payment_method: PaymentMethod = Field(..., description="Payment method")
    description: Optional[str] = Field(None, description="Payment description")
    created_at: datetime = Field(..., description="Payment creation timestamp")
    transaction_id: str = Field(..., description="Transaction identifier")

class CompanyPaymentSummary(BaseModel):
    company_id: str = Field(..., description="Company identifier")
    total_amount: float = Field(..., description="Total payment amount")
    total_payments: int = Field(..., description="Total number of payments")
    total_refunds: int = Field(..., description="Total number of refunds")
    currency: str = Field(..., description="Payment currency")

class FareCalculation(BaseModel):
    estimated_fare: float = Field(..., description="Estimated ride fare")
    currency: str = Field(..., description="Fare currency")
    breakdown: dict = Field(..., description="Fare breakdown details")

class PaymentMethodInfo(BaseModel):
    method: PaymentMethod = Field(..., description="Payment method")
    is_available: bool = Field(..., description="Whether method is available")
    processing_fee: Optional[float] = Field(None, description="Processing fee if applicable")
    estimated_time: Optional[str] = Field(None, description="Estimated processing time")
