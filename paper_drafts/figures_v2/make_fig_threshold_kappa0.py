#!/usr/bin/env python3
"""Joint threshold panel at kappa=0: dynamical p'_MR(L), geometric p'_geom(L),
and Bernoulli reference 1 - p_c = 0.6884.

Per-seed thresholds are averaged with +/-1 sigma error bars (N=3 seeds).
MR pcL is derived from fss_alpha_table.csv when a seed column is present;
geometric pcL uses void_geom_fss_kappa0.csv (long format) or its summary."""
import sys, csv, os
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import numpy as np
import rw_figstyle as S
S.apply()
import matplotlib.pyplot as plt

PC_BERN = 0.6884
GEL = 0.5
COND = 'k0p00'


def fnum(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return float('nan')


def cross_interp(p, a, thr=GEL):
    """Match analyze_FSS.m cross_interp: alpha crossing from above thr."""
    p = np.asarray(p, dtype=float)
    a = np.asarray(a, dtype=float)
    if p.size < 2:
        return float('nan')
    s = np.sign(a - thr)
    for i in range(len(s) - 1):
        if s[i + 1] - s[i] < 0:
            dp = p[i + 1] - p[i]
            da = a[i + 1] - a[i]
            if da != 0:
                return p[i] + (thr - a[i]) * dp / da
    return float('nan')


def seed_key(fieldnames):
    if 'seed' in fieldnames:
        return 'seed'
    if 'si' in fieldnames:
        return 'si'
    return None


def mean_std(values):
    vals = [v for v in values if v == v]
    if not vals:
        return float('nan'), float('nan'), 0
    if len(vals) == 1:
        return vals[0], 0.0, 1
    return float(np.mean(vals)), float(np.std(vals, ddof=1)), len(vals)


def load_mr_stats():
    alpha_path = os.path.join(ROOT, 'matlab/FSS_study/fss_alpha_table.csv')
    pcL_path = os.path.join(ROOT, 'matlab/FSS_study/fss_pcL_table.csv')
    stats = {}

    if os.path.isfile(alpha_path):
        with open(alpha_path, newline='') as fh:
            raw = list(csv.DictReader(fh))
        sk = seed_key(raw[0].keys()) if raw else None
        sub = [r for r in raw if r.get('condition', '').strip() == COND]
        if sub and sk:
            Lvals = sorted(set(int(float(r['L'])) for r in sub))
            seeds = sorted(set(int(float(r[sk])) for r in sub))
            for L in Lvals:
                pcs = []
                for si in seeds:
                    pts = [r for r in sub if int(float(r['L'])) == L and int(float(r[sk])) == si]
                    pu = sorted(set(float(r['p']) for r in pts))
                    am = []
                    for pp in pu:
                        alphas = [fnum(r['alpha']) for r in pts if float(r['p']) == pp]
                        alphas = [a for a in alphas if a == a]
                        am.append(float(np.mean(alphas)) if alphas else float('nan'))
                    pm = [pp for pp, aa in zip(pu, am) if pp > 0.5 and aa == aa]
                    ac = [aa for pp, aa in zip(pu, am) if pp > 0.5 and aa == aa]
                    pc = cross_interp(pm, ac)
                    if pc == pc:
                        pcs.append(pc)
                mu, sig, _ = mean_std(pcs)
                if mu == mu:
                    stats[L] = (mu, sig)
            if stats:
                return stats

    if not os.path.isfile(pcL_path):
        raise SystemExit('Missing %s — run analyze_FSS.' % pcL_path)
    for r in csv.DictReader(open(pcL_path)):
        if r.get('condition', '').strip() != COND:
            continue
        L = float(r['L'])
        pc = fnum(r['pcL'])
        if pc == pc:
            stats[L] = (pc, 0.0)
    return stats


def load_geom_stats():
    geom_path = os.path.join(ROOT, 'matlab/FSS_study/void_geom_fss_kappa0.csv')
    summary_path = os.path.join(ROOT, 'matlab/FSS_study/void_geom_fss_kappa0_summary.csv')
    stats = {}

    if os.path.isfile(geom_path):
        with open(geom_path, newline='') as fh:
            rows = list(csv.DictReader(fh))
        if rows:
            sk = seed_key(rows[0].keys())
            if sk:
                Lvals = sorted(set(float(r['L']) for r in rows))
                for L in Lvals:
                    pcs = [fnum(r.get('pc_geom_z', r.get('pc_geom', 'nan')))
                           for r in rows if float(r['L']) == L]
                    mu, sig, _ = mean_std(pcs)
                    if mu == mu:
                        stats[L] = (mu, sig)
                if stats:
                    return stats
            if 'pc_geom_z_mean' in rows[0]:
                for r in rows:
                    L = float(r['L'])
                    mu = fnum(r['pc_geom_z_mean'])
                    sig = fnum(r.get('pc_geom_z_std', '0'))
                    if mu == mu:
                        stats[L] = (mu, sig if sig == sig else 0.0)
                if stats:
                    return stats
            for r in rows:
                L = float(r['L'])
                pc = fnum(r.get('pc_geom_z', r.get('pc_geom', 'nan')))
                if pc == pc:
                    stats[L] = (pc, 0.0)

    if os.path.isfile(summary_path):
        stats = {}
        for r in csv.DictReader(open(summary_path)):
            L = float(r['L'])
            mu = fnum(r.get('pc_geom_z_mean', r.get('pc_geom_z', 'nan')))
            sig = fnum(r.get('pc_geom_z_std', '0'))
            if mu == mu:
                stats[L] = (mu, sig if sig == sig else 0.0)
        if stats:
            return stats

    if not stats:
        raise SystemExit('Missing %s — run void_geom_FSS_kappa0.' % geom_path)
    return stats


def plot_series(ax, Ls, means, stds, color, marker, label, lw=2, ms=8):
    Ls = np.asarray(Ls, dtype=float)
    means = np.asarray(means, dtype=float)
    stds = np.asarray(stds, dtype=float)
    order = np.argsort(Ls)
    Ls, means, stds = Ls[order], means[order], stds[order]

    ax.plot(Ls, means, '-', color=color, lw=lw, zorder=2)
    has_err = stds > 0
    labeled = False
    if np.any(has_err):
        ax.errorbar(Ls[has_err], means[has_err], yerr=stds[has_err],
                    fmt=marker, ms=ms, color=color, mec='white', mew=0.7,
                    capsize=3, elinewidth=1.2, zorder=3, label=label)
        labeled = True
    if np.any(~has_err):
        ax.plot(Ls[~has_err], means[~has_err], marker, ms=ms, color=color,
                mec='white', mew=0.7, zorder=3,
                label=label if not labeled else None)


mr = load_mr_stats()
geom = load_geom_stats()

L_all = sorted(set(mr) | set(geom))
if not L_all:
    raise SystemExit('No threshold data for kappa=0.')

fig, ax = plt.subplots(figsize=(7.4, 5.2))

if mr:
    Lm = sorted(mr)
    plot_series(ax, Lm, [mr[L][0] for L in Lm], [mr[L][1] for L in Lm],
                S.ACCENT_BLUE, 'o',
                r"dynamical $p_c'^{\mathrm{MR}}(L)$  ($\alpha=0.5$)")

if geom:
    Lg = sorted(geom)
    plot_series(ax, Lg, [geom[L][0] for L in Lg], [geom[L][1] for L in Lg],
                S.ACCENT_ORANGE, 'D',
                r"geometric $p_c'^{\mathrm{geom}}(L)$  (void spanning)")

ax.axhline(PC_BERN, ls=':', color=S.REF_GREY, lw=1.3)
ax.text(min(L_all) * 0.98, PC_BERN + 0.004,
        r'$1-p_c=%.4f$ (Bernoulli void threshold)' % PC_BERN,
        color=S.REF_GREY, fontsize=10, va='bottom')

ax.set_xscale('log')
ax.set_xlabel(r'Lattice size $L$')
ax.set_ylabel(S.YLABEL_PCP)
ax.set_title(r"Threshold reconciliation at $\kappa=0$", fontsize=12.5)
handles, labels = ax.get_legend_handles_labels()
if handles:
    leg = ax.legend(handles, labels, loc='lower right', fontsize=10)
    ax.text(0.98, 0.02, 'error bars: seed-to-seed (N=3)',
            transform=ax.transAxes, ha='right', va='bottom', fontsize=8.5,
            color=S.REF_GREY)
ax.set_ylim(0.665, 0.705)
fig.tight_layout()
out = os.path.join(HERE, 'fig_threshold_kappa0.png')
fig.savefig(out, dpi=200)
print('saved', out)
for L in L_all:
    m_mu, m_sig = mr.get(L, (float('nan'), float('nan')))
    g_mu, g_sig = geom.get(L, (float('nan'), float('nan')))
    print('  L=%4g  MR=%s +/- %s  geom=%s +/- %s' % (
        L,
        '%.4f' % m_mu if m_mu == m_mu else '  —  ',
        '%.4f' % m_sig if m_sig == m_sig else '  —  ',
        '%.4f' % g_mu if g_mu == g_mu else '  —  ',
        '%.4f' % g_sig if g_sig == g_sig else '  —  ',
    ))
