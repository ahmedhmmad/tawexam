import 'package:flutter/material.dart';

class TawRadioGroupInherited<T> extends InheritedWidget {
  const TawRadioGroupInherited({
    required this.groupValue,
    required this.onChanged,
    required super.child,
    super.key,
  });
  final T? groupValue;
  final ValueChanged<T?> onChanged;

  @override
  bool updateShouldNotify(TawRadioGroupInherited<T> old) =>
      groupValue != old.groupValue;
}

class TawRadioGroup<T> extends StatelessWidget {
  const TawRadioGroup({
    required this.groupValue,
    required this.onChanged,
    required this.child,
    super.key,
  });
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;

  static TawRadioGroupInherited<T> of<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TawRadioGroupInherited<T>>()!;

  @override
  Widget build(BuildContext context) => TawRadioGroupInherited<T>(
        groupValue: groupValue,
        onChanged: onChanged,
        child: child,
      );
}
