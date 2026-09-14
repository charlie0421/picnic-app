import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_action_button.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picnic_lib/presentation/providers/popup_provider.dart';
import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class PopupCarousel extends ConsumerStatefulWidget {
  const PopupCarousel({super.key});

  @override
  ConsumerState<PopupCarousel> createState() => _PopupCarouselState();
}

class _PopupCarouselState extends ConsumerState<PopupCarousel> {
  bool _visible = true;
  int _currentIndex = 0;
  List<Popup> _filteredPopups = [];
  List<String> _lastPopupIds = [];
  bool _resetDone = true;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _isPopupHidden(String popupId) async {
    final prefs = await SharedPreferences.getInstance();
    final hideUntil = prefs.getInt('hide_popup_until_$popupId');
    if (hideUntil == null) return false;
    return DateTime.now().millisecondsSinceEpoch < hideUntil;
  }

  Future<List<Popup>> _filterHiddenPopups(List<Popup> popups) async {
    List<Popup> result = [];
    for (final popup in popups) {
      final hidden = await _isPopupHidden(popup.id.toString());
      if (!hidden) result.add(popup);
    }
    return result;
  }

  Future<void> _hideCurrentPopupFor7Days() async {
    if (_filteredPopups.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final hideUntil = now.add(const Duration(days: 7)).millisecondsSinceEpoch;
    final popupId = _filteredPopups[_currentIndex % _filteredPopups.length].id;
    await prefs.setInt('hide_popup_until_$popupId', hideUntil);
    _close();
  }

  void _close() {
    setState(() {
      if (_filteredPopups.isNotEmpty) {
        _filteredPopups.removeAt(_currentIndex % _filteredPopups.length);
        if (_filteredPopups.isEmpty) {
          _visible = false;
        } else {
          _currentIndex = _currentIndex % _filteredPopups.length;
        }
      } else {
        _visible = false;
      }
    });
  }

  List<String> _popupIds(List<Popup> popups) =>
      popups.map((e) => e.id.toString()).toList();

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final popupAsync = ref.watch(popupProvider);
    final lang = Localizations.localeOf(context).languageCode;

    return popupAsync.when(
      data: (popups) {
        // 개발/테스트용: 최초 한 번만 숨김 초기화
        if (!_resetDone) {
          _resetDone = true;
          resetAllPopupHides(popups);
        }
        // 팝업 id 리스트가 완전히 바뀌었을 때만 복사 및 필터링
        final currentIds = _popupIds(popups);
        if (!listEquals(_lastPopupIds, currentIds)) {
          // 비동기 필터링 적용
          return FutureBuilder<List<Popup>>(
            future: _filterHiddenPopups(popups),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              _filteredPopups = List.from(snapshot.data!);
              _lastPopupIds = List.from(currentIds);
              _currentIndex = 0;
              if (_filteredPopups.isEmpty) return const SizedBox.shrink();
              return _buildPopupContent(lang);
            },
          );
        }
        if (_filteredPopups.isEmpty) return const SizedBox.shrink();
        return _buildPopupContent(lang);
      },
      loading: () => const SizedBox.shrink(),
      error: (e, stack) {
        logger.e('PopupProvider error: $e');
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPopupContent(String lang) {
    final popup = _filteredPopups[_currentIndex % _filteredPopups.length];
    final imageUrl = popup.image?[lang] ?? popup.image?['en'] ?? '';
    return Stack(
      children: [
        // 어두운 배경
        Positioned.fill(
          child: Container(color: Colors.black.withAlpha((0.5 * 255).toInt())),
        ),
        // 다이얼로그 기준 바깥 좌우에 버튼 배치
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _filteredPopups.length > 1
                    ? () {
                        setState(() {
                          _currentIndex =
                              (_currentIndex - 1 + _filteredPopups.length) %
                              _filteredPopups.length;
                        });
                        HapticFeedback.selectionClick();
                      }
                    : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.4 * 255).toInt()),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.15 * 255).toInt()),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    color: _filteredPopups.length > 1
                        ? Colors.white
                        : Colors.grey,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _filteredPopups.length > 1
                    ? () {
                        setState(() {
                          _currentIndex =
                              (_currentIndex + 1) % _filteredPopups.length;
                        });
                        HapticFeedback.selectionClick();
                      }
                    : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.4 * 255).toInt()),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.15 * 255).toInt()),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: _filteredPopups.length > 1
                        ? Colors.white
                        : Colors.grey,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        // 중앙 팝업 카드
        Align(
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth * 0.9 > 400
                  ? 400.0
                  : constraints.maxWidth * 0.9;
              final maxHeight = constraints.maxHeight * 0.9 > 500
                  ? 500.0
                  : constraints.maxHeight * 0.9;
              return Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 48),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: maxHeight, // 팝업 높이 고정 (원하는 값으로 조정)
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          child: imageUrl.isNotEmpty
                              ? PicnicCachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  package: 'picnic_lib',
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                      SizedBox(height: PicnicUi.vertical(16)),
                      // 제목과 본문은 하나의 스크롤 예산을 나눠 쓴다. 제목이
                      // 고정 높이였을 때는 긴 현지화 제목이 본문과 버튼 자리를
                      // 먹어 카드 예산 밖으로 밀어냈다.
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: PicnicUi.horizontal(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  popup.title[lang] ?? popup.title['en'] ?? '',
                                  style: PicnicUi.text(
                                    size: 16,
                                    weight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: PicnicUi.vertical(8)),
                                Text(
                                  popup.content[lang] ??
                                      popup.content['en'] ??
                                      '',
                                  style: PicnicUi.text(size: 14),
                                  textAlign: TextAlign.start,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: PicnicUi.vertical(16)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: PicnicUi.horizontal(16),
                        ),
                        child: _buildActions(context),
                      ),
                      SizedBox(height: PicnicUi.vertical(16)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 닫기 / 7일간 보지 않기.
  ///
  /// 320 폭에서 카드는 좌우 48 마진을 빼고 224 밖에 되지 않아, 1:2 로 나눈 칸은
  /// 실제 배포 중인 태국어 "อย่าดูเป็นเวลา 7 วัน" 을 200% 글자로 담지 못하고
  /// 카드 예산 밖으로 밀려났다. 글자가 커지면 두 버튼을 세로로 쌓아 각자 전체
  /// 폭을 쓰게 하고, 평소 폭·글자에서는 기존 1:2 한 줄 배치를 그대로 둔다.
  Widget _buildActions(BuildContext context) {
    final close = PicnicActionButton(
      label: AppLocalizations.of(context).label_popup_close,
      onPressed: _close,
      variant: PicnicActionVariant.secondary,
    );
    final hide = PicnicActionButton(
      label: AppLocalizations.of(context).label_popup_hide_7days,
      onPressed: _hideCurrentPopupFor7Days,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 200 ||
            MediaQuery.textScalerOf(context).scale(14) > 18.2;
        if (stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hide,
              SizedBox(height: PicnicUi.vertical(8)),
              close,
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: close),
            SizedBox(width: PicnicUi.horizontal(16)),
            Expanded(flex: 2, child: hide),
          ],
        );
      },
    );
  }

  // 개발/테스트용: 모든 팝업별 숨김 초기화 함수
  Future<void> resetAllPopupHides(List<Popup> popups) async {
    final prefs = await SharedPreferences.getInstance();
    for (final popup in popups) {
      final popupId = popup.id.toString();
      await prefs.remove('hide_popup_until_$popupId');
    }
  }
}
