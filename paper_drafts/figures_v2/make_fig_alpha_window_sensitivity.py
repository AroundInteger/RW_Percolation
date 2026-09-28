#!/usr/bin/env python3
"""M4 supplement — p'_c(inf) vs alpha fit-window choice (default / wide / narrow)."""
import sys, csv, os
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import numpy as np
import rw_figstyle as S
S.apply()
import matplotlib.pyplot as plt

summary_path = os.path.join(ROOT, 'matlab/FSS_study/alpha_window_summary.csv')
if not os.path.isfile(summary_path):
    raise SystemExit('Missing %s — run alpha_window_sensitivity.' % summary_path)

WINDOW_ORDER = ['default', 'wide', 'narrow']
WINDOW_LABEL = {
    'default': r'default $[L_W/100,\,L_W/10]$',
    'wide':    r'wide $[L_W/200,\,L_W/20]$',
    'narrow':  r'narrow $[L_W/50,\,L_W/5]$',
}

rows = list(csv.DictReader(open(summary_path)))
# focus on kappa-line conditions with valid pc_inf
by_cond = {}
for r in rows:
    cond = r.get('condition', '').strip().strip('"')
    if not cond.startswith('k') or cond == 'k1p00':
        continue
    win = r.get('window', '').strip().strip('"')
    pc = float(r.get('pc_inf', 'nan'))
    kap = float(r.get('kappa', 'nan'))
    if pc != pc:
        continue
    by_cond.setdefault(cond, dict(kappa=kap, windows={}))[win] = pc

if not by_cond:
    raise SystemExit('No valid rows in alpha_window_summary.csv')

conds = sorted(by_cond, key=lambda c: by_cond[c]['kappa'])
fig, ax = plt.subplots(figsize=(8.2, 5.0))
xpos = np.arange(len(WINDOW_ORDER))
width = 0.22

for i, cond in enumerate(conds):
    d = by_cond[cond]
    vals = [d['windows'].get(w, np.nan) for w in WINDOW_ORDER]
    offset = (i - (len(conds)-1)/2) * width
    col = S.kappa_color(d['kappa'])
    ax.bar(xpos + offset, vals, width=width, color=col, edgecolor='white', linewidth=0.6,
           label=r'$\kappa=%.2g$' % d['kappa'])

ax.set_xticks(xpos)
ax.set_xticklabels([WINDOW_LABEL[w] for w in WINDOW_ORDER], fontsize=10)
ax.set_ylabel(r"$p_c'(\infty)$ from shift fit")
ax.set_title(r"Sensitivity of $p_c'(\infty)$ to MSD $\alpha$ fit window ($L\geq200$)", fontsize=12)
ax.legend(loc='upper left', fontsize=9, ncol=2)
fig.tight_layout()
out = os.path.join(HERE, 'fig_alpha_window_sensitivity.png')
fig.savefig(out, dpi=200)
print('saved', out, '; conditions:', len(conds))
