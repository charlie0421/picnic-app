import 'package:riverpod/riverpod.dart';

class BottomNavigationBarCount extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final bottomNavigationBarIndexStateProvider =
    NotifierProvider<BottomNavigationBarCount, int>(
  BottomNavigationBarCount.new,
);
