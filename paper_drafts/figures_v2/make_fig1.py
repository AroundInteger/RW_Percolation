#!/usr/bin/env python3
"""fig1 — alpha(p) for random (kappa=0): identical rendering to fig2a k=0 curve."""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import numpy as np
import rw_figstyle as S
S.apply()
import matplotlib.pyplot as plt
from kappa_alpha_common import (
    load_kappa_rows, draw_kappa_curve, style_alpha_panel, fss_pc_inf_kappa0,
)

BERNOULLI_PC = 0.6884
KAPPA0 = 0.0

rows, pv, _ = load_kappa_rows(ROOT)
pc_inf = fss_pc_inf_kappa0(ROOT)

fig, axs = plt.subplots(1, 2, figsize=(11, 4.6))
panels = [(0, 1, '(a) Full range'), (0.6, 1.0, '(b) Critical region')]
pcR = np.nan
for ax, (lo, hi, ttl) in zip(axs, panels):
    pcR = draw_kappa_curve(ax, rows, pv, KAPPA0)
    style_alpha_panel(ax, lo, hi, ttl)
    ax.axvline(BERNOULLI_PC, ls=':', lw=1.1, color=S.REF_GREY, alpha=0.75, zorder=1)

axs[0].set_ylabel(S.YLABEL_ALPHA)

col = S.kappa_color(KAPPA0)
if pcR == pcR:
    axs[1].annotate(
        r"$p_c'=%.3f$ at $L=500$" % pcR,
        xy=(pcR, 0.5), xytext=(0.62, 0.72),
        fontsize=10, color=col,
        arrowprops=dict(arrowstyle='->', color=col, lw=1.1),
    )
if pc_inf == pc_inf:
    axs[1].text(
        0.605, 0.88,
        r"FSS: $p_c'(\infty)\approx%.3f$" % pc_inf,
        fontsize=9.5, color=S.REF_GREY,
    )
axs[1].text(
    BERNOULLI_PC + 0.008, 0.08,
    r'$1-p_c=%.4f$' % BERNOULLI_PC,
    fontsize=9, color=S.REF_GREY, rotation=90, va='bottom',
)

sm = S.kappa_mappable(0, 1)
cb = fig.colorbar(sm, ax=axs, pad=0.015, fraction=0.045)
cb.set_label(S.XLABEL_KAPPA, fontsize=12)

fig.tight_layout()
out = os.path.join(HERE, 'fig1_random_alpha_vs_p.png')
fig.savefig(out, bbox_inches='tight')
print('saved', out, '; pcL=%.4f pc_inf=%s' % (pcR, pc_inf))
