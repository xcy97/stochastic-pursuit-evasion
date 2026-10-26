"""Recalculate Figure 6 from retained aggregate data; no simulation.
Elapsed time is retained exactly at the nominal cutoff. The analytical
remaining-time proxy is a stated modeling assumption, not a conditional
remaining time inferred from the actual state at the cutoff.
"""
from pathlib import Path
from decimal import Decimal as Q
import csv
root=Path(__file__).resolve().parent.parent
with (root/'tables/fig6_hybrid_input.csv').open(encoding='utf-8-sig',newline='') as f:rows=list(csv.DictReader(f))
for r in rows:
    q=1-Q(r['capture_rate'])
    r['elapsed_addition']=str(q*Q(r['Tmax']))
    r['hybrid_mean']=str(Q(r['old_hybrid'])+q*Q(r['Tmax']))
with (root/'tables/fig6_hybrid_elapsed.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
print('Updated table:',root/'tables/fig6_hybrid_elapsed.csv')
