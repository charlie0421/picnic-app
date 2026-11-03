import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent
RESOLVER = ROOT / "scripts" / "resolve_release_tag.sh"


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args], cwd=repo, check=True, capture_output=True, text=True
    )
    return result.stdout.strip()


class ReleaseTagResolverTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp_dir.name)
        git(self.repo, "init", "-b", "main")
        git(self.repo, "config", "user.name", "Codemagic Test")
        git(self.repo, "config", "user.email", "ci@example.invalid")
        (self.repo / "app.txt").write_text("release\n", encoding="utf-8")
        git(self.repo, "add", "app.txt")
        git(self.repo, "commit", "-m", "release")
        self.commit = git(self.repo, "rev-parse", "HEAD")

    def tearDown(self):
        self.temp_dir.cleanup()

    def resolve(self, **environment: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(RESOLVER)],
            cwd=self.repo,
            env={**os.environ, **environment},
            capture_output=True,
            text=True,
        )

    def test_webhook_tag_is_used_without_git_discovery(self):
        result = self.resolve(
            CM_TAG="picnic-v1.3.1+130103",
            CM_COMMIT="not-a-commit",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "picnic-v1.3.1+130103")

    def test_rebuild_recovers_the_single_release_tag_on_the_commit(self):
        git(self.repo, "tag", "-a", "picnic-v1.3.1+130103", "-m", "release")
        result = self.resolve(CM_TAG="", CM_COMMIT=self.commit)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "picnic-v1.3.1+130103")

    def test_rebuild_rejects_a_commit_without_a_release_tag(self):
        result = self.resolve(CM_TAG="", CM_COMMIT=self.commit)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("exactly one release tag", result.stderr)

    def test_rebuild_rejects_ambiguous_release_tags(self):
        git(self.repo, "tag", "-a", "picnic-v1.3.1+130103", "-m", "production")
        git(
            self.repo,
            "tag",
            "-a",
            "picnic-staging-v1.3.1+130103",
            "-m",
            "staging",
        )
        result = self.resolve(CM_TAG="", CM_COMMIT=self.commit)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("exactly one release tag", result.stderr)


if __name__ == "__main__":
    unittest.main()
