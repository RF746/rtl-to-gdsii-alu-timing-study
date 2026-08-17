#!/usr/bin/env python3
"""Parse a small, documented timing/CTS summary format.

The checked-in reports/sample fixtures are synthetic examples, not raw EDA reports.
No third-party Python packages are required.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, Mapping, Sequence


NUMBER = r"([-+]?\d+(?:\.\d+)?)"

TIMING_PATTERNS: Mapping[str, str] = {
    "wns_ns": rf"^WNS \(setup\):\s*{NUMBER}\s*ns\s*$",
    "tns_ns": rf"^TNS \(setup\):\s*{NUMBER}\s*ns\s*$",
    "violating_endpoints": r"^Violating endpoints:\s*(\d+)\s*$",
}

CTS_PATTERNS: Mapping[str, str] = {
    "clock_sinks": r"^Clock sinks:\s*(\d+)\s*$",
    "inserted_clock_buffers": r"^Inserted clock buffers:\s*(\d+)\s*$",
    "maximum_skew_ns": rf"^Maximum skew:\s*{NUMBER}\s*ns\s*$",
    "insertion_delay_ns": rf"^Insertion delay:\s*{NUMBER}\s*ns\s*$",
}

INTEGER_FIELDS = {
    "violating_endpoints",
    "clock_sinks",
    "inserted_clock_buffers",
}


def parse_report(path: Path, patterns: Mapping[str, str]) -> Dict[str, float | int]:
    """Parse required metrics and fail closed when a field is absent."""
    text = path.read_text(encoding="utf-8")
    parsed: Dict[str, float | int] = {}
    missing = []

    for field, pattern in patterns.items():
        match = re.search(pattern, text, flags=re.MULTILINE)
        if match is None:
            missing.append(field)
            continue
        value = match.group(1)
        parsed[field] = int(value) if field in INTEGER_FIELDS else float(value)

    if missing:
        fields = ", ".join(missing)
        raise ValueError(f"{path}: missing required metric(s): {fields}")

    return parsed


def default_fixture(name: str) -> Path:
    return Path(__file__).resolve().parents[1] / "reports" / "sample" / name


def _provenance(before_path: Path, after_path: Path, cts_path: Path) -> str:
    supplied = tuple(path.resolve() for path in (before_path, after_path, cts_path))
    defaults = tuple(
        default_fixture(name).resolve()
        for name in ("timing_before.rpt", "timing_after.rpt", "cts_summary.rpt")
    )
    if supplied == defaults:
        return "synthetic sample fixtures; not historical raw reports"
    return "user-supplied report files; provenance not asserted by this tool"


def build_summary(before_path: Path, after_path: Path, cts_path: Path) -> Dict[str, object]:
    before = parse_report(before_path, TIMING_PATTERNS)
    after = parse_report(after_path, TIMING_PATTERNS)
    cts = parse_report(cts_path, CTS_PATTERNS)

    return {
        "provenance": _provenance(before_path, after_path, cts_path),
        "timing_before": before,
        "timing_after": after,
        "cts": cts,
        "delta": {
            "wns_change_ns": round(float(after["wns_ns"]) - float(before["wns_ns"]), 3),
            "tns_change_ns": round(float(after["tns_ns"]) - float(before["tns_ns"]), 3),
            "violating_endpoints_change": (
                int(after["violating_endpoints"]) - int(before["violating_endpoints"])
            ),
        },
    }


def format_markdown(summary: Mapping[str, object]) -> str:
    before = summary["timing_before"]
    after = summary["timing_after"]
    cts = summary["cts"]
    delta = summary["delta"]
    assert isinstance(before, dict)
    assert isinstance(after, dict)
    assert isinstance(cts, dict)
    assert isinstance(delta, dict)

    lines = [
        "# Timing and CTS report summary",
        "",
        f"Source: **{summary['provenance']}**",
        "",
        "| Timing metric | Before | After |",
        "|---|---:|---:|",
        f"| Setup WNS | {before['wns_ns']:+.2f} ns | {after['wns_ns']:+.2f} ns |",
        f"| Setup TNS | {before['tns_ns']:+.2f} ns | {after['tns_ns']:+.2f} ns |",
        f"| Violating endpoints | {before['violating_endpoints']} | {after['violating_endpoints']} |",
        "",
        "| CTS metric | Value |",
        "|---|---:|",
        f"| Clock sinks | {cts['clock_sinks']} |",
        f"| Inserted clock buffers | {cts['inserted_clock_buffers']} |",
        f"| Maximum skew | {cts['maximum_skew_ns']:.2f} ns |",
        f"| Insertion delay | {cts['insertion_delay_ns']:.2f} ns |",
        "",
        "Derived changes (after - before): "
        f"WNS {delta['wns_change_ns']:+.2f} ns, "
        f"TNS {delta['tns_change_ns']:+.2f} ns, "
        f"violating endpoints {delta['violating_endpoints_change']:+d}.",
    ]
    return "\n".join(lines)


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before", type=Path, default=default_fixture("timing_before.rpt"))
    parser.add_argument("--after", type=Path, default=default_fixture("timing_after.rpt"))
    parser.add_argument("--cts", type=Path, default=default_fixture("cts_summary.rpt"))
    parser.add_argument(
        "--format",
        choices=("markdown", "json"),
        default="markdown",
        help="Output format (default: markdown)",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        summary = build_summary(args.before, args.after, args.cts)
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    if args.format == "json":
        print(json.dumps(summary, indent=2, sort_keys=True))
    else:
        print(format_markdown(summary))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
