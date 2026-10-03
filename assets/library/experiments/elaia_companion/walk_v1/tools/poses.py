import sys, json, numpy as np
d = sys.argv[1]; M = np.load(f'masks_{d}.npy'); n = len(M)
cons = np.array([np.abs(M[i] - M[i + 1]).sum() for i in range(n - 1)])
thr = float(sys.argv[2]) if len(sys.argv) > 2 else 40
starts = [0] + [i + 1 for i in range(n - 1) if cons[i] > thr]
holds = [(s, (starts[k + 1] if k + 1 < len(starts) else n) - s) for k, s in enumerate(starts)]
U = [M[s:s + h].mean(0) for s, h in holds]
print(d, 'unique poses', len(U), 'hold lengths', [h for _, h in holds])
for P in range(6, 12):
    dd = [np.abs(U[i] - U[i + P]).sum() for i in range(len(U) - P)]
    best = np.argsort(dd)[:3]
    print(' P', P, 'mean', round(np.mean(dd), 1), 'best', [(int(holds[b][0]) + 1, round(float(dd[b]), 1), sum(h for _, h in holds[b:b + P])) for b in best])
json.dump({'holds': [(int(s) + 1, int(h)) for s, h in holds]}, open(f'check/holds_{d}.json', 'w'))
