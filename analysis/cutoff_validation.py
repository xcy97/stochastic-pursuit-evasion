from pathlib import Path
import csv,json,sys,hashlib
import numpy as np
W=Path(__file__).resolve().parents[1]
DATA=W/'inputs/cutoff_validation'
(W/'tables').mkdir(exist_ok=True)
CASES=[('low_A',1,.004642,2000,301.516404),('high_A',1,31.6228,8000,117.723351),
       ('high_N3',3,31.6228,30000,117.723351),('low_C_control',1,.004642,2000,301.516404)]
def bootstrap_mean(x,rng,B=10000):
 vals=[]
 for i in range(0,B,100):
  ids=rng.integers(0,len(x),size=(min(100,B-i),len(x)))
  vals.extend(x[ids].mean(axis=1))
 return np.quantile(vals,[.025,.975]).tolist()
def analyze(require_complete=True):
 out=[];rng=np.random.default_rng(2026102901)
 for name,n,d,total,proxy in CASES:
  rows=[];files=sorted(DATA.glob('production_'+name+'*_trials.csv'))
  for f in files:rows+=list(csv.DictReader(f.open()))
  if not rows:continue
  if require_complete:assert len(rows)==total,(name,len(rows),total)
  ids=[int(x['trial_id']) for x in rows];assert len(ids)==len(set(ids))
  t=np.array([float(x['observed_time']) for x in rows]);cap=np.array([int(x['captured_by_horizon']) for x in rows],dtype=bool)
  tail=np.array([not int(x['captured_by_cutoff']) for x in rows]);rem=t[tail]-1000
  assert np.all(rem>=0)
  v={'case':name,'N':n,'D':d,'n':len(rows),'n_uncaptured_at_1000':int(tail.sum()),'n_uncaptured_at_100000':int((~cap).sum()),
     'mean_observed':float(t.mean()),'max_time':float(t.max()),'restricted_mean':float(np.minimum(t,1000).mean()),'proxy':proxy,
     'remaining_mean':float(rem.mean()) if len(rem) else None}
  if require_complete:
   assert cap.all(),('Extend final horizon before claiming complete mean',name)
   v['full_mean_ci']=bootstrap_mean(t,rng)
   v['remaining_mean_ci']=bootstrap_mean(rem,rng)
   hybrid=np.minimum(t,1000)+tail*proxy
   v['hybrid_same_sample']=float(hybrid.mean());v['hybrid_minus_full']=float((hybrid-t).mean())
   v['hybrid_relative_error_percent']=float(100*(hybrid.mean()/t.mean()-1))
   rel=[];diff=[]
   for i in range(0,10000,100):
    ix=rng.integers(0,len(t),size=(100,len(t)));tt=t[ix].mean(axis=1);hh=hybrid[ix].mean(axis=1)
    rel.extend(100*(hh/tt-1));diff.extend(hh-tt)
   v['hybrid_relative_error_ci']=np.quantile(rel,[.025,.975]).tolist()
   v['hybrid_minus_full_ci']=np.quantile(diff,[.025,.975]).tolist()
   v['proxy_in_remaining_ci']=v['remaining_mean_ci'][0]<=proxy<=v['remaining_mean_ci'][1]
   if n==1:v['proxy_in_full_ci']=v['full_mean_ci'][0]<=proxy<=v['full_mean_ci'][1]
  out.append(v)
 if require_complete:
  (W/'tables/cutoff_validation_results.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
  with (W/'tables/cutoff_validation_results.csv').open('w',newline='',encoding='utf-8-sig') as f:
   z=csv.DictWriter(f,fieldnames=list(out[0]));z.writeheader();z.writerows(out)
 print(json.dumps(out,indent=2),flush=True)
 return out
if __name__=='__main__':
 results=analyze()
 expected=json.loads((DATA/'expected_results.json').read_text())
 assert len(results)==len(expected)==4
 for a,b in zip(results,expected):
  for k,v in b.items():
   if isinstance(v,list):assert np.allclose(a[k],v,rtol=1e-10,atol=1e-8),(a['case'],k)
   elif isinstance(v,(int,float)) and not isinstance(v,bool):assert np.isclose(a[k],v,rtol=1e-10,atol=1e-8),(a['case'],k)
   else:assert a[k]==v,(a['case'],k)
 print('All four cutoff-validation cases match the archived statistics.')
