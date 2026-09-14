import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_action_button.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_feedback.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_filter_chip.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_section_header.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_status_badge.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_surface.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/pic_theme.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/vote_theme.dart';

import '../../../helpers/load_test_fonts.dart';
import '../../../helpers/picnic_ui_test_environment.dart';

double _contrastRatio(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final darker = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}

void _useViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() async {
    await loadTestFonts();
    await loadPicnicUiTestFontWeights();
  });
  setUp(initPicnicUiTestEnvironment);

  group('PicnicUi palette behavior', () {
    for (final hostApp in const ['picnic_app', 'ttja_app']) {
      test('$hostApp production palette has readable dynamic foregrounds', () {
        final palette = PicnicUiTestPalette.fromProductionConfig(hostApp);
        final fixture = PicnicUiColorFixture.install(palette);
        addTearDown(fixture.restore);

        final configuredPrimary = AppColors.primary500;
        final configuredSecondary = AppColors.secondary500;
        final actionColor = PicnicUi.actionColor;

        expect(actionColor, isNot(configuredPrimary));
        if (hostApp == 'picnic_app') {
          expect(actionColor, const Color(0xFF795FD1));
        }
        expect(PicnicUi.onActionColor, AppColors.grey00);
        expect(
          _contrastRatio(actionColor, PicnicUi.onActionColor),
          greaterThanOrEqualTo(4.8),
        );
        expect(PicnicUi.primaryForeground, AppColors.grey900);
        expect(
          _contrastRatio(configuredPrimary, PicnicUi.primaryForeground),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(configuredSecondary, PicnicUi.secondaryForeground),
          greaterThanOrEqualTo(4.5),
        );
        expect(AppColors.primary500, configuredPrimary);
        expect(AppColors.secondary500, configuredSecondary);
      });
    }

    test('computed roles follow a runtime brand palette change', () {
      final picnic = PicnicUiTestPalette.fromProductionConfig('picnic_app');
      final ttja = PicnicUiTestPalette.fromProductionConfig('ttja_app');
      final picnicFixture = PicnicUiColorFixture.install(picnic);
      addTearDown(picnicFixture.restore);
      final picnicAction = PicnicUi.actionColor;

      picnicFixture.restore();
      final ttjaFixture = PicnicUiColorFixture.install(ttja);
      addTearDown(ttjaFixture.restore);

      expect(AppColors.primary500, ttja.primary);
      expect(PicnicUi.actionColor, isNot(picnicAction));
      expect(
        _contrastRatio(PicnicUi.actionColor, PicnicUi.onActionColor),
        greaterThanOrEqualTo(4.8),
      );
    });

    test(
      'action shade is cached per configured primary and invalidates by value',
      () {
        final picnic = PicnicUiTestPalette.fromProductionConfig('picnic_app');
        final ttja = PicnicUiTestPalette.fromProductionConfig('ttja_app');
        final fixture = PicnicUiColorFixture.install(picnic);
        addTearDown(fixture.restore);

        final picnicAction = PicnicUi.actionColor;
        expect(identical(PicnicUi.actionColor, picnicAction), isTrue);

        AppColors.primary500 = Color(picnic.primary.toARGB32());
        expect(
          identical(PicnicUi.actionColor, picnicAction),
          isTrue,
          reason: 'an equal configured Color must retain the cached shade',
        );

        AppColors.primary500 = ttja.primary;
        final ttjaAction = PicnicUi.actionColor;
        expect(ttjaAction, isNot(picnicAction));
        expect(identical(PicnicUi.actionColor, ttjaAction), isTrue);
      },
    );

    test('foregroundFor chooses readable ink for light and dark surfaces', () {
      const dark = Color(0xFF252528);
      const light = Color(0xFFF7F7F8);
      final tintedDark = dark.withValues(alpha: 0.08);

      final onDark = PicnicUi.foregroundFor(dark);
      final onLight = PicnicUi.foregroundFor(light);
      final onTint = PicnicUi.foregroundFor(tintedDark);
      final effectiveTint = Color.alphaBlend(tintedDark, AppColors.grey00);

      expect(onDark, AppColors.grey00);
      expect(onLight, AppColors.grey900);
      expect(onTint, AppColors.grey900);
      expect(_contrastRatio(dark, onDark), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light, onLight), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(effectiveTint, onTint), greaterThanOrEqualTo(4.5));
      expect(
        _contrastRatio(PicnicUi.quietText, PicnicUi.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('translucent surface colors resolve to an opaque decoration', () {
      final decoration = PicnicUi.surfaceDecoration(
        color: const Color(0xFF9374FF).withValues(alpha: 0.08),
      );

      expect(decoration.color, isNotNull);
      expect(decoration.color!.a, 1);
    });

    test('palette fixture restores colors without replacing Environment', () {
      final original = <Color>[
        AppColors.primary500,
        AppColors.secondary500,
        AppColors.sub500,
        AppColors.point500,
        AppColors.point900,
      ];
      final environment = Environment.currentEnvironment;
      final cdnUrl = Environment.cdnUrl;
      final palette = PicnicUiTestPalette.fromProductionConfig('ttja_app');
      final fixture = PicnicUiColorFixture.install(palette);
      addTearDown(fixture.restore);

      expect(AppColors.primary500, palette.primary);
      expect(Environment.currentEnvironment, environment);
      expect(Environment.cdnUrl, cdnUrl);

      fixture.restore();

      expect(<Color>[
        AppColors.primary500,
        AppColors.secondary500,
        AppColors.sub500,
        AppColors.point500,
        AppColors.point900,
      ], original);
      expect(Environment.currentEnvironment, environment);
      expect(Environment.cdnUrl, cdnUrl);
    });
  });

  testWidgets(
    'token text keeps raw Pretendard metrics and MediaQuery scaling',
    (tester) async {
      _useViewport(tester, const Size(393, 892));
      const textKey = Key('scaling-text');

      Widget app(TextScaler scaler) => buildPicnicUiTestApp(
        Text(
          'Readable type',
          key: textKey,
          style: PicnicUi.text(size: 14, weight: FontWeight.w600),
        ),
        textScaler: scaler,
      );

      await tester.pumpWidget(app(TextScaler.noScaling));
      await tester.pump();
      final normalHeight = tester.getSize(find.byKey(textKey)).height;
      final style = tester.widget<Text>(find.byKey(textKey)).style!;

      expect(style.fontFamily, 'packages/picnic_lib/Pretendard');
      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.height, 1.45);
      expect(style.letterSpacing, 0);

      await tester.pumpWidget(app(const TextScaler.linear(2)));
      await tester.pump();
      final largeHeight = tester.getSize(find.byKey(textKey)).height;

      expect(largeHeight, greaterThan(normalHeight * 1.8));
      expect(tester.widget<Text>(find.byKey(textKey)).style!.fontSize, 14);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('action button exposes one action and blocks taps while busy', (
    tester,
  ) async {
    _useViewport(tester, const Size(393, 892));
    const buttonKey = Key('guarded-action');
    final semantics = tester.ensureSemantics();
    try {
      var calls = 0;
      var loading = false;
      StateSetter? updateHost;

      await tester.pumpWidget(
        buildPicnicUiTestApp(
          Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return PicnicActionButton(
                  key: buttonKey,
                  label: '변경 사항 저장',
                  busySemanticLabel: '변경 사항 저장 중',
                  isLoading: loading,
                  onPressed: () {
                    calls += 1;
                    updateHost!(() => loading = true);
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final enabled = tester
          .getSemantics(find.bySemanticsLabel('변경 사항 저장'))
          .getSemanticsData();
      final normalSize = tester.getSize(find.byKey(buttonKey));
      expect(enabled.flagsCollection.isButton, isTrue);
      expect(enabled.hasAction(SemanticsAction.tap), isTrue);
      expect(normalSize.width, greaterThanOrEqualTo(48));
      expect(normalSize.height, greaterThanOrEqualTo(48));

      await tester.tap(find.bySemanticsLabel('변경 사항 저장'));
      await tester.pump();

      expect(calls, 1);
      expect(find.byType(SmallPulseLoadingIndicator), findsOneWidget);
      final busySize = tester.getSize(find.byKey(buttonKey));
      final busy = tester
          .getSemantics(find.bySemanticsLabel('변경 사항 저장 중'))
          .getSemanticsData();
      expect(find.bySemanticsLabel('변경 사항 저장'), findsNothing);
      expect(busy.flagsCollection.isButton, isTrue);
      expect(busy.flagsCollection.isEnabled, Tristate.isFalse);
      expect(busy.flagsCollection.isLiveRegion, isTrue);
      expect(busy.hasAction(SemanticsAction.tap), isFalse);

      await tester.tap(
        find.bySemanticsLabel('변경 사항 저장 중'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(calls, 1);

      updateHost!(() => loading = false);
      await tester.pump();
      final recoveredSize = tester.getSize(find.byKey(buttonKey));

      expect(busySize, normalSize);
      expect(recoveredSize, normalSize);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('wide viewport pulse never participates in button layout', (
    tester,
  ) async {
    _useViewport(tester, const Size(480, 1024));
    const buttonKey = Key('wide-busy-action');

    Widget app({required bool loading}) => buildPicnicUiTestApp(
      Center(
        child: PicnicActionButton(
          key: buttonKey,
          label: '저장',
          onPressed: () {},
          isLoading: loading,
          busySemanticLabel: '저장 중',
        ),
      ),
    );

    await tester.pumpWidget(app(loading: false));
    await tester.pump();
    final normalSize = tester.getSize(find.byKey(buttonKey));

    await tester.pumpWidget(app(loading: true));
    await tester.pump();
    final busySize = tester.getSize(find.byKey(buttonKey));

    await tester.pumpWidget(app(loading: false));
    await tester.pump();
    final recoveredSize = tester.getSize(find.byKey(buttonKey));

    expect(busySize, normalSize);
    expect(recoveredSize, normalSize);
  });

  testWidgets('disabled action keeps its label without exposing a tap', (
    tester,
  ) async {
    _useViewport(tester, const Size(393, 892));
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        buildPicnicUiTestApp(
          const Center(
            child: PicnicActionButton(label: '사용할 수 없는 작업', onPressed: null),
          ),
        ),
      );
      await tester.pump();

      final disabled = tester
          .getSemantics(find.bySemanticsLabel('사용할 수 없는 작업'))
          .getSemanticsData();
      expect(disabled.flagsCollection.isButton, isTrue);
      expect(disabled.hasAction(SemanticsAction.tap), isFalse);
      expect(find.byType(SmallPulseLoadingIndicator), findsNothing);
      final disabledSize = tester.getSize(find.bySemanticsLabel('사용할 수 없는 작업'));
      expect(disabledSize.width, greaterThanOrEqualTo(48));
      expect(disabledSize.height, greaterThanOrEqualTo(48));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        button.style!.backgroundColor!.resolve(const <WidgetState>{
          WidgetState.disabled,
        }),
        PicnicUi.disabledSurface,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('one-character controls keep 48px targets on both axes', (
    tester,
  ) async {
    _useViewport(tester, const Size(393, 892));

    await tester.pumpWidget(
      buildPicnicUiTestApp(
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PicnicActionButton(label: 'A', onPressed: () {}),
              PicnicActionButton(
                label: 'B',
                variant: PicnicActionVariant.secondary,
                onPressed: () {},
              ),
              PicnicFilterChip(
                key: const Key('one-character-chip'),
                label: 'C',
                selected: false,
                onSelected: () {},
              ),
              PicnicSectionHeader(
                title: '제목',
                actionLabel: 'D',
                onAction: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final targets = <Finder>[
      find.widgetWithText(FilledButton, 'A'),
      find.widgetWithText(OutlinedButton, 'B'),
      find.byKey(const Key('one-character-chip')),
      find.widgetWithText(TextButton, 'D'),
    ];
    for (final target in targets) {
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(48), reason: '$target width');
      expect(size.height, greaterThanOrEqualTo(48), reason: '$target height');
    }

    final primary = tester.widget<FilledButton>(targets.first);
    final padding = primary.style!.padding!
        .resolve(const <WidgetState>{})!
        .resolve(TextDirection.ltr);
    expect(padding.top, PicnicUi.vertical(12));
    expect(padding.bottom, PicnicUi.vertical(12));
  });

  testWidgets('chip states are distinct and badge stays noninteractive', (
    tester,
  ) async {
    _useViewport(tester, const Size(393, 892));
    final semantics = tester.ensureSemantics();
    try {
      final palette = PicnicUiTestPalette.fromProductionConfig('picnic_app');
      final fixture = PicnicUiColorFixture.install(palette);
      addTearDown(fixture.restore);
      var selections = 0;

      await tester.pumpWidget(
        buildPicnicUiTestApp(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PicnicFilterChip(
                  key: const Key('selected-chip'),
                  label: '선택된 필터',
                  selected: true,
                  onSelected: () => selections += 1,
                ),
                PicnicFilterChip(
                  key: const Key('unselected-chip'),
                  label: '일반 필터',
                  selected: false,
                  onSelected: () => selections += 1,
                ),
                const PicnicFilterChip(
                  key: Key('disabled-chip'),
                  label: '비활성 필터',
                  selected: false,
                  onSelected: null,
                ),
                const PicnicStatusBadge(
                  label: '처리 완료',
                  backgroundColor: Color(0xFFCDFB5D),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final chip = tester
          .getSemantics(find.bySemanticsLabel('선택된 필터'))
          .getSemanticsData();
      expect(chip.flagsCollection.isButton, isTrue);
      expect(chip.flagsCollection.isSelected, Tristate.isTrue);
      expect(chip.hasAction(SemanticsAction.tap), isTrue);
      expect(
        tester.getSize(find.byKey(const Key('selected-chip'))).height,
        greaterThanOrEqualTo(48),
      );

      final chipText = tester.widget<Text>(find.text('선택된 필터'));
      expect(chipText.style!.color, AppColors.grey900);
      expect(
        _contrastRatio(palette.primary, chipText.style!.color!),
        greaterThanOrEqualTo(4.5),
      );

      final selectedMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byKey(const Key('selected-chip')),
          matching: find.byType(Material),
        ),
      );
      final selectedShape = selectedMaterial.shape! as RoundedRectangleBorder;
      expect(selectedShape.side.color, PicnicUi.actionColor);
      expect(
        _contrastRatio(selectedShape.side.color, PicnicUi.surface),
        greaterThanOrEqualTo(4.8),
      );

      final unselectedMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byKey(const Key('unselected-chip')),
          matching: find.byType(Material),
        ),
      );
      final unselectedShape =
          unselectedMaterial.shape! as RoundedRectangleBorder;
      expect(unselectedShape.side.color, PicnicUi.border);

      final disabled = tester
          .getSemantics(find.bySemanticsLabel('비활성 필터'))
          .getSemanticsData();
      expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
      expect(disabled.hasAction(SemanticsAction.tap), isFalse);

      final badge = tester
          .getSemantics(find.bySemanticsLabel('처리 완료'))
          .getSemanticsData();
      expect(badge.flagsCollection.isButton, isFalse);
      expect(badge.hasAction(SemanticsAction.tap), isFalse);

      await tester.tap(find.bySemanticsLabel('선택된 필터'));
      await tester.pump();
      expect(selections, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('393px feedback and header rows give text the remaining width', (
    tester,
  ) async {
    _useViewport(tester, const Size(393, 892));
    const feedbackKey = Key('feedback-row');
    const headerKey = Key('header-row');
    var feedbackCalls = 0;
    var headerCalls = 0;

    await tester.pumpWidget(
      buildPicnicUiTestApp(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PicnicFeedback(
              key: feedbackKey,
              inline: true,
              message: '상태를 확인하고 필요한 작업을 안전하게 다시 시도해 주세요.',
              actionLabel: '재시도',
              onAction: () => feedbackCalls += 1,
            ),
            PicnicSectionHeader(
              key: headerKey,
              title: '최근 업데이트 및 중요한 긴 공지 모음',
              actionLabel: '보기',
              onAction: () => headerCalls += 1,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(of: find.byKey(feedbackKey), matching: find.byType(Row)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(headerKey), matching: find.byType(Row)),
      findsOneWidget,
    );

    final headerWidth = tester.getSize(find.byKey(headerKey)).width;
    final titleWidth = tester.getSize(find.text('최근 업데이트 및 중요한 긴 공지 모음')).width;
    expect(
      titleWidth,
      greaterThan((headerWidth - PicnicUi.horizontal(12)) / 2),
      reason: 'a short action must not reserve an equal flex share',
    );

    final feedbackAction = find.widgetWithText(OutlinedButton, '재시도');
    final headerAction = find.widgetWithText(TextButton, '보기');
    for (final action in [feedbackAction, headerAction]) {
      final size = tester.getSize(action);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    await tester.tap(feedbackAction);
    await tester.tap(headerAction);
    expect(feedbackCalls, 1);
    expect(headerCalls, 1);
  });

  testWidgets(
    'width-sensitive shared layouts assert a bounded-width contract',
    (tester) async {
      _useViewport(tester, const Size(393, 892));
      const feedbackKey = Key('bounded-feedback-contract');
      const headerKey = Key('bounded-header-contract');

      await tester.pumpWidget(
        buildPicnicUiTestApp(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PicnicFeedback(
                key: feedbackKey,
                inline: true,
                message: '오류',
                actionLabel: '재시도',
                onAction: () {},
              ),
              PicnicSectionHeader(
                key: headerKey,
                title: '제목',
                actionLabel: '보기',
                onAction: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final feedbackLayout = tester.widget<LayoutBuilder>(
        find.descendant(
          of: find.byKey(feedbackKey),
          matching: find.byType(LayoutBuilder),
        ),
      );
      final headerLayout = tester.widget<LayoutBuilder>(
        find.descendant(
          of: find.byKey(headerKey),
          matching: find.byType(LayoutBuilder),
        ),
      );
      const unboundedWidth = BoxConstraints();

      expect(
        () => feedbackLayout.builder(
          tester.element(find.byKey(feedbackKey)),
          unboundedWidth,
        ),
        throwsA(
          predicate<Object>(
            (error) =>
                '$error'.contains('PicnicFeedback requires a bounded width'),
          ),
        ),
      );
      expect(
        () => headerLayout.builder(
          tester.element(find.byKey(headerKey)),
          unboundedWidth,
        ),
        throwsA(
          predicate<Object>(
            (error) => '$error'.contains(
              'PicnicSectionHeader requires a bounded width',
            ),
          ),
        ),
      );
    },
  );

  testWidgets('action roles ignore real portal ColorScheme primaries', (
    tester,
  ) async {
    _useViewport(tester, const Size(393, 892));
    final expectedAction = PicnicUi.actionColor;

    // Initialize ScreenUtil before lazily reading the portal ThemeData globals.
    await tester.pumpWidget(buildPicnicUiTestApp(const SizedBox.shrink()));
    await tester.pump();

    for (final portalTheme in [picThemeLight, voteThemeLight]) {
      await tester.pumpWidget(
        buildPicnicUiTestApp(
          Center(
            child: PicnicActionButton(label: '확인', onPressed: () {}),
          ),
          theme: portalTheme,
        ),
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        button.style!.backgroundColor!.resolve(const <WidgetState>{}),
        expectedAction,
      );
    }
  });

  testWidgets(
    'surface stays opaque and leaves content clipping to its caller',
    (tester) async {
      _useViewport(tester, const Size(393, 892));
      const surfaceKey = Key('unclipped-surface');

      await tester.pumpWidget(
        buildPicnicUiTestApp(
          const PicnicSurface(
            key: surfaceKey,
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(surfaceKey),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color!.a, 1);
      expect(container.clipBehavior, Clip.none);
    },
  );

  testWidgets('components stay within a 320px viewport at 200% text', (
    tester,
  ) async {
    _useViewport(tester, const Size(320, 480));
    const keyedComponents = <Key>[
      Key('long-action'),
      Key('inline-feedback'),
      Key('full-feedback'),
      Key('long-chip'),
      Key('long-badge'),
      Key('long-surface'),
      Key('long-header'),
    ];

    await tester.pumpWidget(
      buildPicnicUiTestApp(
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PicnicActionButton(
                key: keyedComponents[0],
                label: '아주 긴 변경 사항을 안전하게 저장하기',
                icon: const Icon(Icons.save_outlined),
                onPressed: () {},
              ),
              PicnicFeedback(
                key: keyedComponents[1],
                inline: true,
                icon: Icons.info_outline,
                message: '목록을 불러오지 못했습니다. 연결을 확인한 뒤 다시 시도해 주세요.',
                actionLabel: '목록 다시 불러오기',
                onAction: () {},
              ),
              PicnicFeedback(
                key: keyedComponents[2],
                message: '아직 표시할 항목이 없습니다. 잠시 후 새로운 내용을 확인해 주세요.',
                actionLabel: '새로운 내용 확인하기',
                onAction: () {},
              ),
              PicnicFilterChip(
                key: keyedComponents[3],
                label: '진행 중인 장기 프로젝트만 보기',
                selected: true,
                onSelected: () {},
              ),
              const PicnicStatusBadge(
                key: Key('long-badge'),
                label: '검토를 기다리는 중입니다',
                backgroundColor: Color(0xFFCDFB5D),
              ),
              PicnicSurface(
                key: keyedComponents[5],
                padding: const EdgeInsets.all(16),
                child: Text(
                  '표면 안의 긴 설명도 확대된 글자 크기를 그대로 유지합니다.',
                  style: PicnicUi.text(),
                ),
              ),
              PicnicSectionHeader(
                key: keyedComponents[6],
                title: '최근에 업데이트된 매우 긴 섹션 제목',
                actionLabel: '모든 업데이트 자세히 보기',
                onAction: () {},
              ),
            ],
          ),
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    for (final key in keyedComponents) {
      final rect = tester.getRect(find.byKey(key));
      expect(rect.left, greaterThanOrEqualTo(0), reason: '$key left edge');
      expect(rect.right, lessThanOrEqualTo(320), reason: '$key right edge');
    }
    expect(
      tester.getSize(find.byKey(const Key('long-action'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('long-chip'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  test(
    'feedback and section actions require a complete label/callback pair',
    () {
      expect(
        () => PicnicFeedback(message: '오류', actionLabel: '다시 시도'),
        throwsAssertionError,
      );
      expect(
        () => PicnicFeedback(message: '오류', onAction: () {}),
        throwsAssertionError,
      );
      expect(
        () => PicnicSectionHeader(title: '소식', actionLabel: '모두 보기'),
        throwsAssertionError,
      );
      expect(
        () => PicnicSectionHeader(title: '소식', onAction: () {}),
        throwsAssertionError,
      );
    },
  );
}
