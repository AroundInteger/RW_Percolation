"""Shared alpha(p, kappa) grid and drawing for fig1 / fig2a."""
import csv
import os
import numpy as np
import rw_figstyle as S


def kappa_csv_path(root):
    return os.path.join(root, 'matlab/Clusters_kappa/L500/kappa_study_alpha_table.csv')


def load_kappa_rows(root):
    path = kappa_csv_path(root)
    if not os.path.isfile(path):
        raise FileNotFoundError(path)
    rows = list(csv.DictReader(open(path)))
    pv = sorted(set(float(r['p_value']) for r in rows))
    kap = sorted(set(float(r['kappa']) for r in rows))
    return rows, pv, kap


def grid(rows, pv, k):
    a = np.full(len(pv), np.nan)
    s = np.full(len(pv), np.nan)
    for i, p in enumerate(pv):
        v = [float(r['alpha']) for r in rows
             if float(r['kappa']) == k and float(r['p_value']) == p]
        if v:
            a[i] = np.mean(v)
            s[i] = np.std(v) if len(v) > 1 else 0.0
    return np.array(pv), a, s


def pcp(rows, pv, k):
    p, a, _ = grid(rows, pv, k)
    for i in range(len(a) - 1):
        if a[i] >= 0.5 >= a[i + 1]:
            t = (a[i] - 0.5) / (a[i] - a[i + 1]) if a[i] != a[i + 1] else 0
            return p[i] + t * (p[i + 1] - p[i])
    return np.nan


def draw_kappa_curve(ax, rows, pv, k, lw=1.4, fill_alpha=0.12, marker_ms=5):
    """Draw one kappa curve exactly as in fig2a."""
    p, a, sd = grid(rows, pv, k)
    col = S.kappa_color(k)
    ax.plot(p, a, '-', lw=lw, color=col, zorder=3)
    ax.fill_between(p, a - sd, a + sd, color=col, alpha=fill_alpha, zorder=2, lw=0)
    xc = pcp(rows, pv, k)
    if xc == xc:
        ax.plot(xc, 0.5, 'o', ms=marker_ms, color=col, mec='white', mew=0.6, zorder=5)
    return xc


def style_alpha_panel(ax, lo, hi, title):
    S.criterion_line(ax, 0.5)
    ax.text(lo + 0.02 * (hi - lo), 0.53,
            r'$\alpha=0.5$  (Winter–Chambon)', fontsize=9.5, color='black')
    ax.set_xlim(lo, hi)
    ax.set_ylim(-0.05, 1.08)
    ax.set_xlabel(S.XLABEL_P)
    ax.set_title(title, fontsize=12)


def fss_pc_inf_kappa0(root):
    """FSS extrapolated gel point for annotation (letter End Matter)."""
    path = os.path.join(root, 'matlab/FSS_study/fss_pcL_table.csv')
    if not os.path.isfile(path):
        return np.nan
    for r in csv.DictReader(open(path)):
        if r.get('condition', '').strip() == 'k0p00':
            try:
                return float(r.get('pc_inf', 'nan'))
            except ValueError:
                pass
    return np.nan
