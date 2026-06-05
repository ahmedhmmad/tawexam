import 'package:flutter/material.dart';

class RadioGroupInherited<T> extends InheritedWidget {
  const RadioGroupInherited({
    required this.groupValue,
    required this.onChanged,
    required super.child,
    super.key,
  });
  final T? groupValue;
  final ValueChanged<T?> onChanged;

  @override
  bool updateShouldNotify(RadioGroupInherited<T> old) =>
      groupValue != old.groupValue;
}

class RadioGroup<T> extends StatelessWidget {
  const RadioGroup({
    required this.groupValue,
    required this.onChanged,
    required this.child,
    super.key,
  });
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;

  static RadioGroupInherited<T> of<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RadioGroupInherited<T>>()!;

  @override
  Widget build(BuildContext context) => RadioGroupInherited<T>(
        groupValue: groupValue,
        onChanged: onChanged,
        child: child,
      );
}
