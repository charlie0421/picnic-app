"""Tests for scripts/qa/fcm_event_filter.py.

Every input here is a synthetic string. The tests build `adb logcat -v epoch`
records around the exact product logger literals and the logger 2.6
PrettyPrinter box, then check that only the closed schema leaves the filter.

Run: python3 scripts/qa/test_fcm_event_filter.py
"""
import io
import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest import mock

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import fcm_event_filter as f  # noqa: E402

ESC = '\x1b'
TOP = '┌' + '─' * 119
MID = '├' + '┄' * 119
BOT = '└' + '─' * 119
LEVELS = {  # emoji, ANSI 256 foreground (None: logger prints no colour)
    'd': ('🐛', None),
    'i': ('💡', 12),
    'w': ('⚠️', 208),
    'e': ('⛔', 196),
}
SECRET = 'SECRETxTOKENx9f8e7d'
TS = '1793750400.123'
TS_MS = 1793750400123
SCHEMA = {'epoch_ms', 'event', 'status', 'duration_ms', 'source'}


def lc(message, ts=TS, pid=4321, tid=4350, pri='I', tag='flutter'):
    """One `adb logcat -v epoch` record (threadtime layout, epoch time)."""
    return f'{ts} {pid:5d} {tid:5d} {pri} {tag:<8}: {message}'


def paint(text, color):
    return text if color is None else f'{ESC}[38;5;{color}m{text}{ESC}[0m'


def box(level, message, error=None, stack=True, color=True, **record):
    """The PrettyPrinter box for one logger call, one logcat record per line."""
    emoji, fg = LEVELS[level]
    fg = fg if color else None
    lines = [TOP]
    if error is not None:
        lines += [f'│ {line}' for line in error.split('\n')] + [MID]
    if stack:
        lines += ['│ #0   PushTokenService.registerToken (package:picnic_lib/core/services/'
                  'push_token_service.dart:371:16)',
                  '│ #1   <asynchronous suspension>', MID]
    lines += [f'│ {emoji} {line}' for line in message.split('\n')]
    lines.append(BOT)
    return [lc(paint(line, fg), **record) for line in lines]


def events(lines, source=None):
    flt = f.FcmEventFilter(source=source)
    out = []
    for line in lines:
        event = flt.feed(line)
        if event is not None:
            out.append(event)
    return out


def run_cli(argv, data):
    stdin = io.BytesIO(data if isinstance(data, bytes) else data.encode())
    stdout, stderr = io.StringIO(), io.StringIO()
    code = f.main(argv, stdin=stdin, stdout=stdout, stderr=stderr)
    return code, stdout.getvalue(), stderr.getvalue()


def joined(lines):
    return '\n'.join(lines) + '\n'


class SuccessAndStatusTest(unittest.TestCase):
    def test_registration_success_keeps_only_the_duration(self):
        self.assertEqual(events(box('i', 'Push token registered (took 532ms)')),
                         [{'epoch_ms': TS_MS, 'event': 'registration_succeeded',
                           'duration_ms': 532}])

    def test_retry_success_variants_are_distinct_events(self):
        self.assertEqual(
            [e['event'] for e in events(
                box('i', 'Push token registered on retry')
                + box('i', 'Push token registered on retry after timeout'))],
            ['registration_succeeded_auth_retry', 'registration_succeeded_timeout_retry'])

    def test_http_failures_keep_only_the_status(self):
        payload = f'{{"error":"bad jwt {SECRET}","uid":"7c1e2a"}}'
        lines = (box('e', f'Failed to register push token: status=500, data={payload} (took 88ms)')
                 + box('e', f'Retry after timeout failed: status=503, data={payload}')
                 + box('e', f'Retry failed to register push token: status=401, data={payload}')
                 + box('e', f'registerToken function error: status=401, details={payload}',
                       error=f'FunctionException(status: 401, details: {payload})'))
        got = events(lines)
        self.assertEqual(got, [
            {'epoch_ms': TS_MS, 'event': 'registration_http_failed', 'status': 500},
            {'epoch_ms': TS_MS, 'event': 'registration_timeout_retry_failed', 'status': 503},
            {'epoch_ms': TS_MS, 'event': 'registration_auth_retry_failed', 'status': 401},
            {'epoch_ms': TS_MS, 'event': 'registration_function_error', 'status': 401},
        ])
        self.assertNotIn(SECRET, json.dumps(got))
        self.assertNotIn('7c1e2a', json.dumps(got))

    def test_fixed_failure_and_retry_markers(self):
        cases = [
            ('w', 'registerToken skipped: no authenticated user', 'registration_skipped_no_user'),
            ('w', 'registerToken got 401 -> refreshing session and retrying once',
             'registration_auth_retry_started'),
            ('e', 'registerToken timeout after 12s', 'registration_timeout'),
            ('e', 'registerToken network error (SocketException)', 'registration_network_error'),
            ('e', 'registerToken aborted: accessToken missing (user exists but session not ready)',
             'registration_aborted_no_session'),
            ('e', 'Session refresh returned no token; aborting', 'registration_retry_no_session'),
            ('e', 'Push initialization step failed', 'push_init_step_failed'),
            ('e', 'Error during sign in:', 'sign_in_error'),
            ('i', 'Refreshing push token with updated app language', 'token_language_refresh'),
            ('i', '앱이 포그라운드로 복귀', 'app_resumed'),
        ]
        for level, message, event in cases:
            with self.subTest(event=event):
                self.assertEqual(events(box(level, message)),
                                 [{'epoch_ms': TS_MS, 'event': event}])

    def test_registration_start_discards_url_uid_and_the_rest(self):
        message = ('Registering push token to Supabase Edge: POST https://abcd.supabase.co/'
                   f'functions/v1/register-push-token?k={SECRET} (uid: 7c1e2a..., platform: '
                   'android, language: ko)')
        got = events(box('i', message))
        self.assertEqual(got, [{'epoch_ms': TS_MS, 'event': 'registration_started'}])
        for leak in (SECRET, 'supabase.co', '7c1e2a', 'android', 'ko'):
            self.assertNotIn(leak, json.dumps(got))

    def test_native_auth_ok_is_a_debug_line_without_colour(self):
        self.assertEqual(events(box('d', 'Google authentication tokens extracted')),
                         [{'epoch_ms': TS_MS, 'event': 'native_auth_ok'}])

    def test_native_auth_failure_is_reduced_to_a_fixed_class(self):
        canceled = (f'Google login error: GoogleSignInException(code '
                    f'GoogleSignInExceptionCode.canceled, user {SECRET}, null)')
        other = f'Google login error: PlatformException(network_error, {SECRET}, null, null)'
        got = events(box('e', canceled, error=canceled[20:]) + box('e', other))
        self.assertEqual([e['event'] for e in got], ['native_auth_canceled', 'native_auth_failed'])
        self.assertNotIn(SECRET, json.dumps(got))

    def test_error_section_classes_follow_the_top_border(self):
        no_app = ("[core/no-app] No Firebase App '[DEFAULT]' has been created - call "
                  'Firebase.initializeApp()')
        no_supabase = (f'Bad state: Supabase가 초기화되지 않았습니다. initializeSupabase()를 먼저 '
                       f'호출하세요. 에러: {SECRET}')
        got = events(box('e', 'Push initialization step failed', error=no_app)
                     + box('e', 'Push initialization step failed', error=no_supabase))
        self.assertEqual([e['event'] for e in got], [
            'core_no_app', 'push_init_step_failed',
            'supabase_not_initialized', 'push_init_step_failed'])
        self.assertNotIn(SECRET, json.dumps(got))

    def test_a_box_without_a_stack_section_still_counts(self):
        self.assertEqual(events(box('i', 'Push token registered (took 7ms)', stack=False)),
                         [{'epoch_ms': TS_MS, 'event': 'registration_succeeded',
                           'duration_ms': 7}])

    def test_uncoloured_logger_output_is_accepted(self):
        self.assertEqual(events(box('i', 'Push token registered (took 7ms)', color=False)),
                         [{'epoch_ms': TS_MS, 'event': 'registration_succeeded',
                           'duration_ms': 7}])

    def test_microsecond_and_nanosecond_epoch_precision(self):
        for ts in ('1793750400.123456', '1793750400.123456789'):
            with self.subTest(ts=ts):
                self.assertEqual(events(box('i', 'Push token registered on retry', ts=ts)),
                                 [{'epoch_ms': TS_MS,
                                   'event': 'registration_succeeded_auth_retry'}])

    def test_source_is_a_fixed_choice(self):
        self.assertEqual(events(box('i', 'Push token registered on retry'), source='physical'),
                         [{'epoch_ms': TS_MS, 'event': 'registration_succeeded_auth_retry',
                           'source': 'physical'}])
        with self.assertRaises(ValueError):
            f.FcmEventFilter(source='pixel-7')


class NoLeakNoFabricationTest(unittest.TestCase):
    def test_account_object_with_an_allowed_marker_is_dropped(self):
        account = ('Google Sign In attempt result: GoogleSignInAccount:{displayName: Kim, '
                   'email: kim@example.com, id: 1180, photoUrl: https://x.test/p.png, '
                   'note: Google authentication tokens extracted}')
        self.assertEqual(events(box('d', account)), [])

    def test_a_marker_on_a_continuation_line_never_becomes_that_event(self):
        # A payload with a newline is printed as more message lines inside the
        # same box. Only the first line after a border can be an event.
        forged = (f'Failed to register push token: status=500, data={SECRET}\n'
                  'Push token registered (took 5ms)')
        foreground = ('[FCM] onMessage (foreground) title="hi" body="x\n'
                      'Push token registered (took 5ms)\nGoogle authentication tokens extracted"')
        got = events(box('e', forged) + box('i', foreground)
                     + box('d', 'Google Sign In attempt result: X\nGoogle authentication '
                                'tokens extracted'))
        self.assertEqual(got, [{'epoch_ms': TS_MS, 'event': 'registration_http_failed',
                                'status': 500}])

    def test_a_marker_at_the_wrong_level_is_not_an_event(self):
        self.assertEqual(events(box('e', 'Push token registered (took 5ms)')
                                + box('i', 'registerToken timeout after 12s')
                                + box('i', 'Google authentication tokens extracted')), [])

    def test_a_colour_that_disagrees_with_the_emoji_is_dropped(self):
        line = lc(paint('│ 💡 Push token registered (took 5ms)', 196))
        self.assertEqual(events([lc(paint(TOP, 196)), line]), [])

    def test_stack_and_error_body_lines_with_markers_are_dropped(self):
        lines = [lc(TOP),
                 lc('│ #0      main (package:picnic_lib/x.dart:1:1) Push token registered (took 5ms)'),
                 lc('│ #1      _rootRun (dart:async/zone.dart:1:1)'),
                 lc(MID),
                 lc('│ #2      Push token registered (took 5ms)'),
                 lc(TOP),
                 lc(f'│ AuthException(message: {SECRET}, statusCode: 400) [core/no-app] No Firebase'
                    " App '[DEFAULT]'"),
                 lc(MID),
                 lc(f'│ ⛔ Handling auth error: Error during sign in: {SECRET}')]
        self.assertEqual(events(lines), [])

    def test_an_error_class_after_a_middle_border_is_not_a_class(self):
        lines = [lc(TOP), lc('│ StateError: x'), lc(MID),
                 lc("│ [core/no-app] No Firebase App '[DEFAULT]' has been created"), lc(MID),
                 lc('│ Bad state: Supabase가 초기화되지 않았습니다. 에러: x')]
        self.assertEqual(events(lines), [])

    def test_the_second_error_line_is_not_a_class_even_with_the_marker(self):
        error = f'StateError: {SECRET}\n[core/no-app] No Firebase App \'[DEFAULT]\''
        self.assertEqual([e['event'] for e in events(box('e', 'Push initialization step failed',
                                                         error=error))],
                         ['push_init_step_failed'])

    def test_exact_literals_only(self):
        variants = [
            'Push token registered (took 5ms) ',
            'Push token registered  (took 5ms)',
            'Push token registered (took 5 ms)',
            'Push token registered (took 5ms) and more',
            'push token registered on retry',
            'Push token registered on retry!',
            'Registering push token to Supabase Edge: GET https://x.test',
            'Error during sign in: details',
            'Push initialization step failed: x',
            'Google login error:',
            'Failed to register push token: status=500 data=x',
            'Failed to register push token: status=5000, data=x',
        ]
        for message in variants:
            level = 'e' if message.startswith(('Error', 'Failed', 'Google', 'Push init')) else 'i'
            with self.subTest(message=message):
                self.assertEqual(events(box(level, message)), [])

    def test_bounded_numbers(self):
        for message in ('Push token registered (took 600001ms)',
                        'Push token registered (took -5ms)',
                        'Push token registered (took 00000000000000000001ms)'):
            with self.subTest(message=message):
                self.assertEqual(events(box('i', message)), [])
        for status in ('99', '600', '0', '-1', '5e2', '٥٠٠'):
            with self.subTest(status=status):
                self.assertEqual(events(box('e', f'Failed to register push token: '
                                                 f'status={status}, data=x')), [])

    def test_divider_state_is_per_process_and_thread(self):
        lines = [lc(paint(MID, 12), tid=1), lc(paint('│ 💡 Push token registered on retry', 12),
                                               tid=2)]
        self.assertEqual(events(lines), [])

    def test_events_never_carry_raw_fields(self):
        lines = box('i', 'Push token registered (took 1ms)', pid=31337, tid=31338)
        got = events(lines, source='emulator')
        self.assertEqual(len(got), 1)
        self.assertLessEqual(set(got[0]), SCHEMA)
        self.assertNotIn('31337', json.dumps(got))


class MalformedInputTest(unittest.TestCase):
    MESSAGE = '│ 💡 Push token registered on retry'

    def assert_dropped(self, line):
        self.assertEqual(events([lc(MID), line]), [], line)

    def test_malformed_prefixes(self):
        m = self.MESSAGE
        for line in (
            f'11-04 13:15:04.123  4321  4350 I flutter : {m}',          # -v time
            f'I/flutter ( 4321): {m}',                                 # -v brief
            f'1793750400  4321  4350 I flutter : {m}',                 # no fraction
            f'1793750400.12  4321  4350 I flutter : {m}',              # 2-digit fraction
            f'1793750400.123  4321 I flutter : {m}',                   # no tid
            f'1793750400.123  432x  4350 I flutter : {m}',
            f'1793750400.123  4321  4350 E flutter : {m}',             # not print()
            f'1793750400.123  4321  4350 I flutterx: {m}',
            f'1793750400.123  4321  4350 I FirebaseMessaging: {m}',
            f'1793750400.123  4321  4350 I flutter :{m}',
            f'1793750400.123 10123  4321  4350 I flutter : {m}',       # uid column
            f'-1793750400.123  4321  4350 I flutter : {m}',
            f'nan  4321  4350 I flutter : {m}',
            f'1793750400.123  0  4350 I flutter : {m}',
            f'1793750400.123  99999999  4350 I flutter : {m}',
        ):
            with self.subTest(line=line):
                self.assert_dropped(line)

    def test_implausible_epoch_is_dropped(self):
        for ts in ('1500000000.000', '4102444800.000', '99999999999.000', '0.000'):
            with self.subTest(ts=ts):
                self.assertEqual(events([lc(MID, ts=ts), lc(self.MESSAGE, ts=ts)]), [])

    def test_leftover_escape_sequences_are_dropped(self):
        self.assert_dropped(lc(f'{ESC}[1m{self.MESSAGE}{ESC}[0m'))
        self.assert_dropped(lc(f'{ESC}[38;5;12m{self.MESSAGE}'))
        self.assert_dropped(lc(f'{ESC}[38;5;12m│ 💡 Push {ESC}[0mtoken registered on retry'
                               f'{ESC}[0m'))

    def test_non_allowlisted_lines(self):
        for line in ('--------- beginning of main', '', '   ', 'random text',
                     lc('│ 💡 [FCM] App launched from a local notification'),
                     lc('│ 💡 SDK 초기화 완료'),
                     lc('│ ⛔ registerToken failed (_TypeError)')):
            with self.subTest(line=line):
                self.assertEqual(events([lc(MID), line]), [])

    def test_unparseable_lines_reset_the_border_state(self):
        self.assertEqual(events([lc(paint(MID, 12)), 'garbage between',
                                 lc(paint(self.MESSAGE, 12))]), [])

    def test_feed_rejects_non_text(self):
        self.assertIsNone(f.FcmEventFilter().feed(b'1793750400.123'))  # type: ignore[arg-type]


class CliTest(unittest.TestCase):
    def test_normal_output_is_schema_only_json_lines(self):
        data = joined(box('i', 'Push token registered (took 532ms)')
                      + box('e', f'Failed to register push token: status=500, data={SECRET}')
                      + box('d', f'Google Sign In attempt result: {SECRET}'))
        code, out, err = run_cli(['--source', 'emulator'], data)
        self.assertEqual((code, err), (0, ''))
        records = [json.loads(line) for line in out.splitlines()]
        self.assertEqual(records, [
            {'duration_ms': 532, 'epoch_ms': TS_MS, 'event': 'registration_succeeded',
             'source': 'emulator'},
            {'epoch_ms': TS_MS, 'event': 'registration_http_failed', 'source': 'emulator',
             'status': 500},
        ])
        for record in records:
            self.assertLessEqual(set(record), SCHEMA)
            self.assertIn(record['event'], f.EVENTS)
        self.assertNotIn(SECRET, out)

    def test_source_flag_forms(self):
        data = joined(box('i', 'Push token registered on retry'))
        for argv, source in (([], None), (['--source=physical'], 'physical'),
                             (['--source', 'emulator'], 'emulator')):
            with self.subTest(argv=argv):
                code, out, _ = run_cli(argv, data)
                self.assertEqual(code, 0)
                self.assertEqual(json.loads(out).get('source'), source)

    def test_invalid_arguments_get_a_fixed_diagnostic(self):
        for argv in (['--source', SECRET], [f'--source={SECRET}'], [f'--token={SECRET}'],
                     ['--source'], ['--source', 'emulator', 'extra', SECRET], [SECRET]):
            with self.subTest(argv=argv):
                code, out, err = run_cli(argv, joined(box('i', 'Push token registered on retry')))
                self.assertEqual((code, out), (2, ''))
                self.assertEqual(err, f.USAGE_DIAGNOSTIC)
                self.assertNotIn(SECRET, err)

    def test_an_internal_failure_never_echoes_the_input(self):
        def boom(self, line):
            raise RuntimeError(f'cannot parse {line}')
        data = joined(box('i', f'Push token registered on retry {SECRET}'))
        with mock.patch.object(f.FcmEventFilter, 'feed', boom):
            code, out, err = run_cli([], data)
        self.assertEqual((code, out, err), (70, '', f.INTERNAL_DIAGNOSTIC))

    def test_invalid_utf8_is_dropped_silently(self):
        data = (joined([lc(MID)]).encode() + b'\xff\xfe' + SECRET.encode() + b'\n'
                + joined(box('i', 'Push token registered on retry')).encode())
        code, out, err = run_cli([], data)
        self.assertEqual((code, err), (0, ''))
        self.assertEqual([json.loads(line)['event'] for line in out.splitlines()],
                         ['registration_succeeded_auth_retry'])

    def test_an_oversized_record_is_discarded_whole_and_resets_state(self):
        event_line = '│ 💡 Push token registered (took 9ms)'
        # The oversized record is a divider line whose tail looks like an event.
        oversized = (lc(paint(MID, 12)) + 'A' * f.MAX_RECORD_BYTES + SECRET
                     + paint(event_line, 12))
        data = joined([lc(paint(MID, 12)), oversized, lc(paint(event_line, 12))]
                      + box('i', 'Push token registered on retry'))
        code, out, err = run_cli([], data)
        self.assertEqual((code, err), (0, ''))
        # No tail of the oversized record survives, the event right after it has
        # lost its divider, and the next complete box is reported again.
        self.assertEqual([json.loads(line)['event'] for line in out.splitlines()],
                         ['registration_succeeded_auth_retry'])
        self.assertNotIn(SECRET, out)
        self.assertNotIn('AAAA', out)

    def test_the_tail_of_an_oversized_record_is_never_read_as_a_record(self):
        # The last bounded chunk of this record is a complete border record.
        # Reading it would arm the event line that follows.
        first_chunk = 'Z' * (f.MAX_RECORD_BYTES + 2)
        data = joined([first_chunk + lc(paint(MID, 12)),
                       lc(paint('│ 💡 Push token registered (took 9ms)', 12))])
        self.assertEqual(run_cli([], data), (0, '', ''))

    def test_the_record_size_bound_is_exact(self):
        head = lc(paint(MID, 12)) + '\n'
        start = lc('│ 💡 Registering push token to Supabase Edge: POST ')
        for extra, expected in ((0, ['registration_started']), (1, [])):
            pad = f.MAX_RECORD_BYTES - len(start.encode()) + extra
            line = start + 'x' * pad
            with self.subTest(size=len(line.encode())):
                code, out, _ = run_cli([], head + line + '\n')
                self.assertEqual(code, 0)
                self.assertEqual([json.loads(r)['event'] for r in out.splitlines()], expected)

    def test_oversized_records_of_many_chunks_and_at_eof(self):
        huge = lc('A' * (f.MAX_RECORD_BYTES * 5)) + SECRET
        data = joined([huge] + box('i', 'Push token registered on retry')) + huge
        code, out, err = run_cli([], data)
        self.assertEqual((code, err), (0, ''))
        self.assertEqual([json.loads(line)['event'] for line in out.splitlines()],
                         ['registration_succeeded_auth_retry'])

    def test_crlf_line_endings(self):
        data = joined(box('i', 'Push token registered on retry')).replace('\n', '\r\n')
        code, out, _ = run_cli([], data)
        self.assertEqual(json.loads(out)['event'], 'registration_succeeded_auth_retry')

    def test_output_is_streamed_per_event(self):
        lines = [line.encode() + b'\n' for line in
                 box('i', 'Push token registered on retry') + box('i', 'SDK 초기화 완료')]
        seen_before_next_read = []

        class Writer:  # Only flushed text counts as delivered to the pipe.
            def __init__(self):
                self.pending, self.delivered = '', ''

            def write(self, text):
                self.pending += text

            def flush(self):
                self.delivered, self.pending = self.delivered + self.pending, ''

        stdout = Writer()

        class Reader:
            def readline(self, size=-1):
                seen_before_next_read.append(stdout.delivered)
                return lines.pop(0) if lines else b''

        code = f.main([], stdin=Reader(), stdout=stdout, stderr=io.StringIO())
        self.assertEqual(code, 0)
        # Line 4 of the box is the event. It is delivered before line 5 is read.
        self.assertEqual(seen_before_next_read[4], '')
        self.assertIn('registration_succeeded_auth_retry', seen_before_next_read[5])

    def test_the_real_entry_point_over_a_pipe(self):
        data = joined(box('i', 'Push token registered (took 5ms)')
                      + box('e', f'registerToken function error: status=401, details={SECRET}'))
        done = subprocess.run([sys.executable, '-I', str(HERE / 'fcm_event_filter.py'),
                               '--source', 'physical'], input=data.encode(),
                              capture_output=True, timeout=60, check=False)
        self.assertEqual((done.returncode, done.stderr), (0, b''))
        self.assertEqual([json.loads(line) for line in done.stdout.decode().splitlines()], [
            {'duration_ms': 5, 'epoch_ms': TS_MS, 'event': 'registration_succeeded',
             'source': 'physical'},
            {'epoch_ms': TS_MS, 'event': 'registration_function_error', 'source': 'physical',
             'status': 401}])
        bad = subprocess.run([sys.executable, '-I', str(HERE / 'fcm_event_filter.py'),
                              '--source', SECRET], input=data.encode(), capture_output=True,
                             timeout=60, check=False)
        self.assertEqual((bad.returncode, bad.stdout), (2, b''))
        self.assertEqual(bad.stderr.decode(), f.USAGE_DIAGNOSTIC)

    def test_the_module_launches_nothing_and_opens_nothing(self):
        source = (HERE / 'fcm_event_filter.py').read_text()
        for banned in ('subprocess', 'socket', 'urllib', 'http.client', 'open(', 'os.system',
                       'Popen', 'traceback', 'logging'):
            with self.subTest(banned=banned):
                self.assertNotIn(banned, source)


if __name__ == '__main__':
    unittest.main()
