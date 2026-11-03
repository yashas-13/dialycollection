export default function ProgressBar({value}:{value:number}) {
  const safe=Math.max(0,Math.min(100,value))
  return <div className="progress-track" role="progressbar" aria-valuenow={Math.round(safe)} aria-valuemin={0} aria-valuemax={100}><span style={{width:safe+'%'}}/></div>
}
