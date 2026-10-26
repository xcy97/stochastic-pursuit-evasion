"""Export the five numerical table bodies used by the current manuscript.

Uses only the Python standard library. Run this file directly. The generated
LaTeX tabular files go to revision_reproduction/generated_tables. Captions and
labels remain in the manuscript. No simulation or manuscript edit is made.
"""
from pathlib import Path
import csv
ROOT=Path(__file__).resolve().parent.parent
DATA=ROOT/'tables';OUT=ROOT/'generated_tables';OUT.mkdir(exist_ok=True)
def read(name):
    with (DATA/name).open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
def write(name,cols,head,rows):
    text='\\begin{tabular}{'+cols+'}\n\\toprule\n'
    text+=' & '.join(head)+r' \\'+'\n\\midrule\n'
    text+='\n'.join(' & '.join(row)+r' \\' for row in rows)
    text+='\n\\bottomrule\n\\end{tabular}\n'
    (OUT/name).write_text(text,encoding='utf-8')
for n in [3,4]:
    rows=[]
    for r in read(f'fig{n}_main.csv'):
        val='---' if r['mean'].lower() in ['nan',''] else f"{float(r['mean']):.6f}"
        rows.append([f"{float(r['D']):.6f}",str(int(float(r['Tmax']))),str(int(r['captured'])),str(int(r['censored'])),val])
    write(f'table{n-2}_capture_statistics.tex','rrrrr',[r'$D$',r'$T_{\max}$','Captured','Uncaptured','Sample mean'],rows)
s=read('step_means.csv');d=read('step_paired_differences.csv');rows=[]
for case in range(1,5):
    g=sorted([r for r in s if int(r['case_id'])==case],key=lambda r:-float(r['h']))
    diff=next(r for r in d if int(r['case_id'])==case and float(r['h_test'])>5e-5)
    rows.append([f"{float(g[0]['mu']):g}",f"{float(g[0]['a']):g}",f"{float(g[0]['D']):.6f}"]+[f"{float(r['mean']):.4f}" for r in g]+[f"{float(diff['percent']):.2f}",f"[{float(diff['percent_ci_low']):.2f}, {float(diff['percent_ci_high']):.2f}]"])
write('tableA1_steps.tex','rrrrrrrr',[r'$\mu$',r'$a$',r'$D$',r'$\overline T_{10^{-4}}$',r'$\overline T_{10^{-5}}$',r'$\overline T_{10^{-6}}$',r'$\delta_h$ (\%)',r'95\% interval'],rows)
m=read('model_means.csv');d=read('model_paired_differences.csv');rows=[];effects=[]
for case in range(1,7):
    g=sorted([r for r in m if int(r['case_id'])==case],key=lambda r:r['model']);r=g[0]
    prefix=[f"{float(r['mu']):g}",f"{float(r['a']):g}",f"{float(r['D']):.6f}"]
    c=g[2];theory=float(c['analytic']);relative=100*(float(c['mean'])-theory)/theory
    rows.append(prefix+[f"{float(x['mean']):.4f}" for x in g]+[f"[{float(c['ci_low']):.2f}, {float(c['ci_high']):.2f}]",f"{theory:.4f}",f"{relative:.2f}"])
    values=[]
    for comparison in ['A_minus_B','B_minus_C','A_minus_C']:
        x=next(r for r in d if int(r['case_id'])==case and r['comparison']==comparison)
        values.append(f"{float(x['percent_of_A']):.2f} [{float(x['percent_ci_low']):.2f}, {float(x['percent_ci_high']):.2f}]")
    effects.append(prefix+values)
write('tableA2_model_means.tex','rrrrrrrrr',[r'$\mu$',r'$a$',r'$D$','A','B','C',r'C 95\% interval',r'$T_{\mathrm{an}}$',r'$\varepsilon_C$ (\%)'],rows)
write('tableA3_model_effects.tex','rrrccc',[r'$\mu$',r'$a$',r'$D$',r'$\delta_{AB}$',r'$\delta_{BC}$',r'$\delta_{AC}$'],effects)
print('Five numerical table bodies written to:',OUT)
