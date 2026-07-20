# Community Secret Removal Design

## Goal

Remove AWS, DeepL, and YouTube credentials from assets bundled with `picnic_app` while preserving the disabled community code for a possible future reactivation.

## Scope

- Replace the AWS access key, AWS secret key, DeepL API key, and YouTube API key values in `picnic_app/config/dev.json`, `picnic_app/config/local.json`, and `picnic_app/config/prod.json` with empty strings.
- Prevent S3 upload, DeepL translation, and native YouTube metadata requests when their credential is absent.
- Add an automated regression test that rejects non-empty sensitive credentials in every bundled environment file.
- Preserve the existing configuration keys so current configuration parsing continues to work.

## Out of Scope

- Removing community source code or its dependencies.
- Building Supabase Edge Function proxies.
- Changing Supabase anonymous keys, Firebase configuration, OAuth client IDs, or advertising SDK IDs.
- Redesigning community screens or adding new disabled-feature UI.
- Rotating credentials in AWS, DeepL, or Google consoles. This remains an external operational action.

## Architecture

The existing configuration schema remains unchanged, but sensitive values become empty. Each client-side integration validates its credential before making a network request and fails locally with a consistent configuration error. Existing calling widgets continue to use their current error-handling paths, which avoids new UI and keeps the change small.

The regression test reads every JSON file under `picnic_app/config` and asserts that these paths are empty:

- `storage.aws.access_key_id`
- `storage.aws.secret_access_key`
- `api_keys.deepl`
- `api_keys.youtube`

## Data Flow

### S3 upload

1. Community upload code creates or invokes `S3Uploader`.
2. `S3Uploader` checks that the access and secret keys are non-empty before signing or sending a request.
3. Missing credentials produce a local configuration exception.
4. Existing upload error handling displays the current failure state.

### DeepL translation

1. The comment translation action constructs `DeepLTranslationService`.
2. Translation validates that the API key is non-empty before calling DeepL.
3. Missing credentials produce a local configuration exception.
4. `CommentItem` uses its existing translation failure snackbar.

### YouTube metadata

1. Web behavior remains unchanged and uses the existing Supabase `youtube-preview` function.
2. Native behavior checks the YouTube API key before issuing Google API requests.
3. Missing credentials follow the existing fallback `VideoInfo` path without making a request.

## Error Handling

- Credential checks trim whitespace before deciding whether a key exists.
- No credential value is included in exception messages or logs.
- S3 and DeepL fail explicitly because their operations cannot produce a meaningful result without credentials.
- YouTube retains its existing fallback metadata behavior because a public thumbnail and basic embed can still be shown without API metadata.

## Testing

- Add a repository-level configuration test covering all three bundled environment files and all four sensitive paths.
- Add focused unit tests proving S3 and DeepL reject empty credentials before network work.
- Add a focused YouTube service test proving native missing-key handling returns fallback metadata without issuing HTTP requests, using an injectable or testable request boundary only if required.
- Run the focused tests first, then `flutter test` for affected test directories and `flutter analyze` for both `picnic_app` and `picnic_lib`.
- Existing unrelated analyzer and test failures will be reported separately and will not be hidden or reclassified as part of this change.

## Operational Follow-up

After the code change lands, an authorized operator must revoke the exposed AWS, DeepL, and YouTube credentials. New long-lived secret values must not be added back to mobile configuration files.
