#!/usr/bin/env python3
"""fig1 — alpha(p) for random (kappa=0): band (letter) and error-bar variants."""
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
    load_kappa_rows,
    draw_kappa_curve_band,
    draw_kappa_curve_errbars,
    style_alpha_panel,
    fss_pc_inf_kappa0,
)

BERNOULLI_PC = 0.6884
KAPPA0 = 0.0
PANELS = [(0, 1, '(a) Full range'), (0.6, 1.0, '(b) Critical region')]


def _decorate_critical(ax, pcR, pc_inf, col):
    if pcR == pcR:
        ax.annotate(
            r"$p_c'=%.3f$ at $L=500$" % pcR,
            xy=(pcR, 0.5), xytext=(0.62, 0.72),
            fontsize=10, color=col,
            arrowprops=dict(arrowstyle='->', color=col, lw=1.1),
        )
    if pc_inf == pc_inf:
        ax.text(
            0.605, 0.88,
            r"FSS: $p_c'(\infty)\approx%.3f$" % pc_inf,
            fontsize=9.5, color=S.REF_GREY,
        )
    ax.text(
        BERNOULLI_PC + 0.008, 0.08,
        r'$1-p_c=%.4f$' % BERNOULLI_PC,
        fontsize=9, color=S.REF_GREY, rotation=90, va='bottom',
    )


def build_fig1(rows, pv, pc_inf, mode='band'):
    """mode: 'band' (letter default) or 'errbars' (comparison)."""
    fig, axs = plt.subplots(1, 2, figsize=(11, 4.6))
    pcR = np.nan
    col = S.kappa_color(KAPPA0)
    for j, (ax, (lo, hi, ttl)) in enumerate(zip(axs, PANELS)):
        if mode == 'band':
            pcR = draw_kappa_curve_band(ax, rows, pv, KAPPA0)
        else:
            step = 2 if j == 0 else 1
            pcR = draw_kappa_curve_errbars(
                ax, rows, pv, KAPPA0, subsample=step,
            )
        style_alpha_panel(ax, lo, hi, ttl)
        ax.axvline(
            BERNOULLI_PC, ls=':', lw=1.1, color=S.REF_GREY, alpha=0.75, zorder=1,
        )

    axs[0].set_ylabel(S.YLABEL_ALPHA)
    if mode == 'band':
        axs[0].text(
            0.03, 0.12, r'$\pm 1\sigma$, $N_s=3$ lattices',
            fontsize=9, color=col, transform=axs[0].transAxes,
        )

    _decorate_critical(axs[1], pcR, pc_inf, col)

    sm = S.kappa_mappable(0, 1)
    cb = fig.colorbar(sm, ax=axs, pad=0.015, fraction=0.045)
    cb.set_label(S.XLABEL_KAPPA, fontsize=12)
    fig.tight_layout()
    return fig, pcR


rows, pv, _ = load_kappa_rows(ROOT)
pc_inf = fss_pc_inf_kappa0(ROOT)

for mode, fname in (
    ('band', 'fig1_random_alpha_vs_p.png'),
    ('errbars', 'fig1_random_alpha_vs_p_errbars.png'),
):
    fig, pcR = build_fig1(rows, pv, pc_inf, mode=mode)
    out = os.path.join(HERE, fname)
    fig.savefig(out, bbox_inches='tight')
    plt.close(fig)
    print('saved', out, '; mode=%s pcL=%.4f pc_inf=%s' % (mode, pcR, pc_inf))
