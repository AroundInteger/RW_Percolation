#!/usr/bin/env python3
"""fig2a (alpha(p,kappa) family) and fig2b (pc'(kappa) tunable gel point)."""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import numpy as np
import rw_figstyle as S
S.apply()
import matplotlib.pyplot as plt
from kappa_alpha_common import load_kappa_rows, draw_kappa_curve, style_alpha_panel, pcp

rows, pv, kap = load_kappa_rows(ROOT)

# ---------- fig2a ----------
fig, axs = plt.subplots(1, 2, figsize=(11, 4.6))
for ax, (lo, hi, ttl) in zip(axs, [(0, 1, '(a) Full range'), (0.6, 1.0, '(b) Critical region')]):
    for k in kap:
        if k >= 1.0:
            continue
        draw_kappa_curve(ax, rows, pv, k)
    style_alpha_panel(ax, lo, hi, ttl)
axs[0].set_ylabel(S.YLABEL_ALPHA)
sm = S.kappa_mappable(0, 1)
cb = fig.colorbar(sm, ax=axs, pad=0.015, fraction=0.045)
cb.set_label(S.XLABEL_KAPPA, fontsize=12)
fig.savefig(os.path.join(HERE, 'fig2a_kappa_alpha_vs_p.png'), bbox_inches='tight')
print('saved fig2a')

# ---------- fig2b ----------
kk = np.array([k for k in kap if k < 1.0])
pc = np.array([pcp(rows, pv, k) for k in kk])
cols = [S.kappa_color(k) for k in kk]
fig, axs = plt.subplots(1, 2, figsize=(11, 4.6))
ax = axs[0]
ax.scatter(kk, pc, c=cols, s=70, edgecolors='white', linewidths=0.8, zorder=5)
S.reference_line(ax, pc[0])
ax.text(0.02, pc[0] - 0.012, r"Bernoulli $p_c'=%.3f$" % pc[0],
        fontsize=9.5, color=S.REF_GREY, va='top')
ax.annotate('', xy=(1.0, 0.99), xytext=(1.0, pc[-1]),
            arrowprops=dict(arrowstyle='->', color=S.CROSS_GREY, lw=1.2))
ax.text(0.86, 0.95, r"Eden bound $p_c' \to 1$", fontsize=9.5, color='#555', ha='center')
ax.text(0.5, 0.72, r"span $p_c'\approx0.68$–$0.91$", fontsize=10, color=S.ACCENT_BLUE, ha='center')
ax.set_xlabel(S.XLABEL_KAPPA)
ax.set_ylabel(S.YLABEL_PCP)
ax.set_title(r"(a) Tunable gel point $p_c'(\kappa)$", fontsize=12)
ax.set_xlim(-0.05, 1.08)
ax.set_ylim(0.64, 1.0)
ax = axs[1]
sf = 1.0 - kk
ax.scatter(sf, pc, c=cols, s=70, edgecolors='white', linewidths=0.8, zorder=5)
ax.axvline(1e-2, ls='--', color=S.REF_GREY, lw=1.1)
ax.text(1.1e-2, 0.66, r'$\sim1\%$ seed fraction', fontsize=9.5, color=S.REF_GREY)
ax.set_xscale('log')
ax.set_xlabel(r'Seed fraction  $1-\kappa$')
ax.set_ylabel(S.YLABEL_PCP)
ax.set_title('(b) Two regimes', fontsize=12)
ax.set_ylim(0.64, 1.0)
sm = S.kappa_mappable(0, 1)
cb = fig.colorbar(sm, ax=axs, pad=0.015, fraction=0.045)
cb.set_label(S.XLABEL_KAPPA, fontsize=12)
fig.savefig(os.path.join(HERE, 'fig2b_gelpoint_vs_kappa.png'), bbox_inches='tight')
print('saved fig2b ; pc span', round(pc.min(), 3), round(pc.max(), 3))
