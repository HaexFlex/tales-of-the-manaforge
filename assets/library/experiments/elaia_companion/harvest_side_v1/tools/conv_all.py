import sys; sys.path.insert(0, '/workspace/elaia_anims/harv')
from convert_act import run
which = sys.argv[1:]
J = {
 'axe':     dict(act='axe_retry', frames=list(range(41, 84)), W=192, H=136, FX=352.0, SY=400.0, CX=96, CY=132),
 'pickaxe': dict(act='pickaxe', frames=list(range(84, 146)), W=192, H=136, FX=336.0, SY=398.0, CX=96, CY=132),
 'berries': dict(act='berries', frames=list(range(5, 70)), W=192, H=136, FX=340.0, SY=398.0, CX=96, CY=132),
 'water':   dict(act='water', frames=list(range(13, 98)), W=208, H=136, FX=312.0, SY=402.0, CX=104, CY=132, water=True, water_x0=112, water_y0=70),
 'station': dict(act='station', frames=list(range(48, 120)), W=128, H=128, FX=336.0, SY=398.0, CX=64, CY=124),
}
for k in which:
    j = J[k]; log = run(out=f'/workspace/elaia_anims/harv/work/{k}', **j)
    print(k, {i: (v['top'], v['bottom'], v['x0'], v['x1']) for i, v in list(log.items())[::4]})
