import sys; from PIL import Image
# usage: cmp_view.py out.png scale img1 img2 ... (each 128x128 RGBA; crops x 20..108, grass bg)
out, sc, files = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
W = 88; c = Image.new("RGBA", (W * len(files), 128), (74, 122, 52, 255))
for i, f in enumerate(files):
    im = Image.open(f).convert("RGBA").crop((20, 0, 108, 128)); c.alpha_composite(im, (i * W, 0))
c.resize((c.width * sc, 128 * sc), Image.NEAREST).save(out)
