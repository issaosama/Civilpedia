# Slump Test — Content Notes for the Author

This document collects the engineering knowledge, common pitfalls, and code references needed when filling the slump test topic CSVs. Use it as a reference while writing.

## Purpose

The slump test measures the workability (consistency) of fresh concrete. It is the most widely used field test worldwide.

## Standard

- **ASTM C143 / C143M** — Standard Test Method for Slump of Hydraulic-Cement Concrete
- **BS EN 12350-2** — Testing fresh concrete — Slump test
- **ACI 211.1** — Standard Practice for Selecting Proportions for Normal Concrete

## Required Equipment

| Item | Specification |
|------|---------------|
| Slump cone (mould) | Base Ø=200 mm, Top Ø=100 mm, Height=300 mm |
| Tamping rod | Ø=16 mm, Length=600 mm, bullet-pointed end |
| Measuring scale | mm graduations |
| Scoop | For filling the cone |
| Straightedge | Metal, ~500 mm long |

## Key Parameters

- **Slump classes (BS EN 206 / ACI 211.1):**
  - S1 (0–10 mm) — very dry (pavements, precast)
  - S2 (10–40 mm) — low workability (foundations, walls)
  - S3 (40–100 mm) — medium workability (beams, slabs — most common)
  - S4 (100–160 mm) — high workability (congested reinforcement)
  - S5 (≥160 mm) — very high workability (pumped concrete)

- **Typical acceptance limits for structural concrete:** 75–100 mm (varies by specification)
- **Test time:** must be completed within 2 minutes of sampling
- **Temperature range:** 10–32°C (per ACI 301)

## Common Mistakes

1. **Insufficient rodding** — each layer must be rodded exactly 25 times
2. **Lateral movement during cone lift** — causes false low slump
3. **Using unrepresentative sample** — must sample from mid-load per ASTM C172
4. **Time delay** — test must start within 2 minutes of sampling
5. **Wet base plate** — must be clean and moist (not dry, not flooded)

## Notes for CSV Values

- `point_critical=TRUE` only for: slump measurement, compressive strength, air content
- `point_critical=FALSE` for: temperature, time, visual inspection
- Use `severity=high` only for mistakes that could affect structural safety
- Report wording should include variables: (X) for slump result, (Y) for allowable range

## Additional Resources

- ACI 211.1 — Mix design proportions
- ACI 301 — Structural concrete specifications
- ASTM C172 — Sampling fresh concrete
- ASTM C1064 — Temperature of fresh concrete
