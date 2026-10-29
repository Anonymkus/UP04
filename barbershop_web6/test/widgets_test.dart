import 'dart:convert';

import 'package:barbershop_web/models/user.dart';
import 'package:barbershop_web/repositories/auth_api.dart';
import 'package:barbershop_web/screens/auth_screens.dart';
import 'package:barbershop_web/screens/home_screen.dart';
import 'package:barbershop_web/state/auth_notifier.dart';
import 'package:barbershop_web/state/notifiers.dart';
import 'package:barbershop_web/widgets/entity_list_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AuthNotifier> authAs(Role? role) async {
  SharedPreferences.setMockInitialValues({
    if (role != null) ...{
      'auth_access_token': 'token',
      'auth_refresh_token': 'refresh',
      'auth_started_at': DateTime.now().toIso8601String(),
      'auth_user': jsonEncode(
        AppUser(
          id: 1,
          username: 'test',
          fullName: 'Тестов',
          role: role,
        ).toJson(),
      ),
    },
  });
  final prefs = await SharedPreferences.getInstance();
  return AuthNotifier(prefs, AuthApi(Dio()))..restore();
}

Widget app(AuthNotifier auth, Widget child) => ChangeNotifierProvider.value(
  value: auth,
  child: MaterialApp(home: Scaffold(body: child)),
);

Widget status(LoadStatus s, {bool empty = false, VoidCallback? onRetry}) =>
    MaterialApp(
      home: StatusView(
        status: s,
        error: 'Сервер недоступен',
        isEmpty: empty,
        onRetry: onRetry ?? () {},
        child: const Text('Данные'),
      ),
    );

void main() {
  testWidgets('во время загрузки показан индикатор', (tester) async {
    await tester.pumpWidget(status(LoadStatus.loading));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Данные'), findsNothing);
  });

  testWidgets('пустой результат показывает сообщение', (tester) async {
    await tester.pumpWidget(status(LoadStatus.success, empty: true));
    expect(find.textContaining('Ничего не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('ошибка показывает текст и кнопку повтора', (tester) async {
    var retried = 0;
    await tester.pumpWidget(status(LoadStatus.error, onRetry: () => retried++));
    expect(find.text('Сервер недоступен'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(retried, 1);
  });

  testWidgets('форма входа не отправляется с пустыми полями', (tester) async {
    final auth = await authAs(null);
    await tester.pumpWidget(app(auth, const LoginScreen()));
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pump();
    expect(find.text('Обязательное поле'), findsNWidgets(2));
    auth.dispose();
  });

  testWidgets('клиенту не видны разделы администратора', (tester) async {
    final auth = await authAs(Role.client);
    await tester.pumpWidget(app(auth, const HomeScreen()));
    expect(find.text('Мои записи'), findsWidgets);
    expect(find.text('Пользователи'), findsNothing);
    expect(find.text('Статистика'), findsNothing);
    auth.dispose();
  });

  testWidgets('администратор видит разделы управления', (tester) async {
    final auth = await authAs(Role.admin);
    await tester.pumpWidget(app(auth, const HomeScreen()));
    expect(find.text('Пользователи'), findsWidgets);
    expect(find.text('Статистика'), findsWidgets);
    expect(find.text('Мои записи'), findsNothing);
    auth.dispose();
  });
}
