# Assets upload — standing process

**Inbox:** `Assets upload/`

Agents and humans drop new sheets / frames here. **After every coding ship, the inbox must be empty** (README-only). Headless verify checks this.

## Sort map

| Drop | Permanent home |
|------|----------------|
| Tree / bush PNG sheets | `assets/library/` (sliced gameplay frames already under `assets/art/trees/`, `assets/art/bushes/`) |
| JPG duplicates of those sheets | `assets/library/raw_refs/` |
| Keeper source frames | `assets/library/keeper_inbox/` (gameplay copies under `assets/art/keeper/`) |
| Ready-to-use game art | `assets/art/...` directly |

## Rebuild

```bash
python3 tools/slice_haex_inbox.py
```

Reads originals from `assets/library/` (not the inbox) and writes cleaned frames under `assets/art/`.

## Agent checklist (end of run)

1. No files under `Assets upload/` except `README.md`
2. New art lives under `assets/art/` or `assets/library/`
3. VERIFY includes the empty-inbox assertion
