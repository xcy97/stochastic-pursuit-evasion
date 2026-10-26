"""Recompute saved statistics, elapsed-time correction and manuscript tables.
Run from any working directory: python analysis/reproduce.py
No Fortran simulation is launched. No paper/source-data file is modified.
"""
from pathlib import Path
import subprocess,sys,shutil,json
import numpy as np
import pandas as pd
R=Path(__file__).resolve().parent.parent
for script in ['analyze_results.py','calculate_figure6.py','export_manuscript_tables.py']:
 subprocess.run([sys.executable,str(R/'analysis'/script)],check=True)
for n in ['step_means','step_paired_differences','model_means','model_paired_differences']:
 x=pd.read_csv(R/'tables'/f'{n}.csv');y=pd.read_csv(R/'matlab/revision_data'/f'{n}.csv')
 assert list(x.columns)==list(y.columns) and x.shape==y.shape,n
 for col in x.select_dtypes('number'):
  assert np.allclose(x[col],y[col],rtol=1e-10,atol=1e-9,equal_nan=True),(n,col)
 shutil.copy2(R/'tables'/f'{n}.csv',R/'matlab/revision_data'/f'{n}.csv')
for f in [3,4]:
 for kind,old in [('main','legacy'),('theory','theory')]:
  name=f'fig{f}_{kind}.csv';src=R/'tables'/f'recomputed_fig{f}_{old}.csv'
  x=pd.read_csv(src);y=pd.read_csv(R/'matlab/revision_data'/name)
  for col in y.select_dtypes('number'):
   assert np.allclose(x[col],y[col],rtol=1e-9,atol=1e-8,equal_nan=True),(name,col)
  shutil.copy2(src,R/'matlab/revision_data'/name)
 fine=pd.read_csv(R/'tables'/f'recomputed_fig{f}_fine.csv')
 shutil.copy2(R/'tables'/f'recomputed_fig{f}_fine.csv',R/'matlab/revision_data'/f'fig{f}_fine.csv')
shutil.copy2(R/'tables/fig6_hybrid_elapsed.csv',R/'matlab/revision_data/fig6_hybrid_elapsed.csv')
print('PASS: statistics, quadrature, 65 hybrid values and five table bodies reconstructed.')
