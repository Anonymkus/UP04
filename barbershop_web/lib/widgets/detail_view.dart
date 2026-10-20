import 'package:flutter/material.dart';

class DetailView<T> extends StatelessWidget {
  final Future<T?> future;
  final String notFoundText;
  final List<Widget> Function(T value) builder;

  const DetailView({
    super.key,
    required this.future,
    required this.notFoundText,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Ошибка загрузки: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
        final value = snapshot.data;
        if (value == null) return Center(child: Text(notFoundText));
        return ListView(children: builder(value));
      },
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final Widget child;

  const DetailRow(this.label, this.child, {super.key});

  DetailRow.text(this.label, String value, {super.key}) : child = Text(value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
