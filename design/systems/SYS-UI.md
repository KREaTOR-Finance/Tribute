# SYS-UI — HUD Readability

## Goal

Always-visible HP + Stamina for player (and dummy labels). Culling readability over chrome.

## Independently judgeable

- HP bar/text updates live
- Stamina bar/text updates live
- Melee state optional debug line
- No clutter covering combat center

## Architecture

UMG widget or debug canvas HUD component on player controller / character. Prefer UMG for ship path; debug draw acceptable only as temporary FAIL residual.

## Critic checklist

- [ ] Readable at a glance mid-fight
- [ ] Bound to real combat component values
