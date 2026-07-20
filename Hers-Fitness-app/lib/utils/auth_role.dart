String? normalizeUserRole(dynamic value) {
  if (value == null) return null;

  if (value is String) {
    final role = value.trim().toLowerCase();
    if (role.isEmpty || role == 'null') return null;
    if (role.contains('trainer')) return 'trainer';
    if (role.contains('member')) return 'member';
    if (role.contains('admin')) return 'admin';
    return role;
  }

  if (value is Iterable) {
    for (final item in value) {
      final role = normalizeUserRole(item);
      if (role == 'trainer') return role;
      if (role == 'member') return role;
      if (role == 'admin') return role;
    }
    return null;
  }

  if (value is Map) {
    for (final key in const [
      'role',
      'userRole',
      'user_role',
      'accountType',
      'account_type',
      'type',
      'name',
      'value',
      'authority',
      'user',
      'data',
      'profile',
    ]) {
      final role = normalizeUserRole(value[key]);
      if (role != null) return role;
    }

    for (final key in const ['roles', 'authorities', 'permissions']) {
      final role = normalizeUserRole(value[key]);
      if (role != null) return role;
    }

    if (value['trainerProfile'] != null || value['trainer_profile'] != null) {
      return 'trainer';
    }
    if (value['memberProfile'] != null || value['member_profile'] != null) {
      return 'member';
    }

    return null;
  }

  return normalizeUserRole(value.toString());
}
