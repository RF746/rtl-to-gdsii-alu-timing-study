# RTL-to-GDSII ALU & Timing-Closure Study

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A public, sanitized physical-design portfolio project centered on a synthesizable two-stage, 32-bit pipelined ALU. The repository includes self-checking RTL verification, 100 MHz timing constraints, OpenLane/OpenROAD configuration scaffolding, synthetic timing/CTS report fixtures, and a dependency-free Python report summarizer.

> **Evidence boundary:** the source code and tests in this repository are reproducible. The historical portfolio metrics below are retained as project-record results, but their original run directories, proprietary EDA outputs, and signoff databases are not published. The files under `reports/sample/` are explicitly synthetic parser fixtures; they are not raw historical reports and do not independently reproduce the portfolio claims.

## What is reproducible here

- Eight-operation, two-stage 32-bit ALU in synthesizable Verilog
- Valid/enable pipeline control and arithmetic overflow reporting
- Self-checking directed, deterministic-random, bubble, and two-cycle stall/resume simulation
- 10.0 ns SDC clock constraint
- OpenLane 2 and OpenROAD-flow-scripts configuration starting points
- Timing/CTS parsing and summary generation from synthetic fixtures
- Python unit tests and GitHub Actions CI

Generated GDSII, SPEF, SDF, Liberty, database, DRC, LVS, antenna, and signoff reports are intentionally **not** checked in. Regenerating physical-design artifacts requires a compatible EDA flow, the SKY130A PDK, `sky130_fd_sc_hd`, and tool versions/configuration selected by the person running the flow.

## Case study 1 — 32-bit pipelined ALU

**Portfolio period:** January–March 2025

The original study moved a two-stage ALU from RTL through synthesis, floorplanning, placement, clock-tree synthesis, routing, extraction, timing analysis, physical verification, and activity-based power estimation.

### Portfolio-reported historical results

| Metric | Historical result |
|---|---:|
| Target frequency | 100 MHz |
| Standard cells | 2,140 |
| Reported cell area | 18,600 µm² |
| Core dimensions | 215 × 215 µm |
| Gross utilization | 40.2% |
| Post-route power estimate | 7.8 mW |
| VCD annotation coverage | 96.8% |
| Physical verification | Zero DRC/antenna violations; clean LVS |

These values are historical portfolio records, not outputs committed to this repository. Power was recorded from a post-route, parasitic-aware flow using switching activity; exact original databases and reports are unavailable here for independent replay.

## Case study 2 — static timing and CTS optimization

**Portfolio period:** September–December 2024

The original timing study iterated on constraints, implementation settings, clock-tree construction, and critical paths across nominal, slow/max, and fast/min RC analysis views.

### Portfolio-reported historical results

| Metric | Before | After |
|---|---:|---:|
| Setup WNS | -0.34 ns | +0.07 ns |
| Setup TNS | -5.72 ns | 0.00 ns |
| Violating endpoints | 14 | 0 |

| CTS metric | Historical result |
|---|---:|
| Clock sinks | 136 |
| Inserted clock buffers | 29 |
| Maximum skew | 0.19 ns |
| Insertion delay | 0.76 ns |

The synthetic fixtures intentionally use these values to demonstrate parser behavior. Matching numbers in sample output should not be interpreted as regenerated physical-design evidence.

## Repository map

```text
.
├── constraints/alu.sdc          # 100 MHz timing constraints
├── openlane/config.json         # OpenLane 2 starting configuration
├── openroad/config.mk           # OpenROAD-flow-scripts starting configuration
├── reports/sample/              # Clearly labeled synthetic parser inputs
├── rtl/pipelined_alu.v          # Synthesizable design
├── scripts/summarize_reports.py # Timing/CTS parser and formatter
├── tb/pipelined_alu_tb.v        # Self-checking testbench
└── tests/                       # Python unit tests
```

## Quick start

Prerequisites for local verification:

- Python 3.9 or newer
- Icarus Verilog (`iverilog` and `vvp`)
- GNU Make

Run all reproducible tests:

```bash
make test
```

Summarize the synthetic timing/CTS fixtures:

```bash
make metrics
```

Run the parser against other reports using the same simple labeled format:

```bash
python3 scripts/summarize_reports.py \
  --before path/to/timing_before.rpt \
  --after path/to/timing_after.rpt \
  --cts path/to/cts_summary.rpt
```

## Regenerating physical-design outputs

The checked-in configurations are portable starting points, not frozen signoff recipes. To attempt a new implementation run:

1. Install OpenLane 2 or OpenROAD-flow-scripts and record exact tool versions.
2. Install a compatible SKY130A PDK with the `sky130_fd_sc_hd` standard-cell library.
3. Review the SDC, floorplan utilization, routing layers, RC corners, and PDK-specific defaults.
4. Run the selected flow from a clean output directory.
5. Preserve generated manifests and logs so reported results are traceable to a specific configuration and toolchain.
6. Run DRC, antenna, LVS, timing, and power checks appropriate to the intended level of assurance.

Example OpenLane 2 invocation (installation-dependent):

```bash
openlane openlane/config.json
```

Example OpenROAD-flow-scripts invocation (installation-dependent):

```bash
make -C "$ORFS_FLOW" DESIGN_CONFIG="$PWD/openroad/config.mk"
```

Do not treat a successful CI simulation as physical-design signoff. CI verifies functional RTL and parser behavior only.

## ALU interface and operations

Inputs are captured when `enable` is high. A transaction asserted on `valid_in` appears on `result` with `valid_out` after the input and output register stages advance.

| Opcode | Operation |
|---:|---|
| `3'b000` | Addition |
| `3'b001` | Subtraction |
| `3'b010` | Bitwise AND |
| `3'b011` | Bitwise OR |
| `3'b100` | Bitwise XOR |
| `3'b101` | Signed less-than |
| `3'b110` | Logical left shift |
| `3'b111` | Logical right shift |

## Responsible use

This repository contains no employer source code, internal links, customer data, proprietary reports, or confidential design collateral. See [DATA_PROVENANCE.md](DATA_PROVENANCE.md) for the evidence taxonomy and [SECURITY.md](SECURITY.md) for vulnerability reporting.

## License

MIT © 2026 Ryan Faxigue. See [LICENSE](LICENSE).
