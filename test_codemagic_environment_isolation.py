#!/usr/bin/env python3
"""Static environment-isolation tests for codemagic.yaml.

Guards Critical 1 (PR #73): a production tag must never upload an app that
silently points at staging. The invariants below enforce that.

Structure
---------
0. The workflows that must be checked are *derived from the YAML*, not
   hard-coded. Any workflow that builds or publishes a binary is a release
   workflow; a tag-triggered one is dual-target (its target is chosen at run
   time by ``DEPLOY_TARGET``), anything else is production-only. Cloning a tag
   workflow under a new name therefore cannot escape the guard, and a renamed
   or missing key fails closed instead of silently dropping a workflow.

DEPLOY_TARGET handling
----------------------
1. ``DEPLOY_TARGET`` is fail-closed. It may not be given a default with any
   form of shell defaulting (``:-`` ``-`` ``:=`` ``=`` ``:+`` ``+``), may not
   be assigned by the workflow or by ``environment.vars``, and every
   dual-target workflow must assert it with ``${DEPLOY_TARGET:?...}``.
2. Its *value* is constrained to a known allow-list by a
   ``case "$DEPLOY_TARGET" in`` block whose catch-all exits non-zero, and that
   step must run before anything else that reads DEPLOY_TARGET or builds.
   Without it, ``Production`` or ``production `` survive ``${DEPLOY_TARGET:?}``
   and fall into the staging branch.
3. Every ``if``/``elif`` that mentions DEPLOY_TARGET must be a *pure* two-way
   test on it. ``[ "$DEPLOY_TARGET" = "production" ] && [ "$X" = "y" ]`` is not
   a deploy-target switch: at run time ``DEPLOY_TARGET=production X=n`` takes
   the ``else`` branch and builds staging. Such a condition is refused rather
   than trusted to label its branches.

Build/release correctness
-------------------------
4. Build/release commands are branch-correct. A non-production define may only
   appear inside the non-production branch of a DEPLOY_TARGET test, and a
   production define only inside the production branch.
5. Every dual-target workflow really has a production build path, as
   executable code rather than a comment.
6. Every release invocation pins the *whole* define tuple for its branch. It is
   not enough that ``ENVIRONMENT`` is right: a staging release must also pass
   ``PANGLE_ENVIRONMENT=sandbox``, ``PAYMENT_ENVIRONMENT=sandbox`` and the empty
   Pangle slot ids, and a production release must pass the production modes.
   The same tuple is required of the env prefix that invokes
   ``verify_environment_isolation.dart``. That is what stops the isolation check
   from being tautological.

Guards actually run, and actually stop the build
------------------------------------------------
7. A guard that says NO-GO stops the build. The step must ``set -e``
   unconditionally at top level (a ``set -e`` nested in an ``if`` does not
   count), must not ``set +e`` before the guard, and the guard's own status must
   be reachable: no ``|| fallback``, no background ``&``, no use as an
   ``if``/``while`` condition, no command substitution, and no pipeline unless
   ``set -o pipefail`` is on.
8. This guard is itself wired into CI: every dual-target workflow must run
   ``test_codemagic_environment_isolation.py`` and its ``--self-test``, before
   the build.
9. The picnic_app guard tests really run, unnarrowed. ``picnic_app/test/config``
   holds the release-target and isolation unit tests; picnic_lib's suite never
   loads them, so each tag workflow must run ``flutter test`` inside
   ``picnic_app`` without narrowing the path away from ``test/config``.

The guard is itself verified by mutation self-tests: each mutation reproduces a
way Critical 1 can come back, and the guard must reject every one of them.

Runs without pytest:

    python3 test_codemagic_environment_isolation.py              # check the repo
    python3 test_codemagic_environment_isolation.py --self-test  # check the guard

Exits 0 when every invariant holds, 1 otherwise.
"""

import copy
import re
import sys
from collections import namedtuple
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

PRODUCTION = "production"
NON_PRODUCTION = "non-production"
UNLABELLED = "unlabelled"

# The only DEPLOY_TARGET values the rest of this file knows how to reason about.
ALLOWED_DEPLOY_TARGETS = frozenset({"production", "staging"})

# `publishing` keys that only notify humans. Anything else ships a binary.
NOTIFICATION_PUBLISHERS = frozenset({"slack", "email", "scripts"})

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
SELF_INVOCATION = re.compile(r"test_codemagic_environment_isolation\.py")

# Anything whose NO-GO must stop the build.
RELEASE_GUARD = re.compile(
    r"verify_environment_isolation\.dart"
    r"|verify_release_target\.dart"
    r"|test_codemagic_environment_isolation\.py"
)

# `set -e`, `set -eu`, `set -eo pipefail`, `set -o errexit`. The option cluster
# is matched as a whole so `-eo` counts as errexit and `-o` alone does not.
SET_ERREXIT = re.compile(r"^set\s+(?:-[A-Za-z]*e[A-Za-z]*(?=\s|$)|-o\s+errexit\b)")
# `set +e`, `set +eu`, `set +o errexit`.
UNSET_ERREXIT = re.compile(r"^set\s+(?:\+[A-Za-z]*e[A-Za-z]*(?=\s|$)|\+o\s+errexit\b)")
# `set -o pipefail`, `set -eo pipefail`.
SET_PIPEFAIL = re.compile(r"^set\s+-[A-Za-z]*o\s+pipefail\b")

FLUTTER_TEST = re.compile(r"\bflutter\s+test\b")
# `flutter test` flags that take their value as the *next* argument. Without
# this list the value would be mistaken for a narrowed test path.
FLUTTER_TEST_VALUE_FLAGS = frozenset(
    {
        "-r",
        "--reporter",
        "--file-reporter",
        "-j",
        "--concurrency",
        "-n",
        "--name",
        "-N",
        "--plain-name",
        "-t",
        "--tags",
        "-x",
        "--exclude-tags",
        "-d",
        "--device-id",
        "--timeout",
        "--total-shards",
        "--shard-index",
        "--test-randomize-ordering-seed",
        "--coverage-path",
        "--dart-define",
        "--dart-define-from-file",
    }
)
# The directory that holds the release-target / isolation unit tests. A
# `flutter test <path>` that cannot reach it defeats the step.
APP_GUARD_TEST_DIR = "test/config"

DEPLOY_TARGET_REF = re.compile(r"\bDEPLOY_TARGET\b")

# A *pure* two-way test on DEPLOY_TARGET and nothing else. Anything the shell
# would also evaluate -- `&&`, `||`, `-a`, `-o`, a second `[`, a substitution --
# makes the branches unlabelable, because the `else` branch can then be reached
# with DEPLOY_TARGET=production.
PURE_DEPLOY_TEST = re.compile(
    r"^(?P<open>\[\[|\[)\s*"
    r"\"?\$(?:\{DEPLOY_TARGET\}|DEPLOY_TARGET)\"?\s*"
    r"(?P<op>!=|==|=)\s*"
    r"\"?(?P<value>[A-Za-z0-9_-]+)\"?\s*"
    r"(?P<close>\]\]|\])$"
)

# Any shell defaulting of DEPLOY_TARGET. `:?` / `?` (the required assert forms)
# are deliberately excluded; every other operator restores the silent fallback
# that Critical 1 was about.
DEPLOY_SOFT_DEFAULT = re.compile(r"\$\{DEPLOY_TARGET\s*:?[-=+]")
# The workflow choosing its own deploy target instead of taking it from CI.
DEPLOY_ASSIGNMENT = re.compile(
    r"(?<![\w./-])(?:export\s+|declare\s+|typeset\s+|readonly\s+)?DEPLOY_TARGET="
)
DEPLOY_REQUIRE = re.compile(r"\$\{DEPLOY_TARGET:\?")
PRODUCTION_GATE = re.compile(r"verify_release_target\.dart\s+--target=production")

CASE_HEAD = re.compile(r"^case\s+\"?\$\{?DEPLOY_TARGET\}?\"?\s+in\b")
CASE_LABEL = re.compile(r"^(?P<pattern>[^()]*?)\)")
NONZERO_EXIT = re.compile(r"\bexit\s+(?!0\b)\S+")

# --- shell shape helpers ---------------------------------------------------

_HEREDOC = re.compile(r"<<-?\s*(?P<quote>['\"]?)(?P<tag>[A-Za-z_][A-Za-z0-9_]*)(?P=quote)")
_CLOSE_FI = re.compile(r"^fi(?:\s|;|$)")
_CLOSE_BLOCK = re.compile(r"^(?:done|esac)(?:\s|;|$)|^\}(?:\s|;|$)")
_OPEN_CASE = re.compile(r"^case\s")
_OPEN_DO = re.compile(r"(?:^|[\s;])do\s*$")
_OPEN_BRACE = re.compile(r"\{\s*$")
_INLINE_FI = re.compile(r";\s*fi\b")
_CONDITION_HEAD = re.compile(r"^(?:if|elif|while|until)\s|^!\s")
_SUBSTITUTION = re.compile(r"\$\(|`")
_REDIRECT = re.compile(r"\d*[<>]&\d*-?|&>>?")


class GuardError(Exception):
    """A structural problem that makes the config impossible to analyse."""


ScriptLine = namedtuple("ScriptLine", "text depth context lineno")
Command = namedtuple("Command", "text depth context lineno")


def load_workflows(text=None):
    if text is None:
        text = CODEMAGIC.read_text(encoding="utf-8")
    try:
        data = yaml.safe_load(text)
    except yaml.YAMLError as exc:  # pragma: no cover - defensive
        raise GuardError(f"codemagic.yaml does not parse: {exc}")
    if not isinstance(data, dict):
        raise GuardError("codemagic.yaml does not contain a top-level mapping")
    workflows = data.get("workflows")
    if not isinstance(workflows, dict) or not workflows:
        raise GuardError(
            "codemagic.yaml has no `workflows` mapping; the key was renamed or "
            "removed, and this guard refuses to pass on a file it cannot read"
        )
    return workflows


def script_blocks(workflow):
    """Yield (step_name, script_text) for each shell script step."""
    if not isinstance(workflow, dict):
        return
    for step in workflow.get("scripts") or []:
        if isinstance(step, dict) and isinstance(step.get("script"), str):
            yield step.get("name", "<unnamed>"), step["script"]


def _if_condition(stripped):
    """The condition text of an `if`/`elif` line, without `; then`."""
    body = re.sub(r"^(?:if|elif)\s+", "", stripped)
    body = re.sub(r";\s*then\s*$", "", body)
    body = re.sub(r"\s*;\s*$", "", body)
    return body.strip()


def _deploy_branch_polarity(condition):
    """True/False for the `then` branch, or None when it cannot be labelled."""
    match = PURE_DEPLOY_TEST.match(condition)
    if not match:
        return None
    if (match.group("open") == "[") != (match.group("close") == "]"):
        return None
    tests_production = match.group("value") == PRODUCTION
    return tests_production if match.group("op") in ("=", "==") else not tests_production


def _context(stack):
    for frame in reversed(stack):
        if frame["deploy"]:
            if frame["production"] is None:
                return UNLABELLED
            return PRODUCTION if frame["production"] else NON_PRODUCTION
    return None


def scan(script):
    """Yield a :class:`ScriptLine` for every executable line of a shell script.

    Comments, blank lines and here-document bodies are dropped -- a ``fi``
    hidden inside a heredoc must not be allowed to pop a real branch frame.
    ``depth`` is the block-nesting depth the line runs at (0 = unconditional
    top level). ``context`` is ``"production"`` / ``"non-production"`` when the
    line sits in the corresponding branch of a DEPLOY_TARGET test,
    ``"unlabelled"`` inside a branch whose target cannot be determined, or
    ``None`` when no DEPLOY_TARGET test encloses the line at all.
    """
    stack = []  # frames: {"deploy": bool, "production": bool | None}
    depth = 0
    heredoc = None

    for lineno, raw in enumerate(script.splitlines(), 1):
        stripped = raw.strip()

        if heredoc is not None:
            if stripped == heredoc:
                heredoc = None
            continue

        if not stripped or stripped.startswith("#"):
            continue

        continued = stripped.endswith("\\")
        structural = False

        if not continued:
            structural = True
            if _CLOSE_FI.match(stripped):
                if stack:
                    stack.pop()
                depth = max(0, depth - 1)
            elif _CLOSE_BLOCK.match(stripped):
                depth = max(0, depth - 1)
            elif stripped == "else" or stripped.startswith("else "):
                frame = stack[-1] if stack else None
                if frame and frame["deploy"] and frame["production"] is not None:
                    frame["production"] = not frame["production"]
            elif stripped.startswith("elif "):
                # A chained condition cannot be labelled: reaching it means the
                # earlier conditions were false, so fail closed.
                frame = stack[-1] if stack else None
                if frame and (
                    frame["deploy"]
                    or DEPLOY_TARGET_REF.search(_if_condition(stripped))
                ):
                    frame["deploy"] = True
                    frame["production"] = None
            else:
                structural = False

        yield ScriptLine(stripped, depth, _context(stack), lineno)

        if not continued and not structural:
            if stripped.startswith("if ") and not _INLINE_FI.search(stripped):
                condition = _if_condition(stripped)
                if DEPLOY_TARGET_REF.search(condition):
                    stack.append(
                        {
                            "deploy": True,
                            "production": _deploy_branch_polarity(condition),
                        }
                    )
                else:
                    stack.append({"deploy": False, "production": None})
                depth += 1
            elif (
                _OPEN_CASE.match(stripped)
                or _OPEN_DO.search(stripped)
                or _OPEN_BRACE.search(stripped)
            ):
                depth += 1

        heredoc_match = _HEREDOC.search(stripped)
        if heredoc_match and "<<<" not in stripped:
            heredoc = heredoc_match.group("tag")


def deploy_contexts(script):
    """(line, context) for every executable line -- the physical-line view."""
    for line in scan(script):
        yield line.text, line.context


def shell_commands(script):
    """Logical commands, with ``\\``-continued lines joined.

    Release commands spread one invocation over a dozen lines, so the defines
    that belong to a single command have to be reassembled before they can be
    compared against the tuple required for that branch. A continuation cannot
    open or close a block, so the whole logical command carries the context,
    depth and line number of its first line.
    """
    pending = None
    for line in scan(script):
        continued = line.text.endswith("\\")
        body = line.text[:-1].rstrip() if continued else line.text
        if pending is None:
            pending = [body, line.depth, line.context, line.lineno]
        else:
            pending[0] = f"{pending[0]} {body}"
        if not continued:
            yield Command(*pending)
            pending = None
    if pending is not None:
        yield Command(*pending)


def deploy_invocations(script):
    for command in shell_commands(script):
        yield command.text, command.context


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


def _placement(context):
    if context is None:
        return "outside any DEPLOY_TARGET guard"
    if context == UNLABELLED:
        return (
            "inside a branch whose deploy target cannot be determined "
            "(compound or chained condition)"
        )
    return f"in the {context} branch"


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


# ---------------------------------------------------------------------------
# Workflow classification -- derived from the YAML, never hard-coded.
# ---------------------------------------------------------------------------


def _is_tag_triggered(workflow):
    triggering = workflow.get("triggering")
    if triggering is None:
        return False, None
    if not isinstance(triggering, dict):
        return True, "`triggering` is not a mapping"
    events = triggering.get("events")
    if events is None:
        return False, None
    if not isinstance(events, list):
        return True, "`triggering.events` is not a list"
    return "tag" in events, None


def _ships_a_binary(workflow):
    publishing = workflow.get("publishing")
    if publishing is None:
        return False
    if not isinstance(publishing, dict):
        return True
    return any(key not in NOTIFICATION_PUBLISHERS for key in publishing)


def _builds_a_binary(workflow):
    for _, script in script_blocks(workflow):
        for command in shell_commands(script):
            if RELEASE_INVOCATION.search(executable_part(command.text)):
                return True
    return False


def classify_workflows(workflows):
    """Split the workflows into (dual-target, production-only, failures).

    A release workflow is one that builds or publishes a binary. Tag-triggered
    release workflows pick their target at run time from DEPLOY_TARGET, so they
    are the ones Critical 1 is about; the rest (manual Shorebird patches) are
    production-only and must never carry a non-production define at all.
    """
    dual_target = []
    production_only = []
    failures = []

    for name, workflow in workflows.items():
        if not isinstance(workflow, dict):
            failures.append(f"{name}: workflow is not a mapping, so it cannot be checked")
            continue
        ships = _ships_a_binary(workflow)
        builds = _builds_a_binary(workflow)
        if not (ships or builds):
            continue
        tag_triggered, problem = _is_tag_triggered(workflow)
        if problem:
            failures.append(
                f"{name}: {problem}, so this guard cannot tell whether a "
                f"`picnic-v*` tag fires it; fix the `triggering` block"
            )
        if not workflow.get("scripts"):
            failures.append(
                f"{name}: publishes a build but has no `scripts` block; the key "
                f"was renamed or removed and nothing here can be verified"
            )
        (dual_target if tag_triggered else production_only).append(name)

    if not dual_target:
        failures.append(
            "no tag-triggered workflow that builds or publishes a binary was "
            "found in codemagic.yaml; either the release path moved or a key was "
            "renamed, and this guard refuses to pass vacuously"
        )
    return dual_target, production_only, failures


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------


def check_deploy_conditions_are_simple(workflows, dual_target, production_only):
    """Every `if` that tests DEPLOY_TARGET must be a pure two-way switch.

    `[ "$DEPLOY_TARGET" = "production" ] && [ "$ENABLE_SHOREBIRD" = "true" ]`
    reads like a production test but is not one: at run time
    `DEPLOY_TARGET=production ENABLE_SHOREBIRD=false` takes the `else` branch
    and builds the staging define tuple, which publishing then uploads.
    """
    failures = []
    for name in list(dual_target) + list(production_only):
        for step_name, script in script_blocks(workflows[name]):
            where = f"{name} / {step_name!r}"
            for line in scan(script):
                if not line.text.startswith(("if ", "elif ")):
                    continue
                if line.text.startswith("if ") and _INLINE_FI.search(line.text):
                    continue
                condition = _if_condition(line.text)
                if not DEPLOY_TARGET_REF.search(condition):
                    continue
                if line.text.startswith("elif "):
                    failures.append(
                        f"{where}: `elif` tests DEPLOY_TARGET, so which target "
                        f"reaches this branch depends on the earlier conditions "
                        f"and cannot be labelled; use a single "
                        f"`if [ \"$DEPLOY_TARGET\" = \"production\" ]` / `else`: "
                        f"{_abbreviate(line.text)!r}"
                    )
                    continue
                if _deploy_branch_polarity(condition) is None:
                    failures.append(
                        f"{where}: this `if` is not a plain two-way test on "
                        f"DEPLOY_TARGET, so its `then`/`else` branches cannot be "
                        f"read as production/staging -- with any extra operand "
                        f"(`&&`, `||`, `-a`, `-o`) or any defaulting of the "
                        f"variable, DEPLOY_TARGET=production can reach the `else` "
                        f"branch and build staging, which publishing then uploads. "
                        f"Write it as "
                        f"`if [ \"$DEPLOY_TARGET\" = \"production\" ]; then` and move "
                        f"any other condition inside the branch: "
                        f"{_abbreviate(line.text)!r}"
                    )
    return failures


def _find_key(node, wanted, path=""):
    """Yield (dotted path, value) for every occurrence of ``wanted`` as a key."""
    if isinstance(node, dict):
        for key, value in node.items():
            here = f"{path}.{key}" if path else str(key)
            if key == wanted:
                yield here, value
            yield from _find_key(value, wanted, here)
    elif isinstance(node, list):
        for index, value in enumerate(node):
            yield from _find_key(value, wanted, f"{path}[{index}]")


def check_deploy_target_fail_closed(workflows, dual_target):
    """An unset DEPLOY_TARGET must stop the build, not silently pick a target."""
    failures = []
    for name in dual_target:
        workflow = workflows[name]
        asserted = False

        for path, value in _find_key(workflow.get("environment"), "DEPLOY_TARGET"):
            failures.append(
                f"{name}: `environment.{path}` hard-codes DEPLOY_TARGET={value!r}; "
                f"the deploy target must come from the build trigger, or every "
                f"`picnic-v*` tag ships the same target no matter what was requested"
            )

        for step_name, script in script_blocks(workflow):
            where = f"{name} / {step_name!r}"
            for line, _ in deploy_contexts(script):
                if DEPLOY_SOFT_DEFAULT.search(line):
                    failures.append(
                        f"{where}: DEPLOY_TARGET read with a shell default, so an "
                        f"unset variable silently picks a deploy target; only "
                        f'`${{DEPLOY_TARGET:?...}}` is allowed: {line!r}'
                    )
                if DEPLOY_ASSIGNMENT.search(line):
                    failures.append(
                        f"{where}: the workflow assigns DEPLOY_TARGET itself, which "
                        f"defeats the `${{DEPLOY_TARGET:?}}` assert; it must be "
                        f"supplied by the build trigger: {line!r}"
                    )
                if DEPLOY_REQUIRE.search(line):
                    asserted = True
        if not asserted:
            failures.append(
                f"{name}: DEPLOY_TARGET is never asserted; expected a "
                f'`: "${{DEPLOY_TARGET:?...}}"` check so an unset variable fails the build'
            )
    return failures


def _parse_deploy_target_case(script):
    """Parse the `case "$DEPLOY_TARGET" in` allow-list of a script.

    Returns (labels, catch_all_body) or None when there is no such block, and
    raises :class:`GuardError` when there is one but it cannot be read.
    """
    lines = [line.text for line in scan(script)]
    head = next((i for i, text in enumerate(lines) if CASE_HEAD.match(text)), None)
    if head is None:
        return None

    labels = []
    bodies = {}
    current = None
    expecting_label = True
    for text in lines[head + 1 :]:
        if text.startswith("esac"):
            return labels, bodies
        if expecting_label:
            match = CASE_LABEL.match(text)
            if not match:
                raise GuardError(
                    f"cannot read the `case \"$DEPLOY_TARGET\"` allow-list: expected "
                    f"a pattern label, got {text!r}"
                )
            current = match.group("pattern").strip()
            labels.append(current)
            rest = text[match.end() :].strip()
            bodies[current] = [rest] if rest else []
            expecting_label = rest.endswith(";;")
        else:
            bodies[current].append(text)
            if text.endswith(";;"):
                expecting_label = True
    raise GuardError(
        "the `case \"$DEPLOY_TARGET\"` allow-list is never closed with `esac`"
    )


def _step_needs_validated_target(script):
    """True when this step already depends on DEPLOY_TARGET being trustworthy."""
    for command in shell_commands(script):
        executable = executable_part(command.text)
        if DEPLOY_TARGET_REF.search(command.text):
            return True
        if RELEASE_INVOCATION.search(executable):
            return True
        if ISOLATION_VERIFIER.search(executable):
            return True
        if command_defines(command.text):
            return True
    return False


def check_deploy_target_allowlist(workflows, dual_target):
    """DEPLOY_TARGET's *value* must be constrained to a known allow-list.

    `${DEPLOY_TARGET:?}` only proves the variable is non-empty. `Production`
    and `production ` (trailing space) sail through it and then fall into the
    staging branch of every `[ "$DEPLOY_TARGET" = "production" ]` test, so a
    production tag ships a staging app. Only an explicit allow-list that aborts
    on anything else closes that.
    """
    failures = []
    for name in dual_target:
        steps = list(script_blocks(workflows[name]))
        assert_at = next(
            (i for i, (_, script) in enumerate(steps) if DEPLOY_REQUIRE.search(script)),
            None,
        )
        if assert_at is None:
            # check_deploy_target_fail_closed already reports the missing assert.
            continue
        step_name, script = steps[assert_at]
        where = f"{name} / {step_name!r}"

        try:
            parsed = _parse_deploy_target_case(script)
        except GuardError as exc:
            failures.append(f"{where}: {exc}")
            parsed = None

        if parsed is None:
            failures.append(
                f"{where}: no `case \"$DEPLOY_TARGET\" in production|staging) ... "
                f"*) exit 1 ;; esac` allow-list. `${{DEPLOY_TARGET:?}}` only rejects "
                f"an *empty* value, so 'Production' or 'production ' would pass it "
                f"and then take the staging branch of every deploy-target test"
            )
        else:
            labels, bodies = parsed
            literals = set()
            for label in labels:
                if label == "*":
                    continue
                for alternative in label.split("|"):
                    literals.add(alternative.strip().strip("'\""))
            if literals != set(ALLOWED_DEPLOY_TARGETS):
                failures.append(
                    f"{where}: the DEPLOY_TARGET allow-list accepts "
                    f"{sorted(literals)}, expected {sorted(ALLOWED_DEPLOY_TARGETS)}"
                )
            wildcards = [
                label
                for label in literals
                if not re.fullmatch(r"[A-Za-z0-9_-]+", label)
            ]
            if wildcards:
                failures.append(
                    f"{where}: DEPLOY_TARGET allow-list pattern(s) {sorted(wildcards)} "
                    f"are globs, not literals, so unintended values match"
                )
            if "*" not in labels:
                failures.append(
                    f"{where}: the DEPLOY_TARGET allow-list has no `*)` catch-all, so "
                    f"an unknown value falls through and the build continues"
                )
            elif not any(NONZERO_EXIT.search(line) for line in bodies.get("*", [])):
                failures.append(
                    f"{where}: the `*)` branch of the DEPLOY_TARGET allow-list does "
                    f"not `exit` non-zero, so an unknown value only logs a warning"
                )

        earlier = [
            i
            for i, (_, other) in enumerate(steps)
            if i < assert_at and _step_needs_validated_target(other)
        ]
        if earlier:
            failures.append(
                f"{name}: the DEPLOY_TARGET assert runs as step {assert_at + 1}, after "
                f"step(s) {[steps[i][0] for i in earlier]} that already read "
                f"DEPLOY_TARGET or build; it must run first or those steps act on an "
                f"unvalidated target"
            )
    return failures


def check_production_path_exists(workflows, dual_target, production_only):
    """Each release workflow must really run a production build, not mention one."""
    failures = []
    for name in dual_target:
        found = any(
            PROD_DEFINE.search(executable_part(line)) and context == PRODUCTION
            for _, script in script_blocks(workflows[name])
            for line, context in deploy_contexts(script)
        )
        if not found:
            failures.append(
                f"{name}: no executable production build path found (expected a "
                f"--dart-define=ENVIRONMENT=prod invocation in the production branch)"
            )

    for name in production_only:
        found = any(
            PROD_DEFINE.search(executable_part(line))
            for _, script in script_blocks(workflows[name])
            for line, _ in deploy_contexts(script)
        )
        if not found:
            failures.append(
                f"{name}: no executable production build path found (expected a "
                f"--dart-define=ENVIRONMENT=prod invocation)"
            )
    return failures


def check_production_gate_runs_in_production(workflows, dual_target):
    """The protected-target evidence check must gate the production branch."""
    failures = []
    for name in dual_target:
        found = any(
            PRODUCTION_GATE.search(executable_part(line)) and context == PRODUCTION
            for _, script in script_blocks(workflows[name])
            for line, context in deploy_contexts(script)
        )
        if not found:
            failures.append(
                f"{name}: verify_release_target.dart --target=production never runs "
                f"in the production branch, so production releases ship ungated"
            )
    return failures


def check_branch_correct_defines(workflows, dual_target, production_only):
    """Non-prod defines only in the staging branch, prod defines only in prod."""
    failures = []
    for name in dual_target:
        for step_name, script in script_blocks(workflows[name]):
            for line, context in deploy_contexts(script):
                where = f"{name} / {step_name!r}"
                executable = executable_part(line)
                if NON_PROD_DEFINE.search(executable) and context != NON_PRODUCTION:
                    failures.append(
                        f"{where}: non-production build define "
                        f"{_placement(context)}: {line!r}"
                    )
                if PROD_DEFINE.search(executable) and context != PRODUCTION:
                    failures.append(
                        f"{where}: production build define "
                        f"{_placement(context)}: {line!r}"
                    )

    for name in production_only:
        for step_name, script in script_blocks(workflows[name]):
            for line, _ in deploy_contexts(script):
                if NON_PROD_DEFINE.search(executable_part(line)):
                    failures.append(
                        f"{name} / {step_name!r}: non-production build define in a "
                        f"production-only patch workflow: {line!r}"
                    )
    return failures


def check_release_invocation_defines(workflows, dual_target, production_only):
    """Every release command pins the complete define tuple for its branch."""
    failures = []
    for name in dual_target:
        for step_name, script in script_blocks(workflows[name]):
            where = f"{name} / {step_name!r}"
            for command, context in deploy_invocations(script):
                if not RELEASE_INVOCATION.search(executable_part(command)):
                    continue
                if context == PRODUCTION:
                    expected = PRODUCTION_BUILD_DEFINES
                elif context == NON_PRODUCTION:
                    expected = SANDBOX_BUILD_DEFINES
                else:
                    failures.append(
                        f"{where}: release invocation {_placement(context)}, so the "
                        f"defines it ships cannot be checked: {_abbreviate(command)!r}"
                    )
                    continue
                failures += _compare_defines(where, context, command, expected)

    for name in production_only:
        for step_name, script in script_blocks(workflows[name]):
            where = f"{name} / {step_name!r}"
            for command, _ in deploy_invocations(script):
                if RELEASE_INVOCATION.search(executable_part(command)):
                    failures += _compare_defines(
                        where, PRODUCTION, command, PRODUCTION_BUILD_DEFINES
                    )
    return failures


def check_isolation_verifier_inputs(workflows, dual_target):
    """The isolation tool must be fed the same tuple the staging build uses.

    Without this the check is tautological: the env prefix on the tool's own
    command line is a hand-written literal, so flipping the release command's
    defines to production leaves the tool printing GO.
    """
    failures = []
    for name in dual_target:
        invoked = False
        for step_name, script in script_blocks(workflows[name]):
            where = f"{name} / {step_name!r}"
            for command, context in deploy_invocations(script):
                if not ISOLATION_VERIFIER.search(executable_part(command)):
                    continue
                invoked = True
                if context != NON_PRODUCTION:
                    failures.append(
                        f"{where}: verify_environment_isolation.dart runs "
                        f"{_placement(context)}: {_abbreviate(command)!r}"
                    )
                    continue
                failures += _compare_defines(
                    where, NON_PRODUCTION, command, SANDBOX_BUILD_DEFINES
                )
        if not invoked:
            failures.append(
                f"{name}: verify_environment_isolation.dart never runs, so nothing "
                f"validates the generated config the staging build ships"
            )
    return failures


def _has_pipe(text):
    return re.search(r"(?<!\|)\|(?!\|)", text) is not None


def _runs_in_background(text):
    return re.search(r"(?<!&)&(?!&)", _REDIRECT.sub(" ", text)) is not None


def check_guard_failure_fails_the_step(workflows):
    """A guard's NO-GO must become the step's exit status.

    `set -e` being present somewhere in the text is not enough. It must run
    unconditionally at the top level of the step, must not be turned back off
    before the guard, and the guard's own status must be reachable: `|| echo`,
    a background `&`, a pipeline without `pipefail`, a command substitution or
    use as an `if` condition all discard it while leaving `set -e` in place.
    """
    failures = []
    for name, workflow in workflows.items():
        for step_name, script in script_blocks(workflow):
            commands = list(shell_commands(script))
            # Matched on the raw text on purpose: `echo "$(dart run guard.dart)"`
            # hides the guard from `executable_part`, and that is precisely one
            # of the ways its exit status gets thrown away.
            guards = [
                command for command in commands if RELEASE_GUARD.search(command.text)
            ]
            if not guards:
                continue
            where = f"{name} / {step_name!r}"

            errexit_at = next(
                (c.lineno for c in commands if c.depth == 0 and SET_ERREXIT.match(c.text)),
                None,
            )
            pipefail_at = next(
                (c.lineno for c in commands if c.depth == 0 and SET_PIPEFAIL.match(c.text)),
                None,
            )
            disabled_at = [c.lineno for c in commands if UNSET_ERREXIT.match(c.text)]

            for guard in guards:
                shown = _abbreviate(guard.text)
                if errexit_at is None or errexit_at > guard.lineno:
                    failures.append(
                        f"{where}: release guard runs without an unconditional "
                        f"`set -e` before it -- a `set -e` nested inside an `if`, "
                        f"loop or function does not count -- so a NO-GO exit status "
                        f"is discarded by the commands that follow: {shown!r}"
                    )
                else:
                    turned_off = [ln for ln in disabled_at if errexit_at < ln < guard.lineno]
                    if turned_off:
                        failures.append(
                            f"{where}: `set +e` on line {turned_off[0]} of the step "
                            f"turns errexit back off before the release guard runs, "
                            f"so its NO-GO is discarded: {shown!r}"
                        )

                executable = executable_part(guard.text)
                if "||" in executable:
                    failures.append(
                        f"{where}: the release guard's exit status is swallowed by "
                        f"`||`; drop the fallback so a NO-GO fails the step: {shown!r}"
                    )
                if _has_pipe(executable) and (
                    pipefail_at is None or pipefail_at > guard.lineno
                ):
                    failures.append(
                        f"{where}: the release guard runs in a pipeline, so only the "
                        f"last command's status survives and a NO-GO is discarded; "
                        f"run it on its own or add `set -o pipefail`: {shown!r}"
                    )
                if _runs_in_background(executable):
                    failures.append(
                        f"{where}: the release guard is backgrounded with `&`, so its "
                        f"exit status is never checked: {shown!r}"
                    )
                if _CONDITION_HEAD.match(executable):
                    failures.append(
                        f"{where}: the release guard is used as a shell condition, "
                        f"which exempts it from `set -e`; run it as a plain command: "
                        f"{shown!r}"
                    )
                if _SUBSTITUTION.search(guard.text):
                    failures.append(
                        f"{where}: the release guard runs inside a command "
                        f"substitution, so the surrounding command's status is what "
                        f"reaches the shell: {shown!r}"
                    )
    return failures


def check_isolation_guard_runs_in_ci(workflows, dual_target):
    """This guard must itself be wired into every tag workflow.

    A dead guard is worse than no guard: it looks like coverage. Deleting the
    step that runs it must therefore be a violation, exactly as deleting the
    verify_release_target.dart call is.
    """
    failures = []
    for name in dual_target:
        steps = list(script_blocks(workflows[name]))
        plain_at = self_test_at = first_release_at = None
        for index, (_, script) in enumerate(steps):
            for command in shell_commands(script):
                executable = executable_part(command.text)
                if SELF_INVOCATION.search(executable):
                    if "--self-test" in executable:
                        if self_test_at is None:
                            self_test_at = index
                    elif plain_at is None:
                        plain_at = index
                if RELEASE_INVOCATION.search(executable) and first_release_at is None:
                    first_release_at = index
        if plain_at is None:
            failures.append(
                f"{name}: never runs `python3 test_codemagic_environment_isolation.py`, "
                f"so no CI step enforces these invariants and codemagic.yaml can drift "
                f"back to shipping a staging app from a production tag"
            )
        if self_test_at is None:
            failures.append(
                f"{name}: never runs "
                f"`python3 test_codemagic_environment_isolation.py --self-test`, so "
                f"nothing proves in CI that the guard can still detect a broken config"
            )
        if (
            plain_at is not None
            and first_release_at is not None
            and plain_at > first_release_at
        ):
            failures.append(
                f"{name}: the environment isolation guard runs as step {plain_at + 1}, "
                f"after the build in step {first_release_at + 1}; it must run before "
                f"anything is built or uploaded"
            )
    return failures


def _flutter_test_paths(command):
    """Positional test paths passed to `flutter test`, flag values excluded."""
    match = re.search(r"\bflutter\s+test\b(?P<rest>.*)", command)
    if not match:
        return None
    tokens = match.group("rest").split()
    paths = []
    skip_next = False
    for token in tokens:
        if skip_next:
            skip_next = False
            continue
        if token.startswith("-"):
            if "=" not in token and token in FLUTTER_TEST_VALUE_FLAGS:
                skip_next = True
            continue
        paths.append(token)
    return paths


def _reaches_guard_tests(paths):
    """True when these `flutter test` paths still load picnic_app/test/config."""
    if not paths:
        return True  # bare `flutter test` runs the whole suite
    for path in paths:
        cleaned = path.strip("'\"").rstrip("/")
        if cleaned in ("test", "."):
            return True
        if cleaned == APP_GUARD_TEST_DIR or cleaned.startswith(
            APP_GUARD_TEST_DIR + "/"
        ):
            return True
    return False


def _app_test_commands(script):
    """Yield the `flutter test` positional paths run with picnic_app as cwd."""
    in_app = False
    for command in shell_commands(script):
        line = command.text
        if line.startswith("cd "):
            in_app = line[3:].strip().strip('"').strip("'") == "picnic_app"
            continue
        if not in_app:
            continue
        executable = executable_part(line)
        if not FLUTTER_TEST.search(executable):
            continue
        paths = _flutter_test_paths(executable)
        if paths is not None:
            yield line, paths


def _runs_app_tests(script):
    """True when this step runs `flutter test` over picnic_app/test/config."""
    return any(_reaches_guard_tests(paths) for _, paths in _app_test_commands(script))


def check_app_guard_tests_run(workflows, dual_target):
    """picnic_app/test/config must execute in every tag workflow.

    A narrowed path (`flutter test test/widget`) satisfies a naive "runs
    flutter test in picnic_app" check while never loading the release-target
    and isolation guards, so the positional arguments are inspected too.
    """
    failures = []
    for name in dual_target:
        narrowed = []
        ran = False
        for step_name, script in script_blocks(workflows[name]):
            for line, paths in _app_test_commands(script):
                if _reaches_guard_tests(paths):
                    ran = True
                else:
                    narrowed.append(f"{step_name!r}: {_abbreviate(line)!r}")
        if not ran:
            detail = (
                f"; narrowed invocation(s): {'; '.join(narrowed)}" if narrowed else ""
            )
            failures.append(
                f"{name}: picnic_app tests never run over "
                f"picnic_app/{APP_GUARD_TEST_DIR} (expected `flutter test` with "
                f"picnic_app as the working directory and either no path argument "
                f"or one that includes {APP_GUARD_TEST_DIR}){detail}, so the "
                f"release-target and environment-isolation guards there can rot"
            )
    return failures


def run_checks(text=None):
    """Return the list of isolation violations for a codemagic.yaml text."""
    try:
        workflows = load_workflows(text)
    except GuardError as exc:
        return [str(exc)]

    dual_target, production_only, failures = classify_workflows(workflows)
    failures = list(failures)
    failures += check_deploy_target_fail_closed(workflows, dual_target)
    failures += check_deploy_target_allowlist(workflows, dual_target)
    failures += check_deploy_conditions_are_simple(
        workflows, dual_target, production_only
    )
    failures += check_production_path_exists(workflows, dual_target, production_only)
    failures += check_production_gate_runs_in_production(workflows, dual_target)
    failures += check_branch_correct_defines(workflows, dual_target, production_only)
    failures += check_release_invocation_defines(
        workflows, dual_target, production_only
    )
    failures += check_isolation_verifier_inputs(workflows, dual_target)
    failures += check_guard_failure_fails_the_step(workflows)
    failures += check_isolation_guard_runs_in_ci(workflows, dual_target)
    failures += check_app_guard_tests_run(workflows, dual_target)
    return failures


# ---------------------------------------------------------------------------
# Mutation self-tests
#
# A guard that cannot detect a deliberately broken codemagic.yaml is worthless.
# Each mutation reproduces a way Critical 1 can come back; the guard must report
# at least one violation that the unmutated file does not already have.
# ---------------------------------------------------------------------------


def _dump(data):
    return yaml.safe_dump(data, allow_unicode=True, sort_keys=False, width=10_000)


def _deploy_assert_anchor():
    return re.compile(r'(?m)^(?P<indent>\s*): "\$\{DEPLOY_TARGET:\?')


def mutate_identity(text):
    return text


def mutate_yaml_roundtrip(text):
    """Structural mutations dump YAML; prove the dump alone changes nothing."""
    return _dump(yaml.safe_load(text))


def mutate_flip_production_guard(text):
    """Swap the production and staging branches by inverting every test."""
    flip = re.compile(r'(\$\{?DEPLOY_TARGET\}?"?\s*)(!=|=)(\s*")')

    def invert(match):
        return match.group(1) + ("=" if match.group(2) == "!=" else "!=") + match.group(3)

    out = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith(("if ", "elif ")) and "DEPLOY_TARGET" in stripped:
            line = flip.sub(invert, line)
        out.append(line)
    return "\n".join(out) + "\n"


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


def mutate_deploy_default_without_colon(text):
    """Same fallback, spelled `${DEPLOY_TARGET-staging}` (no colon).

    Assigning before the `:?` assert makes the assert unreachable, so the
    build silently picks staging exactly as it did before Critical 1 was fixed.
    """
    return _deploy_assert_anchor().sub(
        lambda m: f'{m.group("indent")}DEPLOY_TARGET="${{DEPLOY_TARGET-staging}}"\n'
        f'{m.group("indent")}: "${{DEPLOY_TARGET:?',
        text,
    )


def mutate_deploy_default_via_test(text):
    """The same fallback expressed as a test rather than an expansion."""
    return _deploy_assert_anchor().sub(
        lambda m: f'{m.group("indent")}[ -n "${{DEPLOY_TARGET-}}" ] || DEPLOY_TARGET=staging\n'
        f'{m.group("indent")}: "${{DEPLOY_TARGET:?',
        text,
    )


def mutate_drop_deploy_target_allowlist(text):
    """Delete the value allow-list, leaving only the non-empty assert.

    `Production` and `production ` then survive `${DEPLOY_TARGET:?}` and fall
    into the staging branch of every deploy-target test.
    """
    out = []
    skipping = False
    for line in text.splitlines():
        stripped = line.strip()
        if not skipping and CASE_HEAD.match(stripped):
            skipping = True
            continue
        if skipping:
            if stripped == "esac":
                skipping = False
            continue
        out.append(line)
    return "\n".join(out) + "\n"


def mutate_relocate_deploy_target_assert(text):
    """Move the assert step to the end, after the build and the upload."""
    data = yaml.safe_load(text)
    for workflow in data["workflows"].values():
        steps = workflow.get("scripts") or []
        index = next(
            (
                i
                for i, step in enumerate(steps)
                if isinstance(step, dict) and DEPLOY_REQUIRE.search(step.get("script", ""))
            ),
            None,
        )
        if index is not None:
            steps.append(steps.pop(index))
    return _dump(data)


def mutate_compound_production_condition(text):
    """Add a second operand to the production test.

    At run time `DEPLOY_TARGET=production ENABLE_SHOREBIRD=false` then takes the
    `else` branch and builds ENVIRONMENT=dev with sandbox SDK modes, which
    publishing.app_store_connect uploads to TestFlight.
    """
    return text.replace(
        'if [ "$DEPLOY_TARGET" = "production" ]; then',
        'if [ "$DEPLOY_TARGET" = "production" ] && [ "$ENABLE_SHOREBIRD" = "true" ]; then',
    )


def mutate_compound_staging_condition(text):
    """The mirror image: an `||` operand on the staging test."""
    return text.replace(
        'if [ "$DEPLOY_TARGET" != "production" ]; then',
        'if [ "$DEPLOY_TARGET" != "production" ] || [ -n "$FORCE_STAGING_CONFIG" ]; then',
    )


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


def mutate_disable_errexit_after_set_e(text):
    """Keep `set -e` in the text but turn it back off before the guard."""
    return re.sub(
        r'(?m)^(\s*)set -e\n\1(python3 -c "import yaml")',
        r"\1set -e\n\1set +e\n\1\2",
        text,
        count=1,
    )


def mutate_conditional_errexit(text):
    """Keep `set -e` in the text but only inside a branch that never runs."""
    return re.sub(
        r'(?m)^(\s*)set -e\n(\1python3 -c "import yaml")',
        r'\1if [ -n "$UNSET_FLAG" ]; then\n\1  set -e\n\1fi\n\2',
        text,
        count=1,
    )


def mutate_swallow_guard_exit_status(text):
    """Append an `|| echo` fallback so a NO-GO never fails the step."""
    return text.replace(
        "dart run tool/verify_release_target.dart --target=production",
        "dart run tool/verify_release_target.dart --target=production "
        '|| echo "release target check skipped"',
    )


def mutate_guard_status_lost_in_pipeline(text):
    """Tee the guard's output, discarding its status (no `pipefail` here)."""
    return text.replace(
        "dart run tool/verify_environment_isolation.dart --environment=dev",
        "dart run tool/verify_environment_isolation.dart --environment=dev "
        "2>&1 | tee /tmp/isolation.log",
    )


def mutate_guard_inside_command_substitution(text):
    """Capture the guard's output, so only `echo`'s status reaches the shell."""
    return text.replace(
        "dart run tool/verify_release_target.dart --target=production",
        'echo "$(dart run tool/verify_release_target.dart --target=production)"',
    )


def mutate_production_gate_demoted_to_echo(text):
    """Leave the production gate present as prose rather than as a command."""
    return text.replace(
        "          dart run tool/verify_release_target.dart --target=production",
        '          echo "dart run tool/verify_release_target.dart --target=production"',
    )


def mutate_hardcode_deploy_target_in_env(text):
    """Pin DEPLOY_TARGET in the workflow environment.

    Every `picnic-v*` tag then ships staging regardless of what the build was
    started with, and every `${DEPLOY_TARGET:?}` assert still passes.
    """
    return re.sub(
        r'(?m)^(\s*)ENABLE_SHOREBIRD: "true"$',
        r'\1ENABLE_SHOREBIRD: "true"\n\1DEPLOY_TARGET: "staging"',
        text,
    )


def mutate_drop_isolation_guard_step(text):
    """Delete the step that runs this guard from every tag workflow."""
    data = yaml.safe_load(text)
    for workflow in data["workflows"].values():
        steps = workflow.get("scripts")
        if not steps:
            continue
        workflow["scripts"] = [
            step
            for step in steps
            if not (
                isinstance(step, dict)
                and SELF_INVOCATION.search(step.get("script", "") or "")
            )
        ]
    return _dump(data)


def mutate_clone_tag_workflow_as_staging(text):
    """Clone a tag workflow under a new name and point it at dev.

    The clone keeps the same `picnic-v*` tag pattern and the same store
    publishing block, so one production tag fires both and the store receives
    the staging build. Hard-coded workflow lists never see it.
    """
    data = yaml.safe_load(text)
    workflows = data["workflows"]
    dual_target, _, _ = classify_workflows(workflows)
    if not dual_target:
        raise AssertionError("no dual-target workflow to clone")
    source = dual_target[0]
    clone = copy.deepcopy(workflows[source])
    for step in clone.get("scripts") or []:
        if isinstance(step, dict) and isinstance(step.get("script"), str):
            step["script"] = step["script"].replace(
                "--dart-define=ENVIRONMENT=prod", "--dart-define=ENVIRONMENT=dev"
            )
    clone["name"] = f"{source}-hotfix"
    workflows[f"{source}-hotfix"] = clone
    return _dump(data)


def mutate_narrow_app_test_path(text):
    """Narrow `flutter test` to a directory that never loads test/config."""
    return re.sub(r"(?m)^(\s*)flutter test$", r"\1flutter test test/widget", text)


def mutate_drop_app_guard_tests(text):
    """Unwire picnic_app/test/config from the tag workflows again."""
    return "\n".join(
        line for line in text.splitlines() if line.strip() != "flutter test"
    ) + "\n"


SELF_TESTS = (
    ("unmutated config is accepted", mutate_identity, False),
    ("yaml round-trip alone introduces nothing", mutate_yaml_roundtrip, False),
    ("production guard polarity inverted", mutate_flip_production_guard, True),
    ("production path only in a comment", mutate_comment_out_production_path, True),
    ("dev define outside any deploy guard", mutate_unguarded_dev_define, True),
    ("DEPLOY_TARGET default reintroduced", mutate_reintroduce_deploy_default, True),
    (
        "DEPLOY_TARGET default reintroduced without a colon",
        mutate_deploy_default_without_colon,
        True,
    ),
    (
        "DEPLOY_TARGET default reintroduced as a test-and-assign",
        mutate_deploy_default_via_test,
        True,
    ),
    (
        "DEPLOY_TARGET value allow-list deleted",
        mutate_drop_deploy_target_allowlist,
        True,
    ),
    (
        "DEPLOY_TARGET assert relocated after the build",
        mutate_relocate_deploy_target_assert,
        True,
    ),
    (
        "production branch condition given a second operand",
        mutate_compound_production_condition,
        True,
    ),
    (
        "staging branch condition given an alternative operand",
        mutate_compound_staging_condition,
        True,
    ),
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
    ("errexit turned back off before the guard", mutate_disable_errexit_after_set_e, True),
    ("errexit only set inside a branch that never runs", mutate_conditional_errexit, True),
    ("guard exit status swallowed by `|| echo`", mutate_swallow_guard_exit_status, True),
    ("guard exit status lost in a `| tee` pipeline", mutate_guard_status_lost_in_pipeline, True),
    (
        "guard exit status hidden in a command substitution",
        mutate_guard_inside_command_substitution,
        True,
    ),
    (
        "production gate demoted from a command to an echo",
        mutate_production_gate_demoted_to_echo,
        True,
    ),
    (
        "DEPLOY_TARGET hard-coded in environment.vars",
        mutate_hardcode_deploy_target_in_env,
        True,
    ),
    ("the step that runs this guard deleted", mutate_drop_isolation_guard_step, True),
    (
        "a second tag workflow cloned to build staging",
        mutate_clone_tag_workflow_as_staging,
        True,
    ),
    ("picnic_app guard tests narrowed to another path", mutate_narrow_app_test_path, True),
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
