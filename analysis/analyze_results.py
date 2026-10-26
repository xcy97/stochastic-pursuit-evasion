"""Recalculate completed simulation results. Requires numpy and pandas only.
Run: python code/analyze_results.py. Writes tables and audit; never simulates.
Paired percentile bootstrap: 10000 draws, fixed seed, joint trial resampling.
"""
from pathlib import Path
import json, hashlib, math
import numpy as np
import pandas as pd
from numpy.polynomial.legendre import leggauss
from numpy.polynomial.laguerre import laggauss

ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'tables'; OUT.mkdir(exist_ok=True)
NBOOT=10000
audit={'bootstrap':{'draws':NBOOT,'method':'percentile [2.5,97.5], np.quantile linear; paired trial resampling','seed_base':20261024},'checks':[], 'overlap':[]}
def check(ok, message):
    if not bool(ok): raise AssertionError(message)
    audit['checks'].append(message)
def save(name, rows):
    df=pd.DataFrame(rows);df.to_csv(OUT/(name+'.csv'),index=False,encoding='utf-8-sig');return df
def seed(mu,a,D):
    return 20261024+int(hashlib.sha256(f'{mu:.6f}/{a:.6f}/{D:.8f}'.encode()).hexdigest()[:8],16)
def boot(x,key):
    x=np.asarray(x);x=x[:,None] if x.ndim==1 else x
    rng=np.random.default_rng(key); chunks=[]
    for start in range(0,NBOOT,200):
        ix=rng.integers(0,len(x),size=(min(200,NBOOT-start),len(x)))
        chunks.append(x[ix].mean(axis=1))
    return np.concatenate(chunks)
def ci(x): return np.quantile(x,[.025,.975])
def theory(D,mu,a,n=160):
    v=a/mu; R=.1; S=1.; ve=1.; r0=1.
    x,w=leggauss(n);u,q=laggauss(n)
    y=((r0-R)/2*x+(r0+R)/2)[:,None]
    z=y+D/v*u
    exponent=np.log(q)[None,:]+ve*S*np.exp(-(y-R)/S)*(-np.expm1(-D/v*u/S))[None,:]/D
    return float((r0-R)/2/v*np.sum(w*np.sum(z*np.exp(exponent),axis=1)/y[:,0]))

for row in json.loads((ROOT/'inputs/manifest.json').read_text(encoding='utf-8')):
    check(hashlib.sha256((ROOT/row['snapshot']).read_bytes()).hexdigest()==row['sha256'],'Snapshot hash: '+row['snapshot'])
step=pd.read_csv(ROOT/'inputs/step/trajectories.csv')
model=pd.read_csv(ROOT/'inputs/models/trajectories.csv')
check(len(step)==12000,'Step records: 12000')
check(len(model)==18000,'Model records: 18000')
for label,df,keys in [('Step',step,['case_id','trial_id','h']),('Model',model,['case_id','trial_id','model'])]:
    check(not df.duplicated(keys).any(),label+' unique row keys')
    check(df.captured.eq(1).all() and df.censored.eq(0).all(),label+' all trajectories captured')
    check(np.isfinite(df.observed_time).all() and df.observed_time.gt(0).all() and df.observed_time.le(1e5).all(),label+' finite positive times <= Tmax')
    check(np.allclose(df.em_updates*df.h,df.observed_time,rtol=1e-10,atol=1e-8),label+' step counts consistent with times')
    check(df.master_seed.eq(20261023).all(),label+' master seed consistent')
    for c,g in df.groupby('case_id'):
        check(all(g[k].nunique()==1 for k in ['mu','a','D']),f'{label} case {c}: parameters constant')
check(np.allclose(np.sort(step.h.unique()),[1e-6,1e-5,1e-4],rtol=1e-12,atol=0),'Exactly three requested time steps')
check(np.allclose(model.h,1e-6,rtol=1e-12,atol=0) and model.Tmax.eq(1e5).all(),'Model h=1e-6 and Tmax=1e5')

step_means=[];step_diffs=[];step_piv={}
provided=pd.read_csv(ROOT/'inputs/step/summary.csv')
for case,g in step.groupby('case_id',sort=True):
    mu,a,D=g.iloc[0][['mu','a','D']].astype(float)
    p=g.pivot(index='trial_id',columns='h',values='observed_time').sort_index().sort_index(axis=1,ascending=False)
    check(p.shape==(1000,3) and np.array_equal(p.index,np.arange(1,1001)) and not p.isna().any().any(),f'Step case {case}: complete paired IDs')
    x=p.to_numpy(); b=boot(x,seed(mu,a,D)); step_piv[int(case)]=p
    for j,h in enumerate(p.columns):
        lo,hi=ci(b[:,j]); val=x[:,j].mean()
        ref=provided[(provided.case_id==case)&np.isclose(provided.h,h,rtol=1e-10,atol=0)].iloc[0]
        check(np.isclose(val,ref.complete_mean,rtol=1e-12),f'Step case {case} h={h:g}: supplied mean reproduced')
        step_means.append(dict(case_id=case,mu=mu,a=a,D=D,h=h,n=1000,mean=val,ci_low=lo,ci_high=hi,sd=x[:,j].std(ddof=1),capture_rate=1))
    for j in [0,1]:
        diff=x[:,j].mean()-x[:,2].mean(); bd=b[:,j]-b[:,2]; br=100*bd/b[:,2];lo,hi=ci(bd);lr,hr=ci(br)
        step_diffs.append(dict(case_id=case,mu=mu,a=a,D=D,h_test=p.columns[j],h_reference=p.columns[2],difference=diff,diff_ci_low=lo,diff_ci_high=hi,percent=100*diff/x[:,2].mean(),percent_ci_low=lr,percent_ci_high=hr))
sm=save('step_means',step_means);sd=save('step_paired_differences',step_diffs)

model_means=[];model_diffs=[];model_refs=[];model_piv={}
provided=pd.read_csv(ROOT/'inputs/models/summary.csv')
for case,g in model.groupby('case_id',sort=True):
    mu,a,D=g.iloc[0][['mu','a','D']].astype(float)
    p=g.pivot(index='trial_id',columns='model',values='observed_time').sort_index()[['A','B','C']]
    check(p.shape==(1000,3) and np.array_equal(p.index,np.arange(1,1001)) and not p.isna().any().any(),f'Model case {case}: complete paired IDs')
    x=p.to_numpy();b=boot(x,seed(mu,a,D));model_piv[int(case)]=p
    th=theory(D,mu,a);th128=theory(D,mu,a,128)
    check(abs(th/th128-1)<3e-4,f'Model case {case}: quadrature 128 vs 160 agrees')
    check(np.isclose(th,provided[provided.case_id==case].iloc[0].analytic_C_reference,rtol=1e-10),f'Model case {case}: analytical reference reproduced')
    for j,name in enumerate(['A','B','C']):
        val=x[:,j].mean();lo,hi=ci(b[:,j]);ref=provided[(provided.case_id==case)&(provided.model==name)].iloc[0]
        check(np.isclose(val,ref.complete_mean,rtol=1e-12),f'Model case {case} {name}: supplied mean reproduced')
        model_means.append(dict(case_id=case,mu=mu,a=a,D=D,model=name,n=1000,h=1e-6,mean=val,ci_low=lo,ci_high=hi,sd=x[:,j].std(ddof=1),capture_rate=1,early_capture_fraction=np.mean(x[:,j]<=3/mu),analytic=th))
    for name,j,k in [('A_minus_B',0,1),('B_minus_C',1,2),('A_minus_C',0,2)]:
        bd=b[:,j]-b[:,k];br=100*bd/b[:,0];lo,hi=ci(bd);lr,hr=ci(br);diff=x[:,j].mean()-x[:,k].mean()
        model_diffs.append(dict(case_id=case,mu=mu,a=a,D=D,comparison=name,difference=diff,diff_ci_low=lo,diff_ci_high=hi,percent_of_A=100*diff/x[:,0].mean(),percent_ci_low=lr,percent_ci_high=hr))
    lo,hi=ci(100*(b[:,2]/th-1))
    model_refs.append(dict(case_id=case,mu=mu,a=a,D=D,analytic=th,C_mean=x[:,2].mean(),C_minus_analytic_percent=100*(x[:,2].mean()/th-1),percent_ci_low=lo,percent_ci_high=hi,A_mean=x[:,0].mean(),A_minus_analytic_percent=100*(x[:,0].mean()/th-1),mean_cos_A=g[g.model=='A'].mean_cos_A.mean(),speed_deficit_ratio_A=g[g.model=='A'].speed_deficit_ratio_A.mean()))
mm=save('model_means',model_means);md=save('model_paired_differences',model_diffs);mr=save('model_analytic_comparison',model_refs)
for sc,mc in [(3,2),(2,3),(4,6)]:
    x=step_piv[sc].iloc[:,-1].to_numpy();y=model_piv[mc]['A'].to_numpy()
    check(np.array_equal(x,y),f'Step case {sc} fine equals model case {mc} A path by path')
    audit['overlap'].append({'step_case':sc,'model_case':mc,'n_shared_trials':1000,'independent_replication':False})

raw=np.loadtxt(ROOT/'inputs/new_capture/trajectories.txt',comments='#')
check(raw.shape==(1000,4),'New weak-noise batch: 1000 rows, four columns')
check(np.array_equal(raw[:,0],np.arange(1,1001)),'New weak-noise batch: IDs 1..1000')
check(np.all(raw[:,2]==1) and np.all(raw[:,3]==0),'New weak-noise batch: 1000 captures, zero censored')
t=raw[:,1];check(np.all(np.isfinite(t)&(t>0)&(t<=1e6)),'New weak-noise times within horizon')
check(abs(t.mean()-73887.735296)<1e-5,'New weak-noise reported mean reproduced')
th=theory(.002154,3.,2.4);th128=theory(.002154,3.,2.4,128)
check(abs(th/th128-1)<3e-4,'New weak-noise analytical quadrature validated')
selected=t<=1e5; x=np.column_stack([t,np.minimum(t,1e5),t*selected,selected.astype(float)])
b=boot(x,seed(3.,2.4,.002154));cut=[]
for name,values,draws,n in [('full_mean',t,b[:,0],1000),('restricted_mean_1e5',np.minimum(t,1e5),b[:,1],1000),('captured_only_mean_1e5',t[selected],b[:,2]/b[:,3],selected.sum())]:
    lo,hi=ci(draws);cut.append(dict(quantity=name,n=int(n),mean=values.mean(),ci_low=lo,ci_high=hi))
ct=save('new_capture_cutoff',cut)
details=dict(D=.002154,mu=3.,a=2.4,h=1e-4,Tmax=1e6,n=1000,captured=1000,censored=0,mean=t.mean(),mean_ci=ci(b[:,0]).tolist(),sd=t.std(ddof=1),median=np.median(t),quantiles={str(q):float(np.quantile(t,q)) for q in [.05,.25,.5,.75,.9,.95,.99]},maximum=t.max(),captured_by_1e5=int(selected.sum()),beyond_1e5=int((~selected).sum()),analytic=th,percent_mean_minus_analytic=100*(t.mean()/th-1),top_1_percent_sum_share=np.sort(t)[-10:].sum()/t.sum(),top_5_percent_sum_share=np.sort(t)[-50:].sum()/t.sum())
(OUT/'new_capture_details.json').write_text(json.dumps(details,ensure_ascii=False,indent=2),encoding='utf-8')
save('new_capture_sorted',dict(time=np.r_[0,np.sort(t)],survival=np.r_[1,1-np.arange(1,1001)/1000]))

# Reconstruct the retained main-scan values and analytical grids.
cfg=json.loads((ROOT/'inputs/legacy/figure_data.json').read_text(encoding='utf-8'))
for fig,mu,a in [(3,3.,2.4),(4,30.,29.97)]:
    rows=[]
    for r in cfg['figures'][str(fig)]:
        r=dict(r)
        if fig==3 and float(r['D'])==.002154:
            r.update(captured_mean=float(t.mean()),captured=1000,censored=0,Tmax=1000000)
        rows.append(dict(D=float(r['D']),mean=np.nan if r['captured_mean'] is None else r['captured_mean'],captured=r['captured'],censored=r['censored'],Tmax=r['Tmax'],h=1e-4))
    save(f'recomputed_fig{fig}_legacy',rows)
    grid=np.geomspace(.001,31.6228,180);vals=[theory(d,mu,a) for d in grid]
    save(f'recomputed_fig{fig}_theory',dict(D=grid,mean=vals))
    subset=sm[(sm.mu==mu)&np.isclose(sm.h,1e-6,rtol=1e-10,atol=0)]
    subset.to_csv(OUT/f'recomputed_fig{fig}_fine.csv',index=False,encoding='utf-8-sig')

audit['summary']={'all_checks_passed':True,'step_rows':len(step),'model_rows':len(model),'new_capture_rows':len(raw),'bootstrap_ci_note':'Sampling uncertainty only; excludes time-step bias and model approximation error. Not simultaneous intervals.','manuscript_changed':False,'source_data_changed':False}
(OUT/'validation.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(details,ensure_ascii=True,indent=2))
print('Step differences:'); print(sd[['case_id','h_test','percent','percent_ci_low','percent_ci_high']].to_string(index=False))
print('Model differences:'); print(md[['case_id','comparison','percent_of_A','percent_ci_low','percent_ci_high']].to_string(index=False))
print('Validated checks:',len(audit['checks']))
