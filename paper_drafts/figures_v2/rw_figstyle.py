"""
rw_figstyle.py — one shared visual system for all RW_Percolation figures.

Import at the top of every figure generator:
    import rw_figstyle as S ; S.apply()

Design system
-------------
* kappa dimension  : plasma colour-ramp, kappa=0 (purple) -> kappa=1 (yellow)
* two fixed accents: ACCENT_BLUE (#1f6feb), ACCENT_ORANGE (#d1600a)
* criterion lines  : black dashed  (alpha=0.5 / delta=45 deg)
* reference lines  : grey dashed   (static percolation nu=0.88, pc etc.)
* crossover region : light-grey shading
* locked axis text : XLABEL_P (occupation probability p),
                     YLABEL_ALPHA (anomalous-diffusion exponent alpha)
"""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import Normalize
from matplotlib.cm import ScalarMappable

# ---- fixed palette ----
ACCENT_BLUE   = '#1f6feb'
ACCENT_ORANGE = '#d1600a'
REF_GREY      = '#666666'
CROSS_GREY    = '#bbbbbb'
KAPPA_CMAP    = plt.cm.plasma

# ---- locked axis terminology (matches the Letter) ----
XLABEL_P      = r'Occupation probability $p$'
YLABEL_ALPHA  = r'Anomalous-diffusion exponent $\alpha$'
YLABEL_PCP    = r"Gel point $p_c'$"
XLABEL_KAPPA  = r'$\kappa$  (nucleation-density parameter)'

def apply():
    plt.rcParams.update({
        'figure.facecolor' : 'white',
        'savefig.facecolor': 'white',
        'savefig.dpi'      : 200,
        'font.size'        : 12,
        'axes.titlesize'   : 13,
        'axes.labelsize'   : 13,
        'axes.linewidth'   : 1.0,
        'axes.grid'        : True,
        'grid.alpha'       : 0.25,
        'grid.linewidth'   : 0.6,
        'legend.fontsize'  : 10.5,
        'legend.framealpha': 0.95,
        'lines.linewidth'  : 1.8,
        'xtick.labelsize'  : 11,
        'ytick.labelsize'  : 11,
        'mathtext.fontset' : 'dejavusans',
    })

def kappa_color(kappa, kmin=0.0, kmax=1.0):
    """Plasma colour for a kappa value, clipped to [0.05,0.92] so the extreme
    ends stay legible (pure yellow / very dark purple are avoided)."""
    if kappa is None or kappa != kappa:
        return REF_GREY
    t = (kappa - kmin) / (kmax - kmin) if kmax > kmin else 0.0
    t = min(max(t, 0.0), 1.0)
    return KAPPA_CMAP(0.05 + 0.87 * t)

def kappa_mappable(kmin=0.0, kmax=1.0):
    sm = ScalarMappable(norm=Normalize(kmin, kmax), cmap=KAPPA_CMAP)
    sm.set_array([])
    return sm

def criterion_line(ax, y, label=None, orient='h'):
    if orient == 'h':
        ax.axhline(y, ls='--', lw=1.3, color='black', zorder=1)
    else:
        ax.axvline(y, ls='--', lw=1.3, color='black', zorder=1)

def reference_line(ax, y, orient='h'):
    if orient == 'h':
        ax.axhline(y, ls='--', lw=1.2, color=REF_GREY, zorder=1)
    else:
        ax.axvline(y, ls='--', lw=1.2, color=REF_GREY, zorder=1)
