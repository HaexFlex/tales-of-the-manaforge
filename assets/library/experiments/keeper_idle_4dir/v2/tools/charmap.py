import sys; from PIL import Image; import numpy as np
p, x0, x1, y0, y1 = sys.argv[1], *map(int, sys.argv[2:6])
a = np.array(Image.open(p).convert('RGBA')).astype(int)
print('     ' + ''.join(str((x // 10) % 10) for x in range(x0, x1))); print('     ' + ''.join(str(x % 10) for x in range(x0, x1)))
for y in range(y0, y1):
    s = ''
    for x in range(x0, x1):
        r, g, b, al = a[y, x]
        if al < 128: c = '.'
        elif r > 180 and g > 120 and b < 160 and r > g: c = 's'
        elif max(r, g, b) < 60: c = '#'
        elif g > r and g > b and g > 90: c = 'g'
        elif r > 200 and g > 200 and b > 200: c = 'w'
        elif b > r and b > g: c = 'b'
        else: c = 'o'
        s += c
    print(f'{y:4d} ' + s)
