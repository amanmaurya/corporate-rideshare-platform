import uuid
import logging
from datetime import datetime
from typing import Dict, Optional, List
from enum import Enum
from dataclasses import dataclass

logger = logging.getLogger(__name__)

class PaymentStatus(Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"

class PaymentMethod(Enum):
    CREDIT_CARD = "credit_card"
    DEBIT_CARD = "debit_card"
    BANK_TRANSFER = "bank_transfer"
    DIGITAL_WALLET = "digital_wallet"
    CORPORATE_ACCOUNT = "corporate_account"

@dataclass
class PaymentRequest:
    ride_id: str
    user_id: str
    company_id: str
    amount: float
    currency: str = "USD"
    description: str = ""
    payment_method: PaymentMethod = PaymentMethod.CORPORATE_ACCOUNT

@dataclass
class PaymentResponse:
    payment_id: str
    status: PaymentStatus
    amount: float
    currency: str
    transaction_id: str
    created_at: datetime
    updated_at: datetime
    error_message: Optional[str] = None

@dataclass
class RefundRequest:
    payment_id: str
    amount: float
    reason: str
    user_id: str

class DummyPaymentProcessor:
    """Dummy payment processor for development/testing"""
    
    def __init__(self):
        self.payments: Dict[str, Dict] = {}
        self.transactions: Dict[str, Dict] = {}
        self.success_rate = 0.95  # 95% success rate for testing
        
    def generate_transaction_id(self) -> str:
        """Generate a dummy transaction ID"""
        return f"TXN_{uuid.uuid4().hex[:8].upper()}"
    
    def process_payment(self, payment_request: PaymentRequest) -> PaymentResponse:
        """Process a payment request"""
        payment_id = str(uuid.uuid4())
        transaction_id = self.generate_transaction_id()
        now = datetime.utcnow()
        
        # Simulate payment processing
        import random
        success = random.random() < self.success_rate
        
        if success:
            status = PaymentStatus.COMPLETED
            error_message = None
        else:
            status = PaymentStatus.FAILED
            error_message = "Payment declined by bank"
        
        # Create payment record
        payment_data = {
            "payment_id": payment_id,
            "ride_id": payment_request.ride_id,
            "user_id": payment_request.user_id,
            "company_id": payment_request.company_id,
            "amount": payment_request.amount,
            "currency": payment_request.currency,
            "description": payment_request.description,
            "payment_method": payment_request.payment_method.value,
            "status": status.value,
            "transaction_id": transaction_id,
            "created_at": now,
            "updated_at": now,
            "error_message": error_message
        }
        
        self.payments[payment_id] = payment_data
        
        # Create transaction record
        transaction_data = {
            "transaction_id": transaction_id,
            "payment_id": payment_id,
            "amount": payment_request.amount,
            "currency": payment_request.currency,
            "status": status.value,
            "created_at": now,
            "processor_response": {
                "success": success,
                "response_code": "200" if success else "400",
                "response_message": "Payment processed successfully" if success else error_message
            }
        }
        
        self.transactions[transaction_id] = transaction_data
        
        logger.info(f"Payment processed: {payment_id} - Status: {status.value}")
        
        return PaymentResponse(
            payment_id=payment_id,
            status=status,
            amount=payment_request.amount,
            currency=payment_request.currency,
            transaction_id=transaction_id,
            created_at=now,
            updated_at=now,
            error_message=error_message
        )
    
    def refund_payment(self, refund_request: RefundRequest) -> Optional[PaymentResponse]:
        """Process a refund request"""
        if refund_request.payment_id not in self.payments:
            return None
            
        payment = self.payments[refund_request.payment_id]
        
        # Create refund record
        refund_id = str(uuid.uuid4())
        now = datetime.utcnow()
        
        refund_data = {
            "refund_id": refund_id,
            "payment_id": refund_request.payment_id,
            "amount": refund_request.amount,
            "reason": refund_request.reason,
            "user_id": refund_request.user_id,
            "status": "completed",
            "created_at": now
        }
        
        # Update original payment
        payment["status"] = PaymentStatus.REFUNDED.value
        payment["updated_at"] = now
        payment["refund_id"] = refund_id
        
        logger.info(f"Refund processed: {refund_id} for payment {refund_request.payment_id}")
        
        return PaymentResponse(
            payment_id=refund_request.payment_id,
            status=PaymentStatus.REFUNDED,
            amount=refund_request.amount,
            currency=payment["currency"],
            transaction_id=payment["transaction_id"],
            created_at=payment["created_at"],
            updated_at=now
        )
    
    def get_payment_status(self, payment_id: str) -> Optional[Dict]:
        """Get payment status"""
        return self.payments.get(payment_id)
    
    def get_user_payments(self, user_id: str) -> List[Dict]:
        """Get all payments for a user"""
        return [payment for payment in self.payments.values() if payment["user_id"] == user_id]
    
    def get_company_payments(self, company_id: str) -> List[Dict]:
        """Get all payments for a company"""
        return [payment for payment in self.payments.values() if payment["company_id"] == company_id]

class PaymentService:
    """Main payment service for the rideshare platform"""
    
    def __init__(self):
        self.processor = DummyPaymentProcessor()
    
    def calculate_ride_fare(self, distance_km: float, duration_minutes: int, 
                           base_rate: float = 2.0, distance_rate: float = 1.5, 
                           time_rate: float = 0.5) -> float:
        """Calculate fare for a ride"""
        fare = base_rate + (distance_km * distance_rate) + (duration_minutes * time_rate)
        return round(fare, 2)
    
    def process_ride_payment(self, ride_id: str, user_id: str, company_id: str, 
                           distance_km: float, duration_minutes: int) -> PaymentResponse:
        """Process payment for a completed ride"""
        amount = self.calculate_ride_fare(distance_km, duration_minutes)
        
        payment_request = PaymentRequest(
            ride_id=ride_id,
            user_id=user_id,
            company_id=company_id,
            amount=amount,
            description=f"Ride fare for {distance_km:.1f}km, {duration_minutes}min",
            payment_method=PaymentMethod.CORPORATE_ACCOUNT
        )
        
        return self.processor.process_payment(payment_request)
    
    def process_corporate_payment(self, ride_id: str, user_id: str, company_id: str, 
                                amount: float, description: str = "") -> PaymentResponse:
        """Process corporate payment (e.g., monthly subscription, premium features)"""
        payment_request = PaymentRequest(
            ride_id=ride_id,
            user_id=user_id,
            company_id=company_id,
            amount=amount,
            description=description,
            payment_method=PaymentMethod.CORPORATE_ACCOUNT
        )
        
        return self.processor.process_payment(payment_request)
    
    def refund_payment(self, payment_id: str, amount: float, reason: str, user_id: str) -> Optional[PaymentResponse]:
        """Process a refund"""
        refund_request = RefundRequest(
            payment_id=payment_id,
            amount=amount,
            reason=reason,
            user_id=user_id
        )
        
        return self.processor.refund_payment(refund_request)
    
    def get_payment_history(self, user_id: str) -> List[Dict]:
        """Get payment history for a user"""
        return self.processor.get_user_payments(user_id)
    
    def get_company_payment_summary(self, company_id: str) -> Dict:
        """Get payment summary for a company"""
        payments = self.processor.get_company_payments(company_id)
        
        total_amount = sum(payment["amount"] for payment in payments if payment["status"] == "completed")
        total_payments = len([p for p in payments if p["status"] == "completed"])
        total_refunds = len([p for p in payments if p["status"] == "refunded"])
        
        return {
            "company_id": company_id,
            "total_amount": total_amount,
            "total_payments": total_payments,
            "total_refunds": total_refunds,
            "currency": "USD"
        }

# Global payment service instance
payment_service = PaymentService()
