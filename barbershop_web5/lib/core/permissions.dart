import '../models/user.dart';

bool canManage(Role? role) => role != null && role.level >= Role.manager.level;

bool isAdmin(Role? role) => role == Role.admin;

bool canOpen(Role role, String path) {
  if (path == '/my-appointments') return role == Role.client;
  if (path.startsWith('/admin')) return isAdmin(role);
  for (final section in ['/appointments', '/clients', '/branches']) {
    if (path.startsWith(section)) return canManage(role);
  }
  for (final section in ['/services', '/barbers']) {
    if (path.startsWith(section)) {
      final editing = path.endsWith('/new') || path.endsWith('/edit');
      return !editing || canManage(role);
    }
  }
  return true;
}
