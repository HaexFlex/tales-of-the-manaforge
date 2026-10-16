# Echo battle flow — reuse assessment

Haex asked the Echo fight to follow the adventure battle flow: after the dialogue, the game decides who goes first; each action plays its strike frame and then the hit frame when a blow lands; the player can pick an action only on their own turn; Elaia's battle frames are mirrored. The 2d6 rules stay: a Swiftness tie goes to the Keeper, KO is at 10% or below, Rootbind fires every 3rd Echo turn.

This note is the assessment only. The flow is not built in this commit.

## What each side does today

Echo rules live in `EchoBattle.choose()` (`scripts/echo_battle.gd`). One click resolves the whole round. `keeper_acts_first()` compares Swiftness and gives a tie to the Keeper, then `_strike_round()` runs the Keeper swing and the Echo turn in that order, or the reverse, before the call returns. Brace, Salve, and Flee do the same: the Echo answers inside the same call. The view (`scripts/echo_battle_view.gd`) then refreshes bars and the log. Portraits stay on the idle sheets (`battle_keeper_idle_e`, `battle_elaia_idle_w` / the key sheet, Bramble's idle). There is no strike frame, no hit frame, and no wait between the two halves, so the menu is free again as soon as `choose()` returns.

Adventure fights live in `FightState` (`scripts/battle/fight_state.gd`) plus `BattlePlayback` and `BattleView`. `FightState.step()` takes one action for `current_actor()` and advances a turn order. `BattleView` ignores clicks while `BattlePlayback.is_busy()` (about line 2547). Playback sets the actor to the attack pose, then the target to hurt (or KO), on a clock (`GAP_STRIKE_SEC` 1.0s, hurt held to about 0.75s). Party poses are the east-facing sheets under `assets/art/battle/party/` (`battle_elaia_attack.png`, `battle_elaia_hurt.png`, and the same set for the Keeper and Bramble). `BattlePlayback.bind_view` is typed to `BattleView` and `FightState`. It is not a free-standing player.

`FightState` is the reach resolver: beasts, rows, targeting, Weave, poison, intents, twists, swarms. It does not know the Echo mercy floor, the spare window, Rootbind-on-the-third-Echo-turn, the hybrid foe's snare/knot pick, or the Echo flee rule. Echo already calls `BattleResolver` for a single swing's dice inside `_resolve_swing`, then applies the Echo-only damage edits (Rootbind halving, mercy floor at 10%, spare window) in `_keeper_strike`.

## What can be reused

| Piece | Reuse it? | Why |
| --- | --- | --- |
| `FightState.step()` / turn order | No | Different fight. Dropping the Echo in here would run beast rules, or would mean teaching `FightState` the Echo special cases. Either way the adventure suite and the Echo v4 parity suite both move. |
| `BattlePlayback` as a class | No, not as it stands | It calls `BattleView.set_fighter_pose` and reads `FightState`. Wiring Echo into that type pulls the 3.6k-line adventure view into the chamber. |
| The playback idea | Yes, later | Attack pose, then hurt pose if the blow landed, then idle. The timing constants in `battle_playback.gd` are the ones to copy. |
| The input lock | Yes, later | Same rule as `BattleView`: while a pose is playing, clicks do nothing. Echo would lock on its own menu, not by calling into `BattleView`. |
| Pose art | Yes, later | `assets/art/battle/party/battle_*_{attack,hurt,idle,ko,brace}.png` already exist for the Keeper, Elaia, and Bramble. |
| `EchoBattle.choose()` | Keep | This is the 2d6 contract the headless suite already locks (tie to the Keeper, KO at or under 10%, Rootbind every 3rd Echo turn, spare, flee, salve cap). |

Elaia's adventure sheets face east. In the chamber she stands on the right, so those sheets have to be mirrored (`flip_h`) or she looks away from the Keeper. The chamber's current `battle_elaia_idle_w` already faces west and should stay the idle until a swing starts. Bramble's party sheet is `battle_bramble_idle_e` and needs the same mirror if he stands on the right.

## What it would cost

A safe build does not call `FightState` or `BattlePlayback`.

1. Split one Echo round into two presented halves without changing dice or the order `choose()` uses today. `keeper_acts_first()` still picks the order. The second half runs only after the first pose finishes, and it must call the same `_keeper_strike` / `_echo_turn` path so the log, mercy floor, and Rootbind stay bit-for-bit.
2. A small pose player on `EchoBattleView` only: swap the portrait to attack, then to hurt when `damage > 0`, then back to idle. Mirror Elaia and Bramble. Copy the playback gaps (1.0s strike, then the hurt hold).
3. Ignore Strike / Brace / Salve / Flee / Spare while that player is busy.
4. Headless coverage: a click during the foe's half does not start a second round; a finished round still matches the current `choose()` result; Elaia's attack sprite is `flip_h`.

That is a new sequencer plus a split of `choose()`, on the order of a few hundred lines in `echo_battle.gd` and `echo_battle_view.gd`, and a new verify marker. It does not delete the adventure path.

## Break risk

Not small, and not safe to land in this pass.

- `choose()` is atomic. Spare, defeat, KO, flee, brace, and salve are all decided before the call returns. Tests and the view read `outcome` and `spare_window` immediately. A split changes when those flags appear. Getting the second half wrong double-fires Rootbind or skips the mercy floor.
- `BattlePlayback` and `FightState` are the adventure fight. Adapting them so an Echo duel can call `step()` risks the reach suite (rows, poison, boss, bank-once) for no rule-set benefit. Echo would also inherit Weave, intents, and the 60-round cap instead of its own timeout.
- Pose art for the Echo foe (Elaia's key sheet, the mercy pose) has no attack/hurt pair. The party attack sheet can cover a normal swing. The key portrait and the Bramble warden sheet still need a fallback to the idle they use now.
- Headless VERIFY runs the Echo path without waiting on real time. A playback queue has to resolve in one `process_frame` when `instant` is set, the way `BattlePlayback` does, or the suite hangs.

## Decision

Do not build this in the playtest round. Leave `EchoBattle.choose()` as the rules. When it is built, add a presentation sequencer beside the Echo view and do not route the duel through `FightState`.
