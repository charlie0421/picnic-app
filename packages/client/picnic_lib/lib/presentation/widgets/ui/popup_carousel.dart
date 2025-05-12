import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picnic_lib/presentation/providers/popup_provider.dart';
import 'package:picnic_lib/data/models/common/popup.dart';

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
        _filteredPopups = popups.where((popup) {
          final start = popup.startAt;
          final stop = popup.stopAt;
          if (start != null && now.isBefore(start)) return false;
          if (stop != null && now.isAfter(stop)) return false;
          return true;
        }).toList();
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
            // 중앙 팝업 카드
            Center(
              child: Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _close,
                          ),
                        ],
                      ),
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                              )
                            : const Icon(Icons.image, size: 80),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        popup.title[lang] ?? popup.title['en'] ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        popup.content[lang] ?? popup.content['en'] ?? '',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: _filteredPopups.length > 1
                                ? () {
                                    setState(() {
                                      _currentIndex = (_currentIndex -
                                              1 +
                                              _filteredPopups.length) %
                                          _filteredPopups.length;
                                    });
                                  }
                                : null,
                          ),
                          TextButton(
                            onPressed: _hideFor7Days,
                            child: const Text('7일간 다시 보지 않기'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: _filteredPopups.length > 1
                                ? () {
                                    setState(() {
                                      _currentIndex = (_currentIndex + 1) %
                                          _filteredPopups.length;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
