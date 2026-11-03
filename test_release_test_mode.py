import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent
POLICY = ROOT / "scripts" / "release_test_mode.sh"


def resolve_mode(tag: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", str(POLICY), tag],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )


class ReleaseTestModeTest(unittest.TestCase):
    def test_regular_release_tags_run_coverage(self):
        for tag in (
            "picnic-v1.3.2+130202",
            "picnic-staging-v1.3.2+130202",
        ):
            with self.subTest(tag=tag):
                result = resolve_mode(tag)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), "run")

    def test_skip_suffix_skips_coverage(self):
        for tag in (
            "picnic-v1.3.2+130203-skip-tests",
            "picnic-staging-v1.3.2+130203-skip-tests",
        ):
            with self.subTest(tag=tag):
                result = resolve_mode(tag)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), "skip")

    def test_only_an_exact_suffix_can_skip_coverage(self):
        for tag in (
            "picnic-v1.3.2+130203-skip-tests-extra",
            "picnic-v1.3.2+130203-skip-test",
        ):
            with self.subTest(tag=tag):
                result = resolve_mode(tag)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), "run")

    def test_unknown_tags_fail_closed(self):
        result = resolve_mode("other-v1.3.2+130203-skip-tests")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
