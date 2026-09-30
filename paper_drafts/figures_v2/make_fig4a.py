#!/usr/bin/env python3
"""fig4a — finite-size scaling of the gel point, pc'(L) vs L^{-1/nu}.
Rebuilt in Python to match the shared figure system (retires the MATLAB export).
Each kappa condition uses its own fitted nu (nu_collapse, fallback nu_shift) from
fss_nu_summary.csv so the abscissa is not circular. Filled = L>=200 (used in fits),
open = L<200 (excluded). kappa in the plasma ramp; kappa>=0.97 crossover drawn
with dashed fits."""
import sys, csv
import os
HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.abspath(os.path.join(HERE,'..','..'))
sys.path.insert(0,HERE)
import numpy as np
import rw_figstyle as S
S.apply()
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

LMIN_FIT = 200
CROSS = 0.9

def fnum(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return float('nan')

# per-condition nu from summary
nu_map = {}
summary_path = os.path.join(ROOT, 'matlab/FSS_study/fss_nu_summary.csv')
if not os.path.isfile(summary_path):
    raise SystemExit('Missing %s — run analyze_FSS first.' % summary_path)
for r in csv.DictReader(open(summary_path)):
    cond = r['condition'].strip().strip('"')
    nu_c = fnum(r.get('nu_collapse'))
    nu_s = fnum(r.get('nu_shift'))
    nu = nu_c if nu_c == nu_c else nu_s
    if nu == nu:
        nu_map[cond] = nu

rows = {}
pcL_path = os.path.join(ROOT, 'matlab/FSS_study/fss_pcL_table.csv')
if not os.path.isfile(pcL_path):
    raise SystemExit('Missing %s — run analyze_FSS first.' % pcL_path)
for r in csv.DictReader(open(pcL_path)):
    cond = r['condition'].strip()
    if not cond.startswith('k') or cond == 'k1p00':
        continue
    if cond not in nu_map:
        continue
    kap = float(r['kappa'])
    rows.setdefault(cond, dict(kappa=kap, nu=nu_map[cond], L=[], pc=[]))
    rows[cond]['L'].append(float(r['L']))
    rows[cond]['pc'].append(float(r['pcL']))

if not rows:
    raise SystemExit('No kappa-line rows with valid nu in summary + pcL tables.')

order = sorted(rows, key=lambda c: rows[c]['kappa'])
fig, ax = plt.subplots(figsize=(7.4, 5.4))

for cond in order:
    d = rows[cond]; kap = d['kappa']; nu = d['nu']
    L = np.array(d['L']); pc = np.array(d['pc'])
    x = L**(-1.0/nu)
    col = S.kappa_color(kap)
    cross = kap >= CROSS
    fitm = L >= LMIN_FIT
    if fitm.sum() >= 2:
        b, a = np.polyfit(x[fitm], pc[fitm], 1)
        xx = np.linspace(0, x[fitm].max()*1.05, 50)
        ax.plot(xx, a + b*xx, ls='--' if cross else '-', lw=1.5, color=col, zorder=2, alpha=0.9)
        ax.plot(0, a, marker='D', ms=7, color=col, mec='white', mew=0.8, zorder=6)
    ax.plot(x[fitm], pc[fitm], 'o', ms=8, color=col, mfc=col, mec='white', mew=0.7, zorder=5)
    ax.plot(x[~fitm], pc[~fitm], 'o', ms=8, color=col, mfc='white', mec=col, mew=1.4, zorder=4)

ax.set_xlabel(r"$L^{-1/\nu}$  (per-$\kappa$ fitted $\nu$)", fontsize=13)
ax.set_ylabel(S.YLABEL_PCP, fontsize=13)
ax.set_title(r'Finite-size scaling of the gel point', fontsize=12.5)
ax.set_xlim(-0.002, None)
ax.axvline(0, color=S.REF_GREY, lw=0.8, alpha=0.5, zorder=0)

sm = S.kappa_mappable(0, 1)
cb = fig.colorbar(sm, ax=ax, pad=0.015)
cb.set_label(r'$\kappa$', fontsize=13)

handles = [
    Line2D([],[],marker='o',color=S.REF_GREY,ls='none',ms=8,mec='white',label=r'$L\geq200$ (fitted)'),
    Line2D([],[],marker='o',color='none',mec=S.REF_GREY,ls='none',ms=8,mew=1.4,label=r'$L<200$ (excluded)'),
    Line2D([],[],marker='D',color=S.REF_GREY,ls='none',ms=7,mec='white',label=r"$p_c'(\infty)$ intercept"),
    Line2D([],[],ls='--',color=S.REF_GREY,lw=1.5,label=r'crossover ($\kappa\geq0.97$)'),
]
ax.legend(handles=handles, loc='upper left', fontsize=9.5)
fig.tight_layout()
out = os.path.join(HERE, 'fig4a_fss_pcL.png')
fig.savefig(out)
print('saved', out, '; conditions:', [(c, rows[c]['kappa'], rows[c]['nu']) for c in order])
