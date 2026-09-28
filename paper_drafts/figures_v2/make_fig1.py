#!/usr/bin/env python3
"""fig1 — alpha(p) for random (kappa=0), styled to match fig2a.

Prefers FSS_study/fss_alpha_table.csv (k0p00, L=500) for the letter's
p'_c ~ 0.681 lineage; falls back to legacy Clusters CSV if needed."""
import sys, csv, os
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import numpy as np
import rw_figstyle as S
S.apply()
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

BERNOULLI_PC = 0.6884  # 1 - p_c reference, not the dynamical crossing


def cross(p, a):
    for i in range(len(a) - 1):
        if a[i] >= 0.5 >= a[i + 1]:
            t = (a[i] - 0.5) / (a[i] - a[i + 1]) if a[i] != a[i + 1] else 0
            return p[i] + t * (p[i + 1] - p[i])
    return np.nan


def fss_kappa0(L=500):
    fss_csv = os.path.join(ROOT, 'matlab/FSS_study/fss_alpha_table.csv')
    if not os.path.isfile(fss_csv):
        return None
    rows = [r for r in csv.DictReader(open(fss_csv))
            if r.get('condition', '').strip() == 'k0p00'
            and int(float(r['L'])) == L]
    if not rows:
        return None
    pu = sorted(set(float(r['p']) for r in rows))
    am, sd = [], []
    for pp in pu:
        vals = [float(r['alpha']) for r in rows if float(r['p']) == pp
                and float(r['alpha']) == float(r['alpha'])]
        am.append(np.mean(vals))
        sd.append(np.std(vals) if len(vals) > 1 else 0.0)
    return np.array(pu), np.array(am), np.array(sd), 'FSS'


def legacy_series():
    legacy = os.path.join(ROOT, 'matlab/Clusters/universality_class_analysis.csv')
    if not os.path.isfile(legacy):
        return None
    rows = list(csv.DictReader(open(legacy)))

    def series(name):
        d = sorted((float(r['p_value']), float(r['alpha']))
                   for r in rows if r['variant'] == name)
        p, a = zip(*d)
        return np.array(p), np.array(a), np.zeros(len(p)), 'legacy'

    return series('Random_Percolation'), series('Density_Increment')


data = fss_kappa0()
pD = aD = sdD = None
source = None
if data:
    pR, aR, sdR, source = data
else:
    leg = legacy_series()
    if leg is None:
        raise SystemExit('Missing FSS alpha table and legacy Clusters CSV')
    (pR, aR, sdR, source), (pD, aD, sdD, _) = leg

pcR = cross(pR, aR)
col = S.kappa_color(0.0)

fig, axs = plt.subplots(1, 2, figsize=(11, 4.6))
for ax, (lo, hi, ttl) in zip(axs, [(0, 1, '(a) Full range'), (0.60, 0.78, '(b) Critical region')]):
    ax.fill_between(pR, aR - sdR, aR + sdR, color=col, alpha=0.14, zorder=2, lw=0)
    ax.plot(pR, aR, '-', lw=1.6, color=col, zorder=4)
    if pcR == pcR:
        ax.plot(pcR, 0.5, 'o', ms=6, color=col, mec='white', mew=0.7, zorder=5)
    if pD is not None:
        ax.plot(pD, aD, '-', lw=1.4, color=S.ACCENT_ORANGE, alpha=0.85, zorder=3)
    S.criterion_line(ax, 0.5)
    ax.axvline(BERNOULLI_PC, ls=':', lw=1.2, color=S.REF_GREY, alpha=0.85, zorder=1)
    ax.text(lo + 0.02 * (hi - lo), 0.53, r'$\alpha=0.5$  (Winter–Chambon)', fontsize=9.5, color='black')
    ax.set_xlim(lo, hi)
    ax.set_ylim(-0.05, 1.08)
    ax.set_xlabel(S.XLABEL_P)
    ax.set_title(ttl, fontsize=12)

axs[0].set_ylabel(S.YLABEL_ALPHA)
if pcR == pcR:
    axs[1].annotate(
        r"$p_c'(\infty)\approx%.3f$" % pcR,
        xy=(pcR, 0.5), xytext=(0.615, 0.72),
        fontsize=10, color=col,
        arrowprops=dict(arrowstyle='->', color=col, lw=1.1),
    )
axs[1].text(
    BERNOULLI_PC + 0.004, 0.12,
    r'$1-p_c=%.4f$' % BERNOULLI_PC,
    fontsize=9, color=S.REF_GREY, rotation=90, va='bottom',
)

handles = [
    Line2D([], [], color=col, lw=1.6, label=r'Random ($\kappa=0$)'),
    Line2D([], [], color='black', ls='--', lw=1.3, label=r'$\alpha=0.5$'),
    Line2D([], [], color=S.REF_GREY, ls=':', lw=1.2, label=r'Bernoulli $1-p_c$'),
]
if pD is not None:
    handles.insert(1, Line2D([], [], color=S.ACCENT_ORANGE, lw=1.4, label='Density increment'))
axs[0].legend(handles=handles, loc='center left', fontsize=9.5)

fig.tight_layout()
out = os.path.join(HERE, 'fig1_random_alpha_vs_p.png')
fig.savefig(out, bbox_inches='tight')
print('saved', out, '; pcR=%.4f source=%s' % (pcR, source))
