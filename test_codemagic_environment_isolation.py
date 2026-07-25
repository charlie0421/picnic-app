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
4. Every release invocation pins the *whole* define tuple for its branch. It is
   not enough that ``ENVIRONMENT`` is right: a staging release must also pass
   ``PANGLE_ENVIRONMENT=sandbox``, ``PAYMENT_ENVIRONMENT=sandbox`` and the empty
   Pangle slot ids, and a production release must pass the production modes.
   The same tuple is required of the env prefix that invokes
   ``verify_environment_isolation.dart``. That is what stops the isolation check
   from being tautological: the tool can no longer be handed hand-written
   sandbox literals while the release command next to it builds with production
   SDK modes -- the two are pinned to one policy, resolved from the executable
   lines that actually run.
5. A guard that says NO-GO stops the build. Any step that runs a release guard
   must ``set -e``, because a guard is generally not the last command in its
   step and its exit status would otherwise be discarded.
6. The picnic_app guard tests really run. ``picnic_app/test/config`` holds the
   release-target and isolation unit tests; picnic_lib's suite never loads them,
   so each tag workflow must run ``flutter test`` inside ``picnic_app``.

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

# The complete set of defines that decides which backend and which SDK modes
# the shipped binary talks to. A release invocation must pin every one of them
# for its branch -- picking the right `ENVIRONMENT` while leaving an ad or
# payment SDK in production mode still ships a staging app wired to production.
SANDBOX_BUILD_DEFINES = {
    "ENVIRONMENT": "dev",
    "PANGLE_ENVIRONMENT": "sandbox",
    "PAYMENT_ENVIRONMENT": "sandbox",
    "PICNIC_PANGLE_IOS_APP_ID": "",
    "PICNIC_PANGLE_ANDROID_APP_ID": "",
    "PICNIC_PANGLE_IOS_REWARDED_ID": "",
    "PICNIC_PANGLE_ANDROID_REWARDED_ID": "",
}

PRODUCTION_BUILD_DEFINES = {
    "ENVIRONMENT": "prod",
    "PANGLE_ENVIRONMENT": "prod",
    "PAYMENT_ENVIRONMENT": "prod",
}

GOVERNED_DEFINES = frozenset(SANDBOX_BUILD_DEFINES) | frozenset(
    PRODUCTION_BUILD_DEFINES
)

# Commands that produce or publish a binary. `flutter build ios --config-only`
# only writes Generated.xcconfig, so it is deliberately not one of these.
RELEASE_INVOCATION = re.compile(
    r"\bshorebird\s+(?:release|patch)\b|\bflutter\s+build\s+(?:ipa|appbundle|apk)\b"
)

ISOLATION_VERIFIER = re.compile(r"verify_environment_isolation\.dart")

# Anything whose NO-GO must stop the build.
RELEASE_GUARD = re.compile(
    r"verify_environment_isolation\.dart"
    r"|verify_release_target\.dart"
    r"|test_codemagic_environment_isolation\.py"
)

SET_E = re.compile(r"^set\s+-[A-Za-z]*e")
FLUTTER_TEST = re.compile(r"\bflutter\s+test\b")

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


def deploy_invocations(script):
    """Like :func:`deploy_contexts`, but joins ``\\``-continued shell lines.

    Release commands spread one invocation over a dozen lines, so the defines
    that belong to a single command have to be reassembled before they can be
    compared against the tuple required for that branch. A continuation cannot
    open or close a block, so the whole logical command carries the context of
    its first line.
    """
    pending = ""
    pending_context = None
    for line, context in deploy_contexts(script):
        continued = line.endswith("\\")
        body = line[:-1].rstrip() if continued else line
        if pending:
            pending = f"{pending} {body}"
        else:
            pending, pending_context = body, context
        if not continued:
            yield pending, pending_context
            pending = ""
    if pending:
        yield pending, pending_context


_QUOTED = re.compile(r"'[^']*'|\"[^\"]*\"")


def executable_part(command):
    """The command with quoted literals removed.

    ``echo "=== Fallback: flutter build ipa ==="`` names a release command but
    does not run one, and a log path like ``/tmp/shorebird_release.log`` is not
    an invocation either. Matching on the unquoted remainder keeps prose out of
    the analysis.
    """
    return _QUOTED.sub(" ", command)


def command_defines(command):
    """Governed define name -> value, as this command actually passes it.

    Three spellings reach the same knob: ``--dart-define=K=V`` on a build
    command, ``--environment=V`` on verify_environment_isolation.dart, and a
    bare ``K=V`` env prefix. The lookbehind keeps ``PANGLE_ENVIRONMENT=`` from
    being read as ``ENVIRONMENT=``.
    """
    command = executable_part(command)
    found = {}
    for key in GOVERNED_DEFINES:
        patterns = [rf"--dart-define={key}=(\S*)"]
        if key == "ENVIRONMENT":
            patterns.append(r"--environment=(\S*)")
        patterns.append(rf"(?<![\w=/-]){key}=(\S*)")
        for pattern in patterns:
            match = re.search(pattern, command)
            if match:
                found[key] = match.group(1)
                break
    return found


def _abbreviate(command, limit=110):
    collapsed = " ".join(command.split())
    if len(collapsed) <= limit:
        return collapsed
    return collapsed[:limit] + " ..."


def _compare_defines(where, target, command, expected):
    """Report every governed define this command gets wrong for its target."""
    found = command_defines(command)
    failures = []
    for key, value in sorted(expected.items()):
        if key not in found:
            failures.append(
                f"{where}: {target} invocation does not pin {key}={value!r}: "
                f"{_abbreviate(command)!r}"
            )
        elif found[key] != value:
            failures.append(
                f"{where}: {target} invocation sets {key}={found[key]!r}, "
                f"expected {value!r}: {_abbreviate(command)!r}"
            )
    return failures


def check_release_invocation_defines(workflows):
    """Every release command pins the complete define tuple for its branch."""
    failures = []
    for name in DUAL_TARGET_WORKFLOWS:
        for step_name, script in script_blocks(workflows[name]):
            where = f"{name} / {step_name!r}"
            for command, context in deploy_invocations(script):
                if not RELEASE_INVOCATION.search(executable_part(command)):
                    continue
                if context == PRODUCTION:
                    expected = PRODUCTION_BUILD_DEFINES
                elif context == "non-production":
                    expected = SANDBOX_BUILD_DEFINES
                else:
                    failures.append(
                        f"{where}: release invocation {_placement(context)}, so the "
                        f"defines it ships cannot be checked: {_abbreviate(command)!r}"
                    )
                    continue
                failures += _compare_defines(where, context, command, expected)

    for name in PRODUCTION_ONLY_WORKFLOWS:
        for step_name, script in script_blocks(workflows[name]):
            where = f"{name} / {step_name!r}"
            for command, _ in deploy_invocations(script):
                if RELEASE_INVOCATION.search(executable_part(command)):
                    failures += _compare_defines(
                        where, PRODUCTION, command, PRODUCTION_BUILD_DEFINES
                    )
    return failures


def check_isolation_verifier_inputs(workflows):
    """The isolation tool must be fed the same tuple the staging build uses.

    Without this the check is tautological: the env prefix on the tool's own
    command line is a hand-written literal, so flipping the release command's
    defines to production leaves the tool printing GO.
    """
    failures = []
    for name in DUAL_TARGET_WORKFLOWS:
        invoked = False
        for step_name, script in script_blocks(workflows[name]):
            where = f"{name} / {step_name!r}"
            for command, context in deploy_invocations(script):
                if not ISOLATION_VERIFIER.search(executable_part(command)):
                    continue
                invoked = True
                if context != "non-production":
                    failures.append(
                        f"{where}: verify_environment_isolation.dart runs "
                        f"{_placement(context)}: {_abbreviate(command)!r}"
                    )
                    continue
                failures += _compare_defines(
                    where, "non-production", command, SANDBOX_BUILD_DEFINES
                )
        if not invoked:
            failures.append(
                f"{name}: verify_environment_isolation.dart never runs, so nothing "
                f"validates the generated config the staging build ships"
            )
    return failures


def check_guard_failure_fails_the_step(workflows):
    """A guard's NO-GO must fail its step instead of being overwritten."""
    failures = []
    for name, workflow in workflows.items():
        for step_name, script in script_blocks(workflow):
            lines = [line.strip() for line in script.splitlines()]
            guard_at = next(
                (
                    i
                    for i, line in enumerate(lines)
                    if not line.startswith("#") and RELEASE_GUARD.search(line)
                ),
                None,
            )
            if guard_at is None:
                continue
            if not any(SET_E.match(line) for line in lines[:guard_at]):
                failures.append(
                    f"{name} / {step_name!r}: runs a release guard without `set -e`, "
                    f"so a NO-GO exit status is discarded by the commands that follow "
                    f"and the build keeps going"
                )
    return failures


def _runs_app_tests(script):
    """True when this step runs `flutter test` with picnic_app as its cwd."""
    in_app = False
    for raw in script.splitlines():
        line = raw.strip()
        if line.startswith("cd "):
            in_app = line[3:].strip().strip('"').strip("'") == "picnic_app"
        elif in_app and FLUTTER_TEST.search(line):
            return True
    return False


def check_app_guard_tests_run(workflows):
    """picnic_app/test/config must execute in every tag workflow."""
    failures = []
    for name in DUAL_TARGET_WORKFLOWS:
        if not any(
            _runs_app_tests(script) for _, script in script_blocks(workflows[name])
        ):
            failures.append(
                f"{name}: picnic_app tests never run (expected `flutter test` with "
                f"picnic_app as the working directory), so the release-target and "
                f"environment-isolation guards in picnic_app/test/config can rot"
            )
    return failures


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
    failures += check_release_invocation_defines(workflows)
    failures += check_isolation_verifier_inputs(workflows)
    failures += check_guard_failure_fails_the_step(workflows)
    failures += check_app_guard_tests_run(workflows)
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


def mutate_production_sdk_mode_in_staging_build(text):
    """Point the staging release command's ad SDK at production.

    `ENVIRONMENT` still says dev, so nothing about the Supabase target changes.
    This is the mutation the old, tautological isolation check could not see:
    verify_environment_isolation.dart was handed `PANGLE_ENVIRONMENT=sandbox`
    as a literal on its own command line, so it kept printing GO.
    """
    return text.replace(
        "--dart-define=PANGLE_ENVIRONMENT=sandbox",
        "--dart-define=PANGLE_ENVIRONMENT=prod",
    )


def mutate_isolation_verifier_env_prefix(text):
    """Lie to the isolation tool about the SDK mode it is meant to prove."""
    return re.sub(
        r"(?m)^(\s*)PAYMENT_ENVIRONMENT=sandbox(\s*\\)$",
        r"\1PAYMENT_ENVIRONMENT=prod\2",
        text,
    )


def mutate_drop_pangle_isolation_define(text):
    """Stop blanking a Pangle slot id, so staging keeps the production slot."""
    return "\n".join(
        line
        for line in text.splitlines()
        if "--dart-define=PICNIC_PANGLE_IOS_APP_ID=" not in line
    ) + "\n"


def mutate_drop_set_e(text):
    """Let a guard's NO-GO be overwritten by the commands after it."""
    return "\n".join(
        line for line in text.splitlines() if line.strip() != "set -e"
    ) + "\n"


def mutate_drop_app_guard_tests(text):
    """Unwire picnic_app/test/config from the tag workflows again."""
    return "\n".join(
        line for line in text.splitlines() if line.strip() != "flutter test"
    ) + "\n"


SELF_TESTS = (
    ("unmutated config is accepted", mutate_identity, False),
    ("production guard polarity inverted", mutate_flip_production_guard, True),
    ("production path only in a comment", mutate_comment_out_production_path, True),
    ("dev define outside any deploy guard", mutate_unguarded_dev_define, True),
    ("DEPLOY_TARGET default reintroduced", mutate_reintroduce_deploy_default, True),
    (
        "staging release command switched to the production ad SDK",
        mutate_production_sdk_mode_in_staging_build,
        True,
    ),
    (
        "isolation tool fed a production SDK mode it cannot detect",
        mutate_isolation_verifier_env_prefix,
        True,
    ),
    (
        "staging build stops blanking a production Pangle slot id",
        mutate_drop_pangle_isolation_define,
        True,
    ),
    ("guard NO-GO no longer fails its step", mutate_drop_set_e, True),
    ("picnic_app guard tests unwired", mutate_drop_app_guard_tests, True),
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
