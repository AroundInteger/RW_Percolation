#!/usr/bin/env python3
"""fig1 — alpha(p) for the random (kappa=0) network.
Prefers FSS_study/fss_alpha_table.csv (k0p00, L=500) to match the letter's
p'_c ~ 0.681 lineage; falls back to legacy Clusters/universality_class_analysis.csv
with a source annotation on the figure."""
import sys, csv
import os
HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.abspath(os.path.join(HERE,'..','..'))
sys.path.insert(0,HERE)
import numpy as np, rw_figstyle as S
S.apply()
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

def cross(p, a):
    for i in range(len(a)-1):
        if a[i] >= 0.5 >= a[i+1]:
            t = (a[i]-0.5)/(a[i]-a[i+1]) if a[i] != a[i+1] else 0
            return p[i]+t*(p[i+1]-p[i])
    return np.nan

source_note = None
pR, aR, pD, aD = None, None, None, None

fss_csv = os.path.join(ROOT, 'matlab/FSS_study/fss_alpha_table.csv')
if os.path.isfile(fss_csv):
    rows = list(csv.DictReader(open(fss_csv)))
    sub = [r for r in rows if r.get('condition','').strip() == 'k0p00'
           and int(float(r['L'])) == 500]
    if sub:
        pu = sorted(set(float(r['p']) for r in sub))
        am = np.array([np.mean([float(r['alpha']) for r in sub if float(r['p'])==pp
                                and float(r['alpha'])==float(r['alpha'])]) for pp in pu])
        pR = np.array(pu)
        aR = am
        source_note = r'FSS $\kappa=0$, $L=500$ (3 seeds)'

if pR is None:
    legacy = os.path.join(ROOT, 'matlab/Clusters/universality_class_analysis.csv')
    if not os.path.isfile(legacy):
        raise SystemExit('Missing FSS alpha table and legacy %s' % legacy)
    rows = list(csv.DictReader(open(legacy)))
    def series(name):
        d = sorted((float(r['p_value']), float(r['alpha'])) for r in rows if r['variant']==name)
        p, a = zip(*d)
        return np.array(p), np.array(a)
    pR, aR = series('Random_Percolation')
    pD, aD = series('Density_Increment')
    source_note = 'legacy universality_class_analysis.csv'
else:
    pD, aD = None, None

pcR = cross(pR, aR)
pcD = cross(pD, aD) if pD is not None else np.nan

fig, axs = plt.subplots(1, 2, figsize=(11, 4.6))
for ax, (lo, hi, ttl) in zip(axs, [(0, 1, '(a) Full range'), (0.55, 0.82, '(b) Critical region')]):
    ax.plot(pR, aR, '-o', ms=4, lw=1.9, color=S.ACCENT_BLUE, zorder=4,
            label='Random percolation' if pD is None else None)
    if pD is not None:
        ax.plot(pD, aD, '-s', ms=4, lw=1.9, color=S.ACCENT_ORANGE, zorder=3)
    S.criterion_line(ax, 0.5)
    ax.axvline(0.6884, ls=':', lw=1.2, color=S.REF_GREY, alpha=0.9, zorder=2)
    ax.set_xlim(lo, hi)
    ax.set_ylim(-0.05, 1.12)
    ax.set_xlabel(S.XLABEL_P)
    ax.set_title(ttl, fontsize=12)
axs[0].set_ylabel(S.YLABEL_ALPHA)
axs[0].text(0.03, 1.05, 'Sol (Fickian)', fontsize=9.5, color=S.REF_GREY)
axs[0].text(0.85, 0.06, 'Gel (arrested)', fontsize=9.5, color=S.REF_GREY, ha='center')
axs[1].annotate(r"$p_c'\approx0.688\approx1-p_c$", xy=(0.6884, 0.5), xytext=(0.575, 0.74),
                fontsize=10, color=S.REF_GREY,
                arrowprops=dict(arrowstyle='->', color=S.REF_GREY, lw=1.1))
handles = [Line2D([],[],color=S.ACCENT_BLUE,marker='o',ms=5,lw=1.9,label='Random percolation')]
if pD is not None:
    handles.append(Line2D([],[],color=S.ACCENT_ORANGE,marker='s',ms=5,lw=1.9,label='Density increment'))
handles.append(Line2D([],[],color='black',ls='--',lw=1.3,label=r'$\alpha=0.5$ (gel criterion)'))
axs[0].legend(handles=handles, loc='center left', fontsize=9.5)
if source_note:
    fig.text(0.99, 0.01, 'Source: ' + source_note, ha='right', va='bottom', fontsize=8, color='#777')
fig.tight_layout()
out = os.path.join(HERE, 'fig1_random_alpha_vs_p.png')
fig.savefig(out)
print('saved', out, '; pcR=%.4f source=%s' % (pcR, source_note))
