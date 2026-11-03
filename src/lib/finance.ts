export type Frequency='daily'|'weekly'|'monthly'
export function money(value:number){return new Intl.NumberFormat('en-IN',{style:'currency',currency:'INR',maximumFractionDigits:0}).format(Number.isFinite(value)?value:0)}
export function installmentAmount(principal:number,installments:number,rate=0){if(!Number.isFinite(principal)||principal<=0||!Number.isInteger(installments)||installments<=0)throw new Error('Principal and installments must be positive.');return Math.ceil(principal*(1+Math.max(0,rate)/100)/installments)}
export function repaymentProgress(paid:number,total:number){return total>0?Math.min(100,Math.max(0,paid/total*100)):0}
