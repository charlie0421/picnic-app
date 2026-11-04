"""Reduce `adb logcat -v epoch` output to a closed set of push/auth events.

The caller pipes logcat into stdin. This tool starts no process, picks no
device, opens no file and cleans up nothing. It writes one JSON object per
recognised event to stdout and drops every other record without echoing it.

Output schema (closed; keys are sorted):
  epoch_ms     int   logcat epoch time in milliseconds (2020-01-01 .. 2100-01-01)
  event        str   one of EVENTS
  status       int   optional, HTTP status 100..599
  duration_ms  int   optional, 0..600000
  source       str   optional, 'emulator' or 'physical' when given with --source

No message text, tag, PID, TID, UID, account, URL, token or error body is ever
part of the output, a diagnostic or an exception. The filter only observes: a
missing event never means success, no session or no write.

Accepted input (anything else is dropped):
  * A logcat record `<sec>.<frac> <pid> <tid> I flutter : <message>` where the
    fraction has 3, 6 or 9 digits (`-v epoch`, optionally with usec/nsec).
  * <message> is one line of the logger 2.6 PrettyPrinter box used by
    picnic_lib/lib/core/utils/logger.dart: an optional ANSI 256-colour wrapper
    `ESC[38;5;<n>m ... ESC[0m`, then `│ `, then for message lines the level
    emoji and a space. Box borders are `┌─…`, `├┄…` and `└─…`.
  * A message line counts only when it is the first message line after a
    border of the same process and thread, its emoji and colour agree on one
    level, and its whole text matches one exact product literal. Payloads
    with newlines become later lines of the same box, so they can never be the
    line that follows a border.
  * An error line (no emoji) counts only when it is the first line after a top
    border and starts with one exact class prefix.
Product literals: picnic_lib push_token_service.dart, google_login.dart,
auth_service.dart and picnic_app/lib/app.dart.
"""
import json
import re
import sys

MAX_RECORD_BYTES = 8192
MAX_TRACKED_THREADS = 64
MIN_EPOCH_S = 1577836800   # 2020-01-01T00:00:00Z
MAX_EPOCH_S = 4102444800   # 2100-01-01T00:00:00Z (exclusive)
MAX_PID = 4194304          # Linux pid_max limit
MAX_DURATION_MS = 600000
SOURCES = ('emulator', 'physical')

USAGE_DIAGNOSTIC = ('fcm_event_filter: invalid arguments; '
                    'usage: fcm_event_filter.py [--source emulator|physical]\n')
INTERNAL_DIAGNOSTIC = 'fcm_event_filter: internal error; input not shown\n'

_LOGCAT = re.compile(
    r'[ ]*([0-9]{1,11})\.([0-9]{3}|[0-9]{6}|[0-9]{9}) +([0-9]{1,7}) +([0-9]{1,7}) '
    r'I flutter {0,8}: (.*)', re.ASCII | re.DOTALL)
_PAINTED = re.compile(r'\x1b\[38;5;([0-9]{1,3})m(.*)\x1b\[0m', re.ASCII | re.DOTALL)
_TOP = re.compile(r'┌─{16,256}')
_MID = re.compile(r'├┄{16,256}')
_BOTTOM = re.compile(r'└─{16,256}')

# Emoji -> (level, colour); logger 2.6 defaults. Debug prints without colour.
_LEVELS = {
    '🐛': ('debug', None),
    '💡': ('info', 12),
    '⚠️': ('warning', 208),
    '⛔': ('error', 196),
}
_STATUS = r'([1-5][0-9]{2})'
_DURATION = r'(0|[1-9][0-9]{0,5})'

# (level, full-match pattern, event, numeric field for group 1 or None)
_MESSAGES = [
    ('info', r'Push token registered \(took ' + _DURATION + r'ms\)',
     'registration_succeeded', 'duration_ms'),
    ('info', r'Push token registered on retry', 'registration_succeeded_auth_retry', None),
    ('info', r'Push token registered on retry after timeout',
     'registration_succeeded_timeout_retry', None),
    ('info', r'Registering push token to Supabase Edge: POST .*', 'registration_started', None),
    ('info', r'Refreshing push token with updated app language', 'token_language_refresh', None),
    ('info', r'앱이 포그라운드로 복귀', 'app_resumed', None),
    ('warning', r'registerToken skipped: no authenticated user',
     'registration_skipped_no_user', None),
    ('warning', r'registerToken got 401 -> refreshing session and retrying once',
     'registration_auth_retry_started', None),
    ('error', r'Failed to register push token: status=' + _STATUS + r', data=.*',
     'registration_http_failed', 'status'),
    ('error', r'Retry after timeout failed: status=' + _STATUS + r', data=.*',
     'registration_timeout_retry_failed', 'status'),
    ('error', r'Retry failed to register push token: status=' + _STATUS + r', data=.*',
     'registration_auth_retry_failed', 'status'),
    ('error', r'registerToken function error: status=' + _STATUS + r', details=.*',
     'registration_function_error', 'status'),
    ('error', r'registerToken timeout after 12s', 'registration_timeout', None),
    ('error', r'registerToken network error \(SocketException\)',
     'registration_network_error', None),
    ('error', r'registerToken aborted: accessToken missing \(user exists but session not ready\)',
     'registration_aborted_no_session', None),
    ('error', r'Session refresh returned no token; aborting',
     'registration_retry_no_session', None),
    ('error', r'Push initialization step failed', 'push_init_step_failed', None),
    ('error', r'Error during sign in:', 'sign_in_error', None),
    ('error', r'Google login error: GoogleSignInException\(code '
              r'GoogleSignInExceptionCode\.canceled[,)].*', 'native_auth_canceled', None),
    ('error', r'Google login error: .+', 'native_auth_failed', None),
    ('debug', r'Google authentication tokens extracted', 'native_auth_ok', None),
]
_MESSAGES = [(level, re.compile(pattern, re.DOTALL), event, field)
             for level, pattern, event, field in _MESSAGES]

# First error line of a box (right after the top border): exact class prefixes.
_ERROR_CLASSES = [
    ("[core/no-app] No Firebase App '", 'core_no_app'),
    ('Bad state: Supabase가 초기화되지 않았습니다.', 'supabase_not_initialized'),
]

EVENTS = frozenset([event for _, _, event, _ in _MESSAGES]
                   + [event for _, event in _ERROR_CLASSES])


def _epoch_ms(seconds, fraction):
    """Integer milliseconds (always finite) or None outside the plausible range."""
    value = int(seconds)
    if not MIN_EPOCH_S <= value < MAX_EPOCH_S:
        return None
    return value * 1000 + int(fraction[:3])


def _unpaint(text):
    """Return (colour or None, inner text) or None when other escapes remain."""
    color = None
    painted = _PAINTED.fullmatch(text)
    if painted:
        color, text = int(painted.group(1)), painted.group(2)
    if '\x1b' in text:
        return None
    return color, text


def _message_event(color, body):
    for emoji, (level, level_color) in _LEVELS.items():
        prefix = emoji + ' '
        if body.startswith(prefix):
            if color is not None and color != level_color:
                return None
            text = body[len(prefix):]
            for want, pattern, event, field in _MESSAGES:
                if want != level:
                    continue
                match = pattern.fullmatch(text)
                if match:
                    extra = {}
                    if field is not None:
                        number = int(match.group(1))
                        if field == 'duration_ms' and number > MAX_DURATION_MS:
                            return None
                        extra[field] = number
                    return event, extra
            return None
    return None


def _error_class(body):
    for prefix, event in _ERROR_CLASSES:
        if body.startswith(prefix):
            return event
    return None


class FcmEventFilter:
    """Pure, streaming record filter. feed() returns an event dict or None."""

    def __init__(self, source=None):
        if source is not None and source not in SOURCES:
            raise ValueError('unsupported source')
        self._source = source
        self._after = {}  # (pid, tid) -> 'top' | 'mid' | None

    def reset(self):
        """Forget every border; call after any record that could not be read."""
        self._after.clear()

    def feed(self, line):
        if not isinstance(line, str):
            self.reset()
            return None
        record = _LOGCAT.fullmatch(line)
        if record is None:
            self.reset()
            return None
        seconds, fraction, pid, tid, message = record.groups()
        pid, tid = int(pid), int(tid)
        epoch_ms = _epoch_ms(seconds, fraction)
        if epoch_ms is None or not (0 < pid <= MAX_PID and 0 < tid <= MAX_PID):
            self.reset()
            return None
        key = (pid, tid)
        previous = self._after.pop(key, None)
        unpainted = _unpaint(message)
        if unpainted is None:
            return None
        color, text = unpainted
        if _TOP.fullmatch(text):
            self._remember(key, 'top')
            return None
        if _MID.fullmatch(text):
            self._remember(key, 'mid')
            return None
        if previous is None or not text.startswith('│ '):
            return None
        body = text[2:]
        found = _message_event(color, body)
        if found is None and previous == 'top':
            event = _error_class(body)
            found = (event, {}) if event else None
        if found is None:
            return None
        event, extra = found
        result = {'epoch_ms': epoch_ms, 'event': event, **extra}
        if self._source is not None:
            result['source'] = self._source
        return result

    def _remember(self, key, state):
        if len(self._after) >= MAX_TRACKED_THREADS:
            self._after.clear()
        self._after[key] = state


def _parse_args(argv):
    """Return the source (or None); raise ValueError without echoing argv."""
    args = list(argv)
    if not args:
        return None
    if len(args) == 1 and args[0].startswith('--source='):
        value = args[0][len('--source='):]
    elif len(args) == 2 and args[0] == '--source':
        value = args[1]
    else:
        raise ValueError('usage')
    if value not in SOURCES:
        raise ValueError('usage')
    return value


def _records(stdin):
    """Yield one decoded record per line, or None for a record that is longer
    than MAX_RECORD_BYTES (newline excluded) or not UTF-8. An overlong record
    is read in bounded chunks and discarded whole; nothing of it is kept."""
    while True:
        chunk = stdin.readline(MAX_RECORD_BYTES + 2)
        if not chunk:
            return
        complete = chunk.endswith(b'\n')
        raw = chunk[:-1] if complete else chunk
        if len(raw) > MAX_RECORD_BYTES:
            while chunk and not chunk.endswith(b'\n'):
                chunk = stdin.readline(MAX_RECORD_BYTES + 2)
            yield None
            continue
        if raw.endswith(b'\r'):
            raw = raw[:-1]
        try:
            yield raw.decode('utf-8')
        except UnicodeDecodeError:
            yield None


def main(argv, stdin=None, stdout=None, stderr=None):
    stdin = stdin if stdin is not None else sys.stdin.buffer
    stdout = stdout if stdout is not None else sys.stdout
    stderr = stderr if stderr is not None else sys.stderr
    try:
        source = _parse_args(argv)
    except ValueError:
        stderr.write(USAGE_DIAGNOSTIC)
        return 2
    try:
        flt = FcmEventFilter(source=source)
        for line in _records(stdin):
            if line is None:
                flt.reset()
                continue
            event = flt.feed(line)
            if event is not None:
                stdout.write(json.dumps(event, sort_keys=True, separators=(',', ':')) + '\n')
                stdout.flush()
    except BaseException:  # noqa: BLE001 - nothing about the input may escape
        stderr.write(INTERNAL_DIAGNOSTIC)
        return 70
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
