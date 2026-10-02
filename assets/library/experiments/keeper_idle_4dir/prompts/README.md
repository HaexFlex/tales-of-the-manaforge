# Keeper idle 4-dir: Grok Imagine brief

Chat: "Tales of Manaforge Pixel Art"
https://grok.com/project/025146c8-0dd7-4881-9be2-9ad3ac90d611?chat=e1a3ba94-d3de-4d50-9e32-a91cb1f85267

Attach (box paths):
- /workspace/keeper_idle/prompts/attach/ref_keeper_front_back_pair_magenta.png  (front + back reference on magenta, 1168x784)
- /workspace/keeper_idle/prompts/attach/ref_keeper_front_x3_magenta.png          (front only, x3)
- /workspace/keeper_idle/prompts/attach/ref_keeper_back_x3_magenta.png           (back only, x3)

Prompt: turnaround_A.prompt.txt (primary). Run it 3-4 times (new generation each time); then turnaround_B.prompt.txt 2 times.
Only if every sheet botches the side views: turnaround_C_side_pair.prompt.txt (E/W from one image) - then S/N come from the best 4-view sheet.
Downloads land in /home/box/Downloads (~1168x784 JPEG). Keep every candidate; note which prompt produced which file.

After download:
  python tools/ingest_turnaround.py /home/box/Downloads/<file>.jpg --name cand_<k>      # keys, splits S/N/E/W, scores consistency
  python tools/build_idles.py --cand cand_<k> [--mirror-west]                         # frames, strips, meta, GIFs, check

One-shot after the computerUse run (ingests every new download as cand_1..n, prints scores):
  bash tools/ingest_all.sh
Then look at work/cand_*/review_x3.png, pick the most consistent sheet, and:
  python tools/build_idles.py --cand cand_<k> [--mirror-west] [--eyes eyes.json] --out final
  python tools/check_frames.py final
