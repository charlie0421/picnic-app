#!/usr/bin/env python3
"""Static environment-isolation tests for codemagic.yaml.

Guards Critical 1 (PR #73): every iOS/Android build+release workflow must drive
its production deploy path with the production backend/payment/Pangle settings,
and no build or release command may pin a dev/staging/sandbox environment
outside an explicit ``DEPLOY_TARGET`` guard. A production tag must never upload
an app that silently points at staging.

Runs without pytest:

    python3 test_codemagic_environment_isolation.py

Exits 0 when every invariant holds, 1 otherwise.
"""

import re
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent
CODEMAGIC = REPO_ROOT / "codemagic.yaml"

# Workflows that build and ship an installable app for a release tag.
BUILD_WORKFLOWS = (
    "picnic-app-ios",
    "picnic-app-android",
    "picnic-app-patch-ios",
    "picnic-app-patch-android",
)

# A build/release invocation pinned to a non-production environment. Both the
# `--dart-define=` form (passed to flutter/shorebird) and the leading env-var
# form (exported before `dart run ...`) are covered.
NON_PROD_DEFINE = re.compile(
    r"--dart-define=ENVIRONMENT=dev"
    r"|--dart-define=PANGLE_ENVIRONMENT=sandbox"
    r"|--dart-define=PAYMENT_ENVIRONMENT=sandbox"
    r"|--environment=dev"
    r"|(?<![\w-])PANGLE_ENVIRONMENT=sandbox"
    r"|(?<![\w-])PAYMENT_ENVIRONMENT=sandbox"
)

PROD_DEFINE = re.compile(r"--dart-define=ENVIRONMENT=prod")


def load_workflows():
    data = yaml.safe_load(CODEMAGIC.read_text(encoding="utf-8"))
    return data["workflows"]


def script_blocks(workflow):
    """Yield (step_name, script_text) for each shell script step."""
    for step in workflow.get("scripts", []):
        if isinstance(step, dict) and "script" in step:
            yield step.get("name", "<unnamed>"), step["script"]


def unguarded_nonprod_defines(script):
    """Lines that pin a non-prod environment while at DEPLOY_TARGET-guard depth 0.

    A "deploy guard" is a shell ``if`` whose condition references
    ``DEPLOY_TARGET``. Non-deploy ``if`` blocks (artifact checks, keystore
    checks, ...) do not count as guards: a dev build nested only inside those is
    still applied unconditionally with respect to the deploy target.
    """
    violations = []
    stack = []  # each entry: True if the frame is a DEPLOY_TARGET guard
    for raw in script.splitlines():
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        # Close blocks before evaluating this line's execution depth.
        if stripped == "fi" or stripped.startswith("fi ") or stripped.startswith("fi;"):
            if stack:
                stack.pop()
            continue
        depth = sum(1 for is_guard in stack if is_guard)
        if depth == 0 and NON_PROD_DEFINE.search(stripped):
            violations.append(stripped)
        # Open a block, unless it is a self-contained single-line `if ...; fi`.
        if stripped.startswith("if ") and not re.search(r";\s*fi\b", stripped):
            stack.append("DEPLOY_TARGET" in stripped)
    return violations


def check_no_unguarded_nonprod(workflows):
    failures = []
    for name in BUILD_WORKFLOWS:
        workflow = workflows[name]
        for step_name, script in script_blocks(workflow):
            for line in unguarded_nonprod_defines(script):
                failures.append(
                    f"{name} / {step_name!r}: unconditional non-production build "
                    f"define outside a DEPLOY_TARGET guard: {line!r}"
                )
    return failures


def check_production_path_exists(workflows):
    failures = []
    for name in BUILD_WORKFLOWS:
        workflow = workflows[name]
        joined = "\n".join(script for _, script in script_blocks(workflow))
        if not PROD_DEFINE.search(joined):
            failures.append(
                f"{name}: no production build path found "
                f"(expected a --dart-define=ENVIRONMENT=prod invocation)"
            )
    return failures


def main():
    workflows = load_workflows()
    failures = []
    failures += check_production_path_exists(workflows)
    failures += check_no_unguarded_nonprod(workflows)

    if failures:
        print("FAIL: codemagic environment isolation")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print("PASS: codemagic environment isolation")
    return 0


if __name__ == "__main__":
    sys.exit(main())
