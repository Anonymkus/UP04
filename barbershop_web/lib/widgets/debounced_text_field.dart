import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebouncedTextField extends StatefulWidget {
  final String value;
  final String label;
  final ValueChanged<String> onChanged;
  final double width;
  final bool digitsOnly;
  final Duration delay;

  const DebouncedTextField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.width = 280,
    this.digitsOnly = false,
    this.delay = const Duration(milliseconds: 400),
  });

  @override
  State<DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<DebouncedTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  Timer? _timer;

  @override
  void didUpdateWidget(DebouncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && !(_timer?.isActive ?? false)) {
      _controller.text = widget.value;
    }
  }

  void _schedule(String text) {
    _timer?.cancel();
    _timer = Timer(widget.delay, () => _emit(text));
  }

  void _emit(String text) {
    _timer?.cancel();
    if (text != widget.value) widget.onChanged(text);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: widget.digitsOnly ? TextInputType.number : null,
        inputFormatters: widget.digitsOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        onChanged: _schedule,
        onSubmitted: _emit,
      ),
    );
  }
}
