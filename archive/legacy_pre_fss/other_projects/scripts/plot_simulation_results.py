import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import pickle
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

# Paths
msd_csv = os.path.join('test_output', 'msd_results_L30_p0.5000.csv')
checkpoint_file = os.path.join('test_output', 'checkpoints', 'checkpoint_step_5000_1750246364.pkl')

# --- Plot MSD vs Step ---
msd_df = pd.read_csv(msd_csv)
plt.figure(figsize=(8, 5))
plt.plot(msd_df['step'], msd_df['msd'], marker='o')
plt.xlabel('Step')
plt.ylabel('Mean Squared Displacement (MSD)')
plt.title('MSD vs Step')
plt.grid(True)
plt.tight_layout()
plt.show()

# --- Plot Walker Coordinates (Start and End) ---
with open(checkpoint_file, 'rb') as f:
    checkpoint_data = pickle.load(f)

state = checkpoint_data['state']
walker_positions = state.walker_positions  # Final positions (N, 3)
initial_positions = state.initial_positions  # Initial positions (N, 3)

fig = plt.figure(figsize=(10, 5))
ax = fig.add_subplot(121, projection='3d')
ax.scatter(initial_positions[:, 0], initial_positions[:, 1], initial_positions[:, 2], c='blue', label='Start', alpha=0.7)
ax.set_title('Walker Start Positions')
ax.set_xlabel('X')
ax.set_ylabel('Y')
ax.set_zlabel('Z')

ax2 = fig.add_subplot(122, projection='3d')
ax2.scatter(walker_positions[:, 0], walker_positions[:, 1], walker_positions[:, 2], c='red', label='End', alpha=0.7)
ax2.set_title('Walker End Positions')
ax2.set_xlabel('X')
ax2.set_ylabel('Y')
ax2.set_zlabel('Z')

plt.tight_layout()
plt.show() 