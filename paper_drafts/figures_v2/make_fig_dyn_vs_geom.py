import sys,csv
import os
HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.abspath(os.path.join(HERE,'..','..'))
sys.path.insert(0,HERE)
import numpy as np, rw_figstyle as S
S.apply()
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

# --- dynamical pc'_MR(kappa), alpha=0.5 crossing, L=500 ---
rows=list(csv.DictReader(open(os.path.join(ROOT,'matlab/Clusters_kappa/L500/kappa_study_alpha_table.csv'))))
PV=sorted(set(float(r['p_value']) for r in rows))
def pcp_MR(k):
    a=[np.mean([float(r['alpha']) for r in rows if float(r['kappa'])==k and float(r['p_value'])==p] or [np.nan]) for p in PV]
    a=np.array(a); p=np.array(PV)
    for i in range(len(a)-1):
        if a[i]>=0.5>=a[i+1]:
            t=(a[i]-0.5)/(a[i]-a[i+1]); return p[i]+t*(p[i+1]-p[i])
    return np.nan

# --- geometric pc'_geom(kappa) from the MATLAB void run (void_pc_geom.csv) ---
import csv as _csv
geom={}
with open(os.path.join(ROOT,'matlab/void_pc_geom.csv')) as fh:
    for r in _csv.DictReader(fh):
        v=float(r['pc_geom_z'])
        if v==v: geom[float(r['kappa'])]=v   # skip NaN (kappa=1)
KK=np.array(sorted(geom))
gm=np.array([geom[k] for k in KK])
mr=np.array([pcp_MR(k) for k in KK])
gap=mr-gm

fig,axs=plt.subplots(1,2,figsize=(12,5.0))

# ----- (a) overlay -----
ax=axs[0]
ax.axvspan(0.82,1.03,color=S.CROSS_GREY,alpha=0.13,zorder=0)
ax.plot(KK,mr,'-o',ms=6.5,color=S.ACCENT_BLUE,mec='white',mew=0.6,zorder=4,
        label=r"dynamical  $p_c'^{\mathrm{MR}}$  ($\alpha=0.5$)")
ax.plot(KK,gm,'D',ms=8,color=S.ACCENT_ORANGE,mec='white',mew=0.6,zorder=5,
        label=r"geometric  $p_c'^{\mathrm{geom}}$  (void spanning)")
ax.axhline(0.6884,ls=':',color=S.REF_GREY,lw=1.1)
ax.text(0.02,0.6884-0.006,r'$1-p_c=0.688$',color=S.REF_GREY,fontsize=9.5,va='top')
ax.annotate('',xy=(1.0,0.99),xytext=(1.0,0.90),arrowprops=dict(arrowstyle='->',color=S.CROSS_GREY,lw=1.3))
ax.text(0.995,0.905,r'$\kappa=1$:'+'\n'+r'void spans to $p\to1$',fontsize=8.6,color='#555',ha='right',va='top')
ax.text(0.92,0.70,'crossover',fontsize=9.5,color='#555',ha='center',style='italic')
ax.set_xlabel(S.XLABEL_KAPPA); ax.set_ylabel(S.YLABEL_PCP)
ax.set_title(r'(a) Structural vs dynamical gel point ($L=500$)',fontsize=12)
ax.set_xlim(-0.05,1.05); ax.set_ylim(0.66,1.0)
ax.legend(loc='upper left',fontsize=10)

# ----- (b) gap -----
ax=axs[1]
ax.axhline(0,ls='--',color=S.REF_GREY,lw=1.1)
ax.axvspan(0.82,1.03,color=S.CROSS_GREY,alpha=0.13,zorder=0)
cols=[S.kappa_color(k) for k in KK]
ax.plot(KK,gap,'-',color='#888',lw=1.2,zorder=2)
ax.scatter(KK,gap,c=cols,s=70,edgecolors='white',linewidths=0.7,zorder=5)
ax.axhspan(-0.01,0.01,color=S.ACCENT_BLUE,alpha=0.06,zorder=0)
ax.text(0.05,0.012,r'coincident ($|\Delta|<0.01$)',fontsize=9.5,color=S.ACCENT_BLUE)
ax.text(0.9,0.045,'decoupling',fontsize=9.5,color='#555',ha='center',style='italic')
ax.set_xlabel(S.XLABEL_KAPPA)
ax.set_ylabel(r"$\Delta p_c' = p_c'^{\mathrm{MR}} - p_c'^{\mathrm{geom}}$")
ax.set_title(r'(b) Dynamical$-$structural gap',fontsize=12)
ax.set_xlim(-0.05,1.05); ax.set_ylim(-0.02,0.075)
fig.tight_layout(); fig.savefig(os.path.join(HERE,'fig_dyn_vs_geom.png'))
print("kappa  MR     geom   gap")
for k,m,g,d in zip(KK,mr,gm,gap): print(f"{k:5.3g}  {m:.3f}  {g:.3f}  {d:+.3f}")
