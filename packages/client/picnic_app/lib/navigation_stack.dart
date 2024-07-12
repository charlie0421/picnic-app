import 'package:flutter/material.dart';

class NavigationStack {
  final List<Widget> _list = [];
  // Pushes an element onto the stack
  void push(Widget value) {
    _list.add(value);
  }

  // Pops an element from the stack
  Widget pop() {
    if (_list.isEmpty) {
      throw StateError('No elements');
    }
    return _list.removeLast();
  }

  // Peeks the top element of the stack
  Widget peek() {
    if (_list.isEmpty) {
      throw StateError('No elements');
    }
    return _list.last;
  }

  // Checks if the stack is empty
  bool get isEmpty => _list.isEmpty;
  // Gets the length of the stack
  int get length => _list.length;
  // Clears all elements from the stack
  void clear() {
    _list.clear();
  }

  @override
  String toString() {
    return _list.toString();
  }
}
