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


def seeds_for_kappa(rows, k):
    return sorted(
        int(float(r['seed']))
        for r in rows
        if float(r['kappa']) == k and r.get('seed', '') != ''
    )


def grid_one_seed(rows, pv, k, seed):
    """Alpha vs p for one (kappa, seed); missing points stay NaN."""
    p = np.array(pv, dtype=float)
    a = np.full(len(pv), np.nan)
    for i, pv_i in enumerate(pv):
        v = [
            float(r['alpha'])
            for r in rows
            if float(r['kappa']) == k
            and float(r['p_value']) == pv_i
            and int(float(r['seed'])) == seed
        ]
        if v:
            a[i] = float(np.mean(v))
    return p, a


def _pcp_from_arrays(p, a, thr=0.5):
    p = np.asarray(p, dtype=float)
    a = np.asarray(a, dtype=float)
    for i in range(len(a) - 1):
        if a[i] >= thr >= a[i + 1]:
            t = (a[i] - thr) / (a[i] - a[i + 1]) if a[i] != a[i + 1] else 0.0
            return p[i] + t * (p[i + 1] - p[i])
    return np.nan


def pcp_all_seeds(rows, pv, k):
    """Per-seed gel points p'_c (alpha=0.5 crossing)."""
    out = []
    for seed in seeds_for_kappa(rows, k):
        p, a = grid_one_seed(rows, pv, k, seed)
        out.append(_pcp_from_arrays(p, a))
    return np.array(out, dtype=float)


def grid(rows, pv, k):
    a = np.full(len(pv), np.nan)
    s = np.full(len(pv), np.nan)
    for i, p in enumerate(pv):
        v = [
            float(r['alpha'])
            for r in rows
            if float(r['kappa']) == k and float(r['p_value']) == p
        ]
        if v:
            a[i] = np.mean(v)
            s[i] = np.std(v, ddof=1) if len(v) > 1 else 0.0
    return np.array(pv), a, s


def pcp(rows, pv, k):
    """Mean-curve gel point (legacy fig2b / annotations)."""
    p, a, _ = grid(rows, pv, k)
    return _pcp_from_arrays(p, a)


def draw_gel_point_seed_uncertainty(ax, rows, pv, k, color, marker_ms=5, y=0.5):
    """Horizontal seed-to-seed uncertainty on p'_c at alpha=0.5."""
    pcs = pcp_all_seeds(rows, pv, k)
    finite = pcs[np.isfinite(pcs)]
    if finite.size == 0:
        return np.nan
    pc_mean = float(np.mean(finite))
    ax.plot(
        pc_mean, y, 'o', ms=marker_ms, color=color, mec='white', mew=0.6, zorder=5,
    )
    if finite.size > 1:
        pc_std = float(np.std(finite, ddof=1))
        ax.errorbar(
            pc_mean, y, xerr=pc_std, fmt='none', ecolor=color, elinewidth=1.2,
            capsize=3, capthick=1.0, zorder=4,
        )
    return pc_mean


def draw_kappa_curve_band(
    ax, rows, pv, k, lw=1.4, fill_alpha=0.12, marker_ms=5, gel_point=True,
):
    p, a, sd = grid(rows, pv, k)
    col = S.kappa_color(k)
    ax.plot(p, a, '-', lw=lw, color=col, zorder=3)
    ax.fill_between(p, a - sd, a + sd, color=col, alpha=fill_alpha, zorder=2, lw=0)
    if gel_point:
        return draw_gel_point_seed_uncertainty(ax, rows, pv, k, col, marker_ms=marker_ms)
    return pcp(rows, pv, k)


def draw_kappa_curve_errbars(
    ax, rows, pv, k, lw=1.4, marker_ms=5, capsize=2, subsample=1, gel_point=True,
):
    p, a, sd = grid(rows, pv, k)
    col = S.kappa_color(k)
    idx = np.arange(len(p))
    if subsample > 1:
        idx = idx[::subsample]
    ax.errorbar(
        p[idx], a[idx], yerr=sd[idx], fmt='-', lw=lw, color=col, capsize=capsize,
        elinewidth=0.9, zorder=3,
    )
    if gel_point:
        return draw_gel_point_seed_uncertainty(ax, rows, pv, k, col, marker_ms=marker_ms)
    return pcp(rows, pv, k)


def draw_kappa_curve(ax, rows, pv, k, lw=1.4, fill_alpha=0.12, marker_ms=5):
    """Draw one kappa curve exactly as in fig2a (band + mean-curve gel marker)."""
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
    path = os.path.join(root, 'matlab/FSS_study/fss_nu_summary.csv')
    if not os.path.isfile(path):
        return np.nan
    for r in csv.DictReader(open(path)):
        if r.get('condition', '').strip() == 'k0p00':
            try:
                return float(r.get('pc_inf', 'nan'))
            except ValueError:
                pass
    return np.nan
