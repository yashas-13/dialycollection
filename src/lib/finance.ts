export type Frequency = 'daily' | 'weekly' | 'monthly'

export function money(value: number) {
  return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(Number.isFinite(value) ? value : 0)
}

export function installmentAmount(principal: number, installments: number, interestRate = 0) {
  if (!Number.isFinite(principal) || principal <= 0 || !Number.isInteger(installments) || installments <= 0) throw new Error('Principal and installment count must be positive.')
  const total = principal + principal * Math.max(0, interestRate) / 100
  return Math.ceil(total / installments)
}

export function nextDueDate(start: string, frequency: Frequency, count: number) {
  const date = new Date(start + 'T12:00:00')
  if (frequency === 'daily') date.setDate(date.getDate() + count)
  if (frequency === 'weekly') date.setDate(date.getDate() + count * 7)
  if (frequency === 'monthly') date.setMonth(date.getMonth() + count)
  return date.toISOString().slice(0, 10)
}

export function repaymentProgress(paid: number, total: number) {
  return total > 0 ? Math.min(100, Math.max(0, paid / total * 100)) : 0
}
