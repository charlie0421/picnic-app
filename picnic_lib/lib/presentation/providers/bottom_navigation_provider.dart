import 'package:riverpod/riverpod.dart';

class BottomNavigationBarCount extends StateNotifier<int> {
  BottomNavigationBarCount() : super(0);

  void setIndex(int index) {
    state = index;
  }
}

final bottomNavigationBarIndexStateProvider =
    StateNotifierProvider<BottomNavigationBarCount, int>((ref) {
  return BottomNavigationBarCount();
});
