# 코튼캔디 지갑 + 캔디 부스트 앱 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** <code>picnic-app</code>이 서버의 세 재화 wallet 계약을 읽고 일반 투표의 코튼캔디 우선 차감, 내부 숏폼/Pangle 보상 복구, 캔디 부스트 홈·스토어 surface를 안전하게 제공하게 한다.

**Architecture:** Supabase wallet/read 계약을 단일 진실로 사용하며 앱은 raw <code>user_profiles</code> 잔액이나 클라이언트 시각으로 재화·캠페인을 판단하지 않는다. Riverpod repository/provider 경계가 RPC DTO를 소유하고, 화면은 immutable model만 렌더링한다. 광고 보상 reference는 callback 전에 로컬에 저장하고 서버 미확인 목록과 합쳐 terminal popup의 첫 frame 이후 acknowledge하여 at-least-once 전달을 보장한다.

**Tech Stack:** Flutter/Dart, Riverpod code generation, Freezed/json_serializable, Supabase Flutter, SharedPreferences 기반 <code>LocalStorage</code>, Flutter widget/golden/integration tests, Android Kotlin/JUnit4, iOS Swift/XCTest.

## Global Constraints

- 승인 설계는 <code>docs/superpowers/specs/2026-07-21-cotton-candy-and-candy-boost-design.md</code>다. 계약 충돌이 발견되면 구현을 멈추고 설계 변경 승인을 받는다.
- 현재 <code>config/dev.json</code>·<code>config/local.json</code>의 Supabase URL/anon/storage tuple은 <code>prod.json</code>과 같고 root <code>supabase/.temp/**</code>·<code>.branches/**</code>가 추적 중이므로 Task 0이 통과하기 전 network integration, device test, Preview, production build는 **NO-GO**다. staging 미구성 시 production으로 fallback하지 않는다.
- production ref <code>xtijtefcycoeqludlngc</code>는 local/dev denylist다. <code>local</code>은 local Supabase만, <code>dev</code>는 별도 staging만 사용하고 production config와 tuple 항목 하나라도 같으면 build/test guard가 exit 1한다.
- 추적된 mobile config의 privileged-looking key 이름(예: AWS access/secret fields)은 별도 보안 감사 대상이다. 실제 privileged credential이면 서버 측 signed flow로 이전하고 회전 evidence를 남기기 전 production release를 만들지 않는다. 값은 log·fixture·manifest에 출력하거나 복사하지 않는다.
- Codemagic tag, Shorebird patch, AWS/Lambda, Supabase copy/deploy는 exact <code>origin/main</code> SHA와 사람 승인 reference를 검증하는 protected CI만 허용한다. feature worktree와 local shell에서는 production 명령을 항상 거부한다.
- 사용자 노출명은 <code>스타캔디</code>, <code>보너스 스타캔디</code>, <code>코튼캔디</code>, <code>캔디 부스트 데이</code>다. 한국어 일반명 “솜사탕”은 코드, ARB, 접근성 label, fixture에 추가하지 않는다.
- 재화 순서는 모든 wallet·투표·정책 UI에서 <code>STAR_CANDY → BONUS_STAR_CANDY → COTTON_CANDY</code>다. 일반 투표 서버 차감 순서만 <code>COTTON_CANDY → BONUS_STAR_CANDY → STAR_CANDY</code>다.
- 일반 <code>VotePortal.vote</code>만 Cotton spend 대상이다. PIC는 <code>pic-voting-v2</code>, JMA는 <code>jma-voting-v2</code>, Goonghap은 현재 writer와 Star/Bonus 정책을 그대로 유지한다.
- 일반 투표 Edge endpoint 이름은 기존 <code>voting-v2</code>를 유지한다. 호환 wrapper가 내부에서 <code>perform_vote_transaction_v3</code>를 호출하며 새 앱은 <code>star_candy_usage</code>, <code>star_candy_bonus_usage</code>, <code>cotton_candy_usage</code>를 요청에 보내지 않는다.
- wallet 표시·검증은 <code>get_wallet_summary()</code>만 사용한다. <code>UserProfilesModel.starCandy</code>와 <code>starCandyBonus</code>는 identity/profile 호환 데이터일 뿐 신규 wallet UI의 source가 아니다.
- 신규 금융 DTO의 bigint 금액은 JSON decimal string으로 받고 Dart <code>BigInt</code>로 parse한다. JSON number가 오면 contract test가 실패해야 한다.
- 내부 숏폼의 Cotton 대상은 <code>view</code>뿐이다. <code>more</code>, Tapjoy, Pincrux, AdMob 및 legacy Bonus 채널의 지급 정책은 바꾸지 않는다.
- Pangle <code>media_extra</code>는 <code>&lt;userId&gt;,&lt;platform&gt;,v2.&lt;signed-opaque-token&gt;</code>이다. native callback과 <code>isValid</code>는 status polling 신호일 뿐 지급 권위가 아니다.
- HOME/STORE 노출은 <code>get_active_promotion_campaigns(surface)</code>가 반환한 동일 campaign version만 사용한다. 앱 <code>DateTime.now()</code>, <code>banner.start_at/end_at</code>, 상품 description으로 캠페인 eligibility를 재계산하지 않는다.
- 승인된 v3 icon source는 최종 transparent PNG로 export해 <code>picnic_lib/assets/icons/store/</code>에 둔다. <code>.superpowers/</code> 파일을 runtime 참조하거나 stage하지 않는다.
- 구현 release version은 <code>1.2.34+123401</code>이며 서버 wallet-aware 최소 version은 <code>1.2.34</code>, 최소 build는 <code>123401</code>로 고정한다. 현재 <code>1.2.33+123301</code> 다음 기능 release이므로 patch를 <code>1.2.34</code>로 올리고, 저장소의 기존 build 규칙 <code>1.2.33 → 123301</code>, <code>1.2.32 → 12320x</code>에 따라 새 patch의 첫 build를 <code>123401</code>로 정한다. 서버 gate가 활성화되기 전 광고 지급은 기존 Bonus mode다.
- 이 계획은 <code>/Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy</code>, 브랜치 <code>feat/cotton-candy-policy</code>에서 실행한다.
- 각 task는 명시된 test가 통과한 뒤 Conventional Commit 하나로 끝낸다. 생성 파일은 <code>dart run build_runner build --delete-conflicting-outputs</code>와 <code>flutter gen-l10n</code>으로만 갱신한다.

### Canonical wallet/ad wire shapes

앱 fixture와 production parser는 아래 key set을 계약 그대로 소유한다. bigint 금액·내부 ID·count는 모두 base-10 JSON string이고, UUID와 timestamp는 string 또는 명시적 <code>null</code>이다. JSON number bigint, 평탄화 alias, <code>state</code> 대신 <code>status</code>, 그리고 필수 nullable key 생략은 contract failure다.

~~~text
wallet_summary = {
  contract_version, star, bonus, cotton, cotton_expiring_amount,
  cotton_next_expires_at, snapshot_at
}
currency_history_item = {
  id, currency, event_type, origin, delta, balance_effect, expires_at,
  purchase_id, refund_id, grant_id, operation_id, created_at
}
currency_history_page = {items, total_count, next_cursor, snapshot_at}

ad_reward_reference = {type, id}
ad_reward_grant = {id, currency, amount, granted_at, expires_at}
ad_reward_status = {reference, state, grant, wallet, snapshot_at}
ad_reward_status_page = {items, total_count, next_cursor, snapshot_at}
pangle_claim = {reference, platform, signed_token, expires_at}
internal_shortform_issue = {ad, tokens, impression_id}
internal_shortform_view = {
  ok, reward_added, impression_id, new_bonus, reward
}
~~~

<code>currency_history_item</code>의 <code>expires_at</code>, <code>purchase_id</code>, <code>refund_id</code>, <code>grant_id</code>는 값이 없어도 key를 <code>null</code>로 보존한다. Pending ad fixture는 <code>grant:null</code>, granted fixture는 정확한 nested <code>ad_reward_grant</code>를 보존한다. <code>wallet</code>은 언제나 위 <code>wallet_summary</code> 형태다.
<code>ad-shortform-issue</code>는 기존 <code>ad</code>/<code>tokens</code>를 보존하고, 그 응답의 token이 가리키는 동일 <code>ad_impressions.id</code>를 top-level UUID <code>impression_id</code>로 반드시 반환한다. Legacy Bonus shortform은 호환 예외로 additive <code>reward</code> key를 생략할 수 있지만, wallet-aware response의 nested <code>reward</code>는 반드시 canonical <code>ad_reward_status</code>로 parse한다.

---

## File Structure

### 신규 production 파일

- <code>picnic_lib/lib/data/models/wallet/wallet_amount.dart</code> — decimal string/BigInt 변환과 표시 formatter.
- <code>picnic_lib/lib/data/models/wallet/wallet_summary.dart</code> — 세 잔액과 Cotton 만료 summary.
- <code>picnic_lib/lib/data/models/wallet/currency_history.dart</code> — cursor history DTO.
- <code>picnic_lib/lib/data/models/vote/vote_transaction.dart</code> — 일반 v3 request/result DTO.
- <code>picnic_lib/lib/data/models/ad/ad_reward_status.dart</code> — reference, claim, status, grant, unacknowledged DTO.
- <code>picnic_lib/lib/data/models/promotion/promotion_campaign.dart</code> — HOME/STORE campaign와 creative DTO.
- <code>picnic_lib/lib/data/models/purchase/purchase_settlement_result.dart</code> — 검증된 기본 지급·promotion resolution·wallet 구매 결과 DTO.
- <code>picnic_lib/lib/data/repositories/wallet_repository.dart</code> — wallet summary/history RPC.
- <code>picnic_lib/lib/data/repositories/vote_transaction_repository.dart</code> — <code>voting-v2</code> v3 payload와 동일 request ID retry.
- <code>picnic_lib/lib/data/repositories/ad_reward_repository.dart</code> — claim/status/list/ack RPC와 shortform v2 parser.
- <code>picnic_lib/lib/data/repositories/promotion_campaign_repository.dart</code> — server-clock surface RPC.
- <code>picnic_lib/lib/data/storage/pending_ad_reward_store.dart</code> — 사용자별 durable reference.
- <code>picnic_lib/lib/presentation/providers/wallet_provider.dart</code> — wallet/history provider.
- <code>picnic_lib/lib/presentation/providers/vote_transaction_provider.dart</code> — injectable general vote repository.
- <code>picnic_lib/lib/presentation/providers/ad_reward_recovery_provider.dart</code> — local/server union, polling, dialog queue, ACK.
- <code>picnic_lib/lib/presentation/providers/ad_reward_provider.dart</code> — injectable reward repository and durable store.
- <code>picnic_lib/lib/presentation/providers/promotion_campaign_provider.dart</code> — surface family provider.
- <code>picnic_lib/lib/presentation/widgets/wallet/wallet_summary_panel.dart</code> — 좌측 정렬 3분할 wallet.
- <code>picnic_lib/lib/presentation/widgets/wallet/currency_history_list_item.dart</code> — 통화 이력 row.
- <code>picnic_lib/lib/presentation/pages/my_page/currency_history_page.dart</code> — 세 통화 history tabs.
- <code>picnic_lib/lib/presentation/widgets/ad_reward_dialog_host.dart</code> — terminal popup과 첫-frame ACK.
- <code>picnic_lib/lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart</code> — STORE campaign 표시.
- <code>picnic_lib/lib/presentation/common/candy_boost_banner.dart</code> — HOME campaign 좌측 정렬 creative.
- <code>picnic_app/android/app/src/main/kotlin/io/iconcasting/picnic/app/pangle/PangleMediaExtra.kt</code> — Android v2 media-extra validator.
- <code>picnic_lib/assets/icons/store/currency_star_candy.png</code>, <code>currency_bonus_star_candy.png</code>, <code>currency_cotton_candy.png</code> — product assets.

### 주요 수정 파일

- Wallet/history: <code>star_candy_info_text.dart</code>, <code>common_my_point_info.dart</code>, <code>store_point_info.dart</code>, <code>usage_policy_dialog.dart</code>, <code>my_page.dart</code>, <code>vote_pick.dart</code>, <code>vote_history_page.dart</code>, <code>vote_history_list_item.dart</code>.
- Vote: <code>voting_dialog.dart</code>, <code>voting_dialog_helper.dart</code>, <code>voting_dialog_widgets.dart</code>, <code>voting_usage_helper.dart</code>.
- Ads: <code>shortform_internal_platform.dart</code>, <code>ad_shortform_fullscreen_page.dart</code>, <code>pangle_platform.dart</code>, <code>pangle_ads.dart</code>, <code>pangle_ads_helper.dart</code>, <code>picnic_app/lib/app.dart</code>.
- Native: <code>PangleNativeHandler.kt</code>, <code>PangleAdManager.swift</code>, Android <code>build.gradle</code>, iOS <code>RunnerTests.swift</code>.
- Promotion: mobile/web purchase state, <code>store_list_tile.dart</code>, purchase dialog handler, <code>common_banner.dart</code>, <code>home_page.dart</code>, <code>vote_home_page.dart</code>.
- Generated/localized: <code>app_en.arb</code>, <code>app_ko.arb</code>, generated <code>app_localizations*.dart</code> and <code>lib/generated/providers/**</code>.

---

### Task 0: Non-production Environment and Release Isolation

**Files:**
- Create: <code>picnic_app/tool/verify_environment_isolation.dart</code>
- Create: <code>picnic_app/test/config/environment_isolation_test.dart</code>
- Create: <code>picnic_lib/lib/core/config/supabase_environment_policy.dart</code>
- Create: <code>picnic_lib/test/core/config/supabase_environment_policy_test.dart</code>
- Create: <code>picnic_app/tool/verify_release_target.dart</code>
- Create: <code>picnic_app/test/config/release_target_test.dart</code>
- Modify: <code>picnic_app/config/local.json</code>
- Modify: <code>picnic_app/config/dev.json</code>
- Modify: <code>picnic_app/lib/main.dart</code>
- Modify: <code>picnic_lib/lib/core/config/environment.dart</code>
- Modify: <code>.gitignore</code>
- Remove from Git index: <code>supabase/.temp/**</code>, <code>supabase/.branches/**</code>
- Modify: <code>codemagic.yaml</code>
- Modify: <code>picnic_app/scripts/shorebird-patch.sh</code>
- Modify: <code>picnic_app/scripts/build_android.sh</code>
- Modify: <code>picnic_app/test_release.sh</code>
- Modify: <code>picnic_app/scripts/common_functions.sh</code>
- Modify: <code>scripts/run_tests.sh</code>
- Modify: <code>picnic_app/aws/resize_image_lambda/deploy.sh</code>

**Interfaces:** Produces fail-closed <code>local|dev|prod</code> config validation and an exact-SHA production release guard. It does not contain, print, or generate credential values.

- [ ] **Step 1: Write failing environment-isolation tests against sanitized fixtures**

Tests load temporary copies and assert:

- local/dev Supabase <code>url</code>, <code>anon_key</code>, storage <code>url</code>, storage <code>anon_key</code> are non-empty and no item equals production.
- URL-derived project ref is not <code>xtijtefcycoeqludlngc</code>; local host is <code>127.0.0.1|localhost</code>; dev ref equals required <code>PICNIC_STAGING_SUPABASE_PROJECT_REF</code> and differs from production.
- production ref, tracked/link metadata, absent staging ref, malformed/unknown environment, and privileged production-mode ad/payment settings in local/dev each fail closed.
- local/dev require <code>PANGLE_ENVIRONMENT=sandbox</code> and <code>PAYMENT_ENVIRONMENT=sandbox</code> (or equivalent explicit test mode) at the build boundary; missing/production values fail before an ad SDK, purchase SDK, or Supabase client is initialized. Production builds require the protected runner to set <code>prod</code> explicitly.
- errors name only the source/key and never print URL/key/token values. A fixture sentinel <code>do-not-print-secret</code> is absent from stdout/stderr.

Run:

~~~bash
cd picnic_app
flutter test test/config/environment_isolation_test.dart
dart run tool/verify_environment_isolation.dart --environment=dev
~~~

Expected now: tests expose that dev/local equal prod and the command exits 1 with <code>NO-GO: non-production environment is not isolated</code>. No remote request occurs.

- [ ] **Step 2: Remove persisted CLI link state from source control**

Add <code>/supabase/.temp/</code> and <code>/supabase/.branches/</code> to the root ignore file, then untrack only those exact paths. Quarantine/remove the persisted link copies from the feature worktree without reading their contents; a local CLI link must be recreated only by an approved local-stack command or ephemeral protected deployment job.

~~~bash
git rm -r --cached --ignore-unmatch supabase/.temp supabase/.branches
if git ls-files 'supabase/.temp/**' 'supabase/.branches/**' | rg .; then exit 1; fi
quarantine_dir="$(mktemp -d)"
test ! -e "$quarantine_dir/supabase/.temp"
if test -e supabase/.temp; then mv supabase/.temp "$quarantine_dir/"; fi
if test -e supabase/.branches; then mv supabase/.branches "$quarantine_dir/"; fi
test ! -e supabase/.temp/project-ref
test ! -e supabase/.branches/_current_branch
~~~

Expected: tracked CLI metadata count 0 and any pre-existing local copies are recoverable under the temporary quarantine path held by the operator. Production link is created only inside the separately approved ephemeral deployment job.

- [ ] **Step 3: Implement the config guard without a bypass**

<code>supabase_environment_policy.dart</code> is the runtime-importable pure policy shared by CLI and Flutter tests. <code>verify_environment_isolation.dart</code> is a thin wrapper that validates the selected non-production config before Flutter build/test and emits names/reasons only. <code>Environment.initConfig</code> invokes the same in-memory validator before <code>rootBundle</code> values reach <code>Supabase.initialize</code>, so a misconfigured release cannot bypass the CLI guard. <code>main.dart</code> removes the implicit <code>ENVIRONMENT=dev</code> default and fails before SDK initialization unless an exact <code>local|dev|prod</code> dart-define is supplied. <code>config/local.json</code> is changed to local Supabase endpoints; <code>config/dev.json</code> is populated only after a separate staging project/ref and public client configuration are provisioned. Staging values come from the approved secret/config channel, not production copy commands or this plan.

Run:

~~~bash
flutter test test/config/environment_isolation_test.dart
dart run tool/verify_environment_isolation.dart --environment=local
PICNIC_STAGING_SUPABASE_PROJECT_REF="$PICNIC_STAGING_SUPABASE_PROJECT_REF" \
  dart run tool/verify_environment_isolation.dart --environment=dev
~~~

Expected: exit 0 only after local/dev are isolated. Until the staging ref exists, dev integration remains NO-GO while offline unit/widget tests may continue.

`picnic_app/integration_test` mock-server flows use `--environment=local` and never require staging. A separate staging smoke command uses `--environment=dev`; the two commands and evidence are not interchangeable.

- [ ] **Step 4: Write and implement exact-SHA release-target tests**

<code>verify_release_target.dart</code> tests and enforces all of the following without a bypass argument: CI provider is approved, event is an explicit production release, checkout is clean, <code>HEAD == requested SHA == origin/main</code>, tag resolves to that SHA, release manifest checksum matches, approval reference is non-empty, environment is exactly <code>prod</code>, and environment isolation/security evidence is complete. Local shell, feature branch, ancestor-but-not-current-main SHA, wildcard tag alone, missing evidence, and unknown deploy target all exit 1 without printing secrets.

Add this verifier as the first step of both production Codemagic workflows before any package install, signing, Shorebird, store upload, or Sentry release action. Configure production workflows for manual approval/protected release credentials; tag matching alone is not authority. A protected-tag/CI-approval configuration screenshot or audit reference is required external evidence.

Replace local production behavior as follows:

- <code>shorebird-patch.sh</code> exits 1 and points to the protected CI patch workflow; remove local <code>--no-confirm</code>/<code>ENVIRONMENT=prod</code> execution.
- Lambda <code>deploy.sh</code> and remote branches of <code>common_functions.sh</code> exit 1 outside an approved CI target and exact SHA. Schema-drop/copy and linked Storage commands are never allowed from this feature worktree.
- <code>build_android.sh</code> and <code>test_release.sh</code> must pass an explicit <code>ENVIRONMENT</code> and the same release-target guard; remove implicit production/default modes and any <code>|| true</code> that can hide a failed guard.
- The release guard statically rejects bare linked Supabase commands, <code>--no-confirm</code>, and direct remote Lambda mutation in developer scripts.

Run:

~~~bash
cd picnic_app
dart test test/config/release_target_test.dart
dart run tool/verify_release_target.dart --target=production
~~~

Expected locally: tests pass, direct production verification exits 1 with <code>NO-GO: protected production runner required</code>. No production action is attempted.

- [ ] **Step 5: Commit the isolation boundary**

~~~bash
git add .gitignore codemagic.yaml picnic_app/config/local.json picnic_app/config/dev.json picnic_app/lib/main.dart picnic_lib/lib/core/config/environment.dart picnic_lib/lib/core/config/supabase_environment_policy.dart picnic_app/tool/verify_environment_isolation.dart picnic_app/tool/verify_release_target.dart picnic_app/test/config picnic_lib/test/core/config picnic_app/scripts/shorebird-patch.sh picnic_app/scripts/build_android.sh picnic_app/test_release.sh picnic_app/scripts/common_functions.sh scripts/run_tests.sh picnic_app/aws/resize_image_lambda/deploy.sh
git add -u supabase/.temp supabase/.branches
git commit -m "chore(release): isolate non-production targets"
~~~

Expected: no CLI link metadata is tracked; no secret values were introduced; local guard tests pass; dev/production integration remains blocked unless its respective external evidence exists.

### Task 1: Stable Wallet Contract Models

**Files:**
- Create: <code>picnic_lib/lib/data/models/wallet/wallet_amount.dart</code>
- Create: <code>picnic_lib/lib/data/models/wallet/wallet_summary.dart</code>
- Create: <code>picnic_lib/lib/data/models/wallet/currency_history.dart</code>
- Test: <code>picnic_lib/test/data/models/wallet/wallet_amount_test.dart</code>
- Test: <code>picnic_lib/test/data/models/wallet/wallet_summary_test.dart</code>
- Test: <code>picnic_lib/test/data/models/wallet/currency_history_test.dart</code>
- Create from canonical exporter: <code>picnic_lib/test/fixtures/wallet_contracts/wallet_summary_v1.json</code>
- Create from canonical exporter: <code>picnic_lib/test/fixtures/wallet_contracts/currency_history_empty_v1.json</code>
- Create from canonical exporter: <code>picnic_lib/test/fixtures/wallet_contracts/currency_history_mixed_v1.json</code>

**Interfaces:**
- Consumes: backend <code>wallet.v1</code> fixtures exported by the Supabase wallet-core plan.
- Produces: <code>WalletCurrency</code>, <code>WalletAmountConverter</code>, <code>formatWalletAmount(BigInt)</code>, <code>WalletSummaryModel.fromJson</code>, <code>CurrencyHistoryPageModel.fromJson</code>.

- [ ] **Step 1: Copy canonical fixtures and write failing parser tests**

Run:

~~~bash
cd /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine
node scripts/wallet/export_contract_fixtures.mjs \
  --manifest supabase/tests/wallet/contracts/manifest.json \
  --output supabase/tests/wallet/contracts/fixtures \
  --app /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_lib/test/fixtures/wallet_contracts \
  --admin /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/test/fixtures/wallet-contracts \
  --app-integration-dart /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart
~~~

Add tests with these assertions:

~~~dart
final json = jsonDecode(
  File('test/fixtures/wallet_contracts/wallet_summary_v1.json')
      .readAsStringSync(),
) as Map<String, dynamic>;
final summary = WalletSummaryModel.fromJson(json);
expect(summary.contractVersion, 'wallet.v1');
expect(summary.star, BigInt.parse('9007199254740993'));
expect(summary.bonus, BigInt.from(250));
expect(summary.cotton, BigInt.from(40));
expect(summary.cottonExpiringAmount, BigInt.from(10));
expect(summary.cottonNextExpiresAt, DateTime.utc(2026, 7, 22));
expect(summary.snapshotAt, DateTime.utc(2026, 7, 21));

expect(
  () => const WalletAmountConverter().fromJson(42),
  throwsA(isA<FormatException>()),
);

expect(json.keys.toSet(), {
  'contract_version',
  'star',
  'bonus',
  'cotton',
  'cotton_expiring_amount',
  'cotton_next_expires_at',
  'snapshot_at',
});
expect(
  () => WalletSummaryModel.fromJson({...json, 'star_balance': '1'}),
  throwsFormatException,
);
expect(
  () => WalletSummaryModel.fromJson(
    Map<String, dynamic>.from(json)..remove('cotton_next_expires_at'),
  ),
  throwsFormatException,
);
~~~

History fixture의 각 item key set도 canonical 목록과 일치하는지 검증하고, nullable reference key를 하나씩 삭제한 input과 <code>delta:42</code>, <code>total_count:2</code> 같은 JSON number input을 모두 거부한다. 평탄화한 <code>star_balance</code>·<code>cotton_balance</code> alias도 거부한다.

Run: <code>cd picnic_lib && flutter test test/data/models/wallet</code>

Expected: FAIL because wallet model files do not exist.

- [ ] **Step 2: Implement the amount boundary and wallet summary**

<code>wallet_amount.dart</code> must contain:

~~~dart
enum WalletCurrency { starCandy, bonusStarCandy, cottonCandy }

extension WalletCurrencyWire on WalletCurrency {
  String get wireValue => switch (this) {
        WalletCurrency.starCandy => 'STAR_CANDY',
        WalletCurrency.bonusStarCandy => 'BONUS_STAR_CANDY',
        WalletCurrency.cottonCandy => 'COTTON_CANDY',
      };

  static WalletCurrency parse(String value) => switch (value) {
        'STAR_CANDY' => WalletCurrency.starCandy,
        'BONUS_STAR_CANDY' => WalletCurrency.bonusStarCandy,
        'COTTON_CANDY' => WalletCurrency.cottonCandy,
        _ => throw FormatException('Unknown wallet currency: ' + value),
      };
}

class WalletCurrencyConverter
    implements JsonConverter<WalletCurrency, String> {
  const WalletCurrencyConverter();

  @override
  WalletCurrency fromJson(String value) => WalletCurrencyWire.parse(value);

  @override
  String toJson(WalletCurrency value) => value.wireValue;
}

class WalletAmountConverter implements JsonConverter<BigInt, Object?> {
  const WalletAmountConverter();

  @override
  BigInt fromJson(Object? value) {
    if (value is! String || !RegExp(r'^-?[0-9]+$').hasMatch(value)) {
      throw FormatException('Wallet amount must be a decimal string');
    }
    return BigInt.parse(value);
  }

  @override
  Object toJson(BigInt value) => value.toString();
}

Map<String, dynamic> requireExactContractKeys(
  Map<String, dynamic> json,
  Set<String> expected,
) {
  final actual = json.keys.toSet();
  if (actual.length != expected.length ||
      !actual.containsAll(expected)) {
    throw FormatException(
      'Contract keys differ: expected $expected, got $actual',
    );
  }
  return json;
}

String formatWalletAmount(BigInt amount) {
  final negative = amount.isNegative;
  final digits = amount.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return negative ? '-' + grouped : grouped;
}
~~~

<code>WalletSummaryModel.fromJson</code>, <code>CurrencyHistoryItemModel.fromJson</code>, <code>CurrencyHistoryPageModel.fromJson</code>은 generated decoder를 호출하기 전에 <code>requireExactContractKeys</code>로 위 canonical key set을 검증한다. 이 경계는 nullable key와 알 수 없는 alias를 묵시하지 않는다.

<code>wallet_summary.dart</code> must define:

~~~dart
@freezed
abstract class WalletSummaryModel with _$WalletSummaryModel {
  const factory WalletSummaryModel({
    @JsonKey(name: 'contract_version') required String contractVersion,
    @WalletAmountConverter() required BigInt star,
    @WalletAmountConverter() required BigInt bonus,
    @WalletAmountConverter() required BigInt cotton,
    @JsonKey(name: 'cotton_expiring_amount')
    @WalletAmountConverter()
    required BigInt cottonExpiringAmount,
    @JsonKey(name: 'cotton_next_expires_at')
    required DateTime? cottonNextExpiresAt,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
  }) = _WalletSummaryModel;

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$WalletSummaryModelFromJson(json);
}
~~~

- [ ] **Step 3: Implement cursor history models**

<code>currency_history.dart</code> must expose:

~~~dart
@freezed
abstract class CurrencyHistoryItemModel with _$CurrencyHistoryItemModel {
  const factory CurrencyHistoryItemModel({
    required String id,
    @WalletCurrencyConverter() required WalletCurrency currency,
    @JsonKey(name: 'event_type') required String eventType,
    required String origin,
    @WalletAmountConverter() required BigInt delta,
    @JsonKey(name: 'balance_effect')
    @WalletAmountConverter()
    required BigInt balanceEffect,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @JsonKey(name: 'purchase_id') String? purchaseId,
    @JsonKey(name: 'refund_id') String? refundId,
    @JsonKey(name: 'grant_id') String? grantId,
    @JsonKey(name: 'operation_id') required String operationId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _CurrencyHistoryItemModel;

  factory CurrencyHistoryItemModel.fromJson(Map<String, dynamic> json) =>
      _$CurrencyHistoryItemModelFromJson(json);
}

@freezed
abstract class CurrencyHistoryPageModel with _$CurrencyHistoryPageModel {
  const factory CurrencyHistoryPageModel({
    required List<CurrencyHistoryItemModel> items,
    @JsonKey(name: 'total_count')
    @WalletAmountConverter()
    required BigInt totalCount,
    @JsonKey(name: 'next_cursor') String? nextCursor,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
  }) = _CurrencyHistoryPageModel;

  factory CurrencyHistoryPageModel.fromJson(Map<String, dynamic> json) =>
      _$CurrencyHistoryPageModelFromJson(json);
}
~~~

Use a custom <code>WalletCurrencyConverter</code> beside the enum so generated JSON maps the exact wire values.

- [ ] **Step 4: Generate code and verify**

Run:

~~~bash
cd picnic_lib
dart run build_runner build --delete-conflicting-outputs
flutter test test/data/models/wallet
~~~

Expected: generated files are created under <code>lib/generated/providers/models/wallet/</code>; all wallet model tests PASS.

- [ ] **Step 5: Commit**

~~~bash
git add picnic_lib/lib/data/models/wallet picnic_lib/lib/generated/providers/models/wallet picnic_lib/test/data/models/wallet picnic_lib/test/fixtures/wallet_contracts
git commit -m "feat(wallet): add stable wallet contract models"
~~~

### Task 2: Wallet Repository and Riverpod State

**Files:**
- Create: <code>picnic_lib/lib/data/repositories/wallet_repository.dart</code>
- Create: <code>picnic_lib/lib/presentation/providers/wallet_provider.dart</code>
- Test: <code>picnic_lib/test/data/repositories/wallet_repository_test.dart</code>
- Test: <code>picnic_lib/test/presentation/providers/wallet_provider_test.dart</code>
- Modify: <code>picnic_lib/lib/presentation/providers/user_info_provider.dart</code>

**Interfaces:**
- Consumes: <code>WalletSummaryModel</code>, <code>CurrencyHistoryPageModel</code>, <code>WalletCurrency.wireValue</code>.
- Produces: <code>WalletRepository.getSummary()</code>, <code>WalletRepository.getHistory({required WalletCurrency currency, String? cursor, int limit = 20})</code>, <code>walletSummaryProvider</code>, <code>currencyHistoryProvider(currency)</code>.

- [ ] **Step 1: Write failing repository tests**

Use <code>MockSupabaseHttpClient</code> to assert exact RPC requests:

~~~dart
expect(requestedPath, contains('/rpc/get_wallet_summary'));
expect(historyBody, {
  'p_currency': 'COTTON_CANDY',
  'p_cursor': null,
  'p_limit': 20,
});
expect(await repository.getSummary(), isA<WalletSummaryModel>());
~~~

Run: <code>cd picnic_lib && flutter test test/data/repositories/wallet_repository_test.dart</code>

Expected: FAIL because <code>WalletRepository</code> is undefined.

- [ ] **Step 2: Implement injected repository**

~~~dart
class WalletRepository {
  const WalletRepository(this.client);
  final SupabaseClient client;

  Future<WalletSummaryModel> getSummary() async {
    final value = await client.rpc('get_wallet_summary');
    return WalletSummaryModel.fromJson(
      Map<String, dynamic>.from(value as Map),
    );
  }

  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) async {
    final value = await client.rpc(
      'get_currency_history',
      params: {
        'p_currency': currency.wireValue,
        'p_cursor': cursor,
        'p_limit': limit,
      },
    );
    return CurrencyHistoryPageModel.fromJson(
      Map<String, dynamic>.from(value as Map),
    );
  }
}
~~~

- [ ] **Step 3: Write failing provider refresh and pagination tests**

Test that summary builds once, <code>refresh()</code> replaces the snapshot, and history appends one cursor page without duplicates:

~~~dart
final container = ProviderContainer(
  overrides: [
    walletRepositoryProvider.overrideWithValue(fakeRepository),
  ],
);
addTearDown(container.dispose);

expect((await container.read(walletSummaryProvider.future)).cotton, BigInt.zero);
await container.read(walletSummaryProvider.notifier).refresh();
expect(container.read(walletSummaryProvider).value!.cotton, BigInt.from(30));

await container
    .read(currencyHistoryProvider(WalletCurrency.cottonCandy).notifier)
    .loadNext();
expect(
  container
      .read(currencyHistoryProvider(WalletCurrency.cottonCandy))
      .value!
      .items
      .map((item) => item.id)
      .toSet()
      .length,
  2,
);
~~~

Expected: FAIL because generated providers are absent.

- [ ] **Step 4: Implement keep-alive summary and family history providers**

~~~dart
@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) => WalletRepository(supabase);

@Riverpod(keepAlive: true)
class WalletSummary extends _$WalletSummary {
  @override
  Future<WalletSummaryModel> build() {
    return ref.watch(walletRepositoryProvider).getSummary();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(walletRepositoryProvider).getSummary,
    );
  }

  void setSummary(WalletSummaryModel summary) {
    state = AsyncData(summary);
  }
}

@riverpod
class CurrencyHistory extends _$CurrencyHistory {
  @override
  Future<CurrencyHistoryPageModel> build(WalletCurrency currency) {
    return ref.watch(walletRepositoryProvider).getHistory(currency: currency);
  }

  Future<void> loadNext() async {
    final current = state.value;
    if (current == null || current.nextCursor == null) return;
    final next = await ref.read(walletRepositoryProvider).getHistory(
      currency: currency,
      cursor: current.nextCursor,
    );
    final seen = current.items.map((item) => item.id).toSet();
    state = AsyncData(current.copyWith(
      items: [
        ...current.items,
        ...next.items.where((item) => seen.add(item.id)),
      ],
      nextCursor: next.nextCursor,
      totalCount: next.totalCount,
    ));
  }
}
~~~

Keep <code>UserInfo</code> profile loading for identity, avatar and admin fields. Add a comment beside the raw balance select stating new wallet UI must use <code>walletSummaryProvider</code>; do not add a Cotton column to <code>UserProfilesModel</code>.

- [ ] **Step 5: Generate, test, commit**

Run:

~~~bash
cd picnic_lib
dart run build_runner build --delete-conflicting-outputs
flutter test test/data/repositories/wallet_repository_test.dart test/presentation/providers/wallet_provider_test.dart
~~~

Expected: all repository/provider tests PASS.

~~~bash
git add picnic_lib/lib/data/repositories/wallet_repository.dart picnic_lib/lib/presentation/providers/wallet_provider.dart picnic_lib/lib/generated/providers/wallet_provider.g.dart picnic_lib/lib/presentation/providers/user_info_provider.dart picnic_lib/test/data/repositories/wallet_repository_test.dart picnic_lib/test/presentation/providers/wallet_provider_test.dart
git commit -m "feat(wallet): load balances from wallet summary rpc"
~~~

### Task 3: Approved Icon Family, Localization, and Three-Segment Wallet

**Files:**
- Create: <code>picnic_lib/assets/icons/store/currency_star_candy.png</code>
- Create: <code>picnic_lib/assets/icons/store/currency_bonus_star_candy.png</code>
- Create: <code>picnic_lib/assets/icons/store/currency_cotton_candy.png</code>
- Create: <code>picnic_lib/lib/presentation/widgets/wallet/wallet_summary_panel.dart</code>
- Modify: <code>picnic_lib/lib/l10n/app_en.arb</code>
- Modify: <code>picnic_lib/lib/l10n/app_ko.arb</code>
- Modify generated: <code>picnic_lib/lib/l10n/app_localizations*.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/star_candy_info_text.dart</code>
- Modify: <code>picnic_lib/lib/presentation/common/common_my_point_info.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/store/common/store_point_info.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart</code>
- Test: <code>picnic_lib/test/presentation/widgets/wallet/wallet_summary_panel_test.dart</code>
- Test: <code>picnic_lib/test/presentation/widgets/wallet/wallet_asset_test.dart</code>
- Modify test: <code>picnic_lib/test/presentation/widgets/star_candy_info_text_test.dart</code>
- Modify test: <code>picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart</code>

**Interfaces:**
- Consumes: <code>walletSummaryProvider</code>, <code>formatWalletAmount</code>.
- Produces: <code>WalletSummaryPanel</code>; existing <code>StarCandyInfoText</code> remains source-compatible as a compact adapter.

- [ ] **Step 1: Write failing asset and widget tests**

~~~dart
for (final path in const [
  'assets/icons/store/currency_star_candy.png',
  'assets/icons/store/currency_bonus_star_candy.png',
  'assets/icons/store/currency_cotton_candy.png',
]) {
  final bytes = File(path).readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  expect(frame.image.width, 192);
  expect(frame.image.height, 192);
}

expect(find.text('스타캔디'), findsOneWidget);
expect(find.text('보너스 스타캔디'), findsOneWidget);
expect(find.text('코튼캔디'), findsOneWidget);
expect(find.textContaining('오늘 만료 10'), findsOneWidget);
expect(
  tester.getTopLeft(find.text('코튼캔디')).dx,
  tester.getTopLeft(find.text('스타캔디')).dx,
);
~~~

Run: <code>cd picnic_lib && flutter test test/presentation/widgets/wallet</code>

Expected: FAIL because assets/widget/localization getters are missing.

- [ ] **Step 2: Export the approved v3 PNGs**

Run:

~~~bash
cd /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy
sips -z 192 192 .superpowers/brainstorm/91609-1784613984/content/currency-star-candy-v3.png --out picnic_lib/assets/icons/store/currency_star_candy.png
sips -z 192 192 .superpowers/brainstorm/91609-1784613984/content/currency-bonus-star-candy-v3.png --out picnic_lib/assets/icons/store/currency_bonus_star_candy.png
sips -z 192 192 .superpowers/brainstorm/91609-1784613984/content/currency-cotton-candy-v3.png --out picnic_lib/assets/icons/store/currency_cotton_candy.png
~~~

Expected: all three outputs are 192×192 PNG with alpha. The source files remain untracked runtime inputs.

- [ ] **Step 3: Add exact localization keys and generate**

Add these English/Korean values:

~~~json
{
  "wallet_star_candy": "Star Candy",
  "wallet_bonus_star_candy": "Bonus Star Candy",
  "wallet_cotton_candy": "Cotton Candy",
  "wallet_cotton_expires_today": "Expires today: {amount}",
  "wallet_cotton_next_expiry": "Next expiry: {date}",
  "wallet_load_failed": "Could not load wallet.",
  "wallet_history_title": "Candy history",
  "wallet_history_empty": "No history yet.",
  "candy_boost_day": "Candy Boost Day",
  "candy_boost_exact_double": "Base reward + 100% extra bonus",
  "candy_boost_extra_bonus": "Base reward + extra bonus",
  "ad_reward_pending": "Checking your reward",
  "ad_reward_granted": "Cotton Candy received",
  "ad_reward_not_granted": "The reward was not granted"
}
~~~

~~~json
{
  "wallet_star_candy": "스타캔디",
  "wallet_bonus_star_candy": "보너스 스타캔디",
  "wallet_cotton_candy": "코튼캔디",
  "wallet_cotton_expires_today": "오늘 만료 {amount}",
  "wallet_cotton_next_expiry": "다음 만료 {date}",
  "wallet_load_failed": "지갑 정보를 불러오지 못했습니다.",
  "wallet_history_title": "캔디 내역",
  "wallet_history_empty": "아직 내역이 없습니다.",
  "candy_boost_day": "캔디 부스트 데이",
  "candy_boost_exact_double": "기본 지급 + 추가 보너스 100%",
  "candy_boost_extra_bonus": "기본 지급 + 추가 보너스",
  "ad_reward_pending": "보상을 확인하고 있어요",
  "ad_reward_granted": "코튼캔디를 받았어요",
  "ad_reward_not_granted": "보상이 지급되지 않았어요"
}
~~~

Include ARB metadata for the two parameterized messages, then run:

~~~bash
cd picnic_lib
flutter gen-l10n
~~~

Expected: generation exits 0 and new getters exist in generated localization classes; other locales use the template fallback.

- [ ] **Step 4: Implement the three-segment panel**

~~~dart
class WalletSummaryPanel extends ConsumerWidget {
  const WalletSummaryPanel({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(walletSummaryProvider).when(
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => Text(AppLocalizations.of(context).wallet_load_failed),
      data: (wallet) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: WalletCurrencySegment(
            asset: 'assets/icons/store/currency_star_candy.png',
            label: AppLocalizations.of(context).wallet_star_candy,
            amount: wallet.star,
          )),
          Expanded(child: WalletCurrencySegment(
            asset: 'assets/icons/store/currency_bonus_star_candy.png',
            label: AppLocalizations.of(context).wallet_bonus_star_candy,
            amount: wallet.bonus,
          )),
          Expanded(child: WalletCurrencySegment(
            asset: 'assets/icons/store/currency_cotton_candy.png',
            label: AppLocalizations.of(context).wallet_cotton_candy,
            amount: wallet.cotton,
            secondary: buildCottonExpiryText(context, wallet),
          )),
        ],
      ),
    );
  }
}

String? buildCottonExpiryText(
  BuildContext context,
  WalletSummaryModel wallet,
) {
  final values = <String>[];
  if (wallet.cottonExpiringAmount > BigInt.zero) {
    values.add(
      AppLocalizations.of(context).wallet_cotton_expires_today(
        formatWalletAmount(wallet.cottonExpiringAmount),
      ),
    );
  }
  if (wallet.cottonNextExpiresAt != null) {
    values.add(
      AppLocalizations.of(context).wallet_cotton_next_expiry(
        DateFormat.yMd(Localizations.localeOf(context).toString())
            .add_Hm()
            .format(wallet.cottonNextExpiresAt!.toLocal()),
      ),
    );
  }
  return values.isEmpty ? null : values.join('\n');
}

class WalletCurrencySegment extends StatelessWidget {
  const WalletCurrencySegment({
    super.key,
    required this.asset,
    required this.label,
    required this.amount,
    this.secondary,
  });

  final String asset;
  final String label;
  final BigInt amount;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            asset,
            package: 'picnic_lib',
            width: 40,
            height: 40,
          ),
          Text(label, textAlign: TextAlign.left),
          Text(formatWalletAmount(amount), textAlign: TextAlign.left),
          if (secondary != null)
            Text(secondary!, textAlign: TextAlign.left),
        ],
      ),
    );
  }
}
~~~

Each <code>WalletCurrencySegment</code> uses <code>CrossAxisAlignment.start</code>, semantic label equal to the localized visible name, and package <code>picnic_lib</code>. Cotton secondary text uses only server <code>cottonExpiringAmount</code>, <code>cottonNextExpiresAt</code>, and <code>snapshotAt</code>.

Replace <code>StarCandyInfoText</code> body with <code>WalletSummaryPanel(compact: true)</code>. Change <code>CommonMyPoint</code> to watch <code>walletSummaryProvider</code>, replace <code>AnimatedDigitWidget</code> with <code>Text(formatWalletAmount(wallet.star + wallet.bonus + wallet.cotton))</code>, and therefore avoid a BigInt-to-num precision loss. Keep <code>StorePointInfo</code> and profile call sites source-compatible.

- [ ] **Step 5: Extend the usage policy and verify**

The policy dialog must show Bonus policy plus a Cotton section containing server expiry amount/time; it must not infer expiry from local time.

Run:

~~~bash
cd picnic_lib
flutter test test/presentation/widgets/wallet test/presentation/widgets/star_candy_info_text_test.dart test/presentation/widgets/vote/store/common
if rg -n "솜사탕" lib assets test; then exit 1; fi
~~~

Expected: all tests PASS and the forbidden Korean term search exits 0 with no matches.

- [ ] **Step 6: Commit only product assets**

~~~bash
git add picnic_lib/assets/icons/store/currency_star_candy.png picnic_lib/assets/icons/store/currency_bonus_star_candy.png picnic_lib/assets/icons/store/currency_cotton_candy.png picnic_lib/lib/l10n picnic_lib/lib/presentation/widgets/wallet picnic_lib/lib/presentation/widgets/star_candy_info_text.dart picnic_lib/lib/presentation/common/common_my_point_info.dart picnic_lib/lib/presentation/widgets/vote/store/common picnic_lib/test/presentation/widgets/wallet picnic_lib/test/presentation/widgets/star_candy_info_text_test.dart picnic_lib/test/presentation/widgets/vote/store/common
if git diff --cached --name-only | rg "^\\.superpowers/"; then exit 1; fi
git commit -m "feat(wallet): add three-currency wallet presentation"
~~~

### Task 4: Currency History and Cotton Vote History

**Files:**
- Create: <code>picnic_lib/lib/presentation/pages/my_page/currency_history_page.dart</code>
- Create: <code>picnic_lib/lib/presentation/widgets/wallet/currency_history_list_item.dart</code>
- Modify: <code>picnic_lib/lib/presentation/pages/my_page/my_page.dart</code>
- Modify: <code>picnic_lib/lib/data/models/vote/vote_pick.dart</code>
- Modify generated: <code>picnic_lib/lib/generated/providers/models/vote/vote_pick.*.dart</code>
- Modify: <code>picnic_lib/lib/presentation/pages/my_page/vote_history_page.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/vote_history_list_item.dart</code>
- Test: <code>picnic_lib/test/presentation/pages/my_page/currency_history_page_test.dart</code>
- Test: <code>picnic_lib/test/presentation/widgets/wallet/currency_history_list_item_test.dart</code>
- Modify test: <code>picnic_lib/test/presentation/pages/my_page/vote_history_page_test.dart</code>
- Modify test: <code>picnic_lib/test/presentation/widgets/vote/vote_history_list_item_test.dart</code>

**Interfaces:**
- Consumes: <code>currencyHistoryProvider(WalletCurrency)</code>.
- Produces: <code>CurrencyHistoryPage</code>; <code>VotePickModel.cottonCandyUsage</code>.

- [ ] **Step 1: Write failing tab, cursor, sign, and vote usage tests**

~~~dart
expect(find.text('스타캔디'), findsOneWidget);
expect(find.text('보너스 스타캔디'), findsOneWidget);
expect(find.text('코튼캔디'), findsOneWidget);
await tester.tap(find.text('코튼캔디'));
await tester.pumpAndSettle();
expect(find.text('+30'), findsOneWidget);
expect(find.text('-10'), findsOneWidget);

final pick = VotePickModel.fromJson({
  ...votePickFixture,
  'cotton_candy_usage': 7,
});
expect(pick.cottonCandyUsage, 7);
~~~

Run: <code>cd picnic_lib && flutter test test/presentation/pages/my_page/currency_history_page_test.dart test/presentation/widgets/vote/vote_history_list_item_test.dart</code>

Expected: FAIL because the page and Cotton field do not exist.

- [ ] **Step 2: Implement history list and page**

<code>CurrencyHistoryListItem</code> renders localized currency, signed <code>delta</code>, <code>eventType</code>, <code>origin</code>, <code>createdAt</code>, optional <code>expiresAt</code>, and a copyable support reference <code>operationId</code>. <code>CurrencyHistoryPage</code> uses three <code>Tab</code>s in wallet display order and calls <code>loadNext()</code> only when <code>nextCursor</code> is non-null.

~~~dart
const currencies = [
  WalletCurrency.starCandy,
  WalletCurrency.bonusStarCandy,
  WalletCurrency.cottonCandy,
];

NotificationListener<ScrollEndNotification>(
  onNotification: (notification) {
    if (notification.metrics.extentAfter == 0) {
      ref.read(currencyHistoryProvider(currency).notifier).loadNext();
    }
    return false;
  },
  child: ListView.builder(
    itemCount: page.items.length,
    itemBuilder: (_, index) =>
        CurrencyHistoryListItem(item: page.items[index]),
  ),
);
~~~

Wire a normal My Page menu item to <code>CurrencyHistoryPage</code>; do not reuse the empty admin-only charge-history callback.

- [ ] **Step 3: Add Cotton to vote pick read/display**

~~~dart
@JsonKey(name: 'cotton_candy_usage') int? cottonCandyUsage,
~~~

Add <code>cotton_candy_usage</code> to <code>VoteHistoryPage._fetch()</code> select and render non-zero usage with <code>currency_cotton_candy.png</code>. Preserve Star/Bonus rows and <code>amount = cotton + bonus + star</code> assertions in tests.

- [ ] **Step 4: Generate, test, commit**

Run:

~~~bash
cd picnic_lib
dart run build_runner build --delete-conflicting-outputs
flutter test test/presentation/pages/my_page/currency_history_page_test.dart test/presentation/widgets/wallet/currency_history_list_item_test.dart test/presentation/pages/my_page/vote_history_page_test.dart test/presentation/widgets/vote/vote_history_list_item_test.dart
~~~

Expected: all four test files PASS.

~~~bash
git add picnic_lib/lib/presentation/pages/my_page picnic_lib/lib/presentation/widgets/wallet/currency_history_list_item.dart picnic_lib/lib/data/models/vote/vote_pick.dart picnic_lib/lib/generated/providers/models/vote/vote_pick.*.dart picnic_lib/lib/presentation/widgets/vote/vote_history_list_item.dart picnic_lib/test/presentation/pages/my_page picnic_lib/test/presentation/widgets/wallet/currency_history_list_item_test.dart picnic_lib/test/presentation/widgets/vote/vote_history_list_item_test.dart
git commit -m "feat(wallet): add three-currency history views"
~~~

### Task 5: General Vote Through the v3-Compatible voting-v2 Wrapper

**Files:**
- Create: <code>picnic_lib/lib/data/models/vote/vote_transaction.dart</code>
- Create: <code>picnic_lib/lib/data/repositories/vote_transaction_repository.dart</code>
- Create: <code>picnic_lib/lib/presentation/providers/vote_transaction_provider.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/voting/voting_dialog.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/voting/voting_dialog_helper.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/voting/voting_usage_helper.dart</code>
- Test: <code>picnic_lib/test/data/repositories/vote_transaction_repository_test.dart</code>
- Modify test: <code>picnic_lib/test/presentation/widgets/vote/voting/voting_dialog_test.dart</code>
- Modify test: <code>picnic_lib/test/presentation/widgets/vote/voting/voting_dialog_helper_test.dart</code>
- Regression test: <code>picnic_lib/test/presentation/widgets/vote/voting/jma_voting_dialog_test.dart</code>
- Fixture: <code>picnic_lib/test/fixtures/wallet_contracts/vote_result_v3.json</code>

**Interfaces:**
- Consumes: <code>WalletSummaryModel</code>, endpoint <code>voting-v2</code>.
- Produces: <code>VoteTransactionRequest</code>, <code>VoteTransactionResultModel</code>, <code>VoteTransactionRepository.performGeneralVote(VoteTransactionRequest)</code>, <code>voteTransactionRepositoryProvider</code>.

- [ ] **Step 1: Write failing request-shape/idempotency tests**

~~~dart
final requestId = const Uuid().v4();
await repository.performGeneralVote(
  VoteTransactionRequest(
    voteId: 10,
    voteItemId: 20,
    amount: BigInt.from(30),
    requestId: requestId,
  ),
);

expect(calls.map((call) => call.functionName).toSet(), {'voting-v2'});
expect(calls.map((call) => call.body['request_id']).toSet(), {requestId});
expect(calls.single.body, isNot(contains('star_candy_usage')));
expect(calls.single.body, isNot(contains('star_candy_bonus_usage')));
expect(calls.single.body, isNot(contains('cotton_candy_usage')));
~~~

Make the fake return the flat stable error envelope <code>{domain_code:'TX_CONFLICT_RETRYABLE',retryable:true}</code> three times with a non-429 status and succeed on the fourth call. Assert all four calls share one <code>request_id</code>. Add separate one-call cases for a plain 429, a 429 carrying that same envelope, a different <code>domain_code</code>, and <code>retryable:false</code>; none may retry. Cover both Map and JSON-string <code>FunctionException.details</code>. Parse the canonical fixture usage as Cotton 5, Bonus 7, Star 5 and assert the returned wallet is Star 95, Bonus 23, Cotton 0; retain <code>operation_id</code>/<code>replayed</code> exactly.

Run: <code>cd picnic_lib && flutter test test/data/repositories/vote_transaction_repository_test.dart</code>

Expected: FAIL because the repository is absent.

- [ ] **Step 2: Implement the exact general vote contract**

~~~dart
@freezed
abstract class VoteTransactionRequest with _$VoteTransactionRequest {
  const factory VoteTransactionRequest({
    required int voteId,
    required int voteItemId,
    required BigInt amount,
    required String requestId,
  }) = _VoteTransactionRequest;
}

@freezed
abstract class VoteUsageModel with _$VoteUsageModel {
  const factory VoteUsageModel({
    @JsonKey(name: 'cotton_candy_usage')
    @WalletAmountConverter()
    required BigInt cottonCandy,
    @JsonKey(name: 'star_candy_bonus_usage')
    @WalletAmountConverter()
    required BigInt bonusStarCandy,
    @JsonKey(name: 'star_candy_usage')
    @WalletAmountConverter()
    required BigInt starCandy,
  }) = _VoteUsageModel;

  factory VoteUsageModel.fromJson(Map<String, dynamic> json) =>
      _$VoteUsageModelFromJson(json);
}

@freezed
abstract class VoteTransactionResultModel
    with _$VoteTransactionResultModel {
  const VoteTransactionResultModel._();

  const factory VoteTransactionResultModel({
    @JsonKey(name: 'operation_id') required String operationId,
    required bool replayed,
    @JsonKey(name: 'votePickId') required int votePickId,
    @JsonKey(name: 'updatedVoteTotal') required int updatedVoteTotal,
    @JsonKey(name: 'addedVoteTotal') required int addedVoteTotal,
    @JsonKey(name: 'updatedAt') required DateTime updatedAt,
    required VoteUsageModel usage,
    required WalletSummaryModel wallet,
  }) = _VoteTransactionResultModel;

  Map<String, dynamic> toLegacyDialogMap() => {
        'operation_id': operationId,
        'replayed': replayed,
        'votePickId': votePickId,
        'updatedVoteTotal': updatedVoteTotal,
        'addedVoteTotal': addedVoteTotal,
        'updatedAt': updatedAt.toIso8601String(),
        'usage': usage.toJson(),
        'wallet': wallet.toJson(),
      };

  factory VoteTransactionResultModel.fromJson(Map<String, dynamic> json) =>
      _$VoteTransactionResultModelFromJson(json);
}

class VoteTransactionRepository {
  VoteTransactionRepository(this.client, {
    this.delay = Future<void>.delayed,
    VoteRetryJitter? nextJitter,
  }) : nextJitter = nextJitter ?? Random.secure().nextInt;
  final SupabaseClient client;
  final Future<void> Function(Duration) delay;
  final VoteRetryJitter nextJitter;

  static const _retryCaps = [
    Duration(milliseconds: 250),
    Duration(milliseconds: 500),
    Duration(milliseconds: 1000),
  ];

  Map<String, dynamic>? _errorEnvelope(Object? details) {
    if (details is Map) return Map<String, dynamic>.from(details);
    if (details is String) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  bool _isRetryableConflict(FunctionException error) {
    if (error.status == 429) return false;
    final envelope = _errorEnvelope(error.details);
    return envelope?['domain_code'] == 'TX_CONFLICT_RETRYABLE' &&
        envelope?['retryable'] == true;
  }

  Future<VoteTransactionResultModel> performGeneralVote(
    VoteTransactionRequest request,
  ) async {
    var retries = 0;
    while (true) {
      try {
        final response = await client.functions.invoke(
          'voting-v2',
          body: {
            'vote_id': request.voteId,
            'vote_item_id': request.voteItemId,
            'amount': request.amount.toString(),
            'request_id': request.requestId,
          },
        );
        return VoteTransactionResultModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } on FunctionException catch (error) {
        if (!_isRetryableConflict(error) ||
            retries >= _retryCaps.length) {
          rethrow;
        }
        final cap = _retryCaps[retries].inMilliseconds;
        retries += 1;
        await delay(Duration(milliseconds: nextJitter(cap + 1)));
      }
    }
  }
}
~~~

Define <code>typedef VoteRetryJitter = int Function(int upperExclusive)</code> and import <code>dart:convert</code>/<code>dart:math</code>. There are at most three retries after the initial request. The injected jitter and delay make tests deterministic; production uses full jitter bounded by 250/500/1000 ms. HTTP 429 is never retryable, even if its body happens to mimic the stable envelope.

The result model preserves existing <code>votePickId</code>, <code>updatedVoteTotal</code>, <code>addedVoteTotal</code>, <code>updatedAt</code> and adds typed <code>usage.cottonCandy</code>, <code>usage.bonusStarCandy</code>, <code>usage.starCandy</code>, and <code>wallet</code>.

Expose the injected repository:

~~~dart
@Riverpod(keepAlive: true)
VoteTransactionRepository voteTransactionRepository(Ref ref) {
  return VoteTransactionRepository(supabase);
}
~~~

- [ ] **Step 3: Split the existing `_handleVote`/`_performVoting` paths**

Replace the current precheck in <code>_handleVote(int myStarCandy, String userId)</code>. A normal <code>VotePortal.vote</code> awaits <code>walletSummaryProvider.future</code> and validates with BigInt only; PIC keeps the existing profile-derived <code>myStarCandy</code> check:

~~~dart
final amount = BigInt.from(voteAmount);
final hasBalance = widget.portalType == VotePortal.vote
    ? VotingDialogHelper.hasGeneralVoteBalance(
        await ref.read(walletSummaryProvider.future),
        amount,
      )
    : BigInt.from(myStarCandy) >= amount;
if (voteAmount == 0 || !hasBalance) {
  // Keep the existing zero/recharge dialog copy and return.
}
~~~

<code>hasGeneralVoteBalance</code> compares <code>amount &lt;= wallet.cotton + wallet.bonus + wallet.star</code> without <code>int</code>/<code>double</code> conversion. Add a test using <code>star:'9007199254740993'</code> to prove values above JavaScript's safe integer remain exact.

The submit button must be reachable with Cotton-only funds. Therefore update the existing synchronous <code>_validateVote()</code>, <code>_toggleCheckAll()</code>, and <code>VotingStarCandyInfo</code> input too: <code>build</code> watches <code>walletSummaryProvider</code> for normal portals and listens for snapshot changes to rerun validation; normal validation/display uses a <code>BigInt</code> sum and <code>formatWalletAmount</code>, while PIC alone calls <code>_getMyStarCandy()</code>. For normal “all”, cap the text request at the server's <code>2147483647</code> per-vote maximum using BigInt comparison and format its decimal string directly. Never call <code>toInt()</code> or <code>toDouble()</code> on a wallet balance. Tests cover Cotton-only enabling, loading/error disabled state, the server cap, and the greater-than-JS-safe balance.

Inside the actual existing <code>_performVoting(int voteAmount, String userId)</code>, retain its captured <code>ProviderContainer</code>, optimistic vote-total update, rollback, navigation, and completion-dialog ordering, but branch before calculating client usage:

~~~dart
late final Map<String, dynamic> completionResult;
if (widget.portalType == VotePortal.vote) {
  final requestId = const Uuid().v4();
  final result = await container
      .read(voteTransactionRepositoryProvider)
      .performGeneralVote(
        VoteTransactionRequest(
          voteId: widget.voteModel.id,
          voteItemId: widget.voteItemModel.id,
          amount: BigInt.from(voteAmount),
          requestId: requestId,
        ),
      );
  container.read(walletSummaryProvider.notifier).setSummary(result.wallet);
  container
      .read(asyncVoteItemListProvider(voteId: widget.voteModel.id).notifier)
      .setVoteItem(
        id: widget.voteItemModel.id,
        voteTotal: result.updatedVoteTotal,
      );
  completionResult = result.toLegacyDialogMap();
} else {
  final usage = _calculateUsage(voteAmount);
  final response = await _invokePicVoting(
    voteAmount: voteAmount,
    userId: userId,
    starCandyUsage: usage['star_candy_usage']!,
    starCandyBonusUsage: usage['star_candy_bonus_usage']!,
  );
  container.read(userInfoProvider.notifier).getUserProfiles();
  final serverTotal = response.data['updatedVoteTotal'] as int?;
  if (serverTotal != null) {
    container
        .read(asyncVoteItemListProvider(voteId: widget.voteModel.id).notifier)
        .setVoteItem(id: widget.voteItemModel.id, voteTotal: serverTotal);
  }
  completionResult = Map<String, dynamic>.from(response.data as Map);
}
~~~

Rename the current <code>_invokeVotingWithRetry</code> to the single-call <code>_invokePicVoting</code>. It invokes <code>VotingDialogHelper.getVotingFunctionName(isPicPortal: true)</code> exactly once and preserves the existing <code>user_id</code>, integer <code>amount</code>, <code>star_candy_usage</code>, and <code>star_candy_bonus_usage</code> body. It contains no 429 retry. Normal execution never calls <code>VotingUsageHelper.calculateUsage()</code> and sends no client allocation fields; PIC client allocation and JMA behavior remain unchanged. In the shared catch, refresh <code>walletSummaryProvider</code> for normal votes and <code>userInfoProvider</code> for PIC.

Implement the routing helpers, including whitespace/case normalization, rather than only adding test expectations:

~~~dart
class VotingDialogHelper {
  const VotingDialogHelper._();

  static String getVotingFunctionName({required bool isPicPortal}) =>
      isPicPortal ? 'pic-voting-v2' : 'voting-v2';

  static bool shouldUseJmaDialog({
    required bool isPicPortal,
    required String? partner,
  }) =>
      !isPicPortal && partner?.trim().toLowerCase() == 'jma';
}
~~~

Wire <code>showVotingDialog</code> through that helper so PIC never enters JMA and every other portal has one shared decision point:

~~~dart
final isPicPortal = portalType == VotePortal.pic;
if (VotingDialogHelper.shouldUseJmaDialog(
  isPicPortal: isPicPortal,
  partner: voteModel.partner,
)) {
  return showJmaVotingDialog(
    context: context,
    voteModel: voteModel,
    voteItemModel: voteItemModel,
    portalType: portalType,
  );
}
return showDialog(
  context: context,
  barrierDismissible: true,
  builder: (_) => VotingDialog(
    voteModel: voteModel,
    voteItemModel: voteItemModel,
    portalType: portalType,
  ),
);
~~~

- [ ] **Step 4: Lock exception routing with tests**

Add exact assertions:

~~~dart
expect(
  VotingDialogHelper.getVotingFunctionName(isPicPortal: false),
  'voting-v2',
);
expect(
  VotingDialogHelper.getVotingFunctionName(isPicPortal: true),
  'pic-voting-v2',
);
expect(
  VotingDialogHelper.shouldUseJmaDialog(
    isPicPortal: false,
    partner: 'jma',
  ),
  isTrue,
);
expect(
  VotingDialogHelper.shouldUseJmaDialog(
    isPicPortal: true,
    partner: 'jma',
  ),
  isFalse,
);
~~~

Also assert no change to Goonghap source files in the staged diff.

- [ ] **Step 5: Generate, test, commit**

Run:

~~~bash
cd picnic_lib
dart run build_runner build --delete-conflicting-outputs
flutter test test/data/repositories/vote_transaction_repository_test.dart test/presentation/widgets/vote/voting/voting_dialog_test.dart test/presentation/widgets/vote/voting/voting_dialog_helper_test.dart test/presentation/widgets/vote/voting/jma_voting_dialog_test.dart
~~~

Expected: retry/request tests PASS; normal balance includes Cotton; PIC/JMA regression tests PASS.

~~~bash
git add picnic_lib/lib/data/models/vote/vote_transaction.dart picnic_lib/lib/data/repositories/vote_transaction_repository.dart picnic_lib/lib/presentation/providers/vote_transaction_provider.dart picnic_lib/lib/generated/providers/models/vote/vote_transaction.*.dart picnic_lib/lib/generated/providers/vote_transaction_provider.g.dart picnic_lib/lib/presentation/widgets/vote/voting picnic_lib/test/data/repositories/vote_transaction_repository_test.dart picnic_lib/test/presentation/widgets/vote/voting picnic_lib/test/fixtures/wallet_contracts/vote_result_v3.json
if git diff --cached --name-only -- picnic_lib/lib | rg "goonghap|jma_voting|pic-voting"; then exit 1; fi
git commit -m "feat(vote): route general votes through wallet v3"
~~~

### Task 6: Durable Ad Reward Contract and Internal Shortform

**Files:**
- Create: <code>picnic_lib/lib/data/models/ad/ad_reward_status.dart</code>
- Create: <code>picnic_lib/lib/data/repositories/ad_reward_repository.dart</code>
- Create: <code>picnic_lib/lib/data/storage/pending_ad_reward_store.dart</code>
- Create: <code>picnic_lib/lib/presentation/providers/ad_reward_provider.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart</code>
- Test: <code>picnic_lib/test/data/repositories/ad_reward_repository_test.dart</code>
- Test: <code>picnic_lib/test/data/storage/pending_ad_reward_store_test.dart</code>
- Modify test: <code>picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform_test.dart</code>
- Modify test: <code>picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page_test.dart</code>
- Fixtures: <code>ad_reward_pending_v1.json</code>, <code>ad_reward_granted_v1.json</code>
- Backend prerequisite owned by the Supabase wallet-core plan: <code>/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/ad-shortform-issue/index.ts</code> returns additive top-level <code>impression_id</code> from the inserted <code>ad_impressions.id</code>.

**Interfaces:**
- Produces: <code>AdRewardReference</code>, <code>AdRewardStatusModel</code>, <code>AdRewardRepository</code>, <code>PendingAdRewardStore</code>, <code>adRewardRepositoryProvider</code>, <code>pendingAdRewardStoreProvider</code>, typed shortform callback.

- [ ] **Step 1: Write failing model/storage tests**

~~~dart
const reference = AdRewardReference(
  type: AdRewardReferenceType.internalImpression,
  id: '018f4f72-2ff0-7ae0-bf62-5b40d9855472',
);
await store.add('user-a', reference);
await store.add('user-a', reference);
expect(await store.readAll('user-a'), [reference]);
expect(await store.readAll('user-b'), isEmpty);

final status = AdRewardStatusModel.fromJson(grantedFixture);
expect(status.state, AdRewardState.granted);
expect(status.grant!.currency, WalletCurrency.cottonCandy);
~~~

Assert pending/granted fixture key sets against the canonical block. Pending must contain <code>grant:null</code>; granted must contain every grant key and nested wallet key. Reject numeric <code>amount</code>/<code>total_count</code>, flattened <code>grant_amount</code>/<code>wallet_cotton</code>, <code>status</code> in place of <code>state</code>, omitted nullable keys, and unknown aliases with <code>FormatException</code>.

Run: <code>cd picnic_lib && flutter test test/data/models/ad test/data/storage/pending_ad_reward_store_test.dart</code>

Expected: FAIL because the types and store are absent.

- [ ] **Step 2: Implement exact reward types and storage key**

~~~dart
enum AdRewardReferenceType { pangleClaim, internalImpression }
enum AdRewardState { pending, granted, denied, expired, abandoned }

extension AdRewardReferenceTypeWire on AdRewardReferenceType {
  String get wireValue => switch (this) {
        AdRewardReferenceType.pangleClaim => 'PANGLE_CLAIM',
        AdRewardReferenceType.internalImpression => 'INTERNAL_IMPRESSION',
      };
}

class AdRewardReferenceTypeConverter
    implements JsonConverter<AdRewardReferenceType, String> {
  const AdRewardReferenceTypeConverter();

  @override
  AdRewardReferenceType fromJson(String value) => switch (value) {
        'PANGLE_CLAIM' => AdRewardReferenceType.pangleClaim,
        'INTERNAL_IMPRESSION' => AdRewardReferenceType.internalImpression,
        _ => throw FormatException('Unknown ad reference type: ' + value),
      };

  @override
  String toJson(AdRewardReferenceType value) => value.wireValue;
}

class AdRewardStateConverter
    implements JsonConverter<AdRewardState, String> {
  const AdRewardStateConverter();

  @override
  AdRewardState fromJson(String value) => switch (value) {
        'PENDING' => AdRewardState.pending,
        'GRANTED' => AdRewardState.granted,
        'DENIED' => AdRewardState.denied,
        'EXPIRED' => AdRewardState.expired,
        'ABANDONED' => AdRewardState.abandoned,
        _ => throw FormatException('Unknown ad reward state: ' + value),
      };

  @override
  String toJson(AdRewardState value) => value.name.toUpperCase();
}

@freezed
abstract class AdRewardReference with _$AdRewardReference {
  const factory AdRewardReference({
    @AdRewardReferenceTypeConverter() required AdRewardReferenceType type,
    required String id,
  }) = _AdRewardReference;

  factory AdRewardReference.fromJson(Map<String, dynamic> json) =>
      _$AdRewardReferenceFromJson(json);
}

@freezed
abstract class PangleClaimModel with _$PangleClaimModel {
  const PangleClaimModel._();

  const factory PangleClaimModel({
    required AdRewardReference reference,
    required String platform,
    @JsonKey(name: 'signed_token') required String signedToken,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
  }) = _PangleClaimModel;

  String mediaExtra(String userId) =>
      userId + ',' + platform + ',v2.' + signedToken;

  factory PangleClaimModel.fromJson(Map<String, dynamic> json) =>
      _$PangleClaimModelFromJson(json);
}

@freezed
abstract class AdRewardGrantModel with _$AdRewardGrantModel {
  const factory AdRewardGrantModel({
    required String id,
    @WalletCurrencyConverter() required WalletCurrency currency,
    @WalletAmountConverter() required BigInt amount,
    @JsonKey(name: 'granted_at') required DateTime grantedAt,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
  }) = _AdRewardGrantModel;

  factory AdRewardGrantModel.fromJson(Map<String, dynamic> json) =>
      _$AdRewardGrantModelFromJson(json);
}

@freezed
abstract class AdRewardStatusModel with _$AdRewardStatusModel {
  const factory AdRewardStatusModel({
    required AdRewardReference reference,
    @AdRewardStateConverter() required AdRewardState state,
    AdRewardGrantModel? grant,
    required WalletSummaryModel wallet,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
  }) = _AdRewardStatusModel;

  factory AdRewardStatusModel.fromJson(Map<String, dynamic> json) =>
      _$AdRewardStatusModelFromJson(json);
}

@freezed
abstract class AdRewardPageModel with _$AdRewardPageModel {
  const factory AdRewardPageModel({
    required List<AdRewardStatusModel> items,
    @JsonKey(name: 'total_count')
    @WalletAmountConverter()
    required BigInt totalCount,
    @JsonKey(name: 'next_cursor') String? nextCursor,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
  }) = _AdRewardPageModel;

  factory AdRewardPageModel.fromJson(Map<String, dynamic> json) =>
      _$AdRewardPageModelFromJson(json);
}

@freezed
abstract class InternalShortformViewResponse
    with _$InternalShortformViewResponse {
  const factory InternalShortformViewResponse({
    required bool ok,
    @JsonKey(name: 'reward_added') required int rewardAdded,
    @JsonKey(name: 'impression_id') required String impressionId,
    @JsonKey(name: 'new_bonus') int? newBonus,
    AdRewardStatusModel? reward,
  }) = _InternalShortformViewResponse;

  factory InternalShortformViewResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$InternalShortformViewResponseFromJson(json);
}

enum PendingAdRewardLocalState { pendingDisplay, ackPending }

class StoredAdRewardReference {
  const StoredAdRewardReference({
    required this.reference,
    required this.state,
  });

  final AdRewardReference reference;
  final PendingAdRewardLocalState state;

  Map<String, dynamic> toJson() => {
        'reference': reference.toJson(),
        'state': state.name,
      };

  factory StoredAdRewardReference.fromJson(Map<String, dynamic> json) {
    requireExactContractKeys(json, const {'reference', 'state'});
    return StoredAdRewardReference(
      reference: AdRewardReference.fromJson(
        Map<String, dynamic>.from(json['reference'] as Map),
      ),
      state: PendingAdRewardLocalState.values.byName(json['state'] as String),
    );
  }
}

class PendingAdRewardStore {
  PendingAdRewardStore(this.storage);
  final LocalStorage storage;
  Future<void> _writeTail = Future<void>.value();

  String _key(String userId) => 'pending_ad_rewards_v1:' + userId;

  Future<void> _serialize(Future<void> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (_, __) {});
    return next;
  }

  Future<List<StoredAdRewardReference>> readAll(String userId) async {
    final raw = await storage.loadData(_key(userId), '[]') ?? '[]';
    final values = jsonDecode(raw) as List<dynamic>;
    return values
        .map((value) => StoredAdRewardReference.fromJson(
              Map<String, dynamic>.from(value as Map),
            ))
        .toList(growable: true);
  }

  Future<void> add(String userId, AdRewardReference reference) =>
      _serialize(() async {
        final values = await readAll(userId);
        final byKey = {
          for (final value in values)
            value.reference.type.name + ':' + value.reference.id: value,
        };
        final key = reference.type.name + ':' + reference.id;
        byKey.putIfAbsent(
          key,
          () => StoredAdRewardReference(
            reference: reference,
            state: PendingAdRewardLocalState.pendingDisplay,
          ),
        );
        await storage.saveData(
          _key(userId),
          jsonEncode(byKey.values.map((value) => value.toJson()).toList()),
        );
      });

  Future<void> markAckPending(
    String userId,
    AdRewardReference reference,
  ) => _serialize(() async {
        final values = await readAll(userId);
        final key = reference.type.name + ':' + reference.id;
        final byKey = {
          for (final value in values)
            value.reference.type.name + ':' + value.reference.id: value,
        };
        byKey[key] = StoredAdRewardReference(
          reference: reference,
          state: PendingAdRewardLocalState.ackPending,
        );
        await storage.saveData(
          _key(userId),
          jsonEncode(byKey.values.map((value) => value.toJson()).toList()),
        );
      });

  Future<void> remove(String userId, AdRewardReference reference) =>
      _serialize(() async {
        final values = await readAll(userId);
        values.removeWhere((value) => value.reference == reference);
        await storage.saveData(
          _key(userId),
          jsonEncode(values.map((value) => value.toJson()).toList()),
        );
      });
}
~~~

Every ad <code>fromJson</code> validates its exact canonical key set with <code>requireExactContractKeys</code> before calling generated decoding. <code>InternalShortformViewResponse.fromJson</code> separately allows only the two known shapes: legacy <code>{ok,reward_added,impression_id,new_bonus}</code> and wallet-aware <code>{ok,reward_added,impression_id,new_bonus,reward}</code>; no other alias is accepted.

Never call <code>LocalStorage.clearStorage()</code>.
The storage test starts 100 concurrent adds across two users, interleaves <code>markAckPending</code> and remove operations, and proves the serialized write tail loses no reference, never downgrades <code>ackPending</code> back to <code>pendingDisplay</code>, and never exposes one user's records through another user's key. It also calls <code>markAckPending</code> for a server-only reference with no local row and proves the method atomically upserts that reference directly as <code>ackPending</code>.

Expose both dependencies for widget/provider tests:

~~~dart
@Riverpod(keepAlive: true)
AdRewardApi adRewardRepository(Ref ref) {
  return AdRewardRepository(supabase);
}

@Riverpod(keepAlive: true)
PendingAdRewardStore pendingAdRewardStore(Ref ref) {
  return PendingAdRewardStore(LocalStorage());
}
~~~

- [ ] **Step 3: Implement repository status/list/ack and shortform v2 parsing**

Repository signatures:

~~~dart
abstract interface class AdRewardApi {
  Future<PangleClaimModel> createPangleClaim({
    required String platform,
    required String placementId,
    required String clientRequestId,
  });
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference);
  Future<AdRewardPageModel> listUnacknowledged({
    String? cursor,
    int limit = 20,
  });
  Future<void> acknowledge(AdRewardReference reference);
  InternalShortformViewResponse parseInternalViewResponse(
    Map<String, dynamic> json,
  );
}

class AdRewardRepository implements AdRewardApi {
  const AdRewardRepository(this.client);
  final SupabaseClient client;
}
~~~

Pangle preflight invokes the authenticated Edge endpoint <code>ad-reward-claim</code>; only that endpoint calls the server-side SQL command <code>create_ad_reward_claim</code>. Its app DTO is exactly <code>{reference:{type:'PANGLE_CLAIM',id},platform,signed_token,expires_at}</code>. Read/ack RPC names are exactly <code>get_ad_reward_status</code>, <code>list_unacknowledged_ad_rewards</code>, and <code>acknowledge_ad_reward</code>. Internal response keeps top-level <code>ok</code>, <code>reward_added</code>, <code>impression_id</code>, <code>new_bonus</code>; wallet-aware code reads nested <code>reward</code>.

Repository tests must assert that claim creation uses <code>functions.invoke('ad-reward-claim')</code> with only <code>platform</code>, <code>placement_id</code>, and <code>client_request_id</code>. They must also assert the exact PostgREST SQL argument names prefixed with <code>p_</code>. Implement the claim/read/ack calls and parse the list envelope as <code>items</code>, decimal-string <code>total_count</code>, nullable <code>next_cursor</code>, and <code>snapshot_at</code>:

~~~dart
Future<PangleClaimModel> createPangleClaim({
  required String platform,
  required String placementId,
  required String clientRequestId,
}) async {
  final response = await client.functions.invoke(
    'ad-reward-claim',
    body: {
      'platform': platform,
      'placement_id': placementId,
      'client_request_id': clientRequestId,
    },
  );
  return PangleClaimModel.fromJson(
    Map<String, dynamic>.from(response.data as Map),
  );
}

Future<AdRewardStatusModel> getStatus(
  AdRewardReference reference,
) async {
  final value = await client.rpc(
    'get_ad_reward_status',
    params: {
      'p_reference_type': reference.type.wireValue,
      'p_reference_id': reference.id,
    },
  );
  return AdRewardStatusModel.fromJson(
    Map<String, dynamic>.from(value as Map),
  );
}

Future<AdRewardPageModel> listUnacknowledged({
  String? cursor,
  int limit = 20,
}) async {
  final value = await client.rpc(
    'list_unacknowledged_ad_rewards',
    params: {'p_cursor': cursor, 'p_limit': limit},
  );
  return AdRewardPageModel.fromJson(
    Map<String, dynamic>.from(value as Map),
  );
}

Future<void> acknowledge(AdRewardReference reference) async {
  await client.rpc(
    'acknowledge_ad_reward',
    params: {
      'p_reference_type': reference.type.wireValue,
      'p_reference_id': reference.id,
    },
  );
}
~~~

- [ ] **Step 4: Replace the unsafe shortform view flow**

The Supabase prerequisite keeps the existing <code>ad</code> and <code>tokens</code> members and adds exactly one top-level <code>impression_id</code> whose value is the same UUID returned by the successful <code>ad_impressions</code> insert. After <code>ad-shortform-issue</code>, validate that UUID and durably persist its reference before <code>loadAd</code> returns a playable URL. Missing, malformed, or unauthenticated issue responses fail closed before playback:

~~~dart
static final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

AdRewardReference? _activeViewReference;
String? _activeViewOwnerUserId;

Future<({String videoUrl, String? ctaUrl, bool blocked})>
    _issueAdTokensFromRoute() async {
  final ownerUserId = supabase.auth.currentUser?.id;
  if (ownerUserId == null) {
    throw StateError('Authenticated user required for ad reward issue');
  }
  final headers = <String, String>{
    'Authorization':
        'Bearer ${supabase.auth.currentSession?.accessToken ?? ''}',
  };
  try {
    headers['X-Device-Id'] = await DeviceManager.getDeviceId();
  } catch (error) {
    logWarning('Could not retrieve ad issue device ID: $error');
  }

  try {
    final issueClient = SupabaseClient(
      Environment.supabaseUrl,
      Environment.supabaseAnonKey,
    );
    final response = await issueClient.functions.invoke(
      'ad-shortform-issue',
      headers: headers,
    );
    if (response.data is! Map) {
      throw const FormatException('Invalid ad issue response');
    }
    final body = Map<String, dynamic>.from(response.data as Map);
    final impressionId = body['impression_id'];
    if (impressionId is! String || !_uuidPattern.hasMatch(impressionId)) {
      throw const FormatException('Invalid ad issue impression_id');
    }
    final ad = Map<String, dynamic>.from(body['ad'] as Map);
    final tokens = Map<String, dynamic>.from(body['tokens'] as Map);
    final videoUrl = rewriteVideoUrlIfNeeded(ad['video_url'] as String?);
    final viewToken = tokens['view_token'] as String?;
    if (videoUrl == null || videoUrl.isEmpty ||
        viewToken == null || viewToken.isEmpty) {
      throw const FormatException('Ad issue is not playable');
    }

    final reference = AdRewardReference(
      type: AdRewardReferenceType.internalImpression,
      id: impressionId,
    );
    await ref
        .read(pendingAdRewardStoreProvider)
        .add(ownerUserId, reference);

    _activeViewReference = reference;
    _activeViewOwnerUserId = ownerUserId;
    _videoUrl = videoUrl;
    _ctaUrl = ad['cta_url'] as String?;
    _viewToken = viewToken;
    _moreToken = tokens['more_token'] as String?;
    return (videoUrl: videoUrl, ctaUrl: _ctaUrl, blocked: false);
  } catch (error) {
    final antiAbuse = mapToAntiAbuseException(error);
    if (antiAbuse is AntiAbuseException) {
      _showRateLimitedAndCloseRoute(antiAbuse.channel);
      return (videoUrl: '', ctaUrl: null, blocked: true);
    }
    rethrow;
  }
}

Future<InternalShortformViewResponse> _callView() async {
  final reference = _activeViewReference ??
      (throw StateError('No issued impression for view callback'));
  final ownerUserId = _activeViewOwnerUserId ??
      (throw StateError('No owner for issued impression'));
  if (supabase.auth.currentUser?.id != ownerUserId) {
    throw StateError('Ad reward owner changed before view callback');
  }
  final response = await supabase.functions.invoke(
    'callback-ad-shortform-view',
    body: {'token': _viewToken},
  );
  final parsed = ref
      .read(adRewardRepositoryProvider)
      .parseInternalViewResponse(
    Map<String, dynamic>.from(response.data as Map),
  );
  if (parsed.impressionId != reference.id) {
    throw const FormatException(
      'callback impression_id does not match issued impression',
    );
  }
  return parsed;
}
~~~

No client-generated UUID may stand in for the server impression, and neither an issue parse failure nor a callback mismatch may call <code>ad-shortform-issue</code> a second time.

Change <code>AdShortformFullscreenPage.onViewComplete</code> to <code>Future&lt;InternalShortformViewResponse&gt; Function()</code>. In <code>_startReward()</code>, a response with nested <code>reward</code> must not open any local success/failure dialog and must not refresh <code>UserInfo</code>; Task 7 routes its persisted reference through the recovery queue. A legacy response with <code>reward == null</code> keeps the existing Bonus-mode behavior: when <code>rewardAdded &gt; 0</code>, refresh the profile and show the existing success UX using server <code>newBonus</code>; otherwise keep its existing no-reward handling. Never infer Cotton mode from <code>reward_added</code> or <code>new_bonus</code>.

Delete the <code>view</code> path through <code>_reissueTokens()</code>. Keep <code>more</code> behavior unchanged. Token expiry creates no replacement impression and leaves the stored reference for Task 7's owner-scoped polling/startup recovery; the fullscreen widget never resolves or displays a wallet result directly.

- [ ] **Step 5: Verify response loss and token expiry**

Run:

~~~bash
cd picnic_lib
dart run build_runner build --delete-conflicting-outputs
flutter test test/data/repositories/ad_reward_repository_test.dart test/data/storage/pending_ad_reward_store_test.dart test/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform_test.dart test/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page_test.dart
~~~

Expected: callback loss retains the same persisted impression; token expiry issues no new impression; wallet-aware current success opens no local dialog; legacy Bonus success still refreshes the profile and renders <code>reward_added/new_bonus</code> UX.

- [ ] **Step 6: Commit**

~~~bash
git add picnic_lib/lib/data/models/ad picnic_lib/lib/data/repositories/ad_reward_repository.dart picnic_lib/lib/data/storage/pending_ad_reward_store.dart picnic_lib/lib/presentation/providers/ad_reward_provider.dart picnic_lib/lib/generated/providers/models/ad picnic_lib/lib/generated/providers/ad_reward_provider.g.dart picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform.dart picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart picnic_lib/test/data/models/ad picnic_lib/test/data/repositories/ad_reward_repository_test.dart picnic_lib/test/data/storage/pending_ad_reward_store_test.dart picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms picnic_lib/test/fixtures/wallet_contracts/ad_reward_*.json
git commit -m "feat(ads): persist internal reward references"
~~~

### Task 7: Startup/Resume Recovery and First-Frame Acknowledge

**Files:**
- Create: <code>picnic_lib/lib/presentation/providers/ad_reward_recovery_provider.dart</code>
- Create: <code>picnic_lib/lib/presentation/widgets/ad_reward_dialog_host.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart</code>
- Modify: <code>picnic_app/lib/app.dart</code>
- Test: <code>picnic_lib/test/presentation/providers/ad_reward_recovery_provider_test.dart</code>
- Test: <code>picnic_lib/test/presentation/widgets/ad_reward_dialog_host_test.dart</code>
- Modify test: <code>picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform_test.dart</code>
- Modify test: <code>picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page_test.dart</code>

**Interfaces:**
- Consumes: <code>AdRewardRepository</code>, <code>PendingAdRewardStore</code>.
- Produces: <code>adRewardRecoveryProvider</code>, <code>recover(userId)</code>, <code>poll(ownerUserId, reference)</code>, <code>resetForLogout()</code>, <code>acknowledgeAfterRender(ownedStatus)</code>, <code>AdRewardDialogHost</code>.

- [ ] **Step 1: Write failing union/dedupe/backoff/ACK tests**

~~~dart
await notifier.recover('user-a');
expect(state.references.map((value) => value.id).toSet(), {
  'local-pending',
  'server-granted',
});
expect(fakeRepository.pollDelays, const [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 15),
]);
expect(fakeRepository.acknowledged, isEmpty);
await tester.pump();
expect(fakeRepository.acknowledged, [grantedReference]);
~~~

Add a gated-delay case with one indefinitely <code>PENDING</code> local reference and one server-terminal reference. Start <code>recover()</code> without awaiting it, pump one event turn, and assert that the terminal reference is already in <code>dialogQueue</code> while the pending reference is in <code>checkingReferences</code>. This proves one 30-second poll chain cannot block another reference's popup. Release the gate and await recovery for test cleanup.

Add the same gate around an <code>ackPending</code> retry and prove it does not delay listing, polling, or displaying a different terminal reference. The gated key itself must remain excluded from the display union.

Add an account-switch race: gate user A's <code>readAll</code>, status, and list calls; activate user B and finish B recovery; then release A. Assert <code>activeUserId == 'user-b'</code>, only B references/queue remain, and no A completion mutates state. Logout must synchronously clear <code>activeUserId</code>, references, queue, <code>_polling</code>, and <code>_queued</code>. Re-login starts a clean generation. An ACK callback captures the queue item's owner and must never derive ownership from whichever user happens to be current later.

The widget test must render <code>ad_reward_pending</code> while <code>checkingReferences</code> is non-empty and assert no ACK. It must also terminate a terminal dialog before first frame and assert no ACK, then repump the same owner/reference and assert one ACK after first frame. Provider regressions must prove the first frame durably changes a local record from <code>pendingDisplay</code> to <code>ackPending</code> and upserts a server-only reference directly as <code>ackPending</code> before the server call; process death before or after the server ACK never queues either reference again; startup/resume retries ACK idempotently for <code>ackPending</code>; ACK failure keeps the tombstone for retry; and only an ACK success removes it.

Add a current internal-view success case: the issue response contains UUID <code>impression_id</code>, that exact <code>INTERNAL_IMPRESSION</code> reference is durably saved before the fullscreen route receives a playable URL, the callback response contains the same <code>impression_id</code> plus nested <code>reward</code>, no fullscreen-local success dialog appears, the reference enters recovery polling and then <code>dialogQueue</code>, and ACK remains empty until <code>AdRewardDialogHost</code> renders its first frame. Missing/non-UUID issue IDs and callback/issued-ID mismatch fail closed without playback or a second issue. Add the compatibility case in the same suite: a response without <code>reward</code> but with <code>reward_added &gt; 0</code>/<code>new_bonus</code> keeps the legacy Bonus success/profile refresh and never enters recovery polling.

Run: <code>cd picnic_lib && flutter test test/presentation/providers/ad_reward_recovery_provider_test.dart test/presentation/widgets/ad_reward_dialog_host_test.dart</code>

Expected: FAIL because recovery/host do not exist.

- [ ] **Step 2: Implement local/server union and fixed backoff**

~~~dart
const adRewardPollDelays = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 15),
];

typedef AdRewardDelay = Future<void> Function(Duration duration);
typedef AdRewardOwnerReader = String? Function();

@Riverpod(keepAlive: true)
AdRewardDelay adRewardDelay(Ref ref) => Future<void>.delayed;

@Riverpod(keepAlive: true)
AdRewardOwnerReader adRewardOwnerReader(Ref ref) =>
    () => supabase.auth.currentUser?.id;

class OwnedAdRewardStatus {
  const OwnedAdRewardStatus({
    required this.ownerUserId,
    required this.status,
  });

  final String ownerUserId;
  final AdRewardStatusModel status;
}

class AdRewardRecoveryState {
  const AdRewardRecoveryState({
    this.activeUserId,
    this.references = const [],
    this.dialogQueue = const [],
    this.checkingReferences = const {},
  });

  final String? activeUserId;
  final List<AdRewardReference> references;
  final List<OwnedAdRewardStatus> dialogQueue;
  final Set<AdRewardReference> checkingReferences;

  AdRewardRecoveryState copyWith({
    List<AdRewardReference>? references,
    List<OwnedAdRewardStatus>? dialogQueue,
    Set<AdRewardReference>? checkingReferences,
  }) => AdRewardRecoveryState(
        activeUserId: activeUserId,
        references: references ?? this.references,
        dialogQueue: dialogQueue ?? this.dialogQueue,
        checkingReferences: checkingReferences ?? this.checkingReferences,
      );
}

@Riverpod(keepAlive: true)
class AdRewardRecovery extends _$AdRewardRecovery {
  final _polling = <String>{};
  final _acknowledging = <String>{};
  final _queued = <String>{};
  var _generation = 0;

  @override
  AdRewardRecoveryState build() => const AdRewardRecoveryState();

  String _key(String ownerUserId, AdRewardReference value) =>
      ownerUserId + ':' + value.type.wireValue + ':' + value.id;

  bool _isCurrent(String ownerUserId, int generation) =>
      generation == _generation &&
      state.activeUserId == ownerUserId &&
      ref.read(adRewardOwnerReaderProvider)() == ownerUserId;

  int _activateUser(String ownerUserId) {
    if (state.activeUserId != ownerUserId) {
      _generation += 1;
      _polling.clear();
      _acknowledging.clear();
      _queued.clear();
      state = AdRewardRecoveryState(activeUserId: ownerUserId);
    }
    return _generation;
  }

  void resetForLogout() {
    _generation += 1;
    _polling.clear();
    _acknowledging.clear();
    _queued.clear();
    state = const AdRewardRecoveryState();
  }

  Future<void> recover(String ownerUserId) async {
    if (ref.read(adRewardOwnerReaderProvider)() != ownerUserId) return;
    final generation = _activateUser(ownerUserId);
    final store = ref.read(pendingAdRewardStoreProvider);
    final repository = ref.read(adRewardRepositoryProvider);
    final localRecords = await store.readAll(ownerUserId);
    if (!_isCurrent(ownerUserId, generation)) return;

    final ackPendingRecords = localRecords
        .where((value) =>
            value.state == PendingAdRewardLocalState.ackPending)
        .toList(growable: false);
    final ackPendingKeys = {
      for (final value in ackPendingRecords)
        _key(ownerUserId, value.reference),
    };
    for (final value in ackPendingRecords) {
      unawaited(
        _resumeAcknowledgement(ownerUserId, value.reference, generation),
      );
    }

    final serverItems = <AdRewardStatusModel>[];
    String? cursor;
    do {
      final page = await repository.listUnacknowledged(cursor: cursor);
      if (!_isCurrent(ownerUserId, generation)) return;
      serverItems.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);

    final unique = <String, AdRewardReference>{
      for (final value in localRecords)
        if (value.state == PendingAdRewardLocalState.pendingDisplay)
          _key(ownerUserId, value.reference): value.reference,
      for (final value in serverItems)
        if (!ackPendingKeys.contains(_key(ownerUserId, value.reference)))
          _key(ownerUserId, value.reference): value.reference,
    };
    state = state.copyWith(references: unique.values.toList());
    await Future.wait<void>([
      for (final reference in unique.values)
        _pollForOwner(ownerUserId, reference, generation),
    ]);
  }

  Future<void> _resumeAcknowledgement(
    String ownerUserId,
    AdRewardReference reference,
    int generation,
  ) async {
    if (!_isCurrent(ownerUserId, generation)) return;
    final token = generation.toString() + ':' + _key(ownerUserId, reference);
    if (!_acknowledging.add(token)) return;
    try {
      await ref.read(adRewardRepositoryProvider).acknowledge(reference);
      if (!_isCurrent(ownerUserId, generation)) return;
      await ref
          .read(pendingAdRewardStoreProvider)
          .remove(ownerUserId, reference);
    } catch (_) {
      // Keep ACK_PENDING durable state; resume retries without redisplay.
    } finally {
      _acknowledging.remove(token);
    }
  }

  Future<void> poll({
    required String ownerUserId,
    required AdRewardReference reference,
  }) async {
    if (ref.read(adRewardOwnerReaderProvider)() != ownerUserId) return;
    final generation = _activateUser(ownerUserId);
    await _pollForOwner(ownerUserId, reference, generation);
  }

  Future<void> _pollForOwner(
    String ownerUserId,
    AdRewardReference reference,
    int generation,
  ) async {
    if (!_isCurrent(ownerUserId, generation)) return;
    final key = _key(ownerUserId, reference);
    if (!_polling.add(key)) return;
    state = state.copyWith(
      checkingReferences: {...state.checkingReferences, reference},
    );
    try {
      final repository = ref.read(adRewardRepositoryProvider);
      for (var attempt = 0; attempt <= adRewardPollDelays.length; attempt++) {
        final status = await repository.getStatus(reference);
        if (!_isCurrent(ownerUserId, generation)) return;
        if (status.reference != reference) {
          throw const FormatException('Ad reward status reference mismatch');
        }
        if (status.state != AdRewardState.pending) {
          if (_queued.add(key)) {
            state = state.copyWith(
              dialogQueue: [
                ...state.dialogQueue,
                OwnedAdRewardStatus(
                  ownerUserId: ownerUserId,
                  status: status,
                ),
              ],
            );
          }
          return;
        }
        if (attempt < adRewardPollDelays.length) {
          await ref.read(adRewardDelayProvider)(adRewardPollDelays[attempt]);
          if (!_isCurrent(ownerUserId, generation)) return;
        }
      }
    } finally {
      _polling.remove(key);
      if (_isCurrent(ownerUserId, generation)) {
        state = state.copyWith(
          checkingReferences: {
            for (final value in state.checkingReferences)
              if (value != reference) value,
          },
        );
      }
    }
  }

  Future<void> acknowledgeAfterRender(
    OwnedAdRewardStatus queued,
  ) async {
    final ownerUserId = queued.ownerUserId;
    final status = queued.status;
    if (status.state == AdRewardState.pending) {
      throw StateError('Pending rewards cannot be acknowledged');
    }
    if (state.activeUserId != ownerUserId ||
        ref.read(adRewardOwnerReaderProvider)() != ownerUserId) {
      throw StateError('Ad reward owner is no longer active');
    }

    final store = ref.read(pendingAdRewardStoreProvider);
    final key = _key(ownerUserId, status.reference);
    await store.markAckPending(ownerUserId, status.reference);
    _queued.remove(key);
    state = state.copyWith(
      references: state.references
          .where((value) => _key(ownerUserId, value) != key)
          .toList(),
      dialogQueue: state.dialogQueue
          .where((value) =>
              _key(value.ownerUserId, value.status.reference) != key)
          .toList(),
    );
    await ref.read(adRewardRepositoryProvider).acknowledge(status.reference);
    await store.remove(ownerUserId, status.reference);
  }
}
~~~

All reference polls start concurrently, and polling stops independently on each terminal status. Every post-await mutation is guarded by both user and generation, and dedupe keys include the owner. While <code>checkingReferences</code> is non-empty, <code>AdRewardDialogHost</code> renders the localized <code>ad_reward_pending</code> checking indicator without calling ACK; terminal queue handling remains independent so a terminal popup can open while another reference is pending. After all five pending polls, retain the local reference for the next startup/resume.

ACK uses a recoverable durable state machine: after the first rendered frame, atomically persist <code>PENDING_DISPLAY → ACK_PENDING</code> for a local reference or insert a missing server-only reference directly as <code>ACK_PENDING</code>, remove the item from the in-memory display queue, call the idempotent server ACK, and delete the local record only after success. Startup/resume excludes every <code>ACK_PENDING</code> key from both local and server display unions and retries only its ACK. Therefore a crash before the server commit, after the commit, or before local cleanup cannot redisplay an already rendered reward; a failed ACK leaves its tombstone for the next retry.

- [ ] **Step 3: Implement dialog first-frame ACK**

<code>AdRewardDialogHost</code> listens to the complete recovery state. It renders a live-region <code>ad_reward_pending</code> indicator whenever <code>checkingReferences</code> is non-empty, without invoking ACK, and independently opens only the terminal <code>dialogQueue</code> head. The dialog body calls:

~~~dart
class AdRewardDialogBody extends StatefulWidget {
  const AdRewardDialogBody({
    super.key,
    required this.status,
    required this.onFirstFrame,
  });

  final AdRewardStatusModel status;
  final Future<void> Function() onFirstFrame;

  @override
  State<AdRewardDialogBody> createState() => _AdRewardDialogBodyState();
}

class _AdRewardDialogBodyState extends State<AdRewardDialogBody> {
  bool _didAcknowledge = false;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || _didAcknowledge) return;
    _didAcknowledge = true;
    unawaited(widget.onFirstFrame());
  });
}

  @override
  Widget build(BuildContext context) {
    final granted = widget.status.state == AdRewardState.granted;
    return AlertDialog(
      title: Text(
        granted
            ? AppLocalizations.of(context).ad_reward_granted
            : AppLocalizations.of(context).ad_reward_not_granted,
      ),
      content: granted
          ? Text(formatWalletAmount(widget.status.grant!.amount))
          : Text(widget.status.state.name.toUpperCase()),
    );
  }
}
~~~

The host calls <code>showDialog</code> for only the queue head. It captures the complete owner/status pair before opening the dialog, verifies that the captured owner is still the authenticated owner, and passes that same pair through first-frame ACK:

~~~dart
final queued = recoveryState.dialogQueue.first;
if (supabase.auth.currentUser?.id != queued.ownerUserId) {
  ref.read(adRewardRecoveryProvider.notifier).resetForLogout();
  return;
}
final status = queued.status;

onFirstFrame: () {
  return ref
      .read(adRewardRecoveryProvider.notifier)
      .acknowledgeAfterRender(queued);
},
~~~

Guard the host with one <code>_dialogOpen</code> boolean, reset it when <code>showDialog</code> completes, and then render the next queue head. The provider performs the durable <code>ACK_PENDING</code> transition from Step 2 and removes the item from the display queue before the server call. An ACK failure keeps the tombstone for a non-visual startup/resume retry; it never requeues an already rendered dialog.

- [ ] **Step 4: Route current shortform success and wire lifecycle recovery**

After Task 6 parses <code>callback-ad-shortform-view</code>, route every wallet-aware response through the already-persisted reference:

~~~dart
final parsed = repository.parseInternalViewResponse(
  Map<String, dynamic>.from(response.data as Map),
);
if (parsed.reward != null) {
  unawaited(
    ref
        .read(adRewardRecoveryProvider.notifier)
        .poll(
          ownerUserId: ownerUserId,
          reference: reference,
        )
        .catchError((Object error, StackTrace stackTrace) {
      logger.e(
        'Internal reward polling failed',
        error: error,
        stackTrace: stackTrace,
      );
    }),
  );
}
return parsed;
~~~

Do not await the up-to-30-second poll chain from the fullscreen callback. <code>AdShortformFullscreenPage</code> returns from the wallet-aware branch without local dialog/profile refresh; <code>AdRewardRecovery.poll</code> owns terminal queue insertion, <code>AdRewardDialogHost</code> owns the only current-mode popup, and its first rendered frame owns ACK. A callback error or process death leaves the stored reference for startup/resume recovery. Legacy <code>reward == null</code> continues the Task 6 Bonus path and does not call <code>poll</code>.

Wrap the existing <code>PatchRestartDialogListener</code> child with <code>AdRewardDialogHost</code>. Use the existing <code>_authSubscription</code> in <code>App</code> and make authentication ownership explicit. Initial authenticated startup, sign-in, token refresh with a changed user, and resume recover the current owner; logout and account switch synchronously reset queue/dedupe state before any new recovery:

~~~dart
String? _activeRewardUserId;

void _syncRewardOwner(String? nextUserId) {
  final recovery = ref.read(adRewardRecoveryProvider.notifier);
  if (_activeRewardUserId != nextUserId) {
    recovery.resetForLogout();
    _activeRewardUserId = nextUserId;
  }
  if (nextUserId != null) {
    unawaited(recovery.recover(nextUserId));
  }
}

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _syncRewardOwner(supabase.auth.currentUser?.id);
  _authSubscription = supabase.auth.onAuthStateChange.listen((authState) {
    _syncRewardOwner(authState.session?.user.id);
  });
}

@override
void didChangeAppLifecycleState(AppLifecycleState appState) {
  if (appState == AppLifecycleState.resumed) {
    // Keep the existing badge sync in this branch too.
    _syncRewardOwner(supabase.auth.currentUser?.id);
  }
}

@override
void dispose() {
  unawaited(_authSubscription?.cancel());
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

~~~

Do not add a second auth subscription. Preserve the existing badge sync and any existing <code>dispose</code> cleanup while merging this code. Tests drive sign-in A → switch B → logout → sign-in B and assert that stale A futures and captured A dialog callbacks cannot display, ACK, or remove B data.

- [ ] **Step 5: Generate, test, commit**

Run:

~~~bash
cd picnic_lib
dart run build_runner build --delete-conflicting-outputs
flutter test test/presentation/providers/ad_reward_recovery_provider_test.dart test/presentation/widgets/ad_reward_dialog_host_test.dart test/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform_test.dart test/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page_test.dart
cd ../picnic_app
flutter test test
~~~

Expected: provider/widget tests PASS; current shortform success uses recovery queue only; legacy Bonus UX remains; startup/resume calls dedupe; no ACK occurs before a rendered frame.

~~~bash
git add picnic_lib/lib/presentation/providers/ad_reward_recovery_provider.dart picnic_lib/lib/generated/providers/ad_reward_recovery_provider.g.dart picnic_lib/lib/presentation/widgets/ad_reward_dialog_host.dart picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform.dart picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart picnic_lib/test/presentation/providers/ad_reward_recovery_provider_test.dart picnic_lib/test/presentation/widgets/ad_reward_dialog_host_test.dart picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform_test.dart picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page_test.dart picnic_app/lib/app.dart
git commit -m "feat(ads): recover unacknowledged rewards on resume"
~~~

### Task 8: Pangle Claim Preflight and Signed Native Media Extra

**Files:**
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform.dart</code>
- Modify: <code>picnic_lib/lib/core/utils/pangle_ads.dart</code>
- Modify: <code>picnic_lib/lib/core/utils/pangle_ads_helper.dart</code>
- Create: <code>picnic_app/android/app/src/main/kotlin/io/iconcasting/picnic/app/pangle/PangleMediaExtra.kt</code>
- Modify: <code>picnic_app/android/app/src/main/kotlin/io/iconcasting/picnic/app/pangle/PangleNativeHandler.kt</code>
- Modify: <code>picnic_app/android/app/build.gradle</code>
- Create: <code>picnic_app/android/app/src/test/kotlin/pangle/custom/PangleMediaExtraTest.kt</code>
- Modify: <code>picnic_app/ios/Runner/PangleAdManager.swift</code>
- Modify: <code>picnic_app/ios/RunnerTests/RunnerTests.swift</code>
- Modify test: <code>picnic_lib/test/core/utils/pangle_ads_test.dart</code>
- Modify test: <code>picnic_lib/test/core/utils/pangle_ads_helper_test.dart</code>
- Create test: <code>picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform_test.dart</code>

**Interfaces:**
- Consumes: <code>AdRewardRepository.createPangleClaim</code>, <code>PendingAdRewardStore</code>, owner-scoped <code>adRewardRecoveryProvider.poll</code>.
- Produces: <code>PangleAds.loadRewardedAd(String placementId, String mediaExtra)</code>; native event names shared across platforms.

- [ ] **Step 1: Write failing Flutter preflight and method-channel tests**

~~~dart
await platform.showAd();
expect(fakeRepository.createdClaim!.placementId, 'rewarded-placement');
expect(fakeStore.saved.single.type, AdRewardReferenceType.pangleClaim);
expect(methodCall.method, 'loadRewardedAd');
expect(methodCall.arguments, {
  'placementId': 'rewarded-placement',
  'mediaExtra': 'user-a,android,v2.signed-token',
});
expect(fakeRecovery.polled, isEmpty);
nativeEvents.add(PangleNativeEvent.rewardEarned);
expect(fakeRecovery.polled, [claim.reference]);
~~~

Run: <code>cd picnic_lib && flutter test test/core/utils/pangle_ads_test.dart test/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform_test.dart</code>

Expected: FAIL because claim/media-extra APIs are absent.

- [ ] **Step 2: Implement Flutter preflight and polling signals**

<code>PanglePlatform._loadPangleAd()</code> must execute in this order:

~~~dart
final adRewardRepository = ref.read(adRewardRepositoryProvider);
final pendingStore = ref.read(pendingAdRewardStoreProvider);
final ownerUserId = supabase.auth.currentUser?.id ??
    (throw StateError('Authenticated user required for Pangle claim'));
final claim = await adRewardRepository.createPangleClaim(
  platform: Platform.isIOS ? 'ios' : 'android',
  placementId: adUnitId,
  clientRequestId: const Uuid().v4(),
);
await pendingStore.add(ownerUserId, claim.reference);
_activeReference = claim.reference;
await _pollingSubscription?.cancel();
_pollingSubscription = PangleAds.pollingSignals.listen((_) {
  unawaited(
    ref.read(adRewardRecoveryProvider.notifier).poll(
      ownerUserId: ownerUserId,
      reference: claim.reference,
    ),
  );
});
return PangleAds.loadRewardedAd(
  adUnitId,
  claim.mediaExtra(ownerUserId),
);
~~~

Remove <code>setOnProfileRefreshNeeded</code> and all reward-driven profile refreshes. Define the shared signal stream and fix the currently missing dismiss emission:

~~~dart
static final _pollingSignalController =
    StreamController<void>.broadcast();
static Stream<void> get pollingSignals =>
    _pollingSignalController.stream;

case PangleAdsHelper.adDismissedEvent:
  _adDismissedController.add(null);
  _pollingSignalController.add(null);
  break;
case PangleAdsHelper.rewardEarnedEvent:
  final args = PangleAdsHelper.parseRewardArgs(call.arguments);
  if (args != null) _rewardEarnedController.add(args);
  _pollingSignalController.add(null);
  break;
case PangleAdsHelper.rewardFailedEvent:
  _rewardFailedController.add(
    PangleAdsHelper.extractErrorMessage(call.arguments),
  );
  _pollingSignalController.add(null);
  break;
~~~

Add <code>_pollingSignalController.close()</code> to <code>dispose()</code>. Do not inspect reward amount or validity to choose a wallet result. Tests must prove the old Android names <code>onAdShowed</code>, <code>onUserEarnedReward</code>, and <code>onUserEarnedRewardFail</code> are no longer emitted by native code.

Add <code>StreamSubscription&lt;void&gt;? _pollingSubscription</code> and <code>AdRewardReference? _activeReference</code> to <code>PanglePlatform</code>; cancel the subscription in <code>dispose()</code>.

- [ ] **Step 3: Normalize Android native input/events with tests**

<code>PangleMediaExtra.kt</code>:

~~~kotlin
package pangle.custom

object PangleMediaExtra {
    fun requireV2(value: String): String {
        val parts = value.split(",", limit = 3)
        require(parts.size == 3)
        require(parts[0].isNotBlank())
        require(parts[1] == "android")
        require(parts[2].startsWith("v2.") && parts[2].length > 3)
        return value
    }
}
~~~

Change the method argument from <code>userId</code> to <code>mediaExtra</code>, pass the validated value unchanged to <code>extraInfo["media_extra"]</code>, and emit only:

~~~kotlin
val placementId = call.argument<String>("placementId")
    ?: return result.error("InvalidParams", "placementId is required", null)
val mediaExtra = call.argument<String>("mediaExtra")
    ?: return result.error("InvalidParams", "mediaExtra is required", null)
loadRewardedAd(
    placementId,
    PangleMediaExtra.requireV2(mediaExtra),
    result,
)

channel.invokeMethod("onAdShown", null)
channel.invokeMethod("onAdClicked", null)
channel.invokeMethod("onAdDismissed", null)
channel.invokeMethod("onRewardEarned", rewardData)
channel.invokeMethod("onRewardFailed", errorData)
~~~

Add <code>testImplementation 'junit:junit:4.13.2'</code> and tests for a valid exact value, missing token, wrong platform, and empty user.

- [ ] **Step 4: Update iOS to pass the signed string unchanged**

Change <code>loadRewardedAd</code> to accept <code>mediaExtra</code> and set:

~~~swift
enum PangleMediaExtraError: Error {
    case invalid
}

enum PangleMediaExtra {
    static func requireV2(_ value: String) throws -> String {
        let parts = value.split(separator: ",", maxSplits: 2).map(String.init)
        guard parts.count == 3,
              !parts[0].isEmpty,
              parts[1] == "ios",
              parts[2].hasPrefix("v2."),
              parts[2].count > 3 else {
            throw PangleMediaExtraError.invalid
        }
        return value
    }
}

guard let args = call.arguments as? [String: Any],
      let placementId = args["placementId"] as? String,
      let mediaExtra = args["mediaExtra"] as? String else {
    result(
        FlutterError(
            code: "InvalidParams",
            message: "placementId and mediaExtra are required",
            details: nil
        )
    )
    return
}
loadRewardedAd(
    placementId: placementId,
    mediaExtra: mediaExtra,
    result: result
)

guard let validatedMediaExtra = try? PangleMediaExtra.requireV2(mediaExtra) else {
    result(
        FlutterError(
            code: "InvalidMediaExtra",
            message: "Signed v2 mediaExtra is required",
            details: nil
        )
    )
    return
}
let extraInfo = ["media_extra": validatedMediaExtra]
~~~

<code>RunnerTests.swift</code> uses <code>@testable import Runner</code> and asserts valid/invalid formats. Existing iOS event names remain unchanged.

- [ ] **Step 5: Run Flutter and native tests**

Run:

~~~bash
cd picnic_lib
flutter test test/core/utils/pangle_ads_test.dart test/core/utils/pangle_ads_enhanced_test.dart test/core/utils/pangle_ads_helper_test.dart test/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform_test.dart
cd ../picnic_app/android
./gradlew testDebugUnitTest
cd ../ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -showdestinations
~~~

Select an installed simulator from the final command, then run:

~~~bash
xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination "platform=iOS Simulator,name=iPhone 16"
~~~

Expected: Flutter tests PASS; Android JUnit PASS; iOS XCTest PASS. If the installed simulator has a different name, use the exact name printed by <code>-showdestinations</code>.

- [ ] **Step 6: Commit**

~~~bash
git add picnic_lib/lib/core/utils/pangle_ads.dart picnic_lib/lib/core/utils/pangle_ads_helper.dart picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform.dart picnic_lib/test/core/utils/pangle_ads* picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform_test.dart picnic_app/android/app/src/main/kotlin/io/iconcasting/picnic/app/pangle picnic_app/android/app/src/test/kotlin/pangle/custom/PangleMediaExtraTest.kt picnic_app/android/app/build.gradle picnic_app/ios/Runner/PangleAdManager.swift picnic_app/ios/RunnerTests/RunnerTests.swift
git commit -m "feat(ads): bind Pangle loads to signed claims"
~~~

### Task 9: Server-Controlled Store and Home Campaign Surfaces

**Files:**
- Create: <code>picnic_lib/lib/data/models/promotion/promotion_campaign.dart</code>
- Create: <code>picnic_lib/lib/data/models/purchase/purchase_settlement_result.dart</code>
- Create: <code>picnic_lib/lib/data/repositories/promotion_campaign_repository.dart</code>
- Create: <code>picnic_lib/lib/presentation/providers/promotion_campaign_provider.dart</code>
- Create: <code>picnic_lib/lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart</code>
- Create: <code>picnic_lib/lib/presentation/common/candy_boost_banner.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_web_state.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/store/purchase/store_list_tile.dart</code>
- Modify: <code>picnic_lib/lib/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler.dart</code>
- Modify: <code>picnic_lib/lib/core/services/receipt_verification_service.dart</code>
- Modify: <code>picnic_lib/lib/core/services/purchase_service.dart</code>
- Modify: <code>picnic_lib/lib/presentation/common/common_banner.dart</code>
- Modify: <code>picnic_lib/lib/presentation/pages/vote/home_page.dart</code>
- Modify: <code>picnic_lib/lib/presentation/pages/vote/vote_home_page.dart</code>
- Tests: <code>promotion_campaign_repository_test.dart</code>, <code>promotion_campaign_provider_test.dart</code>, <code>candy_boost_badge_test.dart</code>, <code>candy_boost_banner_test.dart</code>
- Create test: <code>picnic_lib/test/data/models/purchase/purchase_settlement_result_test.dart</code>
- Modify tests: <code>picnic_lib/test/core/services/receipt_verification_service_test.dart</code>, <code>picnic_lib/test/core/services/purchase_service_logic_test.dart</code>, <code>picnic_lib/test/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler_test.dart</code>, <code>picnic_lib/test/presentation/widgets/vote/store/purchase/purchase_star_candy_state_test.dart</code>
- Fixtures: <code>promotion_surfaces_empty_v1.json</code>, <code>promotion_surfaces_active_v1.json</code>, <code>purchase_results_v1.json</code>

**Interfaces:**
- Produces: <code>PromotionSurface.home/store</code>, <code>ActivePromotionCampaignModel</code>, <code>activePromotionCampaignProvider(surface)</code>, <code>PurchaseSettlementResultModel</code>, typed receipt/purchase success callbacks, and campaign-aware purchase dialogs.

- [ ] **Step 1: Write failing server-clock and fallback tests**

~~~dart
await repository.getActive(PromotionSurface.home);
expect(rpcName, 'get_active_promotion_campaigns');
expect(rpcParams, {'surface': 'HOME'});
expect(rpcParams, isNot(contains('at')));

expect(campaign.localizedDisplayName('en'), 'Candy Boost Day');
expect(campaign.localizedDisplayName('vi'), '캔디 부스트 데이');
expect(campaignWithoutKorean.localizedDisplayName('vi'), 'CANDY_BOOST_DAY');
expect(activeWithoutCreative.visibleHomeItems('ko'), isEmpty);
expect(inactiveHome.items, isEmpty);
expect(inactiveHome.campaignOwnedHomeBannerIds, contains(7001));
~~~

Add creative boundary cases that require both a non-blank localized title and image using requested locale → <code>ko</code> → <code>en</code>. Add HOME render cases where ordinary <code>vote_home</code> contains banner ID 7001: it is excluded when the campaign is inactive, and appears exactly once through <code>CandyBoostBanner</code> when the matching campaign is active. Duplicate ordinary rows with an owned ID must all be excluded.

Run: <code>cd picnic_lib && flutter test test/data/repositories/promotion_campaign_repository_test.dart test/presentation/providers/promotion_campaign_provider_test.dart</code>

Expected: FAIL because campaign types are absent.

- [ ] **Step 2: Implement surface DTO/repository/provider**

~~~dart
enum PromotionSurface { home, store }

extension PromotionSurfaceWire on PromotionSurface {
  String get wireValue =>
      this == PromotionSurface.home ? 'HOME' : 'STORE';
}

@freezed
abstract class PromotionCreativeModel with _$PromotionCreativeModel {
  const PromotionCreativeModel._();

  const factory PromotionCreativeModel({
    @JsonKey(name: 'banner_id') required int bannerId,
    required Map<String, dynamic> title,
    required Map<String, dynamic> image,
    String? thumbnail,
    String? link,
    @Default(3000) int duration,
  }) = _PromotionCreativeModel;

  String? localizedImage(String locale) {
    final value = image[locale] ?? image['ko'] ?? image['en'];
    return value is String && value.trim().isNotEmpty
        ? value.trim()
        : null;
  }

  String? localizedTitle(String locale) {
    final value = title[locale] ?? title['ko'] ?? title['en'];
    return value is String && value.trim().isNotEmpty
        ? value.trim()
        : null;
  }

  factory PromotionCreativeModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionCreativeModelFromJson(json);
}

@freezed
abstract class ActivePromotionCampaignModel
    with _$ActivePromotionCampaignModel {
  const ActivePromotionCampaignModel._();

  const factory ActivePromotionCampaignModel({
    @JsonKey(name: 'campaign_id') required String campaignId,
    @JsonKey(name: 'campaign_version_id')
    required String campaignVersionId,
    required String code,
    @JsonKey(name: 'display_name')
    required Map<String, dynamic> displayName,
    @JsonKey(name: 'extra_bonus_bps') required int extraBonusBps,
    @JsonKey(name: 'window_starts_at') required DateTime windowStartsAt,
    @JsonKey(name: 'window_ends_at') required DateTime windowEndsAt,
    @JsonKey(name: 'show_in_store') required bool showInStore,
    @JsonKey(name: 'show_home_banner') required bool showHomeBanner,
    @JsonKey(name: 'home_creative') PromotionCreativeModel? homeCreative,
  }) = _ActivePromotionCampaignModel;

  String localizedDisplayName(String locale) {
    final value = displayName[locale] ?? displayName['ko'];
    return value is String && value.trim().isNotEmpty ? value : code;
  }

  bool hasReadableHomeCreative(String locale) {
    final creative = homeCreative;
    return showHomeBanner &&
        creative != null &&
        creative.localizedImage(locale) != null &&
        creative.localizedTitle(locale) != null;
  }

  factory ActivePromotionCampaignModel.fromJson(
    Map<String, dynamic> json,
  ) => _$ActivePromotionCampaignModelFromJson(json);
}

@freezed
abstract class ActivePromotionCampaignsModel
    with _$ActivePromotionCampaignsModel {
  const ActivePromotionCampaignsModel._();

  const factory ActivePromotionCampaignsModel({
    required List<ActivePromotionCampaignModel> items,
    @JsonKey(name: 'total_count')
    @WalletAmountConverter()
    required BigInt totalCount,
    @JsonKey(name: 'next_cursor') String? nextCursor,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
    @JsonKey(name: 'campaign_owned_home_banner_ids')
    required List<int> campaignOwnedHomeBannerIds,
  }) = _ActivePromotionCampaignsModel;

  List<ActivePromotionCampaignModel> visibleHomeItems(String locale) =>
      items.where((item) => item.hasReadableHomeCreative(locale)).toList();

  factory ActivePromotionCampaignsModel.fromJson(
    Map<String, dynamic> json,
  ) => _$ActivePromotionCampaignsModelFromJson(json);
}

Future<ActivePromotionCampaignsModel> getActive(
  PromotionSurface surface,
) async {
  final value = await client.rpc(
    'get_active_promotion_campaigns',
    params: {'surface': surface.wireValue},
  );
  return ActivePromotionCampaignsModel.fromJson(
    Map<String, dynamic>.from(value as Map),
  );
}
~~~

The model includes <code>campaignId</code>, <code>campaignVersionId</code>, <code>code</code>, <code>displayName</code>, <code>extraBonusBps</code>, <code>windowStartsAt</code>, <code>windowEndsAt</code>, <code>showInStore</code>, <code>showHomeBanner</code>, nullable home creative, page fields, server <code>snapshotAt</code>, and <code>campaignOwnedHomeBannerIds</code>. Display fallback is requested locale → <code>ko</code> → campaign code. The one shared readable-creative predicate is exactly <code>showHomeBanner &amp;&amp; localizedTitle != null &amp;&amp; localizedImage != null</code>, with title/image fallback requested locale → <code>ko</code> → <code>en</code>. Do not duplicate or weaken this condition in widgets.

The HOME envelope always includes <code>campaign_owned_home_banner_ids</code>, even when <code>items</code> is empty because every owned campaign version is inactive. The backend guarantees that this set contains every non-null <code>home_banner_id</code> ever linked to any immutable campaign version and prevents cross-campaign reuse; the app treats the set as ownership, not eligibility.

Expose the repository and surface family:

~~~dart
@Riverpod(keepAlive: true)
PromotionCampaignRepository promotionCampaignRepository(Ref ref) {
  return PromotionCampaignRepository(supabase);
}

@riverpod
Future<ActivePromotionCampaignsModel> activePromotionCampaign(
  Ref ref,
  PromotionSurface surface,
) {
  return ref.watch(promotionCampaignRepositoryProvider).getActive(surface);
}
~~~

- [ ] **Step 3: Add STORE badge without client eligibility math**

Extend <code>StoreListTile</code> with nullable <code>Widget? badge</code>. Mobile and web purchase lists watch <code>activePromotionCampaignProvider(PromotionSurface.store)</code> and pass <code>CandyBoostBadge</code> only for a returned active campaign.

~~~dart
class CandyBoostBadge extends StatelessWidget {
  const CandyBoostBadge({super.key, required this.campaign});
  final ActivePromotionCampaignModel campaign;

  @override
  Widget build(BuildContext context) {
    final exactDouble = campaign.extraBonusBps == 10000;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Semantics(
      label: campaign.localizedDisplayName(languageCode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(campaign.localizedDisplayName(languageCode)),
          Text(
            exactDouble
                ? AppLocalizations.of(context).candy_boost_exact_double
                : AppLocalizations.of(context).candy_boost_extra_bonus,
          ),
        ],
      ),
    );
  }
}
~~~

Do not compute product entitlement from local clock or description. Purchase confirmation may display the active campaign name but final granted amount comes from the verified server result.

- [ ] **Step 4: Thread the verified purchase result into campaign-aware dialogs**

Create the exact result DTO consumed from <code>verify_receipt</code>:

~~~dart
enum PurchasePromotionState {
  pendingTime,
  eligible,
  ineligible,
  granted,
  rejected,
  cancelledByRefund,
}

class PurchasePromotionStateConverter
    implements JsonConverter<PurchasePromotionState, String> {
  const PurchasePromotionStateConverter();

  @override
  PurchasePromotionState fromJson(String value) => switch (value) {
        'PENDING_TIME' => PurchasePromotionState.pendingTime,
        'ELIGIBLE' => PurchasePromotionState.eligible,
        'INELIGIBLE' => PurchasePromotionState.ineligible,
        'GRANTED' => PurchasePromotionState.granted,
        'REJECTED' => PurchasePromotionState.rejected,
        'CANCELLED_BY_REFUND' =>
          PurchasePromotionState.cancelledByRefund,
        _ => throw FormatException('Unknown purchase promotion state: $value'),
      };

  @override
  String toJson(PurchasePromotionState value) => switch (value) {
        PurchasePromotionState.pendingTime => 'PENDING_TIME',
        PurchasePromotionState.eligible => 'ELIGIBLE',
        PurchasePromotionState.ineligible => 'INELIGIBLE',
        PurchasePromotionState.granted => 'GRANTED',
        PurchasePromotionState.rejected => 'REJECTED',
        PurchasePromotionState.cancelledByRefund => 'CANCELLED_BY_REFUND',
      };
}

const purchaseSettlementKeys = {
  'contract_version',
  'operation_id',
  'replayed',
  'base_star_amount',
  'base_bonus_amount',
  'promotion',
  'wallet',
};

const purchasePromotionKeys = {
  'resolution_id',
  'state',
  'campaign_version_id',
  'promo_bonus_amount',
  'domain_code',
};

@freezed
abstract class PurchasePromotionResultModel
    with _$PurchasePromotionResultModel {
  const factory PurchasePromotionResultModel({
    @JsonKey(name: 'resolution_id') required String resolutionId,
    @PurchasePromotionStateConverter()
    required PurchasePromotionState state,
    @JsonKey(name: 'campaign_version_id')
    required String? campaignVersionId,
    @JsonKey(name: 'promo_bonus_amount')
    @WalletAmountConverter()
    required BigInt promoBonusAmount,
    @JsonKey(name: 'domain_code') required String? domainCode,
  }) = _PurchasePromotionResultModel;

  factory PurchasePromotionResultModel.fromJson(
    Map<String, dynamic> json,
  ) => _$PurchasePromotionResultModelFromJson(
        requireExactContractKeys(json, purchasePromotionKeys),
      );
}

@freezed
abstract class PurchaseSettlementResultModel
    with _$PurchaseSettlementResultModel {
  const factory PurchaseSettlementResultModel({
    @JsonKey(name: 'contract_version') required String contractVersion,
    @JsonKey(name: 'operation_id') required String operationId,
    required bool replayed,
    @JsonKey(name: 'base_star_amount')
    @WalletAmountConverter()
    required BigInt baseStarAmount,
    @JsonKey(name: 'base_bonus_amount')
    @WalletAmountConverter()
    required BigInt baseBonusAmount,
    required PurchasePromotionResultModel? promotion,
    required WalletSummaryModel wallet,
  }) = _PurchaseSettlementResultModel;

  factory PurchaseSettlementResultModel.fromJson(
    Map<String, dynamic> json,
  ) => parseCanonicalPurchaseSettlement(json);

  factory PurchaseSettlementResultModel.fromLegacyJson(
    Map<String, dynamic> json,
  ) => parseLegacyPurchaseSettlement(json);
}

void validatePurchasePromotion(PurchasePromotionResultModel promotion) {
  final pending = promotion.state == PurchasePromotionState.pendingTime;
  if (pending && promotion.domainCode != 'PROMO_REVIEW_REQUIRED') {
    throw const FormatException(
      'PENDING_TIME requires PROMO_REVIEW_REQUIRED',
    );
  }
  if (!pending && promotion.domainCode != null) {
    throw const FormatException(
      'Only PENDING_TIME may carry a promotion domain_code',
    );
  }
  if (promotion.state != PurchasePromotionState.granted &&
      promotion.promoBonusAmount != BigInt.zero) {
    throw const FormatException(
      'Only GRANTED may carry a non-zero promo_bonus_amount',
    );
  }
}

PurchaseSettlementResultModel parseCanonicalPurchaseSettlement(
  Map<String, dynamic> json,
) {
  final exact = requireExactContractKeys(json, purchaseSettlementKeys);
  if (exact['contract_version'] != 'wallet.v1') {
    throw const FormatException('Unsupported purchase contract_version');
  }
  final promotionJson = exact['promotion'];
  if (promotionJson is! Map) {
    throw const FormatException(
      'Canonical wallet.v1 purchase promotion must be an object',
    );
  }
  final promotion = PurchasePromotionResultModel.fromJson(
    Map<String, dynamic>.from(promotionJson),
  );
  validatePurchasePromotion(promotion);
  return _$PurchaseSettlementResultModelFromJson(exact);
}

PurchaseSettlementResultModel parseLegacyPurchaseSettlement(
  Map<String, dynamic> json,
) {
  final inputKeys = json.keys.toSet();
  final withoutPromotion = {...purchaseSettlementKeys}..remove('promotion');
  if (inputKeys.length != withoutPromotion.length ||
      !inputKeys.containsAll(withoutPromotion)) {
    if (inputKeys.length != purchaseSettlementKeys.length ||
        !inputKeys.containsAll(purchaseSettlementKeys)) {
      throw const FormatException('Invalid legacy purchase key set');
    }
  }
  if (json.containsKey('promotion') && json['promotion'] != null) {
    throw const FormatException(
      'Non-null promotion must use the canonical parser',
    );
  }
  final normalized = <String, dynamic>{...json, 'promotion': null};
  final exact = requireExactContractKeys(
    normalized,
    purchaseSettlementKeys,
  );
  if (exact['contract_version'] != 'wallet.v1') {
    throw const FormatException('Unsupported purchase contract_version');
  }
  return _$PurchaseSettlementResultModelFromJson(exact);
}
~~~

Canonical v1 is exactly <code>{contract_version:'wallet.v1',operation_id,replayed,base_star_amount,base_bonus_amount,promotion,wallet}</code> and <code>promotion</code> is non-null. Its state wire values are exactly <code>PENDING_TIME|ELIGIBLE|INELIGIBLE|GRANTED|REJECTED|CANCELLED_BY_REFUND</code>. <code>domain_code='PROMO_REVIEW_REQUIRED'</code> is mandatory only for <code>PENDING_TIME</code>, and every non-GRANTED state carries <code>promo_bonus_amount:'0'</code>. The amount converters and nested <code>WalletSummaryModel</code> reject numeric or malformed amounts. Only the explicitly named <code>fromLegacyJson</code> parser accepts an absent/null promotion and normalizes it to null; a non-null promotion must use the canonical parser.

Change the service signatures so the server result cannot be discarded:

~~~dart
typedef PurchaseSuccess = Future<void> Function(
  PurchaseSettlementResultModel result,
);

Future<PurchaseSettlementResultModel> verifyReceipt(
  String receipt,
  String productId,
  String userId,
  String environment,
);

Future<PurchaseSettlementResultModel> _callVerificationFunction(
  Map<String, dynamic> requestBody,
  String verificationType,
) async {
  // Preserve the existing timeout/retry/reused-receipt behavior.
  final response = await supabase.functions
      .invoke('verify_receipt', body: requestBody)
      .timeout(timeoutDuration);
  return PurchaseSettlementResultModel.fromJson(
    Map<String, dynamic>.from(response.data as Map),
  );
}

Future<void> handleOptimizedPurchase(
  PurchaseDetails purchaseDetails,
  PurchaseSuccess onSuccess,
  Function(String) onError, {
  required bool isActualPurchase,
});
~~~

Return the model through <code>_verifyiOSReceipt</code>/<code>_verifyAndroidReceipt</code>, <code>verifyReceipt</code>, <code>PurchaseService._verifyReceipt</code>, and both actual-success handlers; replace every actual <code>onSuccess()</code> with <code>await onSuccess(result)</code>. Restored purchases continue to skip the callback. On success, set <code>walletSummaryProvider</code> from <code>result.wallet</code>; profile refresh remains only for legacy compatibility data.

Capture the campaign shown when the user confirms, not whichever campaign happens to be active when StoreKit completes. Because the purchase stream identifies this path by product ID, enforce one unresolved attempt per product until a terminal callback or explicit reconciliation:

~~~dart
class PurchaseCampaignAttempt {
  const PurchaseCampaignAttempt({
    required this.attemptId,
    required this.productId,
    required this.displayedCampaign,
  });

  final String attemptId;
  final String productId;
  final ActivePromotionCampaignModel? displayedCampaign;
}

final _purchaseAttemptByProductId =
    <String, PurchaseCampaignAttempt>{};

ActivePromotionCampaignModel? displayedCampaign;
for (final value in storeCampaign.value?.items ??
    const <ActivePromotionCampaignModel>[]) {
  if (value.showInStore) {
    displayedCampaign = value;
    break;
  }
}
final productId = serverProduct['id'] as String;
if (_purchaseAttemptByProductId.containsKey(productId)) {
  await _dialogHandler.showPurchaseAlreadyPendingDialog();
  return;
}
final confirmed = await _dialogHandler.showPurchaseConfirmDialog(
  serverProduct: serverProduct,
  storeProducts: storeProducts,
  displayedCampaign: displayedCampaign,
);
if (confirmed == true) {
  final attempt = PurchaseCampaignAttempt(
    attemptId: const Uuid().v4(),
    productId: productId,
    displayedCampaign: displayedCampaign,
  );
  if (_purchaseAttemptByProductId.putIfAbsent(productId, () => attempt) !=
      attempt) {
    await _dialogHandler.showPurchaseAlreadyPendingDialog();
    return;
  }
  try {
    await _processPurchase(
      context,
      serverProduct,
      storeProducts,
      attemptId: attempt.attemptId,
    );
  } catch (_) {
    if (_purchaseAttemptByProductId[productId]?.attemptId ==
        attempt.attemptId) {
      _purchaseAttemptByProductId.remove(productId);
    }
    rethrow;
  }
}
~~~

The typed purchase callback looks up <code>purchaseDetails.productID</code>, rejects an actual-purchase callback with no matching attempt, and passes the captured attempt campaign with the verified result. It removes the entry only after terminal verified success (after the dialog receives the snapshot), <code>PurchaseStatus.canceled</code>, <code>PurchaseStatus.error</code>, or an immediate store-launch failure. <code>pending</code>, verification timeout, app suspension, and retryable receipt errors retain the entry; the existing restore/reconciliation path may clear it only after it proves a terminal transaction. Before removing, compare the stored <code>attemptId</code> so a stale callback cannot clear another attempt. Restored purchases still skip the actual-success callback and never borrow a current campaign. The handler interfaces are exact:

~~~dart
Future<bool?> showPurchaseConfirmDialog({
  required Map<String, dynamic> serverProduct,
  required List<ProductDetails> storeProducts,
  required ActivePromotionCampaignModel? displayedCampaign,
});

Future<void> showSuccessDialog({
  required PurchaseSettlementResultModel result,
  required ActivePromotionCampaignModel? displayedCampaign,
});

Future<void> showLatePurchaseSuccessDialog({
  required PurchaseSettlementResultModel result,
  required ActivePromotionCampaignModel? displayedCampaign,
});

Future<void> showPurchaseAlreadyPendingDialog();
~~~

Confirmation may append only <code>displayedCampaign.localizedDisplayName(Localizations.localeOf(context).languageCode)</code>; it must not calculate or promise an amount, percentage, or doubling. Success shows campaign name plus <code>formatWalletAmount(result.promotion!.promoBonusAmount)</code> only when state is <code>GRANTED</code> and <code>campaignVersionId == displayedCampaign.campaignVersionId</code>. <code>PENDING_TIME</code> and <code>ELIGIBLE</code> show base-purchase success plus localized “promotion 확인 중” copy. Null legacy promotion, <code>INELIGIBLE</code>, <code>REJECTED</code>, <code>CANCELLED_BY_REFUND</code>, a missing displayed campaign, and version mismatch show generic base-purchase success without a boost claim. Late-purchase success uses the same decision helper and merely adds the existing late-completion explanation.

Tests must prove: canonical numeric amounts and missing/null canonical promotion fail; the legacy parser alone accepts null; all state converter values and invalid state/domain combinations are covered; the <code>purchase_results_v1</code> PENDING_TIME/INELIGIBLE/GRANTED bundle parses; a matching <code>GRANTED</code> result renders the server <code>promo_bonus_amount</code> without BPS arithmetic; an active displayed campaign with ineligible or mismatched server result renders generic success; pending/eligible render checking copy; receipt verification returns the exact response; and PurchaseService/state/dialog receive the same object and captured campaign version. Start two purchases for the same product across a campaign boundary and prove the second is blocked while the first retains its original version; prove timeout retains the lock, terminal success/error/cancel clears only its own attempt, a stale callback cannot clear a newer attempt, and a different product may proceed independently.

- [ ] **Step 5: Add HOME creative through shared CommonBanner**

<code>CommonBanner</code> watches HOME campaign only when <code>location == 'vote_home'</code>. <code>CandyBoostBanner</code> uses <code>Alignment.centerLeft</code> and <code>TextAlign.left</code>, image/link/duration from campaign creative, and server-selected campaign version.

~~~dart
class CommonBannerSlide {
  const CommonBannerSlide({
    required this.id,
    required this.duration,
    required this.child,
  });

  final String id;
  final Duration duration;
  final Widget child;
}

Duration _slideDuration(int milliseconds) =>
    Duration(milliseconds: milliseconds > 0 ? milliseconds : 3000);

List<CommonBannerSlide> _ordinarySlides(List<BannerModel> banners) => [
      for (final item in banners)
        CommonBannerSlide(
          id: 'ordinary:${item.id}',
          duration: _slideDuration(item.duration),
          child: _buildBannerItem(item),
        ),
    ];

List<CommonBannerSlide> _homeSlides(
  List<BannerModel> ordinaryBanners,
  ActivePromotionCampaignsModel campaigns,
  String languageCode,
) {
  final ownedIds = campaigns.campaignOwnedHomeBannerIds.toSet();
  final emittedCampaignBannerIds = <int>{};
  final campaignSlides = <CommonBannerSlide>[
    for (final campaign in campaigns.visibleHomeItems(languageCode))
      if (emittedCampaignBannerIds.add(campaign.homeCreative!.bannerId))
        CommonBannerSlide(
          id: 'campaign:${campaign.homeCreative!.bannerId}',
          duration: _slideDuration(campaign.homeCreative!.duration),
          child: CandyBoostBanner(campaign: campaign),
        ),
  ];
  final ordinarySlides = _ordinarySlides(
    ordinaryBanners
        .where((banner) => !ownedIds.contains(banner.id))
        .toList(),
  );
  return [...campaignSlides, ...ordinarySlides];
}

void _startAutoplay(List<CommonBannerSlide> slides) {
  _autoplayTimer?.cancel();
  if (slides.length < 2) return;
  if (_currentIndex >= slides.length) _currentIndex = 0;
  _autoplayTimer = Timer(slides[_currentIndex].duration, () {
    if (!mounted) return;
    _swiperController?.move((_currentIndex + 1) % slides.length);
  });
}

Widget _renderSlides(List<CommonBannerSlide> slides) {
  if (slides.isEmpty) return const SizedBox.shrink();
  if (_currentIndex >= slides.length) _currentIndex = 0;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _startAutoplay(slides);
  });
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: slides.length == 1
            ? KeyedSubtree(
                key: ValueKey(slides.single.id),
                child: slides.single.child,
              )
            : Swiper(
                controller: _swiperController,
                itemCount: slides.length,
                itemBuilder: (_, index) => KeyedSubtree(
                  key: ValueKey(slides[index].id),
                  child: slides[index].child,
                ),
                onIndexChanged: (index) {
                  setState(() => _currentIndex = index);
                  _startAutoplay(slides);
                },
                autoplay: false,
                duration: 300,
              ),
      ),
      if (slides.length > 1)
        SizedBox(
          height: 20,
          child: CustomPagination(
            itemCount: slides.length,
            activeIndex: _currentIndex,
          ),
        ),
    ],
  );
}

final ordinary = ref.watch(
  asyncBannerListProvider(location: widget.location),
);
return ordinary.when(
  data: (ordinaryBanners) {
    if (widget.location != 'vote_home') {
      return _renderSlides(_ordinarySlides(ordinaryBanners));
    }
    final homeCampaign = ref.watch(
      activePromotionCampaignProvider(PromotionSurface.home),
    );
    return homeCampaign.when(
      data: (campaigns) => _renderSlides(
        _homeSlides(
          ordinaryBanners,
          campaigns,
          Localizations.localeOf(context).languageCode,
        ),
      ),
      loading: _buildBannerShimmer,
      error: (error, stackTrace) => buildErrorView(
        context,
        error: error.toString(),
        stackTrace: stackTrace,
      ),
    );
  },
  loading: _buildBannerShimmer,
  error: (error, stackTrace) => buildErrorView(
    context,
    error: error.toString(),
    stackTrace: stackTrace,
  ),
);
~~~

Extract the current shimmer into <code>_buildBannerShimmer()</code>. HOME never renders ordinary banners from a partial campaign state: campaign loading renders only shimmer, and campaign error renders only the error view. Filtering happens before ordinary widgets are built and removes every duplicate row whose ID is campaign-owned. It therefore applies while a campaign is inactive, missing creative, or represented by another version. Campaign slides remain prepended and a campaign banner ID renders at most once. The single slide list drives item count, pagination, current-index bounds, duration, and autoplay for both campaign and ordinary entries.

On pull-to-refresh, both <code>HomePage</code> and fallback <code>VoteHomePage</code> invalidate HOME campaign and ordinary banner providers. Leave scheduling behavior for unowned ordinary banners unchanged; Candy Boost never reads <code>banner.start_at/end_at</code>. Tests cover campaign loading/error withholding ordinary content, campaign-only/ordinary-only/mixed lists, current index after list shrink, each source's duration controlling the next move, owned duplicate filtering, <code>Locale('en', 'US').languageCode == 'en'</code>, and no HOME provider watch at other locations.

- [ ] **Step 6: Generate and run campaign/purchase/store/home tests**

Run:

~~~bash
cd picnic_lib
dart run build_runner build --delete-conflicting-outputs
flutter test test/data/repositories/promotion_campaign_repository_test.dart test/presentation/providers/promotion_campaign_provider_test.dart test/data/models/purchase/purchase_settlement_result_test.dart test/core/services/receipt_verification_service_test.dart test/core/services/purchase_service_logic_test.dart test/presentation/widgets/vote/store/purchase/candy_boost_badge_test.dart test/presentation/common/candy_boost_banner_test.dart test/presentation/common/common_banner_render_test.dart test/presentation/pages/vote/home_page_test.dart test/presentation/pages/vote/vote_home_page_render_test.dart test/presentation/widgets/vote/store/purchase
~~~

Expected: STORE/HOME use identical <code>campaignVersionId</code>; verified purchase result reaches the dialog unchanged; only matching server-GRANTED promotion claims a boost; no <code>at</code> parameter is sent; missing title or image hides HOME; inactive/duplicate campaign-owned ordinary banners are excluded; active owned creative appears exactly once; copy is left aligned.

- [ ] **Step 7: Commit**

~~~bash
git add picnic_lib/lib/data/models/promotion picnic_lib/lib/data/models/purchase picnic_lib/lib/data/repositories/promotion_campaign_repository.dart picnic_lib/lib/core/services/receipt_verification_service.dart picnic_lib/lib/core/services/purchase_service.dart picnic_lib/lib/presentation/providers/promotion_campaign_provider.dart picnic_lib/lib/generated/providers/models/promotion picnic_lib/lib/generated/providers/models/purchase picnic_lib/lib/generated/providers/promotion_campaign_provider.g.dart picnic_lib/lib/presentation/widgets/vote/store/purchase picnic_lib/lib/presentation/common picnic_lib/lib/presentation/pages/vote/home_page.dart picnic_lib/lib/presentation/pages/vote/vote_home_page.dart picnic_lib/test/data/models/purchase picnic_lib/test/data/repositories/promotion_campaign_repository_test.dart picnic_lib/test/core/services/receipt_verification_service_test.dart picnic_lib/test/core/services/purchase_service_logic_test.dart picnic_lib/test/presentation/providers/promotion_campaign_provider_test.dart picnic_lib/test/presentation/widgets/vote/store/purchase picnic_lib/test/presentation/common picnic_lib/test/presentation/pages/vote picnic_lib/test/fixtures/wallet_contracts/promotion_surfaces_*.json picnic_lib/test/fixtures/wallet_contracts/purchase_results_v1.json
git commit -m "feat(store): render server-controlled candy boost surfaces"
~~~

### Task 10: Goldens, Integration, Version Gate, and Final Verification

**Files:**
- Create: <code>picnic_lib/test/presentation/widgets/wallet/wallet_summary_panel_golden_test.dart</code>
- Create: <code>picnic_lib/test/presentation/common/candy_boost_banner_golden_test.dart</code>
- Create generated: <code>picnic_lib/test/goldens/wallet_summary_panel.png</code>
- Create generated: <code>picnic_lib/test/goldens/candy_boost_banner.png</code>
- Create from canonical exporter: <code>picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart</code>
- Modify: <code>picnic_app/integration_test/helpers/mock_supabase_server.dart</code>
- Modify: <code>picnic_app/integration_test/flows/vote_flow_test.dart</code>
- Create: <code>picnic_app/integration_test/flows/ad_reward_recovery_flow_test.dart</code>
- Modify: <code>picnic_app/integration_test/app_test.dart</code>
- Modify: <code>picnic_app/pubspec.yaml</code>
- Modify test: <code>picnic_lib/test/presentation/providers/check_update_provider_test.dart</code>
- Modify: <code>picnic_lib/lib/presentation/dialogs/force_update_overlay.dart</code>

**Interfaces:**
- Consumes all earlier task interfaces.
- Produces release <code>1.2.34+123401</code> and executable acceptance coverage.

- [ ] **Step 1: Write golden tests at fixed dimensions**

~~~dart
Map<String, dynamic> loadGoldenFixture(String path) {
  return Map<String, dynamic>.from(
    jsonDecode(File(path).readAsStringSync()) as Map,
  );
}

final walletSummaryFixture = WalletSummaryModel.fromJson(
  loadGoldenFixture(
    'test/fixtures/wallet_contracts/wallet_summary_v1.json',
  ),
);

final activeCampaignFixture = ActivePromotionCampaignsModel.fromJson(
  loadGoldenFixture(
    'test/fixtures/wallet_contracts/promotion_surfaces_active_v1.json',
  ),
).visibleHomeItems('ko').single;

class GoldenWalletSummary extends WalletSummary {
  GoldenWalletSummary(this.value);
  final WalletSummaryModel value;

  @override
  Future<WalletSummaryModel> build() async => value;
}

Widget buildWalletGoldenApp(WalletSummaryModel wallet) {
  return ProviderScope(
    overrides: [
      walletSummaryProvider.overrideWith(
        () => GoldenWalletSummary(wallet),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(child: WalletSummaryPanel()),
    ),
  );
}

Widget buildCampaignGoldenApp(
  ActivePromotionCampaignModel campaign,
) {
  return MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Material(child: CandyBoostBanner(campaign: campaign)),
  );
}

testWidgets('three-currency wallet golden', (tester) async {
  tester.view.physicalSize = const Size(1179, 510);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(buildWalletGoldenApp(walletSummaryFixture));
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(WalletSummaryPanel),
    matchesGoldenFile('../../../goldens/wallet_summary_panel.png'),
  );
});

testWidgets('left-aligned candy boost banner golden', (tester) async {
  tester.view.physicalSize = const Size(1179, 600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(buildCampaignGoldenApp(activeCampaignFixture));
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(CandyBoostBanner),
    matchesGoldenFile('../../goldens/candy_boost_banner.png'),
  );
});
~~~

Import <code>dart:convert</code> and <code>dart:io</code> in both host-side golden tests. These paths are resolved from <code>picnic_lib</code> by <code>flutter test</code>; device integration tests below deliberately do not use <code>File</code> or <code>rootBundle</code> for contract fixtures.

Run:

~~~bash
cd picnic_lib
flutter test --update-goldens test/presentation/widgets/wallet/wallet_summary_panel_golden_test.dart test/presentation/common/candy_boost_banner_golden_test.dart
flutter test test/presentation/widgets/wallet/wallet_summary_panel_golden_test.dart test/presentation/common/candy_boost_banner_golden_test.dart
~~~

Expected: reviewed PNGs show equal-size icon family, left-aligned currency text/Cotton expiry, and left-aligned pink campaign copy; normal golden run PASS.

- [ ] **Step 2: Extend integration mock and general vote flow**

Generate the device-safe Dart fixture library from the same canonical exporter. Do not copy JSON by hand:

~~~bash
node /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/scripts/wallet/export_contract_fixtures.mjs \
  --manifest /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet/contracts/manifest.json \
  --output /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet/contracts/fixtures \
  --app /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_lib/test/fixtures/wallet_contracts \
  --admin /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/test/fixtures/wallet-contracts \
  --app-integration-dart /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart
~~~

The generated library exposes stable raw const maps and no filesystem loader. Assert the complete standardized set without hand-writing generated JSON or checksum values:

~~~dart
const expectedWalletContractFixtureNames = <String>{
  'wallet_summary_v1.json',
  'currency_history_empty_v1.json',
  'currency_history_mixed_v1.json',
  'vote_result_v3.json',
  'ad_reward_pending_v1.json',
  'ad_reward_granted_v1.json',
  'promotion_surfaces_empty_v1.json',
  'promotion_surfaces_active_v1.json',
  'purchase_results_v1.json',
  'admin_cs_summary_v1.json',
  'admin_money_timeline_v1.json',
  'stable_error_v1.json',
};

expect(walletContractFixtureJson.keys.toSet(), expectedWalletContractFixtureNames);
expect(
  walletContractFixtureSha256.keys.toSet(),
  expectedWalletContractFixtureNames,
);
for (final checksum in walletContractFixtureSha256.values) {
  expect(checksum, matches(RegExp(r'^[0-9a-f]{64}$')));
}
expect(
  walletContractFixtureSetSha256,
  matches(RegExp(r'^[0-9a-f]{64}$')),
);
~~~

The exporter fills the complete JSON and real checksums. Change <code>MockSupabaseServer._handleRequest</code> to async, import <code>../fixtures/wallet_contract_fixtures.g.dart</code>, record the function body, and serve the generated const:

~~~dart
Map<String, dynamic>? lastVoteBody;

Future<void> _handleRequest(HttpRequest request) async {
  final path = request.uri.path;
  request.response.headers.add('Access-Control-Allow-Origin', '*');
  request.response.headers.add('Content-Type', 'application/json');
  if (path.endsWith('/functions/v1/voting-v2')) {
    lastVoteBody = Map<String, dynamic>.from(
      jsonDecode(await utf8.decoder.bind(request).join()) as Map,
    );
    request.response.statusCode = HttpStatus.ok;
    request.response.write(
      walletContractFixtureJson['vote_result_v3.json']!,
    );
    await request.response.close();
    return;
  }
  if (scenario == MockScenario.networkError) {
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.write(jsonEncode({'error': 'Mock network error'}));
    await request.response.close();
  } else if (path.contains('/auth/')) {
    _handleAuthRequest(request);
  } else if (path.contains('/rest/')) {
    _handleDataRequest(request);
  } else {
    _handleDefaultRequest(request);
  }
}
~~~

Replace the existing empty vote flow bodies with an injected-client integration:

~~~dart
testWidgets('general vote sends v3 body through voting-v2', (tester) async {
  final client = SupabaseClient(
    TestAppSetup.mockServer.baseUrl,
    'integration-anon-key',
  );
  final repository = VoteTransactionRepository(
    client,
    delay: (_) async {},
  );
  final result = await repository.performGeneralVote(
    VoteTransactionRequest(
      voteId: 10,
      voteItemId: 20,
      amount: BigInt.from(17),
      requestId: '018f4f72-2ff0-7ae0-bf62-5b40d9855472',
    ),
  );
  final body = TestAppSetup.mockServer.lastVoteBody!;
  expect(body['request_id'], '018f4f72-2ff0-7ae0-bf62-5b40d9855472');
  expect(body, isNot(contains('star_candy_usage')));
  expect(body, isNot(contains('star_candy_bonus_usage')));
  expect(body, isNot(contains('cotton_candy_usage')));
  expect(result.usage.cottonCandy, BigInt.from(5));
  expect(result.usage.bonusStarCandy, BigInt.from(7));
  expect(result.usage.starCandy, BigInt.from(5));
  expect(result.wallet.star, BigInt.from(95));
  expect(result.wallet.cotton, BigInt.zero);
  expect(result.wallet.bonus, BigInt.from(23));
  expect(
    walletContractFixtureSha256['vote_result_v3.json'],
    matches(RegExp(r'^[0-9a-f]{64}$')),
  );
  expect(
    walletContractFixtureSetSha256,
    matches(RegExp(r'^[0-9a-f]{64}$')),
  );
  expect(
    jsonDecode(walletContractFixtureJson['vote_result_v3.json']!),
    isA<Map<String, dynamic>>(),
  );
});
~~~

PIC and JMA endpoint assertions remain in the Task 5 widget regression tests because <code>VoteTransactionRepository</code> is intentionally general-vote only. No integration code calls <code>File</code> or <code>rootBundle</code> for contract fixtures, so this runs on Android/iOS devices without a host-repository path.

- [ ] **Step 3: Add process-resume reward acceptance flow**

The new integration flow recreates a <code>ProviderContainer</code> over one memory-backed <code>LocalStorage</code> to model a process restart. Add these exact fakes:

~~~dart
class MemoryLocalStorage implements LocalStorage {
  final values = <String, String>{};

  @override
  Future<void> saveData(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<String?> loadData(String key, String? defaultValue) async {
    return values[key] ?? defaultValue;
  }

  @override
  Future<void> removeData(String key) async {
    values.remove(key);
  }

  @override
  Future<void> clearStorage() async {
    values.clear();
  }
}

class FakeAdRewardApi implements AdRewardApi {
  FakeAdRewardApi({required this.statuses});
  final Map<AdRewardReference, AdRewardStatusModel> statuses;
  int ackCount = 0;

  @override
  Future<AdRewardStatusModel> getStatus(
    AdRewardReference reference,
  ) async => statuses[reference]!;

  @override
  Future<AdRewardPageModel> listUnacknowledged({
    String? cursor,
    int limit = 20,
  }) async {
    return AdRewardPageModel(
      items: statuses.values.toList(),
      totalCount: BigInt.from(statuses.length),
      nextCursor: null,
      snapshotAt: DateTime.utc(2026, 7, 21),
    );
  }

  @override
  Future<void> acknowledge(AdRewardReference reference) async {
    ackCount += 1;
  }

  @override
  Future<PangleClaimModel> createPangleClaim({
    required String platform,
    required String placementId,
    required String clientRequestId,
  }) {
    throw StateError('Claim creation is outside this recovery test');
  }

  @override
  InternalShortformViewResponse parseInternalViewResponse(
    Map<String, dynamic> json,
  ) {
    throw StateError('Shortform parsing is outside this recovery test');
  }
}
~~~

Then execute:

~~~dart
final memory = MemoryLocalStorage();
final pendingStore = PendingAdRewardStore(memory);
await pendingStore.add('user-a', internalReference);
final api = FakeAdRewardApi(
  statuses: {
    internalReference: internalGranted,
    pangleReference: pangleGranted,
  },
);

ProviderContainer createContainer() => ProviderContainer(overrides: [
      adRewardRepositoryProvider.overrideWithValue(api),
      pendingAdRewardStoreProvider.overrideWithValue(pendingStore),
      adRewardDelayProvider.overrideWithValue((_) async {}),
      adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
    ]);

final beforeAck = createContainer();
await beforeAck
    .read(adRewardRecoveryProvider.notifier)
    .recover('user-a');
expect(
  beforeAck.read(adRewardRecoveryProvider).dialogQueue.length,
  2,
);
beforeAck.dispose();
expect(api.ackCount, 0);

final afterRestart = createContainer();
await afterRestart
    .read(adRewardRecoveryProvider.notifier)
    .recover('user-a');
final queue = afterRestart.read(adRewardRecoveryProvider).dialogQueue;
expect(queue.length, 2);
for (final queued in queue) {
  expect(queued.ownerUserId, 'user-a');
  await afterRestart
      .read(adRewardRecoveryProvider.notifier)
      .acknowledgeAfterRender(queued);
}
expect(api.ackCount, 2);
expect(await pendingStore.readAll('user-a'), isEmpty);
afterRestart.dispose();
~~~

Import this flow from <code>integration_test/app_test.dart</code>. Task 7’s widget test remains the proof that <code>acknowledgeAfterRender</code> is invoked only by the dialog’s first-frame callback.

- [ ] **Step 4: Fix and test the force-version presentation**

Change:

~~~dart
String get forceVersion => updateInfo.forceVersion;
~~~

Add a test that <code>ForceUpdateOverlay</code> displays <code>1.2.34</code> when latest is <code>1.2.35</code> and force is <code>1.2.34</code>. Server-side eligibility still remains authoritative if update fetch/cache is unavailable.

- [ ] **Step 5: Set the wallet-aware app version**

Change <code>picnic_app/pubspec.yaml</code>:

~~~yaml
version: 1.2.34+123401
~~~

Run: <code>cd picnic_app && flutter pub get</code>

Expected: dependency resolution exits 0 and <code>package_info_plus</code> exposes version <code>1.2.34</code>, build <code>123401</code>.

- [ ] **Step 6: Run focused integration tests**

Run:

~~~bash
cd picnic_app
dart run tool/verify_environment_isolation.dart --environment=local
PICNIC_TEST_DEVICE_ID="$(flutter devices --machine | jq -r \
  '[.[] | select(.targetPlatform | test("^(android|ios)"))][0].id // empty')"
test -n "$PICNIC_TEST_DEVICE_ID"
flutter test integration_test/flows/vote_flow_test.dart \
  -d "$PICNIC_TEST_DEVICE_ID"
flutter test integration_test/flows/ad_reward_recovery_flow_test.dart \
  -d "$PICNIC_TEST_DEVICE_ID"
~~~

Expected: an installed Android/iOS target is selected, general Cotton-first flow PASS, PIC/JMA remain unchanged, and reward restart/ACK flow PASS. If <code>test -n</code> fails, start one Android emulator or iOS simulator and rerun the same block.

- [ ] **Step 7: Run full app verification**

Run:

~~~bash
node /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/scripts/wallet/verify_contract_checksums.mjs \
  --manifest /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet/contracts/manifest.json \
  /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_lib/test/fixtures/wallet_contracts \
  /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/test/fixtures/wallet-contracts \
  --app-integration-dart /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart

cd /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_lib
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

cd ../picnic_app
dart run tool/verify_environment_isolation.dart --environment=local
dart format --output=none --set-exit-if-changed lib integration_test
flutter analyze
flutter test

cd android
./gradlew testDebugUnitTest

cd ../../
git diff --check
git status --short
if git diff --cached --name-only | rg "^\\.superpowers/"; then exit 1; fi
~~~

Expected: the verifier prints <code>12 contract fixtures verified; checksum mismatches: 0; integration constants verified</code>; every command exits 0; generated files are current; no staged path starts with <code>.superpowers/</code>.

- [ ] **Step 8: Commit**

~~~bash
git add picnic_lib/test/goldens picnic_lib/test/fixtures/wallet_contracts picnic_lib/test/presentation/widgets/wallet/wallet_summary_panel_golden_test.dart picnic_lib/test/presentation/common/candy_boost_banner_golden_test.dart picnic_lib/lib/presentation/dialogs/force_update_overlay.dart picnic_lib/test/presentation/providers/check_update_provider_test.dart picnic_app/integration_test picnic_app/pubspec.yaml picnic_app/pubspec.lock
git commit -m "test(wallet): verify cotton candy release flows"
~~~

---

## Release Gate Checklist

- [ ] Supabase, app, admin, and generated device-fixture checksums match; verifier reports 12 fixtures, 0 mismatches, and verified integration constants.
- [ ] <code>get_wallet_summary</code> renders zero and non-zero Cotton without raw profile balance reads.
- [ ] General <code>VotePortal.vote</code> calls <code>voting-v2</code> with one stable <code>request_id</code> and no client usage fields; wrapper deployment is confirmed to call <code>perform_vote_transaction_v3</code>.
- [ ] General vote retries at most three times only for <code>TX_CONFLICT_RETRYABLE</code>/<code>retryable:true</code>; every 429 is single-attempt.
- [ ] PIC, JMA, and Goonghap writer behavior is unchanged.
- [ ] Internal view callback never creates a replacement impression after token expiry.
- [ ] Pangle load has a persisted claim and exact signed v2 <code>media_extra</code> before native SDK load.
- [ ] Native reward/dismiss/failure events only trigger status polling.
- [ ] Local pending plus server unacknowledged union survives process restart and account switches cannot leak references, queue entries, or ACK ownership.
- [ ] Terminal popup ACK occurs after its first rendered frame; durable <code>ACK_PENDING</code> suppresses redisplay across both crash windows, and idempotent startup/resume ACK removes the tombstone only after success.
- [ ] Current internal shortform success reaches that same recovery queue/first-frame ACK path; legacy Bonus response still uses <code>reward_added/new_bonus</code> UX.
- [ ] HOME and STORE display one server-selected campaign version and send no client <code>at</code> value.
- [ ] Every campaign-owned HOME banner ID is excluded from ordinary banners even while inactive/duplicated; active campaign creative appears once.
- [ ] HOME campaign loading/error never leaks ordinary banners, and one unified slide list controls duration, autoplay, pagination, and index bounds.
- [ ] Missing HOME title or image renders nothing; creative fallback is locale → Korean → English and campaign name fallback is locale → Korean → code.
- [ ] Purchase UI claims boost only from a matching server <code>GRANTED</code> result and displays its decimal-string <code>promo_bonus_amount</code> without local BPS math.
- [ ] Canonical/legacy purchase parsers enforce exact keys, state/domain rules, decimal strings, and non-null canonical promotion; same-product attempts remain locked to their captured campaign until terminal resolution.
- [ ] Wallet, policy dialog, vote history, store and home use approved names, left alignment, and product PNG paths.
- [ ] Release build/version is <code>1.2.34+123401</code>; server minimum gate is configured before Cotton mode.
- [ ] Local/dev Supabase tuple differs from production, staging ref evidence exists, no Supabase CLI link metadata is tracked, and an explicit <code>ENVIRONMENT</code> is required.
- [ ] Codemagic production tag resolves to exact <code>origin/main</code> SHA and protected approval evidence; local Shorebird/Lambda/remote schema-copy commands fail closed.
- [ ] Privileged-looking mobile config fields were audited; any active privileged credential was removed from the client and rotated before release.
- [ ] <code>.superpowers/</code> has no staged files and no product code references.

## Execution Handoff

Plan execution uses <code>superpowers:subagent-driven-development</code> with one fresh worker per task and two-stage review between commits. If executing inline instead, use <code>superpowers:executing-plans</code> and stop at each task’s verification checkpoint.
