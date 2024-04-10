import numpy as np

# NMC, LPSCI, VGCF
rho = np.array([4.87, 1.64, 1.9])

# case 1
wf = np.array([0.5, 0.47, 0.03])
vf = wf / rho
vf /= np.sum(vf)
print(wf)
print(vf)

# case 2
wf = np.array([0.65, 0.32, 0.03])
vf = wf / rho
vf /= np.sum(vf)
print(wf)
print(vf)

# case 3
wf = np.array([0.80, 0.17, 0.03])
vf = wf / rho
vf /= np.sum(vf)
print(wf)
print(vf)
