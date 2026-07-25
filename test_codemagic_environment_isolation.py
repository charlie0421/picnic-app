#!/usr/bin/env python3
"""Static environment-isolation tests for codemagic.yaml.

Guards Critical 1 (PR #73): a production tag must never upload an app that
silently points at staging. Three invariants enforce that:

1. ``DEPLOY_TARGET`` is fail-closed. It may not be read with a ``:-`` default
   (a default silently picks a target when the CI variable is unset), and every
   build workflow must assert it explicitly with ``${DEPLOY_TARGET:?...}``.
2. Build/release commands are branch-correct. A non-production define may only
   appear inside the non-production branch of a ``DEPLOY_TARGET`` test, and a
   production define only inside the production branch. Being nested under
   *some* ``DEPLOY_TARGET`` ``if`` is not enough -- polarity is checked.
3. Every build workflow really has a production build path, as executable code
   rather than a comment.

The guard is itself verified by mutation self-tests: each mutation reproduces a
way Critical 1 can come back, and the guard must reject every one of them.

Runs without pytest:

    python3 test_codemagic_environment_isolation.py              # check the repo
    python3 test_codemagic_environment_isolation.py --self-test  # check the guard

Exits 0 when every invariant holds, 1 otherwise.
"""

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write(
        "PyYAML is required to verify codemagic environment isolation.\n"
        "Install it with: python3 -m pip install pyyaml\n"
        "This guard must not be skipped silently -- it is what keeps a "
        "production tag from shipping a staging app.\n"
    )
    raise SystemExit(1)

REPO_ROOT = Path(__file__).resolve().parent
CODEMAGIC = REPO_ROOT / "codemagic.yaml"

# Tag-triggered workflows that can ship either target, selected at run time by
# DEPLOY_TARGET. These are the ones Critical 1 is about.
DUAL_TARGET_WORKFLOWS = (
    "picnic-app-ios",
    "picnic-app-android",
)

# Manual Shorebird patch workflows. Production-only by design: they have no
# `triggering` block and are gated on verify_release_target.dart rather than on
# DEPLOY_TARGET, so they must never carry a non-production define at all.
PRODUCTION_ONLY_WORKFLOWS = (
    "picnic-app-patch-ios",
    "picnic-app-patch-android",
)

BUILD_WORKFLOWS = DUAL_TARGET_WORKFLOWS + PRODUCTION_ONLY_WORKFLOWS

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

# `[ "$DEPLOY_TARGET" = "production" ]` / `[ "${DEPLOY_TARGET:-x}" != "prod" ]`.
# `[^=!]*` cannot cross the operator, so it stops at the comparison.
DEPLOY_COMPARISON = re.compile(
    r"DEPLOY_TARGET[^=!]*(?P<op>!=|=)\s*\"?(?P<value>[\w-]+)\"?"
)
DEPLOY_DEFAULT = re.compile(r"\$\{DEPLOY_TARGET:-")
DEPLOY_REQUIRE = re.compile(r"\$\{DEPLOY_TARGET:\?")
PRODUCTION_GATE = re.compile(r"verify_release_target\.dart\s+--target=production")

PRODUCTION = "production"


def load_workflows(text=None):
    if text is None:
        text = CODEMAGIC.read_text(encoding="utf-8")
    data = yaml.safe_load(text)
    return data["workflows"]


def script_blocks(workflow):
    """Yield (step_name, script_text) for each shell script step."""
    for step in workflow.get("scripts", []):
        if isinstance(step, dict) and "script" in step:
            yield step.get("name", "<unnamed>"), step["script"]


def _then_branch_is_production(op, value):
    """Which deploy target does the `then` branch of this test correspond to?"""
    tests_production = value == PRODUCTION
    return tests_production if op == "=" else not tests_production


def deploy_contexts(script):
    """Yield (line, context) for each executable line of a shell script.

    ``context`` is ``"production"`` / ``"non-production"`` when the line sits in
    the corresponding branch of a ``DEPLOY_TARGET`` test, ``"unknown"`` inside a
    branch whose target cannot be determined, or ``None`` when no
    ``DEPLOY_TARGET`` test encloses the line at all.
    """
    stack = []  # frames: {"deploy": bool, "production": bool | None}
    for raw in script.splitlines():
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue

        if stripped == "fi" or stripped.startswith(("fi ", "fi;")):
            if stack:
                stack.pop()
            continue

        if stripped == "else" or stripped.startswith("else "):
            if stack and stack[-1]["deploy"] and stack[-1]["production"] is not None:
                stack[-1]["production"] = not stack[-1]["production"]
            continue

        if stripped.startswith("elif "):
            # Cannot reason about the target of a chained condition.
            if stack and stack[-1]["deploy"]:
                stack[-1]["production"] = None
            continue

        context = None
        for frame in reversed(stack):
            if frame["deploy"]:
                if frame["production"] is None:
                    context = "unknown"
                else:
                    context = PRODUCTION if frame["production"] else "non-production"
                break
        yield stripped, context

        # Open a block, unless it is a self-contained single-line `if ...; fi`.
        if stripped.startswith("if ") and not re.search(r";\s*fi\b", stripped):
            match = DEPLOY_COMPARISON.search(stripped)
            if match:
                stack.append(
                    {
                        "deploy": True,
                        "production": _then_branch_is_production(
                            match.group("op"), match.group("value")
                        ),
                    }
                )
            else:
                stack.append({"deploy": False, "production": None})


def _placement(context):
    if context is None:
        return "outside any DEPLOY_TARGET guard"
    return f"in the {context} branch"


def check_branch_correct_defines(workflows):
    """Non-prod defines only in the staging branch, prod defines only in prod."""
    failures = []
    for name in DUAL_TARGET_WORKFLOWS:
        for step_name, script in script_blocks(workflows[name]):
            for line, context in deploy_contexts(script):
                where = f"{name} / {step_name!r}"
                if NON_PROD_DEFINE.search(line) and context != "non-production":
                    failures.append(
                        f"{where}: non-production build define "
                        f"{_placement(context)}: {line!r}"
                    )
                if PROD_DEFINE.search(line) and context != PRODUCTION:
                    failures.append(
                        f"{where}: production build define "
                        f"{_placement(context)}: {line!r}"
                    )

    for name in PRODUCTION_ONLY_WORKFLOWS:
        for step_name, script in script_blocks(workflows[name]):
            for line, _ in deploy_contexts(script):
                if NON_PROD_DEFINE.search(line):
                    failures.append(
                        f"{name} / {step_name!r}: non-production build define in a "
                        f"production-only patch workflow: {line!r}"
                    )
    return failures


def check_production_path_exists(workflows):
    """Each build workflow must really run a production build, not mention one."""
    failures = []
    for name in DUAL_TARGET_WORKFLOWS:
        found = any(
            PROD_DEFINE.search(line) and context == PRODUCTION
            for _, script in script_blocks(workflows[name])
            for line, context in deploy_contexts(script)
        )
        if not found:
            failures.append(
                f"{name}: no executable production build path found (expected a "
                f"--dart-define=ENVIRONMENT=prod invocation in the production branch)"
            )

    for name in PRODUCTION_ONLY_WORKFLOWS:
        found = any(
            PROD_DEFINE.search(line)
            for _, script in script_blocks(workflows[name])
            for line, _ in deploy_contexts(script)
        )
        if not found:
            failures.append(
                f"{name}: no executable production build path found (expected a "
                f"--dart-define=ENVIRONMENT=prod invocation)"
            )
    return failures


def check_deploy_target_fail_closed(workflows):
    """An unset DEPLOY_TARGET must stop the build, not silently pick a target."""
    failures = []
    for name in DUAL_TARGET_WORKFLOWS:
        asserted = False
        for step_name, script in script_blocks(workflows[name]):
            for line, _ in deploy_contexts(script):
                if DEPLOY_DEFAULT.search(line):
                    failures.append(
                        f"{name} / {step_name!r}: DEPLOY_TARGET read with a default, "
                        f"so an unset variable silently picks a deploy target: {line!r}"
                    )
                if DEPLOY_REQUIRE.search(line):
                    asserted = True
        if not asserted:
            failures.append(
                f"{name}: DEPLOY_TARGET is never asserted; expected a "
                f'`: \"${{DEPLOY_TARGET:?...}}\"` check so an unset variable fails the build'
            )
    return failures


def check_production_gate_runs_in_production(workflows):
    """The protected-target evidence check must gate the production branch."""
    failures = []
    for name in DUAL_TARGET_WORKFLOWS:
        found = any(
            PRODUCTION_GATE.search(line) and context == PRODUCTION
            for _, script in script_blocks(workflows[name])
            for line, context in deploy_contexts(script)
        )
        if not found:
            failures.append(
                f"{name}: verify_release_target.dart --target=production never runs "
                f"in the production branch, so production releases ship ungated"
            )
    return failures


def run_checks(text=None):
    """Return the list of isolation violations for a codemagic.yaml text."""
    workflows = load_workflows(text)
    failures = []
    failures += check_deploy_target_fail_closed(workflows)
    failures += check_production_path_exists(workflows)
    failures += check_production_gate_runs_in_production(workflows)
    failures += check_branch_correct_defines(workflows)
    return failures


# ---------------------------------------------------------------------------
# Mutation self-tests
#
# A guard that cannot detect a deliberately broken codemagic.yaml is worthless.
# Each mutation reproduces a way Critical 1 can come back; the guard must report
# at least one violation that the unmutated file does not already have.
# ---------------------------------------------------------------------------


def mutate_identity(text):
    return text


def mutate_flip_production_guard(text):
    """Swap the production and staging branches by inverting every test."""

    def flip(match):
        op = match.group("op")
        return match.group(0).replace(op, "!=" if op == "=" else "=", 1)

    return DEPLOY_COMPARISON.sub(flip, text)


def mutate_comment_out_production_path(text):
    """Leave the production build path present only as a comment."""
    out = []
    for line in text.splitlines():
        if PROD_DEFINE.search(line) and not line.strip().startswith("#"):
            indent = line[: len(line) - len(line.lstrip())]
            out.append(f"{indent}# {line.strip()}")
        else:
            out.append(line)
    return "\n".join(out) + "\n"


def mutate_unguarded_dev_define(text):
    """Introduce a dev build define that no DEPLOY_TARGET branch encloses."""
    marker = 'echo "=== Flutter 패키지 설치 ==="'
    for line in text.splitlines():
        if marker in line:
            indent = line[: len(line) - len(line.lstrip())]
            injected = f"{indent}flutter build ios --dart-define=ENVIRONMENT=dev"
            return text.replace(line, f"{injected}\n{line}", 1)
    raise AssertionError("self-test anchor not found in codemagic.yaml")


def mutate_reintroduce_deploy_default(text):
    """Restore the silent staging fallback for an unset DEPLOY_TARGET."""
    return text.replace('"$DEPLOY_TARGET"', '"${DEPLOY_TARGET:-staging}"')


SELF_TESTS = (
    ("unmutated config is accepted", mutate_identity, False),
    ("production guard polarity inverted", mutate_flip_production_guard, True),
    ("production path only in a comment", mutate_comment_out_production_path, True),
    ("dev define outside any deploy guard", mutate_unguarded_dev_define, True),
    ("DEPLOY_TARGET default reintroduced", mutate_reintroduce_deploy_default, True),
)


def run_self_tests():
    original = CODEMAGIC.read_text(encoding="utf-8")
    baseline = set(run_checks(original))
    failures = []
    for description, mutate, expect_violation in SELF_TESTS:
        mutated = mutate(original)
        if mutated == original and expect_violation:
            failures.append(f"mutation had no effect, so it proves nothing: {description}")
            continue
        introduced = set(run_checks(mutated)) - baseline
        if bool(introduced) != expect_violation:
            verb = "missed" if expect_violation else "falsely flagged"
            failures.append(f"guard {verb}: {description}")

    if failures:
        print("FAIL: codemagic isolation guard self-test")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print(f"PASS: codemagic isolation guard self-test ({len(SELF_TESTS)} mutations)")
    return 0


def main(argv):
    if "--self-test" in argv:
        return run_self_tests()

    failures = run_checks()
    if failures:
        print("FAIL: codemagic environment isolation")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print("PASS: codemagic environment isolation")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
