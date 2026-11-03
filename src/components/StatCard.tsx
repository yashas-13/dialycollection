import type { ReactNode } from 'react'
export default function StatCard({label,value,detail,icon,tone='blue'}:{label:string;value:string;detail:string;icon:ReactNode;tone?:string}) {
  return <article className="stat-card"><div className="stat-top"><span>{label}</span><span className={'stat-icon '+tone}>{icon}</span></div><strong>{value}</strong><small>{detail}</small></article>
}
