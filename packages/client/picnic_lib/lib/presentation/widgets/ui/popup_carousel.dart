import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picnic_lib/presentation/providers/popup_provider.dart';
import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:flutter/services.dart';

class PopupCarousel extends ConsumerStatefulWidget {
  const PopupCarousel({super.key});

  @override
  ConsumerState<PopupCarousel> createState() => _PopupCarouselState();
}

class _PopupCarouselState extends ConsumerState<PopupCarousel> {
  bool _visible = true;
  int _currentIndex = 0;
  bool _loadingPrefs = true;
  List<Popup> _filteredPopups = [];

  @override
  void initState() {
    super.initState();
    _checkHidePopup();
  }

  Future<void> _checkHidePopup() async {
    setState(() {
      _loadingPrefs = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final hideUntil = prefs.getInt('hide_popup_until');
    if (hideUntil != null && now.millisecondsSinceEpoch < hideUntil) {
      setState(() {
        _visible = false;
        _loadingPrefs = false;
      });
    } else {
      setState(() {
        _visible = true;
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _hideFor7Days() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final hideUntil = now.add(const Duration(days: 7)).millisecondsSinceEpoch;
    await prefs.setInt('hide_popup_until', hideUntil);
    setState(() {
      _visible = false;
    });
  }

  void _close() {
    setState(() {
      _visible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final popupAsync = ref.watch(popupProvider);
    final lang = Localizations.localeOf(context).languageCode;
    if (!_visible || _loadingPrefs) return const SizedBox.shrink();
    return popupAsync.when(
      data: (popups) {
        final now = DateTime.now();
        // 시작/종료 시간 필터링은 provider에서 처리한다고 가정
        // 여기서는 7일간 보지 않기(hideUntil)만 체크
        final prefs =
            SharedPreferences.getInstance(); // 이미 _checkHidePopup에서 처리됨
        // _visible이 false면 이미 return 처리됨
        _filteredPopups = popups;
        logger.d(_filteredPopups);
        if (_filteredPopups.isEmpty) return const SizedBox.shrink();
        final popup = _filteredPopups[_currentIndex % _filteredPopups.length];
        final imageUrl = popup.image?[lang] ?? popup.image?['en'] ?? '';
        return Stack(
          children: [
            // 어두운 배경
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
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
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
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
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
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
            // 중앙 팝업 카드 (좌우 마진 추가, 디자인 개선)
            Align(
              alignment: Alignment.center,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth * 0.9 > 400
                      ? 400.0
                      : constraints.maxWidth * 0.9;
                  return Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 48),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: imageUrl.isNotEmpty
                                  ? PicnicCachedNetworkImage(
                                      imageUrl: imageUrl, fit: BoxFit.cover)
                                  : Image.asset(
                                      package: 'picnic_lib',
                                      'assets/images/logo.png',
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            popup.title[lang] ?? popup.title['en'] ?? '',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            popup.content[lang] ?? popup.content['en'] ?? '',
                            style: const TextStyle(fontSize: 15, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: const BorderSide(
                                        color: Color(0xFFDDDDDD)),
                                  ),
                                  onPressed: _close,
                                  child: const Text('닫기',
                                      style: TextStyle(fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(fontSize: 16),
                                  ),
                                  onPressed: _hideFor7Days,
                                  child: const Text('7일간 보지 않기'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
