#!/usr/bin/env python3
"""Joint threshold panel at kappa=0: dynamical p'_MR(L), geometric p'_geom(L),
and Bernoulli reference 1 - p_c = 0.6884."""
import sys, csv, os
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import numpy as np
import rw_figstyle as S
S.apply()
import matplotlib.pyplot as plt

PC_BERN = 0.6884

pcL_path = os.path.join(ROOT, 'matlab/FSS_study/fss_pcL_table.csv')
geom_path = os.path.join(ROOT, 'matlab/FSS_study/void_geom_fss_kappa0.csv')
if not os.path.isfile(pcL_path):
    raise SystemExit('Missing %s — run analyze_FSS.' % pcL_path)
if not os.path.isfile(geom_path):
    raise SystemExit('Missing %s — run void_geom_FSS_kappa0.' % geom_path)

mr = {}
for r in csv.DictReader(open(pcL_path)):
    if r.get('condition', '').strip() != 'k0p00':
        continue
    L = float(r['L'])
    pc = float(r['pcL'])
    if pc == pc:
        mr[L] = pc

geom = {}
for r in csv.DictReader(open(geom_path)):
    L = float(r['L'])
    pc = float(r.get('pc_geom_z', r.get('pc_geom', 'nan')))
    if pc == pc:
        geom[L] = pc

L_all = sorted(set(mr) | set(geom))
if not L_all:
    raise SystemExit('No threshold data for kappa=0.')

fig, ax = plt.subplots(figsize=(7.4, 5.2))
Lm = np.array([L for L in L_all if L in mr])
if len(Lm):
    ax.plot(Lm, [mr[L] for L in Lm], '-o', ms=8, color=S.ACCENT_BLUE, mec='white', mew=0.7,
            lw=2, label=r"dynamical $p_c'^{\mathrm{MR}}(L)$  ($\alpha=0.5$)")
Lg = np.array([L for L in L_all if L in geom])
if len(Lg):
    ax.plot(Lg, [geom[L] for L in Lg], 'D', ms=9, color=S.ACCENT_ORANGE, mec='white', mew=0.7,
            label=r"geometric $p_c'^{\mathrm{geom}}(L)$  (void spanning)")

ax.axhline(PC_BERN, ls=':', color=S.REF_GREY, lw=1.3)
ax.text(min(L_all)*0.98, PC_BERN + 0.004, r'$1-p_c=%.4f$ (Bernoulli void threshold)' % PC_BERN,
        color=S.REF_GREY, fontsize=10, va='bottom')

ax.set_xscale('log')
ax.set_xlabel(r'Lattice size $L$')
ax.set_ylabel(S.YLABEL_PCP)
ax.set_title(r"Threshold reconciliation at $\kappa=0$", fontsize=12.5)
ax.legend(loc='lower right', fontsize=10)
ax.set_ylim(0.665, 0.705)
fig.tight_layout()
out = os.path.join(HERE, 'fig_threshold_kappa0.png')
fig.savefig(out, dpi=200)
print('saved', out)
for L in L_all:
    print('  L=%4g  MR=%s  geom=%s' % (L,
          '%.4f' % mr[L] if L in mr else '  —  ',
          '%.4f' % geom[L] if L in geom else '  —  '))
