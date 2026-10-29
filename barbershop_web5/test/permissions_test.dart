import 'package:barbershop_web/core/permissions.dart';
import 'package:barbershop_web/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('клиент видит каталог, но не может его менять', () {
    expect(canOpen(Role.client, '/services'), isTrue);
    expect(canOpen(Role.client, '/barbers/3'), isTrue);
    expect(canOpen(Role.client, '/services/new'), isFalse);
    expect(canOpen(Role.client, '/barbers/3/edit'), isFalse);
    expect(canManage(Role.client), isFalse);
  });

  test('«Мои записи» доступны только клиенту', () {
    expect(canOpen(Role.client, '/my-appointments'), isTrue);
    expect(canOpen(Role.manager, '/my-appointments'), isFalse);
    expect(canOpen(Role.admin, '/my-appointments'), isFalse);
  });

  test('клиент не открывает записи, клиентов и филиалы', () {
    expect(canOpen(Role.client, '/appointments'), isFalse);
    expect(canOpen(Role.client, '/clients/1'), isFalse);
    expect(canOpen(Role.client, '/branches'), isFalse);
  });

  test('менеджер ведёт записи и справочники', () {
    expect(canManage(Role.manager), isTrue);
    expect(canOpen(Role.manager, '/appointments/new'), isTrue);
    expect(canOpen(Role.manager, '/clients/2/edit'), isTrue);
    expect(canOpen(Role.manager, '/services/new'), isTrue);
  });

  test('менеджеру недоступны администрирование и физическое удаление', () {
    expect(canOpen(Role.manager, '/admin/users'), isFalse);
    expect(canOpen(Role.manager, '/admin/stats'), isFalse);
    expect(isAdmin(Role.manager), isFalse);
  });

  test('администратор управляет пользователями и видит статистику', () {
    expect(canOpen(Role.admin, '/admin/users'), isTrue);
    expect(canOpen(Role.admin, '/admin/stats'), isTrue);
    expect(isAdmin(Role.admin), isTrue);
    expect(canManage(Role.admin), isTrue);
  });

  test('роль разбирается из ответа сервера, неизвестная — как клиент', () {
    expect(Role.parse('admin'), Role.admin);
    expect(Role.parse('manager'), Role.manager);
    expect(Role.parse('superuser'), Role.client);
  });
}
