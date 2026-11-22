"""Recompute the six E10 spread references with NumPy 2.4.6 and SciPy 1.17.1."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
from scipy.integrate import solve_ivp

CONFIG = Path(__file__).resolve().parents[1] / 'config' / '3d-intercell-study.json'
with CONFIG.open(encoding='utf-8') as f:
    cfg = json.load(f)
layout, cell, sim = cfg['layout'], cfg['cell'], cfg['simulation']
rows, cols, layers = layout['rows'], layout['columns'], layout['layers']
n = rows * cols * layers
# Independently enumerate positive-axis nearest-neighbor interfaces in the
# documented ordering r + c*rows + layer*rows*columns.
edge_i, edge_j, edge_g = [], [], []
for layer in range(layers):
    for col in range(cols):
        for row in range(rows):
            i = row + col*rows + layer*rows*cols
            if col + 1 < cols:
                edge_i.append(i); edge_j.append(i+rows); edge_g.append(layout['gx_W_per_K'])
            if row + 1 < rows:
                edge_i.append(i); edge_j.append(i+1); edge_g.append(layout['gy_W_per_K'])
            if layer + 1 < layers:
                edge_i.append(i); edge_j.append(i+rows*cols); edge_g.append(layout['gz_W_per_K'])
edge_i=np.asarray(edge_i,dtype=int); edge_j=np.asarray(edge_j,dtype=int); edge_g=np.asarray(edge_g,dtype=float)
assert (n, edge_i.size) == (36,75)
Tb=np.asarray(cfg['boundary']['temperature_K'],dtype=float)
H=float(cfg['boundary']['conductance_W_per_K'])
C=float(cell['thermalCapacity_J_per_K'])
I=float(cfg['electrical']['current_A']); R0=float(cfg['electrical']['R0_Ohm'])
alphaT=0.003; alphaSOC=0.05; Tref=298.15; capacity_C=18000.0
T0=float(cell['initialTemperature_K']); soc0=float(cell['initialSOC'])

def run(gz: float) -> dict:
    g=edge_g.copy()
    # Edges are inserted x,y,z per node; reconstruct axis class from endpoints.
    layer_i=edge_i // (rows*cols); layer_j=edge_j // (rows*cols)
    g[layer_i != layer_j]=gz
    def rhs(_t, y):
        T=y[:n]; soc=y[n:]
        q=I*I*R0*(1+alphaT*(T-Tref)+alphaSOC*(1-soc))
        flow=np.zeros(n)
        flux=g*(T[edge_j]-T[edge_i])
        np.add.at(flow,edge_i,flux); np.add.at(flow,edge_j,-flux)
        dT=(flow+H*(Tb-T)+q)/C
        dSOC=np.full(n,-I/capacity_C)
        return np.concatenate((dT,dSOC))
    y0=np.concatenate((np.full(n,T0),np.full(n,soc0)))
    sol=solve_ivp(rhs,(0.0,float(sim['duration_s'])),y0,method='BDF',
                  rtol=1e-10,atol=1e-12,max_step=0.5)
    if not sol.success: raise RuntimeError(sol.message)
    T=sol.y[:n,-1].reshape(layers,rows*cols)
    means=T.mean(axis=1)
    return {'gz_W_per_K':gz,'finalLayerMeans_K':means.tolist(),
            'finalLayerSpread_K':float(means.max()-means.min()),
            'nfev':int(sol.nfev),'njev':int(sol.njev),'nlu':int(sol.nlu),
            'solver':'scipy.integrate.solve_ivp(method=BDF, rtol=1e-10, atol=1e-12, max_step=0.5)'}

values=[0.10,0.175,0.25,0.40,0.625,0.75]
results=[run(v) for v in values]
print(json.dumps(results, indent=2))
