"""Regression tests for run_notification_delivery_ios.py.

Run from the repository root:
    python3 scripts/qa/test_run_notification_delivery_ios.py -v

No simulator, Xcode build, CocoaPods, network, or GUI is used. Simulator
mutations (install, launch, push, terminate, uninstall) go to FakeSimulator,
and the build step is replaced. A pass proves only the runner's payload,
evidence, acknowledgement, ownership, project-edit and cleanup decisions. It
is not a native simulator, notification display or tap result. Product files
are read, never written.
"""
import contextlib
import io
import json
import os
from pathlib import Path
import plistlib
import sys
import tempfile
import textwrap
import time
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_notification_delivery_ios as runner  # noqa: E402
import run_firebase_device_ios as ios_base  # noqa: E402

ROOT_DIR = Path(__file__).resolve().parents[2]
SIM_UDID = 'A1B2C3D4-1111-4222-8333-0000000000AA'
RUNTIME = 'com.apple.CoreSimulator.SimRuntime.iOS-26-5'
NONCE = '0123456789abcdef0123456789abcdef'
MESSAGE_NONCE = 'fedcba9876543210fedcba9876543210'
MESSAGE_ID = 'qa-ios-sim-' + MESSAGE_NONCE
ACTION_URL = 'https://applink.picnic.fan/vote/list'
PID = 4242
ACK_TOKEN = '5a' * 16
LAUNCH_MS = 1_800_000_000_000
PUSH_MS = LAUNCH_MS + 60_000
NOW_MS = LAUNCH_MS + 600_000
EVIDENCE_PATH = ('/sim/data/Containers/Data/Application/X/Library/Caches/'
                 'notification-delivery-ios.json')
# What the locked path_provider_foundation 2.6.0 returns for
# getTemporaryDirectory on iOS (NSCachesDirectory), relative to the data
# container. The cross-language check that the ACTUAL app writer and the
# runner agree is picnic_app/test/notification_delivery/evidence_path_test.dart.
PROVIDER_TEMPORARY_DIR = 'Library/Caches'


def identity(push_started_ms=PUSH_MS):
    return runner.RunIdentity(
        nonce=NONCE, pid=PID, evidence_path=EVIDENCE_PATH,
        launch_started_ms=LAUNCH_MS, push_started_ms=push_started_ms,
        message_id=MESSAGE_ID if push_started_ms is not None else None)


# Hand-written lifecycle of a good run, in order. Each tuple is
# (milestone reached after this event, event fields without seq).
def good_events(upto='list_filtered'):
    t = LAUNCH_MS
    steps = [
        ('started', {'type': 'launched', 'wallMs': t + 10, 'nonceValid': True}),
        (None, {'type': 'auth_state', 'wallMs': t + 20, 'signedIn': False,
                'loopbackHost': '127.0.0.1'}),
        (None, {'type': 'firebase_ready', 'wallMs': t + 30, 'defaultApp': True,
                'autoInit': False}),
        (None, {'type': 'coordinator_created', 'wallMs': t + 40}),
        (None, {'type': 'push_initialize_started', 'wallMs': t + 41}),
        (None, {'type': 'local_notifications_skipped', 'wallMs': t + 42}),
        (None, {'type': 'permission_requested', 'wallMs': t + 43}),
        (None, {'type': 'navigation', 'wallMs': t + 44, 'stackTop': 'VoteHomePage',
                'stackLength': 1, 'portal': 'vote'}),
        ('before', {'type': 'before_screen', 'wallMs': t + 50,
                    'marker': 'qa-notification-delivery-before',
                    'stackTop': 'VoteHomePage'}),
        (None, {'type': 'initial_message', 'wallMs': t + 60, 'isNull': True,
                'messageId': None}),
        (None, {'type': 'permission_result', 'wallMs': t + 9000, 'status': 'authorized'}),
        (None, {'type': 'token_requested', 'wallMs': t + 9010, 'returned': None}),
        ('permission', {'type': 'topic_noop', 'wallMs': t + 9020}),
        (None, {'type': 'push_initialize_done', 'wallMs': t + 9030}),
        (None, {'type': 'lifecycle', 'wallMs': t + 20000, 'state': 'inactive'}),
        (None, {'type': 'lifecycle', 'wallMs': t + 20001, 'state': 'hidden'}),
        ('paused', {'type': 'lifecycle', 'wallMs': t + 20002, 'state': 'paused'}),
        (None, {'type': 'lifecycle', 'wallMs': PUSH_MS + 5000, 'state': 'resumed'}),
        (None, {'type': 'opened', 'wallMs': PUSH_MS + 5010, 'messageId': MESSAGE_ID,
                'actionUrl': ACTION_URL,
                'dataKeys': ['action_url']}),
        ('opened', {'type': 'tap_forwarded', 'wallMs': PUSH_MS + 5011,
                    'messageId': MESSAGE_ID}),
        ('navigated', {'type': 'navigation', 'wallMs': PUSH_MS + 5050,
                       'stackTop': 'VoteListPage', 'stackLength': 2, 'portal': 'vote'}),
        (None, {'type': 'list_state', 'wallMs': PUSH_MS + 5100,
                'voteLists': [{'area': 'all', 'status': 'active'}], 'cardIds': [],
                'selectedChips': ['ALL'], 'statusValues': ['active']}),
        ('list_active', {'type': 'list_state', 'wallMs': PUSH_MS + 5500,
                         'voteLists': [{'area': 'all', 'status': 'active'}],
                         'cardIds': [910001], 'selectedChips': ['ALL'],
                         'statusValues': ['active']}),
        (None, {'type': 'list_state', 'wallMs': PUSH_MS + 30000,
                'voteLists': [{'area': 'kpop', 'status': 'active'}],
                'cardIds': [910001], 'selectedChips': ['PICNIC'],
                'statusValues': ['active']}),
        ('list_filtered', {'type': 'list_state', 'wallMs': PUSH_MS + 40000,
                           'voteLists': [{'area': 'kpop', 'status': 'end'}],
                           'cardIds': [910003], 'selectedChips': ['PICNIC'],
                           'statusValues': ['end']}),
    ]
    events = []
    for milestone, fields in steps:
        events.append(dict(fields))
        if milestone == upto:
            break
    for index, event in enumerate(events, 1):
        event['seq'] = index
    return events


GOOD_REQUESTS = [
    {'method': 'GET', 'path': '/rest/v1/vote', 'statusCode': 200, 'area': 'all',
     'voteStatus': 'active', 'ids': [910001, 910002]},
    {'method': 'GET', 'path': '/rest/v1/vote', 'statusCode': 200, 'area': 'kpop',
     'voteStatus': 'active', 'ids': [910001]},
    {'method': 'GET', 'path': '/rest/v1/vote', 'statusCode': 200, 'area': 'kpop',
     'voteStatus': 'end', 'ids': [910003]},
]


def document(events, requests=GOOD_REQUESTS, **overrides):
    doc = {'schema': 'picnic-notification-delivery-ios/1', 'runNonce': NONCE, 'pid': PID,
           'evidencePath': EVIDENCE_PATH, 'events': events,
           'loopback': {'requests': requests, 'unexpected': []}}
    doc.update(overrides)
    return doc


def renumber(events):
    for index, event in enumerate(events, 1):
        event['seq'] = index
    return events


def validate(doc, run=None):
    return runner.validate_evidence(doc, run or identity(), now_ms=NOW_MS)


class PayloadTest(unittest.TestCase):
    def test_the_payload_has_the_exact_target_alert_id_and_action_url(self):
        payload = runner.build_payload(MESSAGE_NONCE)
        self.assertEqual(payload, {
            'Simulator Target Bundle': 'io.picnic.qa.notificationDelivery',
            'aps': {'alert': {'title': 'Picnic QA',
                              'body': 'Tap to open the vote list'},
                    'sound': 'default'},
            'gcm.message_id': MESSAGE_ID,
            'action_url': ACTION_URL,
        })

    def test_the_encoded_payload_is_json_within_the_apns_limit(self):
        data = runner.encode_payload(runner.build_payload(MESSAGE_NONCE))
        self.assertLessEqual(len(data), 4096)
        self.assertEqual(json.loads(data)['gcm.message_id'], MESSAGE_ID)

    def test_an_oversized_payload_is_refused(self):
        payload = runner.build_payload(MESSAGE_NONCE)
        payload['padding'] = 'x' * 5000
        with self.assertRaises(runner.RunnerError):
            runner.encode_payload(payload)

    def test_a_message_nonce_that_is_not_32_hex_characters_is_refused(self):
        for bad in ('', 'abc', NONCE.upper(), NONCE + '0', 'g' * 32):
            with self.subTest(bad=bad), self.assertRaises(runner.RunnerError):
                runner.build_payload(bad)

    def test_new_nonces_are_distinct_32_hex_strings(self):
        values = {runner.new_nonce() for _ in range(20)}
        self.assertEqual(len(values), 20)
        for value in values:
            self.assertRegex(value, r'^[0-9a-f]{32}$')


class EvidenceValidatorTest(unittest.TestCase):
    def test_a_complete_good_run_reaches_every_milestone(self):
        progress = validate(document(good_events()))
        self.assertEqual(progress, {name: True for name in runner.MILESTONES})

    def test_partial_evidence_reports_only_the_milestones_reached(self):
        progress = validate(document(good_events('paused')), identity(None))
        self.assertTrue(progress['paused'])
        self.assertFalse(progress['opened'])
        self.assertFalse(progress['list_filtered'])

    def test_evidence_from_another_run_nonce_is_stale(self):
        with self.assertRaisesRegex(runner.RunnerError, 'nonce'):
            validate(document(good_events(), runNonce='f' * 32))

    def test_evidence_from_another_process_is_stale(self):
        with self.assertRaisesRegex(runner.RunnerError, 'pid'):
            validate(document(good_events(), pid=PID + 1))

    def test_evidence_written_before_the_launch_is_stale(self):
        events = good_events()
        events[0]['wallMs'] = LAUNCH_MS - 1
        with self.assertRaisesRegex(runner.RunnerError, 'before the launch'):
            validate(document(events))

    def test_evidence_at_another_path_is_rejected(self):
        with self.assertRaisesRegex(runner.RunnerError, 'path'):
            validate(document(good_events(), evidencePath='/elsewhere/x.json'))

    def test_a_wrong_schema_is_rejected(self):
        with self.assertRaises(runner.RunnerError):
            validate(document(good_events(), schema='other/1'))

    def test_a_non_dictionary_document_is_malformed(self):
        for bad in ([], 'text', None, {'events': 'x'}):
            with self.subTest(bad=bad), self.assertRaises(runner.RunnerError):
                validate(bad)

    def test_a_sequence_gap_is_rejected(self):
        events = good_events()
        events[5]['seq'] = 99
        with self.assertRaisesRegex(runner.RunnerError, 'seq'):
            validate(document(events))

    def test_time_that_goes_backwards_is_rejected(self):
        events = good_events()
        events[10]['wallMs'] = events[9]['wallMs'] - 1
        with self.assertRaisesRegex(runner.RunnerError, 'time'):
            validate(document(events))

    def test_an_unknown_event_type_is_rejected(self):
        events = good_events()
        events.insert(3, {'type': 'navigated_by_qa', 'wallMs': LAUNCH_MS + 35})
        with self.assertRaisesRegex(runner.RunnerError, 'unknown'):
            validate(document(renumber(events)))

    def test_a_wrong_message_id_is_rejected(self):
        events = good_events()
        for event in events:
            if event.get('messageId') == MESSAGE_ID:
                event['messageId'] = 'qa-ios-sim-' + '0' * 32
        with self.assertRaisesRegex(runner.RunnerError, 'message'):
            validate(document(events))

    def test_a_message_id_prefix_alone_is_not_the_message(self):
        events = good_events()
        for event in events:
            if event.get('messageId') == MESSAGE_ID:
                event['messageId'] = MESSAGE_ID[:-1]
        with self.assertRaises(runner.RunnerError):
            validate(document(events))

    def test_a_wrong_action_url_is_rejected(self):
        events = good_events()
        next(e for e in events if e['type'] == 'opened')['actionUrl'] = ACTION_URL + '?x=1'
        with self.assertRaisesRegex(runner.RunnerError, 'action'):
            validate(document(events))

    def test_a_duplicate_opened_event_is_rejected(self):
        events = good_events()
        index = next(i for i, e in enumerate(events) if e['type'] == 'tap_forwarded')
        same_time = events[index]['wallMs']
        events.insert(index + 1, dict(events[index - 1], wallMs=same_time))
        events.insert(index + 2, dict(events[index], wallMs=same_time))
        with self.assertRaisesRegex(runner.RunnerError, 'more than one'):
            validate(document(renumber(events)))

    def test_an_opened_event_before_the_push_is_rejected(self):
        events = good_events()
        next(e for e in events if e.get('state') == 'resumed')['wallMs'] = PUSH_MS - 2
        next(e for e in events if e['type'] == 'opened')['wallMs'] = PUSH_MS - 1
        with self.assertRaisesRegex(runner.RunnerError, 'before the push'):
            validate(document(renumber(events)))

    def test_an_opened_event_before_any_push_was_sent_is_rejected(self):
        with self.assertRaisesRegex(runner.RunnerError, 'before the push'):
            validate(document(good_events('opened')), identity(None))

    def test_an_opened_event_without_a_prior_pause_is_out_of_order(self):
        events = [e for e in good_events() if e.get('state') != 'paused']
        with self.assertRaisesRegex(runner.RunnerError, 'paused'):
            validate(document(renumber(events)))

    def test_the_vote_list_before_the_tap_is_rejected(self):
        events = good_events()
        events.insert(9, {'type': 'navigation', 'wallMs': LAUNCH_MS + 55,
                          'stackTop': 'VoteListPage', 'stackLength': 2, 'portal': 'vote'})
        with self.assertRaisesRegex(runner.RunnerError, 'before the notification'):
            validate(document(renumber(events)))

    def test_a_list_state_before_the_tap_is_rejected(self):
        events = good_events()
        events.insert(9, dict(good_events()[-1], wallMs=LAUNCH_MS + 55))
        with self.assertRaisesRegex(runner.RunnerError, 'before the notification'):
            validate(document(renumber(events)))

    def test_a_start_screen_that_is_the_vote_list_is_not_distinct(self):
        events = good_events()
        next(e for e in events if e['type'] == 'before_screen')['stackTop'] = 'VoteListPage'
        with self.assertRaises(runner.RunnerError):
            validate(document(events))

    def test_a_missing_start_screen_blocks_the_before_milestone(self):
        events = [e for e in good_events('paused') if e['type'] != 'before_screen']
        progress = validate(document(renumber(events)), identity(None))
        self.assertFalse(progress['before'])
        self.assertFalse(progress['paused'])

    def test_a_non_null_initial_message_is_rejected(self):
        events = good_events()
        initial = next(e for e in events if e['type'] == 'initial_message')
        initial.update(isNull=False, messageId=MESSAGE_ID)
        with self.assertRaisesRegex(runner.RunnerError, 'initial message'):
            validate(document(events))

    def test_a_denied_permission_is_rejected(self):
        events = good_events()
        next(e for e in events if e['type'] == 'permission_result')['status'] = 'denied'
        with self.assertRaisesRegex(runner.RunnerError, 'permission'):
            validate(document(events))

    def test_a_returned_token_is_rejected(self):
        events = good_events()
        next(e for e in events if e['type'] == 'token_requested')['returned'] = 'tok'
        with self.assertRaisesRegex(runner.RunnerError, 'token'):
            validate(document(events))

    def test_a_signed_in_state_is_rejected(self):
        events = good_events()
        next(e for e in events if e['type'] == 'auth_state')['signedIn'] = True
        with self.assertRaisesRegex(runner.RunnerError, 'signed'):
            validate(document(events))

    def test_messaging_auto_init_on_is_rejected(self):
        events = good_events()
        next(e for e in events if e['type'] == 'firebase_ready')['autoInit'] = True
        with self.assertRaisesRegex(runner.RunnerError, 'auto-init'):
            validate(document(events))

    def test_a_backend_registration_is_rejected(self):
        events = good_events()
        events.insert(12, {'type': 'register_noop', 'wallMs': LAUNCH_MS + 9015})
        with self.assertRaisesRegex(runner.RunnerError, 'registration'):
            validate(document(renumber(events)))

    def test_an_uncaught_error_is_rejected(self):
        events = good_events()
        events.append({'type': 'uncaught_error', 'wallMs': PUSH_MS + 50000,
                       'exception': 'StateError'})
        with self.assertRaisesRegex(runner.RunnerError, 'error'):
            validate(document(renumber(events)))

    def test_a_flutter_error_outside_image_loading_is_rejected(self):
        events = good_events()
        events.append({'type': 'flutter_error', 'wallMs': PUSH_MS + 50000,
                       'library': 'rendering library', 'exception': 'FlutterError'})
        with self.assertRaises(runner.RunnerError):
            validate(document(renumber(events)))

    def test_an_image_loading_error_is_tolerated(self):
        events = good_events()
        events.append({'type': 'flutter_error', 'wallMs': PUSH_MS + 50000,
                       'library': 'image resource service', 'exception': 'HttpException'})
        self.assertTrue(validate(document(renumber(events)))['list_filtered'])

    def test_an_event_overflow_is_rejected(self):
        events = good_events()
        events.append({'type': 'overflow', 'wallMs': PUSH_MS + 50000})
        with self.assertRaisesRegex(runner.RunnerError, 'overflow'):
            validate(document(renumber(events)))

    def test_a_list_with_unexpected_rows_does_not_reach_the_active_milestone(self):
        events = good_events()
        for event in events:
            if event['type'] == 'list_state' and event['cardIds'] == [910001]:
                event['cardIds'] = [910003]
        progress = validate(document(events))
        self.assertFalse(progress['list_active'])

    def test_the_filtered_milestone_needs_the_picnic_chip_and_ended_status(self):
        events = good_events()
        events[-1]['selectedChips'] = ['ALL']
        events[-1]['voteLists'] = [{'area': 'all', 'status': 'end'}]
        self.assertFalse(validate(document(events))['list_filtered'])

    def test_the_filtered_milestone_needs_the_served_kpop_end_request(self):
        requests = [r for r in GOOD_REQUESTS if r['voteStatus'] != 'end']
        self.assertFalse(validate(document(good_events(), requests))['list_filtered'])

    def test_the_active_milestone_needs_the_served_active_request(self):
        requests = [r for r in GOOD_REQUESTS if r['area'] != 'all']
        self.assertFalse(validate(document(good_events(), requests))['list_active'])


class ReadEvidenceTest(unittest.TestCase):
    def setUp(self):
        self.dir = Path(tempfile.mkdtemp())

    def test_a_missing_file_is_none(self):
        self.assertIsNone(runner.read_evidence(self.dir / 'missing.json'))

    def test_invalid_json_is_malformed(self):
        path = self.dir / 'e.json'
        path.write_text('{"events": [')
        with self.assertRaisesRegex(runner.RunnerError, 'malformed'):
            runner.read_evidence(path)

    def test_an_oversized_file_is_refused(self):
        path = self.dir / 'e.json'
        path.write_text(json.dumps({'x': 'y' * (runner.MAX_EVIDENCE_BYTES + 1)}))
        with self.assertRaisesRegex(runner.RunnerError, 'bytes'):
            runner.read_evidence(path)

    def test_a_symlink_is_refused(self):
        target = self.dir / 'target.json'
        target.write_text('{}')
        link = self.dir / 'e.json'
        link.symlink_to(target)
        with self.assertRaisesRegex(runner.RunnerError, 'regular'):
            runner.read_evidence(link)


class AckTest(unittest.TestCase):
    def setUp(self):
        self.dir = Path(tempfile.mkdtemp())
        self.path = self.dir / 'notification-displayed'
        self.token = 'a' * 32

    def test_a_missing_ack_is_not_yet_given(self):
        self.assertFalse(runner.check_ack(self.path, self.token, time.time() - 5))

    def test_the_exact_token_written_after_the_prompt_is_accepted(self):
        prompt = time.time() - 5
        self.path.write_text(self.token + '\n')
        self.assertTrue(runner.check_ack(self.path, self.token, prompt))

    def test_another_token_is_rejected(self):
        self.path.write_text('b' * 32)
        with self.assertRaisesRegex(runner.RunnerError, 'token'):
            runner.check_ack(self.path, self.token, time.time() - 5)

    def test_an_ack_older_than_the_prompt_is_stale(self):
        self.path.write_text(self.token)
        old = time.time() - 600
        os.utime(self.path, (old, old))
        with self.assertRaisesRegex(runner.RunnerError, 'stale'):
            runner.check_ack(self.path, self.token, time.time() - 5)

    def test_a_symlinked_ack_is_rejected(self):
        target = self.dir / 'elsewhere'
        target.write_text(self.token)
        self.path.symlink_to(target)
        with self.assertRaises(runner.RunnerError):
            runner.check_ack(self.path, self.token, time.time() - 5)


TEMPLATE_DIR = ROOT_DIR / '.superpowers/sentry-t1/ios-delivery-plan'


def write_template(ios):
    """The installed Flutter 3.41.4 iOS template files the runner checks."""
    (ios / 'Runner').mkdir(parents=True)
    (ios / 'Runner.xcodeproj').mkdir()
    (ios / 'Runner/AppDelegate.swift').write_text(runner.TEMPLATE_APP_DELEGATE)
    (ios / 'Runner/SceneDelegate.swift').write_text(runner.TEMPLATE_SCENE_DELEGATE)
    with open(ios / 'Runner/Info.plist', 'wb') as out:
        plistlib.dump({
            'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)',
            'UIApplicationSceneManifest': {
                'UIApplicationSupportsMultipleScenes': False,
                'UISceneConfigurations': {'UIWindowSceneSessionRoleApplication': [{
                    'UISceneConfigurationName': 'flutter',
                    'UISceneDelegateClassName': '$(PRODUCT_MODULE_NAME).SceneDelegate',
                    'UISceneStoryboardFile': 'Main'}]}},
        }, out)


GENERATED_PBXPROJ = textwrap.dedent('''\
    \t\t331C8080294A63A400263BE5 /* RunnerTests */ = {
    \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = io.picnic.qa.picnicApp.RunnerTests;
    \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = io.picnic.qa.picnicApp.RunnerTests;
    \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = io.picnic.qa.picnicApp.RunnerTests;
    \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = io.picnic.qa.picnicApp;
    \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = io.picnic.qa.picnicApp;
    \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = io.picnic.qa.picnicApp;
    ''')


class TemplateTest(unittest.TestCase):
    def setUp(self):
        self.ios = Path(tempfile.mkdtemp()) / 'ios'
        write_template(self.ios)

    def test_the_template_constants_match_the_installed_template_snapshot(self):
        if not TEMPLATE_DIR.is_dir():
            self.skipTest('template snapshot not present')
        self.assertEqual(runner.TEMPLATE_APP_DELEGATE,
                         (TEMPLATE_DIR / 'TemplateAppDelegate.swift').read_text())
        self.assertEqual(runner.TEMPLATE_SCENE_DELEGATE,
                         (TEMPLATE_DIR / 'TemplateSceneDelegate.swift').read_text())

    def test_the_expected_template_gets_only_the_notification_delegate(self):
        runner.check_ios_template(self.ios)
        runner.write_qa_app_delegate(self.ios)
        text = (self.ios / 'Runner/AppDelegate.swift').read_text()
        self.assertIn('UNUserNotificationCenter.current().delegate = self', text)
        self.assertNotIn('registerForRemoteNotifications', text)
        self.assertIn('import UserNotifications\n', text)
        self.assertEqual(
            text.replace(runner.QA_DELEGATE_LINES, '').replace(runner.QA_IMPORT_LINE, ''),
            runner.TEMPLATE_APP_DELEGATE)

    def test_an_unexpected_app_delegate_is_rejected(self):
        path = self.ios / 'Runner/AppDelegate.swift'
        path.write_text(path.read_text().replace('FlutterImplicitEngineDelegate', 'Other'))
        with self.assertRaisesRegex(runner.RunnerError, 'AppDelegate'):
            runner.check_ios_template(self.ios)

    def test_an_unexpected_scene_delegate_is_rejected(self):
        (self.ios / 'Runner/SceneDelegate.swift').write_text('class SceneDelegate {}\n')
        with self.assertRaisesRegex(runner.RunnerError, 'SceneDelegate'):
            runner.check_ios_template(self.ios)

    def test_a_template_without_the_scene_manifest_is_rejected(self):
        with open(self.ios / 'Runner/Info.plist', 'wb') as out:
            plistlib.dump({'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)'}, out)
        with self.assertRaisesRegex(runner.RunnerError, 'scene'):
            runner.check_ios_template(self.ios)

    def test_the_generated_bundle_ids_are_rewritten_with_the_tests_suffix(self):
        text = runner.rewrite_bundle_ids(GENERATED_PBXPROJ)
        self.assertEqual(text.count(
            'PRODUCT_BUNDLE_IDENTIFIER = io.picnic.qa.notificationDelivery;'), 3)
        self.assertEqual(text.count(
            'PRODUCT_BUNDLE_IDENTIFIER = io.picnic.qa.notificationDelivery.RunnerTests;'), 3)
        self.assertNotIn('picnicApp', text)

    def test_an_unexpected_generated_bundle_id_is_rejected(self):
        for bad in (GENERATED_PBXPROJ.replace('picnicApp;', 'picnicApp2;', 1),
                    GENERATED_PBXPROJ + '\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = '
                                        'io.iconcasting.picnic.app;\n',
                    GENERATED_PBXPROJ.replace(
                        'PRODUCT_BUNDLE_IDENTIFIER = io.picnic.qa.picnicApp;\n', '', 1)):
            with self.subTest(bad=bad[-60:]), self.assertRaises(runner.RunnerError):
                runner.rewrite_bundle_ids(bad)


class PubspecAndLockTest(unittest.TestCase):
    PRODUCT = textwrap.dedent('''\
        name: picnic_app
        version: 1.3.6+130605
        environment:
            sdk: '>=3.3.1 <4.0.0'
        dependencies:
            flutter:
                sdk: flutter
            picnic_lib:
                path: ../picnic_lib
            intl: ^0.20.2
        dev_dependencies:
            firebase_messaging: ^17.0.1
            flutter_test:
                sdk: flutter
        flutter:
            uses-material-design: true
            assets:
                - config/
                - assets/login/
                - shorebird.yaml
        ''')

    def test_the_qa_pubspec_keeps_cocoapods_and_only_picnic_lib_by_path(self):
        text = runner.build_qa_pubspec(self.PRODUCT, Path('/abs/picnic_lib'),
                                       {'firebase_core_platform_interface': '6.0.2'},
                                       ['assets/login/'])
        self.assertRegex(text, r'(?m)^name: picnic_app$')
        self.assertRegex(text, r'(?m)^flutter:\n(?:    .*\n)*    config:\n'
                               r'        enable-swift-package-manager: false\n')
        self.assertEqual(text.count('path:'), 1)
        self.assertIn('path: "/abs/picnic_lib"', text)
        self.assertNotIn('config/', text)
        self.assertNotIn('shorebird.yaml', text)

    def test_a_lock_that_drifts_from_the_product_lock_is_rejected(self):
        directory = Path(tempfile.mkdtemp())
        lock = textwrap.dedent('''\
            packages:
              firebase_core:
                dependency: "direct main"
                description:
                  name: firebase_core
                source: hosted
                version: "{version}"
            sdks:
              dart: ">=3.9.0 <4.0.0"
            ''')
        (directory / 'product.lock').write_text(lock.format(version='5.1.0'))
        (directory / 'qa.lock').write_text(lock.format(version='5.2.0'))
        with self.assertRaisesRegex(runner.RunnerError, 'lock'):
            runner.check_locks(directory / 'product.lock', directory / 'qa.lock')

    def test_a_pinned_package_that_was_not_resolved_is_rejected(self):
        directory = Path(tempfile.mkdtemp())
        lock = 'packages:\n  intl:\n    dependency: "direct main"\n    version: "0.20.2"\n'
        (directory / 'product.lock').write_text(lock)
        (directory / 'qa.lock').write_text(lock)
        with self.assertRaisesRegex(runner.RunnerError, 'firebase_core'):
            runner.check_locks(directory / 'product.lock', directory / 'qa.lock')

    def test_the_qa_sources_go_to_lib_and_never_overwrite_a_product_file(self):
        workspace = Path(tempfile.mkdtemp())
        (workspace / 'lib').mkdir()
        files = runner.copy_qa_sources(workspace)
        self.assertEqual(sorted(files), [
            'notification_delivery/vote_list_loopback.dart',
            'notification_delivery_ios_qa.dart'])
        self.assertTrue((workspace / runner.ENTRY).is_file())
        with self.assertRaisesRegex(runner.RunnerError, 'exists'):
            runner.copy_qa_sources(workspace)


class BuiltAppTest(unittest.TestCase):
    def setUp(self):
        self.app = Path(tempfile.mkdtemp()) / 'Runner.app'
        (self.app / 'Frameworks/App.framework/flutter_assets/assets/login').mkdir(parents=True)
        (self.app / 'Frameworks/App.framework/flutter_assets/assets/login/a.png').write_bytes(b'x')
        plist = dict(ios_base.QA_PLIST_SETTINGS, CFBundleIdentifier=runner.BUNDLE_ID)
        with open(self.app / 'Info.plist', 'wb') as out:
            plistlib.dump(plist, out)

    def test_a_clean_build_with_the_qa_bundle_and_settings_passes(self):
        report = runner.check_built_app(self.app)
        self.assertEqual(report['bundle_id'], runner.BUNDLE_ID)

    def test_another_bundle_identifier_is_rejected(self):
        with open(self.app / 'Info.plist', 'rb') as source:
            plist = plistlib.load(source)
        plist['CFBundleIdentifier'] = 'io.picnic.qa.picnicApp'
        with open(self.app / 'Info.plist', 'wb') as out:
            plistlib.dump(plist, out)
        with self.assertRaisesRegex(runner.RunnerError, 'CFBundleIdentifier'):
            runner.check_built_app(self.app)

    def test_a_messaging_auto_init_setting_that_changed_is_rejected(self):
        with open(self.app / 'Info.plist', 'rb') as source:
            plist = plistlib.load(source)
        plist['FirebaseMessagingAutoInitEnabled'] = True
        with open(self.app / 'Info.plist', 'wb') as out:
            plistlib.dump(plist, out)
        with self.assertRaises(runner.RunnerError):
            runner.check_built_app(self.app)

    def test_config_assets_and_credentials_in_the_build_are_rejected(self):
        for rel in ('Frameworks/App.framework/flutter_assets/config/prod.json',
                    'Frameworks/App.framework/flutter_assets/shorebird.yaml',
                    'GoogleService-Info.plist', 'embedded.mobileprovision',
                    'Runner.entitlements'):
            with self.subTest(rel=rel):
                path = self.app / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('x')
                with self.assertRaises(runner.RunnerError):
                    runner.check_built_app(self.app)
                path.unlink()

    def test_a_build_without_flutter_assets_cannot_be_verified(self):
        import shutil
        shutil.rmtree(self.app / 'Frameworks')
        with self.assertRaisesRegex(runner.RunnerError, 'flutter_assets'):
            runner.check_built_app(self.app)


class SharedRunnerDefaultsTest(unittest.TestCase):
    """The keyword parameters added to run_firebase_device_ios.create_project."""

    def make_qa(self):
        workspace = Path(tempfile.mkdtemp())
        (workspace / 'pubspec.yaml').write_text('name: x\n')
        qa = mock.Mock()
        qa.workspace = workspace
        qa.logs = workspace / 'qa-logs'
        qa.logs.mkdir()
        qa.env = {'PATH': '/usr/bin'}
        qa.result = {}
        return qa

    def test_the_default_create_command_is_unchanged(self):
        qa = self.make_qa()
        ios_base.create_project(qa, 300)
        command = qa.run.call_args.args[1]
        self.assertEqual(command, [
            'flutter', 'create', '--platforms=ios', '--project-name', 'firebase_readiness',
            '--org', 'io.picnic.qa', '--no-pub', str(qa.workspace)])

    def test_the_notification_runner_creates_picnic_app_in_the_qa_org(self):
        qa = self.make_qa()
        ios_base.create_project(qa, 300, project_name='picnic_app', org='io.picnic.qa')
        command = qa.run.call_args.args[1]
        self.assertEqual(command[4], 'picnic_app')
        self.assertEqual(command[6], 'io.picnic.qa')


class FakeSimulator:
    """Records every simulator call; emits app evidence on launch and push."""

    def __init__(self, test_dir, *, preinstalled=False, unknown_list=False,
                 present_at_install=False, keep_after_uninstall=False,
                 tap=True, ack=True, interrupt_on_push=False, pid_alive=False):
        self.calls = []
        self.installed = preinstalled
        self.unknown_list = unknown_list
        self.present_at_install = present_at_install
        self.keep_after_uninstall = keep_after_uninstall
        self.tap, self.ack = tap, ack
        self.interrupt_on_push = interrupt_on_push
        self.pid_alive = pid_alive
        self.container = test_dir / 'Containers/Data/Application/C0FFEE'
        # Where the app writes: the provider's directory in the container.
        (self.container / PROVIDER_TEMPORARY_DIR).mkdir(parents=True)
        self.evidence = self.container / PROVIDER_TEMPORARY_DIR / runner.EVIDENCE_FILE
        self.ack_path = test_dir / 'ws/qa-ack/notification-displayed'
        self.list_calls = 0
        self.nonce = None
        self.app = test_dir / 'Runner.app'

    def app_state(self):
        self.list_calls += 1
        self.calls.append(('listapps',))
        if self.unknown_list:
            raise runner.RunnerError('cannot parse the installed app list')
        if self.present_at_install and self.list_calls == 2:
            return 'present'
        return 'present' if self.installed else 'absent'

    def install(self, app):
        self.calls.append(('install', runner.BUNDLE_ID))
        self.installed = True
        return {'exit_code': 0, 'cleanup': {'remaining': False}}

    def data_container(self):
        self.calls.append(('get_app_container', runner.BUNDLE_ID))
        return self.container

    def _write(self, events, message_id=None):
        """What the QA app writes: the launch nonce, its pid, the real time."""
        now = int(time.time() * 1000)
        for event in events:
            event['wallMs'] = now
            if event.get('messageId') == MESSAGE_ID:
                event['messageId'] = message_id
        doc = document(events, runNonce=self.nonce, evidencePath=str(self.evidence))
        self.evidence.write_text(json.dumps(doc))

    def build(self, qa, args, arch, run_nonce):
        """What build_app does for the app: compiles [run_nonce] into it."""
        self.calls.append(('build', run_nonce))
        self.nonce = self.compiled_nonce(run_nonce)
        return self.app

    def compiled_nonce(self, run_nonce):
        return run_nonce

    def launch(self, *arguments):
        # The app reads only the nonce compiled into the build.
        self.calls.append(('launch', runner.BUNDLE_ID, *arguments))
        self._write(good_events('paused'))
        return PID

    def push(self, payload_path):
        message_id = json.loads(Path(payload_path).read_text())['gcm.message_id']
        self.calls.append(('push', runner.BUNDLE_ID, message_id))
        if self.interrupt_on_push:
            raise KeyboardInterrupt()
        if self.tap:
            self._write(good_events(), message_id)
        if self.ack:
            self.ack_path.write_text(ACK_TOKEN + '\n')
        return {'exit_code': 0, 'cleanup': {'remaining': False}}

    def terminate(self):
        self.calls.append(('terminate', runner.BUNDLE_ID))
        return {'exit_code': 0, 'cleanup': {'remaining': False}}

    def uninstall(self):
        self.calls.append(('uninstall', runner.BUNDLE_ID))
        if not self.keep_after_uninstall:
            self.installed = False
        return {'exit_code': 0, 'cleanup': {'remaining': False}}

    def process_alive(self, pid):
        return self.pid_alive


class MainTest(unittest.TestCase):
    def setUp(self):
        self.dir = Path(tempfile.mkdtemp())
        self.app = self.dir / 'Runner.app'
        self.app.mkdir()

    def run_main(self, fake, timeouts=('--tap-timeout', '2'), nonces=None):
        def make_sim(*_args, **_kwargs):
            return fake

        argv = ['--simulator-udid', SIM_UDID, '--simulator-runtime', RUNTIME,
                '--developer-dir', '/Applications/Xcode.app/Contents/Developer',
                '--permission-timeout', '2', '--observe-timeout', '2',
                '--list-timeout', '2', '--filter-timeout', '2', '--ack-timeout', '2',
                *timeouts]
        out, err = io.StringIO(), io.StringIO()
        nonce_patch = (mock.patch.object(runner, 'new_nonce', side_effect=nonces)
                       if nonces is not None else contextlib.nullcontext())
        with mock.patch.object(runner, 'check_target',
                               return_value={'name': 'Picnic Firebase QA 26.5',
                                             'runtime': RUNTIME, 'state': 'Booted'}), \
                mock.patch.object(runner, 'build_app', side_effect=fake.build), \
                nonce_patch, \
                mock.patch.object(runner, 'Simulator', side_effect=make_sim), \
                mock.patch.object(runner, 'workspace_processes', return_value=[]), \
                mock.patch.object(runner, 'POLL_INTERVAL_S', 0.01), \
                mock.patch.object(runner, 'new_ack_token', return_value=ACK_TOKEN), \
                mock.patch.object(tempfile, 'mkdtemp', return_value=str(self.dir / 'ws')), \
                contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            (self.dir / 'ws').mkdir(exist_ok=True)
            code = runner.main(argv, environ={'PATH': '/usr/bin', 'HOME': str(self.dir)})
        result = json.loads((self.dir / 'ws/qa-result.json').read_text())
        return code, result, out.getvalue()

    def named(self, fake):
        return [call for call in fake.calls if call[0] in (
            'install', 'launch', 'push', 'terminate', 'uninstall')]

    def test_a_good_run_passes_with_runtime_and_visual_evidence_reported_apart(self):
        fake = FakeSimulator(self.dir)
        code, result, out = self.run_main(fake)
        self.assertEqual(code, 0, result.get('error'))
        self.assertEqual(result['status'], 'passed')
        self.assertEqual(result['runtime_evidence']['status'], 'passed')
        self.assertEqual(result['visual']['notification_displayed'], 'acknowledged')
        self.assertTrue(result['cleanup']['verified'])
        self.assertEqual([c[0] for c in self.named(fake)],
                         ['install', 'launch', 'push', 'terminate', 'uninstall'])
        self.assertTrue(all(c[1] == runner.BUNDLE_ID for c in self.named(fake)))
        self.assertIn('QA_PHASE=await_permission', out)
        self.assertIn('QA_PHASE=await_tap', out)
        self.assertIn('QA_ACK_FILE=', out)
        self.assertNotIn(SIM_UDID, out)

    def test_a_push_exit_code_without_a_display_ack_is_not_a_pass(self):
        fake = FakeSimulator(self.dir, ack=False)
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertEqual(result['runtime_evidence']['status'], 'passed')
        self.assertEqual(result['visual']['notification_displayed'], 'missing')
        self.assertTrue(result['cleanup']['verified'])

    def test_a_preinstalled_qa_app_is_never_owned_or_removed(self):
        fake = FakeSimulator(self.dir, preinstalled=True)
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertIn('already installed', result['error'])
        self.assertEqual(self.named(fake), [])

    def test_an_unknown_app_list_is_never_taken_as_absent(self):
        fake = FakeSimulator(self.dir, unknown_list=True)
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertEqual(self.named(fake), [])

    def test_an_app_that_appears_before_install_is_not_owned(self):
        fake = FakeSimulator(self.dir, present_at_install=True)
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertEqual(self.named(fake), [])

    def test_a_missing_tap_times_out_and_still_removes_the_owned_app(self):
        fake = FakeSimulator(self.dir, tap=False, ack=False)
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertIn('await_tap', result['error'])
        self.assertEqual([c[0] for c in self.named(fake)][-2:], ['terminate', 'uninstall'])
        self.assertTrue(result['cleanup']['verified'])

    def test_an_interrupted_run_removes_the_owned_app(self):
        fake = FakeSimulator(self.dir, interrupt_on_push=True)
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 130)
        self.assertEqual(result['status'], 'interrupted')
        self.assertEqual([c[0] for c in self.named(fake)][-2:], ['terminate', 'uninstall'])

    def test_an_app_that_stays_installed_makes_a_good_run_fail(self):
        fake = FakeSimulator(self.dir, keep_after_uninstall=True)
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertEqual(result['runtime_evidence']['status'], 'passed')
        self.assertFalse(result['cleanup']['verified'])

    def test_an_app_process_that_survives_makes_a_good_run_fail(self):
        fake = FakeSimulator(self.dir, pid_alive=True)
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertFalse(result['cleanup']['verified'])

    def test_a_stale_evidence_file_before_launch_fails_the_run(self):
        fake = FakeSimulator(self.dir)
        fake.evidence.write_text('{}')
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertIn('stale', result['error'])
        self.assertNotIn(('launch',), [c[:1] for c in fake.calls])
        self.assertEqual([c[0] for c in self.named(fake)][-2:], ['terminate', 'uninstall'])

    def test_the_build_gets_the_run_nonce_and_the_launch_gets_none(self):
        fake = FakeSimulator(self.dir)
        code, result, _ = self.run_main(fake, nonces=[NONCE, MESSAGE_NONCE])
        self.assertEqual(code, 0, result.get('error'))
        self.assertEqual([c for c in fake.calls if c[0] == 'build'], [('build', NONCE)])
        self.assertEqual([c for c in fake.calls if c[0] == 'launch'],
                         [('launch', runner.BUNDLE_ID)])

    def test_an_app_built_with_another_nonce_is_refused(self):
        fake = FakeSimulator(self.dir)
        fake.compiled_nonce = lambda _run_nonce: 'f' * 32
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertIn('evidence run nonce does not match', result['error'])
        self.assertNotIn(('push',), [c[:1] for c in fake.calls])
        self.assertTrue(result['cleanup']['verified'])

    def test_an_app_without_a_compiled_nonce_is_refused(self):
        fake = FakeSimulator(self.dir)
        fake.compiled_nonce = lambda _run_nonce: None
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertIn('evidence run nonce does not match', result['error'])
        self.assertNotIn(('push',), [c[:1] for c in fake.calls])

    def test_an_invalid_run_nonce_never_builds_or_installs(self):
        for bad in ('', 'not-hex', NONCE.upper(), NONCE[:-1]):
            with self.subTest(bad=bad):
                fake = FakeSimulator(Path(tempfile.mkdtemp()))
                self.dir = fake.container.parents[3]
                code, result, _ = self.run_main(fake, nonces=[bad, MESSAGE_NONCE])
                self.assertEqual(code, 1)
                self.assertIn('run nonce must be 32 lowercase hex', result['error'])
                self.assertEqual([c[0] for c in fake.calls
                                  if c[0] in ('build', 'install', 'launch')], [])

    def test_a_dangling_symlink_at_the_evidence_path_is_stale_before_launch(self):
        fake = FakeSimulator(self.dir)
        fake.evidence.symlink_to(self.dir / 'missing-target')
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertIn('stale', result['error'])
        self.assertNotIn(('launch',), [c[:1] for c in fake.calls])

    def test_a_file_left_in_container_tmp_is_not_the_evidence(self):
        fake = FakeSimulator(self.dir)
        (fake.container / 'tmp').mkdir()
        (fake.container / 'tmp' / runner.EVIDENCE_FILE).write_text('{}')
        code, result, _ = self.run_main(fake)
        self.assertEqual(code, 0, result.get('error'))


class BuildNonceTest(unittest.TestCase):
    """The real build_app with only its file, tool and check steps replaced."""

    def run_build(self, run_nonce):
        workspace = Path(tempfile.mkdtemp())
        qa = mock.Mock()
        qa.workspace = workspace
        qa.result = {}
        product_assets = runner.kept_assets(
            (ROOT_DIR / 'picnic_app/pubspec.yaml').read_text())
        steps = {
            (ios_base, 'create_project'): None,
            (runner.full_app, 'copy_product'): ({}, None, product_assets),
            (runner.full_app, 'scan_workspace'): None,
            (runner.full_app, 'copy_checked'): 'sha',
            (runner, 'copy_qa_sources'): {},
            (runner, 'prepare_ios'): None,
            (runner, 'check_locks'): {},
            (ios_base, 'check_dependency_manager'): None,
            (ios_base, 'check_simulator_arch'): None,
            (ios_base, 'check_pods'): None,
            (runner, 'check_built_app'): {'bundle_id': runner.BUNDLE_ID},
        }
        with contextlib.ExitStack() as stack:
            mocks = {name: stack.enter_context(mock.patch.object(module, name,
                                                                 return_value=value))
                     for (module, name), value in steps.items()}
            args = mock.Mock(create_timeout=1, pub_timeout=1, build_timeout=1)
            try:
                runner.build_app(qa, args, 'arm64', run_nonce)
            finally:
                self.created = mocks['create_project'].called
        return qa

    def test_the_flutter_build_command_carries_the_run_nonce_exactly_once(self):
        qa = self.run_build(NONCE)
        builds = [call.args[1] for call in qa.run.call_args_list
                  if call.args[0] == 'build-simulator']
        self.assertEqual(len(builds), 1)
        command = builds[0]
        self.assertEqual(command[:4], ['flutter', 'build', 'ios', '--simulator'])
        self.assertEqual([part for part in command if NONCE in part],
                         ['--dart-define=PICNIC_QA_RUN_NONCE=' + NONCE])
        self.assertEqual(sum('PICNIC_QA_RUN_NONCE' in part for part in command), 1)
        other = [call.args[1] for call in qa.run.call_args_list
                 if call.args[0] != 'build-simulator']
        self.assertFalse(any(NONCE in part for command in other for part in command))

    def test_an_invalid_nonce_stops_before_any_project_step(self):
        for bad in (None, '', 'not-hex', NONCE.upper(), NONCE + '0'):
            with self.subTest(bad=bad):
                with self.assertRaisesRegex(runner.RunnerError, 'nonce'):
                    self.run_build(bad)
                self.assertFalse(self.created)


class LaunchTest(unittest.TestCase):
    def test_the_real_launch_names_only_the_udid_and_bundle_and_adds_no_env(self):
        sim = runner.Simulator(Path('/Xcode/Contents/Developer'), {'PATH': '/usr/bin'},
                               SIM_UDID, Path(tempfile.mkdtemp()), Path(tempfile.mkdtemp()),
                               '/Users/qa', {'install': 1, 'launch': 7})
        with mock.patch.object(runner.Simulator, '_capture',
                               return_value=f'{runner.BUNDLE_ID}: 4242\n') as capture:
            self.assertEqual(sim.launch(), 4242)
        name, arguments, timeout = capture.call_args.args
        self.assertEqual(arguments, ['launch', SIM_UDID, runner.BUNDLE_ID])
        self.assertEqual(timeout, 7)
        self.assertIsNone(capture.call_args.kwargs.get('env'))
        self.assertNotIn('SIMCTL_CHILD_PICNIC_QA_RUN_NONCE', sim.env)


class ContainerTest(unittest.TestCase):
    def test_a_data_container_of_the_target_simulator_is_accepted(self):
        home = Path('/Users/qa')
        path = (home / 'Library/Developer/CoreSimulator/Devices' / SIM_UDID /
                'data/Containers/Data/Application/0A1B2C3D-0000-4000-8000-000000000001')
        self.assertEqual(runner.check_container(str(path) + '\n', home, SIM_UDID), path)

    def test_a_container_of_another_simulator_or_path_is_rejected(self):
        home = Path('/Users/qa')
        for bad in (
                f'{home}/Library/Developer/CoreSimulator/Devices/OTHER/data/Containers/'
                'Data/Application/0A1B2C3D-0000-4000-8000-000000000001',
                f'{home}/Library/Developer/CoreSimulator/Devices/{SIM_UDID}/data/'
                'Containers/Data/Application/../../x',
                '/tmp/x', ''):
            with self.subTest(bad=bad), self.assertRaises(runner.RunnerError):
                runner.check_container(bad, home, SIM_UDID)

    def test_the_evidence_file_is_in_the_container_library_caches(self):
        container = Path('/c/Data/Application/0A1B2C3D-0000-4000-8000-000000000001')
        self.assertEqual(runner.evidence_path(container),
                         container / 'Library/Caches/notification-delivery-ios.json')

    def test_the_launch_output_must_name_the_bundle_and_a_pid(self):
        self.assertEqual(runner.parse_launch_output(f'{runner.BUNDLE_ID}: 4242\n'), 4242)
        for bad in ('', 'com.other.app: 4242', f'{runner.BUNDLE_ID}: x',
                    f'{runner.BUNDLE_ID}: 1\n{runner.BUNDLE_ID}: 2\n'):
            with self.subTest(bad=bad), self.assertRaises(runner.RunnerError):
                runner.parse_launch_output(bad)


if __name__ == '__main__':
    unittest.main()
