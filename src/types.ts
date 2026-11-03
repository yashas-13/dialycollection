export type Frequency = 'daily' | 'weekly' | 'monthly'
export type LoanStatus = 'active' | 'closed' | 'defaulted'
export interface Borrower {
  id: string; name: string; phone: string; address: string; city: string; createdAt: string
}
export interface Loan {
  id: string; borrowerId: string; borrowerName: string; code: string; frequency: Frequency
  principal: number; interestRate: number; totalPayable: number; installmentAmount: number
  installments: number; startDate: string; status: LoanStatus; paid: number; pending: number
  balance: number; nextDue: string; lastPaid?: string
}
export interface Payment {
  id: string; loanId: string; borrowerName: string; amount: number; paidAt: string
  method: 'cash' | 'upi' | 'bank'; reference?: string; note?: string
}
