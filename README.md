# Cellular-handover-simulation

# 📶 Cellular Handover Simulation

This MATLAB project simulates call traffic and handovers in a three-cell cellular network. It generates heatmaps showing how varying **handover probabilities** and **channel capacities** affect **blocked**, **dropped**, and **completed** calls.

---

## 📊 Features

- Simulates user call arrivals and departures across cells A → B → C
- Probabilistic handovers with configurable parameters
- Tracks:
  - Blocked calls (no channel at arrival)
  - Dropped calls (handover fails)
  - Completed calls (successfully ended)
- Generates heatmaps for each metric over a parameter sweep

---

The simulation will generate 3 heatmaps:

Blocked Calls
Dropped Calls
Completed Calls

⚙️ Parameters
The following parameters can be configured inside parameter_sweep_heatmap.m:

p_handover_vals: Range of handover probabilities (e.g., 0.1:0.1:0.9)

channel_vals: Range of channel counts per cell (e.g., 5:5:30)

Tsim: Total simulation time (e.g., 5000)

lambda: Call arrival rate (e.g., 0.1)

mu: Call duration rate (e.g., 1/180 for average 180s call)

🛠️ Requirements
MATLAB R2016b or later

No external toolboxes required

Made by - Jayesh Pathak 
