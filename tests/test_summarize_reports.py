import importlib.util
import io
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "summarize_reports", ROOT / "scripts" / "summarize_reports.py"
)
assert SPEC is not None and SPEC.loader is not None
summarize_reports = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(summarize_reports)


class ReportSummaryTests(unittest.TestCase):
    def test_sample_summary_and_deltas(self):
        sample = ROOT / "reports" / "sample"
        summary = summarize_reports.build_summary(
            sample / "timing_before.rpt",
            sample / "timing_after.rpt",
            sample / "cts_summary.rpt",
        )

        self.assertEqual(summary["timing_before"]["wns_ns"], -0.34)
        self.assertEqual(summary["timing_after"]["tns_ns"], 0.0)
        self.assertEqual(summary["cts"]["clock_sinks"], 136)
        self.assertEqual(summary["cts"]["inserted_clock_buffers"], 29)
        self.assertEqual(summary["delta"]["wns_change_ns"], 0.41)
        self.assertEqual(summary["delta"]["tns_change_ns"], 5.72)
        self.assertEqual(summary["delta"]["violating_endpoints_change"], -14)

    def test_missing_metric_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            incomplete = Path(directory) / "incomplete.rpt"
            incomplete.write_text("WNS (setup): -0.10 ns\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "missing required metric"):
                summarize_reports.parse_report(
                    incomplete, summarize_reports.TIMING_PATTERNS
                )

    def test_markdown_labels_synthetic_provenance(self):
        sample = ROOT / "reports" / "sample"
        summary = summarize_reports.build_summary(
            sample / "timing_before.rpt",
            sample / "timing_after.rpt",
            sample / "cts_summary.rpt",
        )
        output = summarize_reports.format_markdown(summary)
        self.assertIn("synthetic sample fixtures", output)
        self.assertIn("| Setup WNS | -0.34 ns | +0.07 ns |", output)
        self.assertIn("violating endpoints -14", output)

    def test_custom_inputs_use_neutral_provenance(self):
        sample = ROOT / "reports" / "sample"
        with tempfile.TemporaryDirectory() as directory:
            custom_before = Path(directory) / "before.rpt"
            custom_before.write_text(
                (sample / "timing_before.rpt").read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            summary = summarize_reports.build_summary(
                custom_before,
                sample / "timing_after.rpt",
                sample / "cts_summary.rpt",
            )
        self.assertIn("user-supplied", summary["provenance"])
        self.assertNotIn("synthetic sample fixtures", summary["provenance"])

    def test_cli_reports_input_errors_without_traceback(self):
        captured = io.StringIO()
        with redirect_stderr(captured):
            exit_code = summarize_reports.main(["--before", "/missing/report.rpt"])
        self.assertEqual(2, exit_code)
        self.assertIn("error:", captured.getvalue())
        self.assertNotIn("Traceback", captured.getvalue())


if __name__ == "__main__":
    unittest.main()
