#!/usr/bin/env python3
"""
make_fig4b.py  --  publication nu(kappa) figure for the PRL Letter.

Reads matlab/FSS_study/fss_nu_summary.csv and plots the effective
correlation-length exponent along the kappa line from the two estimators with
leverage (data collapse and transition-width scaling). Filled markers = the
clean single-class regime (kappa <= 0.8, shaded nu_eff band); open markers =
the crossover region (kappa >= 0.9) approaching the Eden singular limit
(kappa -> 1, pc' -> 1), where the L<=500 / 3-size fits do not resolve an
exponent. Degenerate width estimates (unphysical value or CI) are suppressed.
The static 3D percolation value nu = 0.88 is drawn for reference.

Usage:
    python3 make_fig4b.py [path/to/fss_nu_summary.csv] [out.png]
Defaults: matlab/FSS_study/fss_nu_summary.csv  ->  paper_drafts/figures_v2/fig4b_nu_vs_kappa.png
"""
import sys, csv, os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.patches import Patch

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
_default_csv = os.path.join(ROOT, 'matlab/FSS_study/fss_nu_summary.csv')
_default_out = os.path.join(HERE, 'fig4b_nu_vs_kappa.png')
csv_path = sys.argv[1] if len(sys.argv) > 1 else _default_csv
out_path = sys.argv[2] if len(sys.argv) > 2 else _default_out

CROSSOVER_KAPPA = 0.9
BAND_KAPPA_MAX  = 0.8
WIDTH_VAL_MAX   = 5.0
WIDTH_CI_MAX    = 2.0

def fnum(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return float('nan')

rows = []
with open(csv_path, newline='') as fh:
    for r in csv.DictReader(fh):
        cond = (r.get('condition') or '').strip().strip('"')
        kap  = fnum(r.get('kappa'))
        if kap != kap or kap >= 1.0 or not cond.startswith('k'):
            continue
        rows.append(dict(kappa=kap,
                         nu_collapse=fnum(r.get('nu_collapse')),
                         nu_collapse_ci=fnum(r.get('nu_collapse_ci')),
                         nu_width=fnum(r.get('nu_width')),
                         nu_width_ci=fnum(r.get('nu_width_ci'))))
rows.sort(key=lambda d: d['kappa'])
if not rows:
    raise SystemExit('No kappa-line rows found in %s' % csv_path)

def width_ok(d):
    v, c = d['nu_width'], d['nu_width_ci']
    return v == v and 0 < v < WIDTH_VAL_MAX and (c != c or c < WIDTH_CI_MAX)

C_COL, C_WID, C_REF, C_CROSS = '#1f6feb', '#d1600a', '#666666', '#bbbbbb'

fig, ax = plt.subplots(figsize=(7.4, 5.4))

ax.axvspan(CROSSOVER_KAPPA, 1.02, color=C_CROSS, alpha=0.14, zorder=0)

band_vals = [v for d in rows if d['kappa'] <= BAND_KAPPA_MAX
             for v in (d['nu_collapse'], d['nu_width']) if v == v]
if band_vals:
    lo, hi = min(band_vals), max(band_vals)
    ax.axhspan(lo, hi, xmax=(CROSSOVER_KAPPA+0.05)/1.07, color=C_COL, alpha=0.07, zorder=0)
    ax.text(0.02, 0.5*(lo+hi)+0.10, r'$\nu_{\mathrm{eff}}\approx%.1f$' % (round(0.5*(lo+hi),1)),
            color=C_COL, fontsize=13, va='center', fontweight='bold')

ax.axhline(0.88, ls='--', lw=1.3, color=C_REF, zorder=1)
ax.text(0.02, 0.90, r'$\nu=0.88$ (static 3D percolation)', color=C_REF, fontsize=10,
        ha='left', va='bottom')

cw = [d for d in rows if d['kappa'] <= BAND_KAPPA_MAX and width_ok(d)]
xw = [d for d in rows if d['kappa'] >= CROSSOVER_KAPPA and width_ok(d)]
if cw:
    ax.errorbar([d['kappa'] for d in cw], [d['nu_width'] for d in cw],
                yerr=[d['nu_width_ci'] if d['nu_width_ci']==d['nu_width_ci'] else 0 for d in cw],
                fmt='s', ms=8, color=C_WID, ecolor=C_WID, capsize=4, lw=1.5,
                mfc=C_WID, mec=C_WID, zorder=4)
if xw:
    ax.errorbar([d['kappa'] for d in xw], [d['nu_width'] for d in xw],
                yerr=[d['nu_width_ci'] if d['nu_width_ci']==d['nu_width_ci'] else 0 for d in xw],
                fmt='s', ms=8, color=C_WID, ecolor=C_WID, capsize=4, lw=1.5,
                mfc='white', mec=C_WID, zorder=4)

cc = [d for d in rows if d['kappa'] <= BAND_KAPPA_MAX and d['nu_collapse']==d['nu_collapse']]
xc = [d for d in rows if d['kappa'] >= CROSSOVER_KAPPA and d['nu_collapse']==d['nu_collapse']]
if cc:
    ax.errorbar([d['kappa'] for d in cc], [d['nu_collapse'] for d in cc],
                yerr=[d['nu_collapse_ci'] if d['nu_collapse_ci']==d['nu_collapse_ci'] else 0 for d in cc],
                fmt='o', ms=9, color=C_COL, ecolor=C_COL, capsize=4, lw=1.5,
                mfc=C_COL, mec=C_COL, zorder=5)
if xc:
    ax.errorbar([d['kappa'] for d in xc], [d['nu_collapse'] for d in xc],
                yerr=[d['nu_collapse_ci'] if d['nu_collapse_ci']==d['nu_collapse_ci'] else 0 for d in xc],
                fmt='o', ms=9, color=C_COL, ecolor=C_COL, capsize=4, lw=1.5,
                mfc='white', mec=C_COL, zorder=5)

ax.text(0.955, 1.15, 'crossover to Eden\nsingular limit\n($\\kappa\\to1$; exponent\nnot determined)',
        fontsize=9.5, color='#555555', ha='center', va='bottom')

ax.set_xlabel(r'$\kappa$  (nucleation-density parameter)', fontsize=13)
ax.set_ylabel(r'effective exponent  $\nu$', fontsize=13)
ax.set_title(r'Correlation-length exponent along the $\kappa$ line ($L\geq200$ fits)', fontsize=12.5)
ax.set_xlim(-0.05, 1.02)
ax.set_ylim(0.4, 3.2)
ax.grid(True, alpha=0.25)
handles = [Line2D([],[],marker='o',color=C_COL,ls='none',ms=9,label=r'$\nu_{\mathrm{collapse}}$ ($\pm$ jackknife)'),
           Line2D([],[],marker='s',color=C_WID,ls='none',ms=8,label=r'$\nu_{\mathrm{width}}$ ($\pm$ jackknife)'),
           Line2D([],[],marker='o',color='#555',ls='none',ms=9,mfc='white',
                  label=r'open: crossover ($\kappa\geq%.2g$)' % CROSSOVER_KAPPA)]
ax.legend(handles=handles, loc='upper left', fontsize=10.5, framealpha=0.95)
fig.tight_layout()
fig.savefig(out_path, dpi=200)
print('saved', out_path, 'from', csv_path)
print('  clean (kappa<=%.2g): %d pts;  crossover (kappa>=%.2g): %d pts' %
      (BAND_KAPPA_MAX, len(cc), CROSSOVER_KAPPA, len(xc)))
print('  width kept:', [round(d['kappa'],3) for d in cw+xw],
      ' width suppressed:', [round(d['kappa'],3) for d in rows if not width_ok(d)])
