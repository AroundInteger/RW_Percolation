#!/usr/bin/env python3
"""fig_collapse — 2x3 data-collapse panels at kappa = 0, 0.6, 0.8.
Top row: alpha(p,L) vs p (raw). Bottom row: alpha vs (p - pc_inf) L^{1/nu}
after collapse using nu_collapse (fallback nu_shift) from fss_nu_summary.csv.
Output: fig_collapse_kappa035.png"""
import sys, csv, os
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import numpy as np
import rw_figstyle as S
S.apply()
import matplotlib.pyplot as plt

KAPPA_TAGS = [('k0p00', 0.0), ('k0p60', 0.6), ('k0p80', 0.8)]
LMIN_SHOW = 200

def fnum(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return float('nan')

summary_path = os.path.join(ROOT, 'matlab/FSS_study/fss_nu_summary.csv')
alpha_path = os.path.join(ROOT, 'matlab/FSS_study/fss_alpha_table.csv')
for p in (summary_path, alpha_path):
    if not os.path.isfile(p):
        raise SystemExit('Missing %s — run RW3D_FSS_study + analyze_FSS.' % p)

meta = {}
for r in csv.DictReader(open(summary_path)):
    cond = r['condition'].strip().strip('"')
    nu_c = fnum(r.get('nu_collapse'))
    nu_s = fnum(r.get('nu_shift'))
    meta[cond] = dict(
        kappa=fnum(r.get('kappa')),
        pc_inf=fnum(r.get('pc_inf')),
        nu=nu_c if nu_c == nu_c else nu_s,
    )

raw = list(csv.DictReader(open(alpha_path)))

fig, axs = plt.subplots(2, 3, figsize=(12.5, 7.2), sharey='row')

for j, (tag, kap_ref) in enumerate(KAPPA_TAGS):
    if tag not in meta or meta[tag]['nu'] != meta[tag]['nu']:
        axs[0, j].text(0.5, 0.5, 'missing ' + tag, ha='center', va='center', transform=axs[0, j].transAxes)
        continue
    pc_inf = meta[tag]['pc_inf']
    nu = meta[tag]['nu']
    col = S.kappa_color(kap_ref)

    sub = [r for r in raw if r.get('condition', '').strip() == tag]
    Lvals = sorted(set(int(float(r['L'])) for r in sub))
    Lplot = [L for L in Lvals if L >= LMIN_SHOW]

    ax_top = axs[0, j]
    ax_bot = axs[1, j]
    for L in Lplot:
        pts = [r for r in sub if int(float(r['L'])) == L]
        pu = sorted(set(float(r['p']) for r in pts))
        am = np.array([np.mean([float(r['alpha']) for r in pts if float(r['p']) == pp
                                and fnum(r['alpha']) == fnum(r['alpha'])]) for pp in pu])
        lw = 1.2 if L == 500 else 0.9
        ms = 4 if L == 500 else 3
        ax_top.plot(pu, am, '-o', ms=ms, lw=lw, color=col, alpha=0.45 + 0.1*(L == 500), label='L=%d' % L)
        if pc_inf == pc_inf and nu == nu:
            xcol = (np.array(pu) - pc_inf) * L**(1.0 / nu)
            m = (np.array(pu) > 0.5) & (np.abs(np.array(pu) - pc_inf) <= 0.10)
            ax_bot.plot(xcol[m], am[m], 'o', ms=ms, color=col, alpha=0.55, label='L=%d' % L)

    S.criterion_line(ax_top, 0.5)
    ax_top.axvline(pc_inf, ls=':', color=S.REF_GREY, lw=1.0)
    ax_top.set_title(r'$\kappa=%.2g$  raw' % kap_ref, fontsize=11)
    ax_top.set_xlim(0.55, min(0.95, pc_inf + 0.18 if pc_inf == pc_inf else 0.95))
    if j == 0:
        ax_top.set_ylabel(S.YLABEL_ALPHA)
    ax_top.legend(fontsize=7.5, loc='lower left', framealpha=0.9)

    S.criterion_line(ax_bot, 0.5)
    ax_bot.set_title(r'collapsed ($\nu=%.2f$)' % nu, fontsize=11)
    ax_bot.set_xlabel(r"$(p-p_c'(\infty))\,L^{1/\nu}$")
    if j == 0:
        ax_bot.set_ylabel(S.YLABEL_ALPHA)

fig.suptitle(r'Data collapse of $\alpha(p,L)$ at $\kappa=0,\,0.6,\,0.8$ ($L\geq200$)', fontsize=13, y=1.01)
fig.tight_layout()
out = os.path.join(HERE, 'fig_collapse_kappa035.png')
fig.savefig(out, bbox_inches='tight')
print('saved', out)
