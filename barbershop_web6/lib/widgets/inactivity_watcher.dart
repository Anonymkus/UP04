import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warnBefore;
  final VoidCallback onWarn;
  final VoidCallback onActive;
  final VoidCallback onTimeout;
  final Widget child;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.warnBefore,
    required this.onWarn,
    required this.onActive,
    required this.onTimeout,
    required this.child,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warnTimer;
  Timer? _timer;
  bool _warned = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _restart() {
    if (_warned) {
      _warned = false;
      widget.onActive();
    }
    _warnTimer?.cancel();
    _timer?.cancel();
    _warnTimer = Timer(widget.timeout - widget.warnBefore, () {
      _warned = true;
      widget.onWarn();
    });
    _timer = Timer(widget.timeout, widget.onTimeout);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _warnTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}
