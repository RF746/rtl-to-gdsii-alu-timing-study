# Data provenance and evidence boundaries

This repository separates reproducible implementation assets from historical portfolio records so readers can evaluate each category appropriately.

## 1. Reproducible public assets

These files were prepared as a sanitized public portfolio implementation:

- `rtl/pipelined_alu.v`
- `tb/pipelined_alu_tb.v`
- `constraints/alu.sdc`
- `openlane/config.json`
- `openroad/config.mk`
- `scripts/summarize_reports.py`
- `tests/`

They can be inspected and, where prerequisites are available, executed directly. CI covers functional simulation and Python tests; it does not run a complete physical-design flow.

## 2. Synthetic fixtures

Every file under `reports/sample/` is a hand-authored synthetic fixture. The values intentionally mirror documented portfolio metrics to make parser output easy to compare with the case-study narrative.

Synthetic fixtures are:

- not raw OpenROAD, OpenSTA, OpenLane, or commercial EDA output;
- not signoff evidence;
- not extracted from an employer or customer system; and
- not proof that the public RTL will regenerate the same physical metrics.

## 3. Historical portfolio records

The README preserves the following project-record results:

- 2,140 cells, 100 MHz target, 18,600 µm² reported cell area;
- 215 × 215 µm core and 40.2% gross utilization;
- 7.8 mW post-route power estimate and 96.8% VCD annotation coverage;
- zero reported DRC/antenna violations and clean LVS;
- setup timing improved from -0.34 ns WNS / -5.72 ns TNS to +0.07 ns WNS / 0 ns TNS;
- 136 clock sinks, 29 inserted buffers, 0.19 ns maximum skew, and 0.76 ns insertion delay.

The original run directories, databases, exact tool manifests, raw reports, and signoff artifacts are not published. Therefore, these metrics must be read as historical portfolio claims rather than independently reproducible results from this repository.

## 4. Excluded information

No employer source code, employer name, internal URL, account identifier, customer information, confidential hardware specification, private report, or licensed PDK content is included. SKY130 and `sky130_fd_sc_hd` are named only as external regeneration prerequisites; PDK files must be obtained from their authorized distribution channels.

## 5. Reproduction expectations

Physical-design results vary with tool and PDK revisions, liberty/RC corners, floorplan choices, routing settings, host environment, random seeds, and analysis assumptions. Anyone publishing new measurements should retain a tool manifest, complete configuration, logs, and generated reports, and should label those new results separately from the historical case studies.
