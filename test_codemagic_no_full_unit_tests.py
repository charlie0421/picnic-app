import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent
CODEMAGIC = ROOT / "codemagic.yaml"


class CodemagicNoFullUnitTestsTest(unittest.TestCase):
    def test_codemagic_does_not_run_picnic_lib_full_coverage_suite(self):
        config = CODEMAGIC.read_text(encoding="utf-8")

        self.assertNotIn("cd picnic_lib", config)
        self.assertNotIn("flutter test --coverage", config)
        self.assertNotIn("picnic_lib/build/test-results", config)

    def test_policy_guard_runs_in_codemagic(self):
        config = CODEMAGIC.read_text(encoding="utf-8")

        self.assertIn(
            "python3 -m unittest -v test_release_tag_resolver.py "
            "test_codemagic_no_full_unit_tests.py",
            config,
        )


if __name__ == "__main__":
    unittest.main()
