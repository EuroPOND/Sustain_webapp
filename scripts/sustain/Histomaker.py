# -*- coding: iso-8859-15 -*-

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt

data=[@@PSA@@,@@PSB@@,@@PSC@@]
Labels=['Subtype 1', 'Subtype 2', 'Subtype 3']

N=len(data)
x_s=np.arange(1,N+1)	

fig, ax = plt.subplots(figsize=(12, 8))
ax.grid(axis='y')
 
ax.bar(x_s,data,width=1, lw=3, fc=(1, 0.5, 0, 0.5), edgecolor=(1, 0.5, 0, 1))

ax.set_yticks([0,25,50,75,100])
ax.set_yticklabels(["0%","25%","50%","75%","100%"], fontsize=24)
ax.set_ylabel('Subject subtype probability', fontsize=28)

ax.set_xticks(x_s)
ax.set_xticklabels(Labels, fontsize=28)

plt.tight_layout()
plt.savefig('Histo.png')                     

                  
