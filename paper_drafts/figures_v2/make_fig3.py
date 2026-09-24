#!/usr/bin/env python3
"""fig3 — GSER signature, 'one signature, shifted point' (SM).
(a) G',G'' moduli of the random (kappa=0) network across its gel point, from the
    measured MSD via the generalised Stokes--Einstein relation.
(b) phase angle delta vs distance from the gel point, delta=90*alpha, for several
    kappa; all collapse through delta=45 deg (Winter--Chambon) at Delta p=0."""
import sys, csv, glob
import os
HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.abspath(os.path.join(HERE,'..','..'))  # repo root from paper_drafts/figures_v2/
sys.path.insert(0,HERE)
import numpy as np, scipy.io as sio, rw_figstyle as S
from scipy.special import gamma as Gamma
S.apply()
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

# ---- physical constants (as in the manuscript) ----
kB=1.380649e-23; T=293.0; a=0.243e-6; l=10e-9; dt=2.5e-5   # dt maps [1e4,1e5] steps -> omega[0.4,4]
def gser(msd_lat):
    """Single power-law fit over the anomalous window [1e4,1e5] steps, then the
    power-law GSER -> clean parallel moduli. Returns omega grid, G', G'', alpha."""
    step=np.arange(1,len(msd_lat)+1); t=step*dt; r2=msd_lat*l**2
    w=(step>=1e4)&(step<=1e5)&(msd_lat>0)
    alpha,logA=np.polyfit(np.log(t[w]),np.log(r2[w]),1)   # r2 = A t^alpha
    A=np.exp(logA); alpha=float(np.clip(alpha,1e-3,1.0))
    omega=np.logspace(np.log10(0.4),np.log10(4.0),40)
    Gstar=kB*T*omega**alpha/(np.pi*a*A*Gamma(1+alpha))
    return omega,Gstar*np.cos(np.pi*alpha/2),Gstar*np.sin(np.pi*alpha/2),alpha

pmap={0.65:'sol',0.68:r"$\approx p_c'$",0.70:'gel'}
files={p:glob.glob(os.path.join(ROOT,'matlab/Clusters1/MSD_Random_Percolation_p%.4f_*L500*.mat'%p))[0] for p in pmap}

fig,axs=plt.subplots(1,2,figsize=(11,4.7))

# ---- (a) moduli ----
ax=axs[0]
shades={0.65:'#8fb6f0',0.68:S.ACCENT_BLUE,0.70:'#0b3d91'}
for p in [0.65,0.68,0.70]:
    m=sio.loadmat(files[p],squeeze_me=True)['msd']
    om,Gp,Gpp,al=gser(np.asarray(m,float))
    o=np.argsort(om); om,Gp,Gpp=om[o],Gp[o],Gpp[o]
    amid=al
    ax.loglog(om,Gp,'-',lw=2.4,color=shades[p],zorder=4,
              label=r"$p=%.2f$ (%s, $\alpha\!\approx\!%.2f$)"%(p,pmap[p],amid))
    ax.loglog(om,Gpp,'--',lw=1.4,color=shades[p],zorder=3)
ax.set_xlabel(r'$\omega$  (rad s$^{-1}$)'); ax.set_ylabel(r"$G',\,G''$  (Pa)")
ax.set_title(r'(a) Moduli across the gel point (random network)',fontsize=11.5)
ax.grid(True,which='both',alpha=0.18)
lg=[Line2D([],[],color='#444',lw=2.4,label=r"$G'$ (thick)"),
    Line2D([],[],color='#444',lw=1.4,ls='--',label=r"$G''$ (thin)")]
leg1=ax.legend(loc='upper left',fontsize=8.6); ax.add_artist(leg1)
ax.legend(handles=lg,loc='lower right',fontsize=9)

# ---- (b) delta collapse ----
ax=axs[1]
rows=list(csv.DictReader(open(os.path.join(ROOT,'matlab/Clusters_kappa/L500/kappa_study_alpha_table.csv'))))
PV=sorted(set(float(r['p_value']) for r in rows))
def grid(k):
    return np.array(PV),np.array([np.mean([float(r['alpha']) for r in rows
        if float(r['kappa'])==k and float(r['p_value'])==p] or [np.nan]) for p in PV])
def pcp(k):
    p,al=grid(k)
    for i in range(len(al)-1):
        if al[i]>=0.5>=al[i+1]:
            t=(al[i]-0.5)/(al[i]-al[i+1]); return p[i]+t*(p[i+1]-p[i])
    return np.nan
ax.axhspan(45,90,color=S.ACCENT_BLUE,alpha=0.05); ax.axhspan(0,45,color=S.ACCENT_ORANGE,alpha=0.05)
for k in [0.0,0.6,0.8,0.97]:
    p,al=grid(k); d=90*al; pc=pcp(k); m=~np.isnan(d)
    ax.plot(p[m]-pc,d[m],'-o',ms=4,color=S.kappa_color(k),label=r'$\kappa=%.2g$'%k,zorder=4)
S.criterion_line(ax,45); ax.axvline(0,ls=':',color=S.REF_GREY,lw=1)
ax.set_xlim(-0.14,0.14); ax.set_ylim(0,93)
ax.set_xlabel(r"$\Delta p = p - p_c'(\kappa)$"); ax.set_ylabel(r'Phase angle $\delta$ ($^\circ$)')
ax.set_title(r'(b) One signature, shifted point',fontsize=11.5)
ax.text(-0.132,86,r'Sol ($\delta>45^\circ$)',fontsize=9,color=S.ACCENT_BLUE)
ax.text(0.055,4,r'Gel ($\delta<45^\circ$)',fontsize=9,color=S.ACCENT_ORANGE)
ax.text(0.004,47,r'$\delta=45^\circ$',fontsize=9,color='black')
ax.legend(loc='upper right',fontsize=9.5)
fig.tight_layout(); fig.savefig('fig3_gser_spectra.png')
print('saved fig3 ; pc:',[round(pcp(k),3) for k in [0,0.6,0.8,0.97]])
