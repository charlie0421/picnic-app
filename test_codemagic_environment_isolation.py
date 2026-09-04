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
The deploy target is decided by the *tag*, not by a CI variable a human has to
remember to set: ``picnic-v*`` is production, ``picnic-staging-v*`` is staging.
Both patterns fire the same workflow, which derives ``DEPLOY_TARGET`` from
``CM_TAG`` -- Codemagic's built-in "the tag being built if started from a tag
webhook, unset otherwise" [1] -- and hands it to the later steps through
``$CM_ENV``.

1. Exactly one step may assign ``DEPLOY_TARGET``, and only from the tag: a
   ``case "$CM_TAG" in`` whose branches assign a literal target and whose ``*)``
   catch-all exits non-zero. ``CM_TAG`` itself must be required (``${CM_TAG:?}``),
   never defaulted and never assigned. The derived value leaves the step only
   through ``echo "DEPLOY_TARGET=$DEPLOY_TARGET" >> "$CM_ENV"``.
2. The tag patterns must line up with the targets: each trigger pattern maps to
   exactly one target and each target to exactly one pattern, no two patterns
   overlap, and a pattern that names a target must map to that target -- a
   staging tag may not build production, nor the reverse.
3. ``DEPLOY_TARGET`` is fail-closed everywhere. It may not be given a default
   with any form of shell defaulting (``:-`` ``-`` ``:=`` ``=`` ``:+`` ``+``),
   may not be set by ``environment.vars``, and *every* step that reads it must
   open with its own unconditional ``: "${DEPLOY_TARGET:?...}"``. That last rule
   is what keeps a broken ``$CM_ENV`` hand-off from being fatal: with an empty
   ``DEPLOY_TARGET`` every ``[ "$DEPLOY_TARGET" = "production" ]`` test quietly
   takes the staging branch and publishes, which is Critical 1 all over again.
4. The derivation step must run before any step that reads DEPLOY_TARGET,
   builds, or carries a governed build define.
5. Every ``if``/``elif`` that mentions DEPLOY_TARGET must be a *pure* two-way
   test on it. ``[ "$DEPLOY_TARGET" = "production" ] && [ "$X" = "y" ]`` is not
   a deploy-target switch: at run time ``DEPLOY_TARGET=production X=n`` takes
   the ``else`` branch and builds staging. Such a condition is refused rather
   than trusted to label its branches.

[1] https://docs.codemagic.io/yaml-basic-configuration/environment-variables/

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
import itertools
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
# Any spelling of the workflow setting DEPLOY_TARGET, including the `$CM_ENV`
# hand-off (`echo "DEPLOY_TARGET=..." >> "$CM_ENV"`), which sets it for every
# later step. Only the sanctioned derivation shape is allowed to match.
DEPLOY_ASSIGNMENT = re.compile(
    r"(?<![\w./-])(?:export\s+|declare\s+|typeset\s+|readonly\s+)?DEPLOY_TARGET="
)
DEPLOY_REQUIRE = re.compile(r"\$\{DEPLOY_TARGET:\?")
# The assert as a standalone, unconditional command. `echo "${DEPLOY_TARGET:?}"`
# also contains the operator but is not a guard, so the whole line is matched.
DEPLOY_ASSERT_LINE = re.compile(r'^:\s+"\$\{DEPLOY_TARGET:\?')
# Reading the variable. `DEPLOY_TARGET=staging` is an assignment, not a read.
DEPLOY_READ = re.compile(r"\$\{?DEPLOY_TARGET\b")
PRODUCTION_GATE = re.compile(r"verify_release_target\.dart\s+--target=production")

# Codemagic's built-in tag variable: "The tag being built if started from a tag
# webhook, unset otherwise".
# https://docs.codemagic.io/yaml-basic-configuration/environment-variables/
TAG_VARIABLE = "CM_TAG"
TAG_CASE_HEAD = re.compile(r"^case\s+\"?\$\{?CM_TAG\}?\"?\s+in\b")
TAG_ASSERT_LINE = re.compile(r'^:\s+"\$\{CM_TAG:\?')
TAG_SOFT_DEFAULT = re.compile(r"\$\{CM_TAG\s*:?[-=+]")
TAG_ASSIGNMENT = re.compile(
    r"(?<![\w./-])(?:export\s+|declare\s+|typeset\s+|readonly\s+)?CM_TAG="
)
SAFE_TAG_RESOLVER_ASSIGNMENT = re.compile(
    r'^CM_TAG="\$\(bash scripts/resolve_release_tag\.sh\)"$'
)

# The one sanctioned way the derived target crosses a step boundary. This file
# already uses the idiom for SIGNING_PROFILE_NAME; anything else -- a literal
# value, a different variable -- is an unsanctioned assignment.
CM_ENV_EXPORT = re.compile(
    r'^echo\s+"DEPLOY_TARGET=\$\{?DEPLOY_TARGET\}?"\s*>>\s*"\$\{?CM_ENV\}?"\s*$'
)
# `DEPLOY_TARGET=staging` and nothing else: no expansion, no substitution.
DEPLOY_LITERAL_ASSIGNMENT = re.compile(
    r"^DEPLOY_TARGET=(?P<quote>['\"]?)(?P<value>[A-Za-z0-9_-]+)(?P=quote)$"
)

CASE_LABEL = re.compile(r"^(?P<pattern>[^()]*?)\)")
CATCH_ALL = "*"
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

    A tag-triggered workflow whose every trigger pattern starts with
    ``picnic-staging-`` can only ever be fired by a staging tag; it is
    classified staging-only and must never carry a production define, nor is it
    required to have a production build path.
    """
    dual_target = []
    staging_only = []
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
        if not tag_triggered:
            production_only.append(name)
        else:
            patterns, _ = _trigger_tag_patterns(name, workflow)
            if patterns and all(
                pattern.startswith("picnic-staging-") for pattern in patterns
            ):
                staging_only.append(name)
            else:
                dual_target.append(name)

    if not dual_target:
        failures.append(
            "no tag-triggered workflow that builds or publishes a binary was "
            "found in codemagic.yaml; either the release path moved or a key was "
            "renamed, and this guard refuses to pass vacuously"
        )
    return dual_target, staging_only, production_only, failures


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
                f"the deploy target must be derived from the tag that started the "
                f"build, or every tag ships the same target no matter which one "
                f"was pushed"
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
                if DEPLOY_REQUIRE.search(line):
                    asserted = True
        if not asserted:
            failures.append(
                f"{name}: DEPLOY_TARGET is never asserted; expected a "
                f'`: "${{DEPLOY_TARGET:?...}}"` check so an unset variable fails the build'
            )
    return failures


def _strip_terminator(text):
    return re.sub(r"\s*;;\s*$", "", text).strip()


def _parse_case(script, head_pattern):
    """Parse the `case ... in` block whose head matches ``head_pattern``.

    Returns ``(labels, bodies, head_line, esac_line)`` -- ``bodies`` maps each
    label to the :class:`ScriptLine` list of its branch, with the ``;;``
    terminators removed -- or ``None`` when the script has no such block.
    Raises :class:`GuardError` when a block is present but cannot be read: an
    allow-list this guard cannot parse must never pass silently.
    """
    lines = list(scan(script))
    head = next(
        (i for i, line in enumerate(lines) if head_pattern.match(line.text)), None
    )
    if head is None:
        return None

    labels = []
    bodies = {}
    current = None
    expecting_label = True
    for line in lines[head + 1 :]:
        text = line.text
        if text.startswith("esac"):
            return labels, bodies, lines[head], line
        if expecting_label:
            match = CASE_LABEL.match(text)
            if not match:
                raise GuardError(
                    f"cannot read the `case \"${TAG_VARIABLE}\"` mapping: expected a "
                    f"pattern label, got {text!r}"
                )
            current = match.group("pattern").strip()
            if current in bodies:
                raise GuardError(
                    f"the `case \"${TAG_VARIABLE}\"` mapping repeats the label "
                    f"{current!r}, so only the first branch can ever run"
                )
            labels.append(current)
            rest = _strip_terminator(text[match.end() :])
            bodies[current] = [line._replace(text=rest)] if rest else []
            expecting_label = text.rstrip().endswith(";;")
        else:
            body = _strip_terminator(text)
            if body:
                bodies[current].append(line._replace(text=body))
            expecting_label = text.rstrip().endswith(";;")
    raise GuardError(
        f"the `case \"${TAG_VARIABLE}\"` mapping is never closed with `esac`"
    )


def _has_tag_case(script):
    return any(TAG_CASE_HEAD.match(line.text) for line in scan(script))


def _prefix_glob(pattern):
    """The literal prefix of a ``<literal>*`` tag pattern, or None.

    Restricting the grammar to a literal prefix plus one trailing ``*`` is what
    makes overlap decidable: two such patterns can match the same tag if and
    only if one prefix is a prefix of the other. Anything richer is refused
    rather than guessed at.
    """
    if pattern.count("*") != 1 or not pattern.endswith("*"):
        return None
    prefix = pattern[:-1]
    if not prefix or re.search(r"[?\[\]]", prefix):
        return None
    return prefix


def _declared_target(prefix):
    """The deploy target a tag pattern names, by this repo's tag convention.

    ``picnic-staging-v*`` names staging. The unqualified release tag
    ``picnic-v*`` names no target and is therefore production. Returns None when
    the pattern names more than one target and is thus ambiguous.
    """
    tokens = {token for token in re.split(r"[^A-Za-z0-9]+", prefix.lower()) if token}
    named = tokens & {target.lower() for target in ALLOWED_DEPLOY_TARGETS}
    if len(named) > 1:
        return None
    if named:
        return named.pop()
    return PRODUCTION


def _trigger_tag_patterns(name, workflow):
    """(included tag patterns, failures) for a workflow's `triggering` block."""
    triggering = workflow.get("triggering")
    if not isinstance(triggering, dict):
        return [], [
            f"{name}: `triggering` is not a mapping, so the tags that fire this "
            f"workflow -- and therefore the targets it can ship -- cannot be read"
        ]
    entries = triggering.get("tag_patterns")
    if not isinstance(entries, list) or not entries:
        return [], [
            f"{name}: has no `triggering.tag_patterns` list, so nothing pins which "
            f"tags fire this workflow and the tag can no longer decide the target"
        ]

    patterns = []
    failures = []
    for index, entry in enumerate(entries):
        if isinstance(entry, str):
            patterns.append(entry)
        elif isinstance(entry, dict) and "pattern" in entry:
            if entry.get("include") is True:
                patterns.append(str(entry["pattern"]))
            else:
                failures.append(
                    f"{name}: `triggering.tag_patterns[{index}]` is not a plain "
                    f"include ({entry!r}); this guard only reasons about an "
                    f"include-list where each pattern maps to exactly one target"
                )
        else:
            failures.append(
                f"{name}: `triggering.tag_patterns[{index}]` has no `pattern` key: "
                f"{entry!r}"
            )
    return patterns, failures


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


def check_deploy_target_derived_from_tag(
    workflows, dual_target, expected_targets=None
):
    """DEPLOY_TARGET must come from the tag, in exactly one sanctioned step.

    The tag decides the target so nobody has to remember a CI variable, but that
    only holds if the derivation is the *single* place the value is produced and
    it really reads the tag. A second assignment anywhere, a value invented from
    something other than `$CM_TAG`, a mapping that sends a staging tag to
    production, overlapping patterns, a missing catch-all or a missing
    `$CM_ENV` hand-off all put a staging build back on the production path.
    """
    expected = sorted(
        ALLOWED_DEPLOY_TARGETS if expected_targets is None else set(expected_targets)
    )
    failures = []
    for name in dual_target:
        workflow = workflows[name]
        steps = list(script_blocks(workflow))

        # --- the tag variable itself must be required, never defaulted ------
        for step_name, script in script_blocks(workflow):
            where = f"{name} / {step_name!r}"
            for line in scan(script):
                if TAG_SOFT_DEFAULT.search(line.text):
                    failures.append(
                        f"{where}: {TAG_VARIABLE} read with a shell default, so a "
                        f"build that started from no tag invents one and derives a "
                        f"deploy target from it; only "
                        f'`${{{TAG_VARIABLE}:?...}}` is allowed: {line.text!r}'
                    )
                if TAG_ASSIGNMENT.search(line.text) and not SAFE_TAG_RESOLVER_ASSIGNMENT.match(
                    line.text
                ):
                    failures.append(
                        f"{where}: the workflow assigns {TAG_VARIABLE} itself, so the "
                        f"deploy target stops following the tag that started the "
                        f"build: {line.text!r}"
                    )

        # --- exactly one step may assign DEPLOY_TARGET ----------------------
        assigning = [
            (index, step_name, script)
            for index, (step_name, script) in enumerate(steps)
            if any(DEPLOY_ASSIGNMENT.search(line.text) for line in scan(script))
        ]
        if not assigning:
            failures.append(
                f"{name}: nothing derives DEPLOY_TARGET from the tag; expected a "
                f'step with `case "${TAG_VARIABLE}" in` that assigns it and exports '
                f'it with `echo "DEPLOY_TARGET=$DEPLOY_TARGET" >> "$CM_ENV"`'
            )
            continue

        with_case = [entry for entry in assigning if _has_tag_case(entry[2])]
        if len(with_case) > 1:
            failures.append(
                f"{name}: DEPLOY_TARGET is derived from the tag in more than one "
                f"step ({[entry[1] for entry in with_case]}); the later one silently "
                f"overrides the earlier"
            )
        derive_index, derive_name, derive_script = (with_case or assigning)[0]
        where = f"{name} / {derive_name!r}"

        for index, (step_name, script) in enumerate(steps):
            if index == derive_index:
                continue
            for line in scan(script):
                if DEPLOY_ASSIGNMENT.search(line.text):
                    failures.append(
                        f"{name} / {step_name!r}: assigns DEPLOY_TARGET outside the "
                        f"tag-derivation step {derive_name!r}, so a later step can "
                        f"override the target the tag chose: {line.text!r}"
                    )

        if not with_case:
            failures.append(
                f"{where}: assigns DEPLOY_TARGET but not from the release tag; "
                f'expected `case "${TAG_VARIABLE}" in` so the tag, and nothing else, '
                f"decides what is published"
            )
            continue

        try:
            parsed = _parse_case(derive_script, TAG_CASE_HEAD)
        except GuardError as exc:
            failures.append(f"{where}: {exc}")
            continue
        labels, bodies, case_head, esac = parsed
        lines = list(scan(derive_script))

        resolver_assignments = [
            line
            for line in lines
            if SAFE_TAG_RESOLVER_ASSIGNMENT.match(line.text) and line.depth == 0
        ]
        if expected_targets is None and (
            len(resolver_assignments) != 1
            or resolver_assignments[0].lineno > case_head.lineno
        ):
            failures.append(
                f"{where}: must resolve the webhook or rebuild tag exactly once "
                "before mapping it with `bash scripts/resolve_release_tag.sh`"
            )

        tag_asserts = [
            line
            for line in lines
            if TAG_ASSERT_LINE.match(line.text) and line.depth == 0
        ]
        if not tag_asserts or min(l.lineno for l in tag_asserts) > case_head.lineno:
            failures.append(
                f'{where}: {TAG_VARIABLE} is not asserted with an unconditional '
                f'`: "${{{TAG_VARIABLE}:?...}}"` before the tag is mapped, so a build '
                f"that did not start from a tag reaches the mapping with an empty "
                f"value instead of stopping with a clear message"
            )

        # --- the mapping itself ---------------------------------------------
        mapping = {}
        for label in labels:
            body = bodies[label]
            if label == CATCH_ALL:
                if any(DEPLOY_ASSIGNMENT.search(l.text) for l in body):
                    failures.append(
                        f"{where}: the `*)` catch-all of the tag mapping assigns "
                        f"DEPLOY_TARGET instead of refusing to guess: "
                        f"{[l.text for l in body]}"
                    )
                if not any(NONZERO_EXIT.search(l.text) for l in body):
                    failures.append(
                        f"{where}: the `*)` catch-all of the tag mapping does not "
                        f"`exit` non-zero, so a tag that matches no pattern falls "
                        f"through with DEPLOY_TARGET unset and the build continues"
                    )
                continue
            assigns = [l for l in body if DEPLOY_ASSIGNMENT.search(l.text)]
            if len(assigns) != 1:
                failures.append(
                    f"{where}: tag pattern {label!r} makes {len(assigns)} "
                    f"DEPLOY_TARGET assignments, expected exactly one"
                )
                continue
            match = DEPLOY_LITERAL_ASSIGNMENT.match(assigns[0].text)
            if not match or match.group("value") not in ALLOWED_DEPLOY_TARGETS:
                failures.append(
                    f"{where}: tag pattern {label!r} does not assign DEPLOY_TARGET a "
                    f"literal {sorted(ALLOWED_DEPLOY_TARGETS)} value, so what it "
                    f"ships depends on something other than the tag: "
                    f"{assigns[0].text!r}"
                )
                continue
            mapping[label] = match.group("value")

        if CATCH_ALL not in labels:
            failures.append(
                f"{where}: the tag mapping has no `*)` catch-all, so a tag that "
                f"matches no pattern leaves DEPLOY_TARGET unset and the build "
                f"continues instead of failing closed"
            )

        prefixes = {}
        for label in mapping:
            prefix = _prefix_glob(label)
            if prefix is None:
                failures.append(
                    f"{where}: tag pattern {label!r} is not a literal prefix followed "
                    f"by a single trailing `*`, so this guard cannot prove it does "
                    f"not also match the other target's tags"
                )
            else:
                prefixes[label] = prefix

        for first, second in itertools.combinations(sorted(prefixes), 2):
            if prefixes[first].startswith(prefixes[second]) or prefixes[
                second
            ].startswith(prefixes[first]):
                failures.append(
                    f"{where}: tag patterns {first!r} and {second!r} overlap, so one "
                    f"tag matches both and which target it ships depends on the "
                    f"order of the `case` branches"
                )

        for label, target in sorted(mapping.items()):
            if label not in prefixes:
                continue
            declared = _declared_target(prefixes[label])
            if declared is None:
                failures.append(
                    f"{where}: tag pattern {label!r} names more than one deploy "
                    f"target, so what it is meant to ship is ambiguous"
                )
            elif declared != target:
                failures.append(
                    f"{where}: tag pattern {label!r} maps to {target!r} but names "
                    f"{declared!r}; a staging tag must not build production, nor a "
                    f"production tag staging"
                )

        if sorted(mapping.values()) != expected:
            failures.append(
                f"{where}: the tag mapping covers {sorted(mapping.values())}, "
                f"expected exactly {expected} -- one tag "
                f"pattern per deploy target, none unreachable and none reachable "
                f"from two patterns"
            )

        trigger_patterns, trigger_failures = _trigger_tag_patterns(name, workflow)
        failures += trigger_failures
        if not trigger_failures and sorted(trigger_patterns) != sorted(mapping):
            failures.append(
                f"{name}: the workflow triggers on tag patterns "
                f"{sorted(trigger_patterns)} but the derivation maps "
                f"{sorted(mapping)}; a trigger with no mapping aborts every build it "
                f"fires, and a mapping with no trigger is dead code hiding a target"
            )

        # --- the derived value must actually reach the later steps ----------
        exports = [line for line in lines if CM_ENV_EXPORT.match(line.text)]
        if not exports:
            failures.append(
                f"{where}: the derived DEPLOY_TARGET is never exported with "
                f'`echo "DEPLOY_TARGET=$DEPLOY_TARGET" >> "$CM_ENV"`, so it dies with '
                f"this step and every later step reads it empty"
            )
        else:
            if len(exports) > 1:
                failures.append(
                    f"{where}: DEPLOY_TARGET is written to `$CM_ENV` "
                    f"{len(exports)} times; the last write silently wins"
                )
            export = exports[0]
            if export.depth != 0:
                failures.append(
                    f"{where}: the `$CM_ENV` export of DEPLOY_TARGET is nested inside "
                    f"a block, so it may not run at all: {export.text!r}"
                )
            if export.lineno < esac.lineno:
                failures.append(
                    f"{where}: DEPLOY_TARGET is exported to `$CM_ENV` before the tag "
                    f"mapping finishes, so the exported value is not the derived one"
                )

        sanctioned = {
            line.lineno
            for body in bodies.values()
            for line in body
            if DEPLOY_ASSIGNMENT.search(line.text)
        } | {line.lineno for line in exports}
        for line in lines:
            if DEPLOY_ASSIGNMENT.search(line.text) and line.lineno not in sanctioned:
                failures.append(
                    f'{where}: DEPLOY_TARGET is assigned outside the `case '
                    f'"${TAG_VARIABLE}"` mapping and outside the single `$CM_ENV` '
                    f"export, so its value no longer follows the tag: {line.text!r}"
                )

        earlier = [
            step_name
            for index, (step_name, script) in enumerate(steps)
            if index < derive_index and _step_needs_validated_target(script)
        ]
        if earlier:
            failures.append(
                f"{name}: the tag-derivation step runs as step {derive_index + 1}, "
                f"after step(s) {earlier} that already read DEPLOY_TARGET, build, or "
                f"carry a governed build define; it must run first or those steps act "
                f"on a target the tag has not yet chosen"
            )
    return failures


def check_deploy_target_consumers_assert(workflows, dual_target):
    """Every step that reads DEPLOY_TARGET must assert it first, itself.

    The derivation hands the value on through `$CM_ENV`. If that propagation
    ever breaks -- a renamed variable, a step that runs in a different shell, a
    Codemagic change -- `$DEPLOY_TARGET` is simply empty in the later steps, and
    every `[ "$DEPLOY_TARGET" = "production" ]` test then takes the *staging*
    branch and publishes it. A per-step `: "${DEPLOY_TARGET:?...}"` turns that
    silent mis-target back into a failed build, which is what Critical 1 was
    about. It has to be unconditional and it has to come before the first read:
    an assert nested in an `if`, or placed after the test it is meant to
    protect, protects nothing.
    """
    failures = []
    for name in dual_target:
        for step_name, script in script_blocks(workflows[name]):
            where = f"{name} / {step_name!r}"
            lines = list(scan(script))
            reads = [
                line
                for line in lines
                if DEPLOY_READ.search(line.text)
                and not DEPLOY_ASSERT_LINE.match(line.text)
            ]
            if not reads:
                continue
            asserts = [
                line
                for line in lines
                if DEPLOY_ASSERT_LINE.match(line.text) and line.depth == 0
            ]
            if not asserts:
                failures.append(
                    f"{where}: reads DEPLOY_TARGET without its own "
                    f'`: "${{DEPLOY_TARGET:?...}}"` assert, so if the `$CM_ENV` '
                    f"hand-off breaks this step runs with an empty target and takes "
                    f"the staging branch: {reads[0].text!r}"
                )
            elif min(line.lineno for line in asserts) > reads[0].lineno:
                failures.append(
                    f"{where}: the `${{DEPLOY_TARGET:?...}}` assert runs on line "
                    f"{min(line.lineno for line in asserts)}, after DEPLOY_TARGET is "
                    f"first read on line {reads[0].lineno}, so the read it is meant "
                    f"to protect happens first: {reads[0].text!r}"
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


def check_staging_only_stays_staging(workflows, staging_only):
    """A staging-only workflow must never carry a production define at all.

    Its trigger patterns prove no production tag can fire it, so a production
    define anywhere in it is either dead code or -- worse -- a patch built with
    production config shipped to the staging release channel.
    """
    failures = []
    for name in staging_only:
        shipped = False
        for step_name, script in script_blocks(workflows[name]):
            where = f"{name} / {step_name!r}"
            for line, context in deploy_contexts(script):
                executable = executable_part(line)
                if PROD_DEFINE.search(executable):
                    failures.append(
                        f"{where}: production build define in a staging-only "
                        f"workflow: {line!r}"
                    )
                if (
                    RELEASE_INVOCATION.search(executable)
                    and context == NON_PRODUCTION
                ):
                    shipped = True
        if not shipped:
            failures.append(
                f"{name}: no executable staging invocation found inside the "
                f"non-production branch, so this staging-only workflow ships "
                f"nothing this guard can check"
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


def check_release_test_skip_policy(workflows, dual_target):
    """Coverage may be skipped only by an explicit release-tag suffix.

    The resolved tag must cross the Codemagic step boundary, and both binary
    workflows must delegate the decision to the tested policy script before
    starting the expensive test suite.
    """
    failures = []
    tag_export = re.compile(
        r'^echo\s+"RELEASE_TAG=\$\{?CM_TAG\}?"\s*>>\s*'
        r'"\$\{?CM_ENV\}?"\s*$'
    )
    tag_export_example = 'echo "RELEASE_TAG=$CM_TAG" >> "$CM_ENV"'
    mode_assignment = (
        'RELEASE_TEST_MODE="$(bash scripts/release_test_mode.sh '
        '\"$RELEASE_TAG\")"'
    )
    skip_condition = 'if [ "$RELEASE_TEST_MODE" = "skip" ]; then'
    policy_test_command = (
        "python3 -m unittest -v test_release_test_mode.py "
        "test_release_tag_resolver.py"
    )

    for name in dual_target:
        steps = list(script_blocks(workflows[name]))
        exports = [
            (step_index, step_name, line)
            for step_index, (step_name, script) in enumerate(steps)
            for line in scan(script)
            if tag_export.match(line.text)
        ]
        if len(exports) != 1:
            failures.append(
                f"{name}: must propagate the single resolved release tag with "
                f"`{tag_export_example}`; found {len(exports)} exports"
            )
        elif exports[0][2].depth != 0:
            failures.append(
                f"{name} / {exports[0][1]!r}: the RELEASE_TAG export is nested "
                "inside a block, so later steps may receive no release tag"
            )

        policy_test_runs = [
            (step_index, step_name, line)
            for step_index, (step_name, script) in enumerate(steps)
            for line in scan(script)
            if line.text == policy_test_command
        ]
        if len(policy_test_runs) != 1:
            failures.append(
                f"{name}: must run the release tag and Rebuild policy tests "
                f"exactly once in Codemagic; found {len(policy_test_runs)} runs"
            )
        elif policy_test_runs[0][2].depth != 0:
            failures.append(
                f"{name} / {policy_test_runs[0][1]!r}: release policy tests are "
                "nested inside a block, so they may not run"
            )

        coverage_steps = [
            (step_index, step_name, script)
            for step_index, (step_name, script) in enumerate(steps)
            if any("flutter test --coverage" in line.text for line in scan(script))
        ]
        if len(coverage_steps) != 1:
            failures.append(
                f"{name}: expected exactly one unit-test coverage step; found "
                f"{len(coverage_steps)}"
            )
            continue

        coverage_index, step_name, script = coverage_steps[0]
        where = f"{name} / {step_name!r}"
        lines = list(scan(script))
        required = {
            "release-tag assertion": [
                line for line in lines if line.text.startswith(': "${RELEASE_TAG:?')
            ],
            "tested tag policy": [
                line for line in lines if line.text == mode_assignment
            ],
            "skip-only condition": [
                line for line in lines if line.text == skip_condition
            ],
            "successful early exit": [
                line for line in lines if line.text == "exit 0"
            ],
            "coverage command": [
                line for line in lines if "flutter test --coverage" in line.text
            ],
        }
        for label, matches in required.items():
            if len(matches) != 1:
                failures.append(
                    f"{where}: expected exactly one {label} for the auditable "
                    f"`-skip-tests` release-tag policy; found {len(matches)}"
                )

        if all(len(matches) == 1 for matches in required.values()):
            tag_assert = required["release-tag assertion"][0]
            mode = required["tested tag policy"][0]
            condition = required["skip-only condition"][0]
            successful_exit = required["successful early exit"][0]
            coverage = required["coverage command"][0]
            errexit = [
                line
                for line in lines
                if line.depth == 0 and SET_ERREXIT.match(line.text)
            ]
            closing_fis = [
                line
                for line in lines
                if line.lineno > condition.lineno
                and line.depth == condition.depth
                and _CLOSE_FI.match(line.text)
            ]
            close = closing_fis[0] if closing_fis else None

            if not errexit or min(line.lineno for line in errexit) > tag_assert.lineno:
                failures.append(
                    f"{where}: must enable `set -e` at top level before the tag "
                    "policy so policy and coverage failures stop the build"
                )
            elif any(
                line.lineno < coverage.lineno and UNSET_ERREXIT.match(line.text)
                for line in lines
            ):
                failures.append(
                    f"{where}: disables `set -e` before coverage, so a failed test "
                    "can be hidden by a later successful command"
                )
            if any(line.depth != 0 for line in (tag_assert, mode, condition, coverage)):
                failures.append(
                    f"{where}: the release-tag assertion, policy call, skip "
                    "condition, and coverage command must all run at top level"
                )
            if not (
                tag_assert.lineno
                < mode.lineno
                < condition.lineno
                < successful_exit.lineno
                < coverage.lineno
            ):
                failures.append(
                    f"{where}: release-test controls must run in this order: tag "
                    "assertion, policy call, skip condition, early exit, coverage"
                )
            if close is None:
                failures.append(
                    f"{where}: the skip-only condition has no matching top-level `fi`"
                )
            else:
                alternate_branch_before_exit = any(
                    line.lineno < successful_exit.lineno
                    and line.depth == condition.depth + 1
                    and (
                        line.text == "else"
                        or line.text.startswith("else ")
                        or line.text.startswith("elif ")
                    )
                    for line in lines
                    if line.lineno > condition.lineno
                )
                exit_is_in_skip_branch = (
                    condition.lineno < successful_exit.lineno < close.lineno
                    and successful_exit.depth == condition.depth + 1
                    and not alternate_branch_before_exit
                )
                if not exit_is_in_skip_branch:
                    failures.append(
                        f"{where}: `exit 0` must be inside the skip-only branch; "
                        "otherwise every release can silently bypass coverage"
                    )
                if coverage.lineno <= close.lineno:
                    failures.append(
                        f"{where}: coverage must run after the skip-only branch "
                        "closes, so ordinary release tags cannot bypass it"
                    )

        if len(exports) == 1 and exports[0][0] >= coverage_index:
            failures.append(
                f"{name}: RELEASE_TAG is exported in step {exports[0][0] + 1}, "
                f"not before the coverage step {coverage_index + 1}"
            )
        if len(policy_test_runs) == 1 and policy_test_runs[0][0] >= coverage_index:
            failures.append(
                f"{name}: release policy tests run in step "
                f"{policy_test_runs[0][0] + 1}, not before the coverage step "
                f"{coverage_index + 1}"
            )
    return failures


def check_patch_release_version_is_full(workflows):
    """Patch workflows must target the full release version.

    Shorebird releases are registered under the full pubspec version
    (e.g. 1.2.39+123904, confirmed empirically on staging 2026-07-28).
    Deriving RELEASE_VERSION with the build number stripped
    (`cut -d'+' -f1`) makes `shorebird patch` unable to find its
    release, so every patch run fails - the production patch workflows
    shipped with exactly that truncation.
    """
    failures = []
    truncation = re.compile(r"cut\s+-d\s*['\"]?\+")
    for name, workflow in workflows.items():
        for step_name, script in script_blocks(workflow):
            if "shorebird patch" not in script:
                continue
            for line in script.splitlines():
                stripped = line.strip()
                if stripped.startswith("RELEASE_VERSION=") and truncation.search(
                    stripped
                ):
                    failures.append(
                        f"{name} / {step_name}: RELEASE_VERSION strips the "
                        "build number, but shorebird releases use the full "
                        "version - the patch cannot find its release"
                    )
    return failures


def check_patch_split_debug_info_gate(workflows):
    """Production patches must mirror the release's --split-debug-info flag.

    1.3.0+130008 부터 프로덕션 릴리스는 항상 --split-debug-info 로 빌드된다.
    패치가 다른 빌드 인자로 컴파일되면 릴리스와 어긋난 패치가 나가므로,
    게이트는 (a) MmPPBB 6자리가 아닌 빌드 번호를 실패시키고 (b) 130008
    이상에서만 플래그를 전달해야 한다. 정적 검사 대신 게이트 블록을 실제
    bash 로 실행해 행동을 검증한다 — "숫자면 통과" 같은 완화가 재발하면
    13008 (자릿수 오타) 케이스가 잡아낸다.
    """
    import subprocess

    failures = []
    cases = [
        # (RELEASE_VERSION, expect_exit_zero, expect_flag)
        ("1.3.0+130007", True, False),
        ("1.3.0+130008", True, True),
        ("1.4.0+140001", True, True),
        ("1.3.12+131201", True, True),  # PP 두 자리
        ("1.3.0+13008", False, None),  # 자릿수 오타 — 조용히 구릴리스 취급 금지
        ("1.3.0+abc", False, None),
        ("1.3.0+99999999", False, None),  # MmPPBB 범위 밖
        ("1.4.0+120000", False, None),  # 표시 버전과 빌드 번호 불일치
        ("1.4.0+000001", False, None),  # 표시 버전과 빌드 번호 불일치
    ]
    for name, workflow in workflows.items():
        for step_name, script in script_blocks(workflow):
            if (
                "shorebird patch android" not in script
                or 'EXTRA_BUILD_ARGS=""' not in script
            ):
                continue
            lines = script.splitlines()
            start = next(
                i for i, l in enumerate(lines) if l.strip() == 'EXTRA_BUILD_ARGS=""'
            )
            # EXTRA_BUILD_ARGS="" 부터, 임계값(-ge 130008) if 를 닫는 fi 까지가
            # 게이트 블록이다 — 중간 검증 if 의 개수에 의존하지 않는다.
            block, seen_threshold, complete = [], False, False
            for line in lines[start:]:
                block.append(line)
                if "-ge 130008" in line:
                    seen_threshold = True
                if seen_threshold and line.strip() == "fi":
                    complete = True
                    break
            gate = "\n".join(block)
            if not complete:
                failures.append(
                    f"{name} / {step_name}: split-debug-info 게이트 블록을 "
                    "추출하지 못했다 (임계값 if 미발견)"
                )
                continue
            for version, expect_ok, expect_flag in cases:
                proc = subprocess.run(
                    [
                        "bash",
                        "-c",
                        f'RELEASE_VERSION="{version}"\n'
                        f'PATCH_BUILD_NUMBER=${{RELEASE_VERSION#*+}}\n'
                        f"{gate}\n"
                        'printf "OUT:%s" "$EXTRA_BUILD_ARGS"',
                    ],
                    capture_output=True,
                    text=True,
                )
                ok = proc.returncode == 0
                if ok != expect_ok:
                    failures.append(
                        f"{name} / {step_name}: 버전 {version} 은 "
                        f"{'통과' if expect_ok else '실패'}해야 하는데 "
                        f"exit={proc.returncode}"
                    )
                    continue
                if expect_ok:
                    has_flag = "--split-debug-info=build/symbols" in proc.stdout
                    if has_flag != expect_flag:
                        failures.append(
                            f"{name} / {step_name}: 버전 {version} 의 플래그 "
                            f"기대={expect_flag}, 실제={has_flag}"
                        )
    return failures


def run_checks(text=None):
    """Return the list of isolation violations for a codemagic.yaml text."""
    try:
        workflows = load_workflows(text)
    except GuardError as exc:
        return [str(exc)]

    dual_target, staging_only, production_only, failures = classify_workflows(
        workflows
    )
    failures = list(failures)
    tag_driven = dual_target + staging_only
    failures += check_deploy_target_fail_closed(workflows, tag_driven)
    failures += check_deploy_target_derived_from_tag(workflows, dual_target)
    failures += check_deploy_target_derived_from_tag(
        workflows, staging_only, expected_targets=("staging",)
    )
    failures += check_deploy_target_consumers_assert(workflows, tag_driven)
    failures += check_deploy_conditions_are_simple(
        workflows, tag_driven, production_only
    )
    failures += check_production_path_exists(workflows, dual_target, production_only)
    failures += check_production_gate_runs_in_production(workflows, dual_target)
    failures += check_staging_only_stays_staging(workflows, staging_only)
    failures += check_branch_correct_defines(workflows, tag_driven, production_only)
    failures += check_release_invocation_defines(
        workflows, tag_driven, production_only
    )
    failures += check_isolation_verifier_inputs(workflows, tag_driven)
    failures += check_guard_failure_fails_the_step(workflows)
    failures += check_isolation_guard_runs_in_ci(workflows, tag_driven)
    failures += check_app_guard_tests_run(workflows, tag_driven)
    failures += check_release_test_skip_policy(workflows, dual_target)
    failures += check_patch_release_version_is_full(workflows)
    failures += check_patch_split_debug_info_gate(workflows)
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


def mutate_drop_tag_case_mapping(text):
    """Delete the whole `case "$CM_TAG"` mapping.

    DEPLOY_TARGET is then exported to `$CM_ENV` from nothing at all, so the tag
    stops deciding anything.
    """
    out = []
    skipping = False
    for line in text.splitlines():
        stripped = line.strip()
        if not skipping and TAG_CASE_HEAD.match(stripped):
            skipping = True
            continue
        if skipping:
            if stripped == "esac":
                skipping = False
            continue
        out.append(line)
    return "\n".join(out) + "\n"


def mutate_drop_tag_case_catchall(text):
    """Delete the `*)` branch, so an unmapped tag leaves DEPLOY_TARGET unset."""
    out = []
    in_case = False
    skipping = False
    for line in text.splitlines():
        stripped = line.strip()
        if TAG_CASE_HEAD.match(stripped):
            in_case = True
        if in_case and not skipping and stripped == "*)":
            skipping = True
            continue
        if skipping:
            if stripped == ";;":
                skipping = False
            continue
        if stripped == "esac":
            in_case = False
        out.append(line)
    return "\n".join(out) + "\n"


def mutate_swap_tag_target_mapping(text):
    """Point the staging tag at production and the production tag at staging.

    Only the two `case` labels move, so every other line -- including both
    `DEPLOY_TARGET=` assignments -- is byte-identical. Nothing textual gives it
    away; only the pattern/target relationship does.
    """
    staging = "            picnic-staging-v*)"
    production = "            picnic-v*)"
    out = []
    for line in text.splitlines():
        if line == staging:
            out.append(production)
        elif line == production:
            out.append(staging)
        else:
            out.append(line)
    return "\n".join(out) + "\n"


def mutate_overlapping_tag_patterns(text):
    """Broaden the staging pattern until it also matches production tags.

    `picnic-*` matches `picnic-v1.2.3`, so a production tag now matches both
    branches and its target depends on which `case` label comes first.
    """
    return text.replace("picnic-staging-v*", "picnic-*")


def mutate_trigger_pattern_without_mapping(text):
    """Add a third trigger pattern that the derivation does not map."""
    return text.replace(
        "        - pattern: 'picnic-staging-v*'\n          include: true\n",
        "        - pattern: 'picnic-staging-v*'\n          include: true\n"
        "        - pattern: 'picnic-hotfix-v*'\n          include: true\n",
    )


def mutate_derive_deploy_target_from_branch(text):
    """Derive the target from the branch instead of the tag.

    `CM_BRANCH` on a tag build is whatever branch the tag points into, so the
    target stops being a property of the released artefact.
    """
    return text.replace('case "$CM_TAG" in', 'case "$CM_BRANCH" in').replace(
        ': "${CM_TAG:?is unset; this workflow only runs from a release tag}"',
        ': "${CM_BRANCH:?is unset}"',
    )


def mutate_override_deploy_target_in_later_step(text):
    """Overwrite the derived target in a later step."""
    anchor = (
        "      - name: Verify environment isolation policy\n"
        "        script: |\n"
        "          set -e\n"
    )
    if anchor not in text:
        raise AssertionError("self-test anchor not found in codemagic.yaml")
    return text.replace(anchor, anchor + "          DEPLOY_TARGET=staging\n")


def mutate_export_hardcoded_deploy_target(text):
    """Export a constant to `$CM_ENV` instead of the derived value."""
    return text.replace(
        'echo "DEPLOY_TARGET=$DEPLOY_TARGET" >> "$CM_ENV"',
        'echo "DEPLOY_TARGET=staging" >> "$CM_ENV"',
    )


def mutate_drop_cm_env_export(text):
    """Never hand the derived target to the later steps.

    Every consumer then reads an empty DEPLOY_TARGET -- which, without the
    per-step asserts, is exactly the silent staging build of Critical 1.
    """
    return "\n".join(
        line
        for line in text.splitlines()
        if line.strip() != 'echo "DEPLOY_TARGET=$DEPLOY_TARGET" >> "$CM_ENV"'
    ) + "\n"


def mutate_drop_tag_requirement(text):
    """Stop requiring the tag variable."""
    return "\n".join(
        line for line in text.splitlines() if ': "${CM_TAG:?' not in line
    ) + "\n"


def mutate_drop_tag_resolver(text):
    """Remove rebuild tag recovery while leaving the webhook-only path intact."""
    return "\n".join(
        line
        for line in text.splitlines()
        if line.strip() != 'CM_TAG="$(bash scripts/resolve_release_tag.sh)"'
    ) + "\n"


def mutate_drop_release_tag_export(text):
    """Stop propagating the resolved tag to later workflow steps."""
    return "\n".join(
        line
        for line in text.splitlines()
        if line.strip() != 'echo "RELEASE_TAG=$CM_TAG" >> "$CM_ENV"'
    ) + "\n"


def mutate_drop_release_test_mode_gate(text):
    """Run coverage unconditionally even for an explicit skip-tests tag."""
    return "\n".join(
        line
        for line in text.splitlines()
        if "scripts/release_test_mode.sh" not in line
    ) + "\n"


def mutate_drop_release_policy_tests(text):
    """Let the tested tag and Rebuild policies rot outside Codemagic."""
    return "\n".join(
        line
        for line in text.splitlines()
        if not (
            "test_release_test_mode.py" in line
            and "test_release_tag_resolver.py" in line
        )
    ) + "\n"


def mutate_drop_release_coverage_errexit(text):
    """Let policy or coverage failures be hidden by later successful commands."""
    step_prefix = """\
      - name: Run unit tests with coverage
        script: |
          set -e
"""
    return text.replace(
        step_prefix,
        """\
      - name: Run unit tests with coverage
        script: |
""",
    )


def mutate_move_release_test_exit_outside_gate(text):
    """Skip coverage for every tag by moving the successful exit before the gate."""
    gated_exit = """\
          if [ "$RELEASE_TEST_MODE" = "skip" ]; then
            echo "Skipping picnic_lib unit tests with coverage by release tag: $RELEASE_TAG"
            exit 0
          fi"""
    unconditional_exit = """\
          exit 0
          if [ "$RELEASE_TEST_MODE" = "skip" ]; then
            echo "Skipping picnic_lib unit tests with coverage by release tag: $RELEASE_TAG"
          fi"""
    return text.replace(gated_exit, unconditional_exit)


def mutate_default_tag_variable(text):
    """Give the tag variable a default, so a tagless build still ships."""
    return text.replace('case "$CM_TAG" in', 'case "${CM_TAG:-picnic-v0.0.0}" in')


def mutate_drop_consumer_deploy_asserts(text):
    """Let the consumer steps read DEPLOY_TARGET with no assert of their own.

    The derivation step keeps its assert, so a workflow-level "is it asserted
    somewhere" check still passes while a broken `$CM_ENV` hand-off silently
    routes every build into the staging branch.
    """
    return "\n".join(
        line
        for line in text.splitlines()
        if "was not propagated from the tag-derivation step" not in line
    ) + "\n"


def mutate_nest_consumer_deploy_asserts(text):
    """Keep the consumer asserts in the text but only inside a branch that never
    runs, so an empty DEPLOY_TARGET reaches the deploy-target tests anyway."""
    anchor = ': "${DEPLOY_TARGET:?was not propagated from the tag-derivation step}"'
    out = []
    for line in text.splitlines():
        if line.strip() == anchor:
            indent = line[: len(line) - len(line.lstrip())]
            out.append(f'{indent}if [ -n "$UNSET_FLAG" ]; then')
            out.append(f"{indent}  {anchor}")
            out.append(f"{indent}fi")
        else:
            out.append(line)
    return "\n".join(out) + "\n"


def mutate_derivation_step_after_consumer(text):
    """Run the tag derivation after a step that already reads DEPLOY_TARGET."""
    data = yaml.safe_load(text)
    moved = False
    for workflow in data["workflows"].values():
        steps = workflow.get("scripts") or []
        scripts = [
            step.get("script") if isinstance(step, dict) else None for step in steps
        ]
        derive = next(
            (
                i
                for i, script in enumerate(scripts)
                if isinstance(script, str) and _has_tag_case(script)
            ),
            None,
        )
        if derive is None:
            continue
        consumer = next(
            (
                i
                for i, script in enumerate(scripts)
                if i != derive
                and isinstance(script, str)
                and _step_needs_validated_target(script)
            ),
            None,
        )
        if consumer is None or consumer < derive:
            continue
        steps[derive], steps[consumer] = steps[consumer], steps[derive]
        moved = True
    if not moved:
        raise AssertionError("no derivation step to relocate")
    return _dump(data)


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
    dual_target, _, _, _ = classify_workflows(workflows)
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


def _staging_patch_tail(text):
    """(head, tail) split at the first staging-only patch workflow."""
    marker = "picnic-app-staging-patch-ios:"
    index = text.find(marker)
    if index < 0:
        return text, ""
    return text[:index], text[index:]


def mutate_staging_patch_prod_define(text):
    """A staging-only patch invocation ships ENVIRONMENT=prod."""
    head, tail = _staging_patch_tail(text)
    return head + tail.replace(
        "--dart-define=ENVIRONMENT=dev", "--dart-define=ENVIRONMENT=prod", 1
    )


def mutate_staging_patch_unguarded_invocation(text):
    """The staging patch command escapes its DEPLOY_TARGET guard."""
    head, tail = _staging_patch_tail(text)
    newline = chr(10)
    guarded = (
        '          if [ "$DEPLOY_TARGET" != "production" ]; then'
        + newline
        + "          shorebird patch ios"
    )
    tail = tail.replace(guarded, "          shorebird patch ios", 1)
    tail = tail.replace(
        newline + "          fi" + newline + '          echo "✅ iOS',
        newline + '          echo "✅ iOS',
        1,
    )
    return head + tail


def mutate_staging_patch_trigger_widened(text):
    """A production tag pattern sneaks into the staging-only trigger."""
    head, tail = _staging_patch_tail(text)
    anchor = (
        "        - pattern: 'picnic-staging-patch-v*'"
        + chr(10)
        + "          include: true"
    )
    return head + tail.replace(
        anchor,
        anchor
        + chr(10)
        + "        - pattern: 'picnic-v*'"
        + chr(10)
        + "          include: true",
        1,
    )


def mutate_staging_patch_drop_consumer_assert(text):
    """The patch step reads DEPLOY_TARGET without asserting it first."""
    head, tail = _staging_patch_tail(text)
    anchor = (
        '          : "${DEPLOY_TARGET:?was not propagated from the tag-derivation step}"'
        + chr(10)
        + "          # Staging-only workflow:"
    )
    return head + tail.replace(
        anchor, "          # Staging-only workflow:", 1
    )


def mutate_staging_patch_catchall_assigns(text):
    """The staging patch tag catch-all guesses a target instead of refusing."""
    head, tail = _staging_patch_tail(text)
    refusal = (
        "            *) echo \"Tag '$CM_TAG' is not a staging patch tag; "
        'refusing" >&2; exit 1 ;;'
    )
    return head + tail.replace(refusal, "            *) DEPLOY_TARGET=staging ;;", 1)


def mutate_patch_release_version_truncated(text):
    return text.replace(
        "RELEASE_VERSION=$(grep \"^version:\" pubspec.yaml"
        " | sed 's/version: //' | tr -d ' ')",
        "RELEASE_VERSION=$(grep \"^version:\" pubspec.yaml"
        " | sed 's/version: //' | cut -d'+' -f1)",
        1,
    )


SELF_TESTS = (
    ("unmutated config is accepted", mutate_identity, False),
    (
        "patch workflow strips the build number from RELEASE_VERSION",
        mutate_patch_release_version_truncated,
        True,
    ),
    (
        "staging-only patch ships a production define",
        mutate_staging_patch_prod_define,
        True,
    ),
    (
        "staging-only patch invocation escapes its deploy guard",
        mutate_staging_patch_unguarded_invocation,
        True,
    ),
    (
        "staging-only trigger widened to a production tag",
        mutate_staging_patch_trigger_widened,
        True,
    ),
    (
        "staging-only patch step drops its DEPLOY_TARGET assert",
        mutate_staging_patch_drop_consumer_assert,
        True,
    ),
    (
        "staging-only tag catch-all guesses a target",
        mutate_staging_patch_catchall_assigns,
        True,
    ),
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
    ("tag -> target mapping deleted", mutate_drop_tag_case_mapping, True),
    (
        "tag mapping left without a fail-closed catch-all",
        mutate_drop_tag_case_catchall,
        True,
    ),
    (
        "staging tag mapped to production and vice versa",
        mutate_swap_tag_target_mapping,
        True,
    ),
    ("tag patterns broadened until they overlap", mutate_overlapping_tag_patterns, True),
    (
        "a trigger tag pattern with no target mapped to it",
        mutate_trigger_pattern_without_mapping,
        True,
    ),
    (
        "deploy target derived from the branch instead of the tag",
        mutate_derive_deploy_target_from_branch,
        True,
    ),
    (
        "derived target overridden by a later step",
        mutate_override_deploy_target_in_later_step,
        True,
    ),
    (
        "a constant exported to $CM_ENV instead of the derived target",
        mutate_export_hardcoded_deploy_target,
        True,
    ),
    ("derived target never handed to the later steps", mutate_drop_cm_env_export, True),
    ("tag variable no longer required", mutate_drop_tag_requirement, True),
    ("rebuild tag resolver removed", mutate_drop_tag_resolver, True),
    ("resolved release tag not propagated", mutate_drop_release_tag_export, True),
    ("release test-mode gate removed", mutate_drop_release_test_mode_gate, True),
    ("release policy tests not run in Codemagic", mutate_drop_release_policy_tests, True),
    (
        "coverage step no longer fails fast",
        mutate_drop_release_coverage_errexit,
        True,
    ),
    (
        "release test-mode exit moved outside its skip-only gate",
        mutate_move_release_test_exit_outside_gate,
        True,
    ),
    ("tag variable given a default", mutate_default_tag_variable, True),
    (
        "consumer steps read DEPLOY_TARGET with no assert of their own",
        mutate_drop_consumer_deploy_asserts,
        True,
    ),
    (
        "consumer asserts nested inside a branch that never runs",
        mutate_nest_consumer_deploy_asserts,
        True,
    ),
    (
        "tag derivation moved after a step that reads DEPLOY_TARGET",
        mutate_derivation_step_after_consumer,
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
