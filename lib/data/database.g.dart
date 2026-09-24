// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocalAccountsTable extends LocalAccounts
    with TableInfo<$LocalAccountsTable, LocalAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _authProviderMeta = const VerificationMeta(
    'authProvider',
  );
  @override
  late final GeneratedColumn<String> authProvider = GeneratedColumn<String>(
    'auth_provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authUserIdMeta = const VerificationMeta(
    'authUserId',
  );
  @override
  late final GeneratedColumn<String> authUserId = GeneratedColumn<String>(
    'auth_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastLoginAtMeta = const VerificationMeta(
    'lastLoginAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastLoginAt = GeneratedColumn<DateTime>(
    'last_login_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    authProvider,
    authUserId,
    email,
    displayName,
    avatarUrl,
    isActive,
    createdAt,
    updatedAt,
    lastLoginAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('auth_provider')) {
      context.handle(
        _authProviderMeta,
        authProvider.isAcceptableOrUnknown(
          data['auth_provider']!,
          _authProviderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authProviderMeta);
    }
    if (data.containsKey('auth_user_id')) {
      context.handle(
        _authUserIdMeta,
        authUserId.isAcceptableOrUnknown(
          data['auth_user_id']!,
          _authUserIdMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
        _lastLoginAtMeta,
        lastLoginAt.isAcceptableOrUnknown(
          data['last_login_at']!,
          _lastLoginAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {authProvider, authUserId},
  ];
  @override
  LocalAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      authProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_provider'],
      )!,
      authUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_user_id'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastLoginAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_login_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $LocalAccountsTable createAlias(String alias) {
    return $LocalAccountsTable(attachedDatabase, alias);
  }
}

class LocalAccount extends DataClass implements Insertable<LocalAccount> {
  final int id;
  final String? serverId;
  final String authProvider;
  final String? authUserId;
  final String? email;
  final String displayName;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final DateTime? deletedAt;
  const LocalAccount({
    required this.id,
    this.serverId,
    required this.authProvider,
    this.authUserId,
    this.email,
    required this.displayName,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['auth_provider'] = Variable<String>(authProvider);
    if (!nullToAbsent || authUserId != null) {
      map['auth_user_id'] = Variable<String>(authUserId);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastLoginAt != null) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  LocalAccountsCompanion toCompanion(bool nullToAbsent) {
    return LocalAccountsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      authProvider: Value(authProvider),
      authUserId: authUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(authUserId),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      displayName: Value(displayName),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastLoginAt: lastLoginAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLoginAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory LocalAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAccount(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      authProvider: serializer.fromJson<String>(json['authProvider']),
      authUserId: serializer.fromJson<String?>(json['authUserId']),
      email: serializer.fromJson<String?>(json['email']),
      displayName: serializer.fromJson<String>(json['displayName']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastLoginAt: serializer.fromJson<DateTime?>(json['lastLoginAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'authProvider': serializer.toJson<String>(authProvider),
      'authUserId': serializer.toJson<String?>(authUserId),
      'email': serializer.toJson<String?>(email),
      'displayName': serializer.toJson<String>(displayName),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastLoginAt': serializer.toJson<DateTime?>(lastLoginAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  LocalAccount copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? authProvider,
    Value<String?> authUserId = const Value.absent(),
    Value<String?> email = const Value.absent(),
    String? displayName,
    Value<String?> avatarUrl = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastLoginAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => LocalAccount(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    authProvider: authProvider ?? this.authProvider,
    authUserId: authUserId.present ? authUserId.value : this.authUserId,
    email: email.present ? email.value : this.email,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastLoginAt: lastLoginAt.present ? lastLoginAt.value : this.lastLoginAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  LocalAccount copyWithCompanion(LocalAccountsCompanion data) {
    return LocalAccount(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      authProvider: data.authProvider.present
          ? data.authProvider.value
          : this.authProvider,
      authUserId: data.authUserId.present
          ? data.authUserId.value
          : this.authUserId,
      email: data.email.present ? data.email.value : this.email,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastLoginAt: data.lastLoginAt.present
          ? data.lastLoginAt.value
          : this.lastLoginAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccount(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('authProvider: $authProvider, ')
          ..write('authUserId: $authUserId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    authProvider,
    authUserId,
    email,
    displayName,
    avatarUrl,
    isActive,
    createdAt,
    updatedAt,
    lastLoginAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAccount &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.authProvider == this.authProvider &&
          other.authUserId == this.authUserId &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.avatarUrl == this.avatarUrl &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastLoginAt == this.lastLoginAt &&
          other.deletedAt == this.deletedAt);
}

class LocalAccountsCompanion extends UpdateCompanion<LocalAccount> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> authProvider;
  final Value<String?> authUserId;
  final Value<String?> email;
  final Value<String> displayName;
  final Value<String?> avatarUrl;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastLoginAt;
  final Value<DateTime?> deletedAt;
  const LocalAccountsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.authProvider = const Value.absent(),
    this.authUserId = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  LocalAccountsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String authProvider,
    this.authUserId = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : authProvider = Value(authProvider),
       createdAt = Value(createdAt);
  static Insertable<LocalAccount> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? authProvider,
    Expression<String>? authUserId,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? avatarUrl,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastLoginAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (authProvider != null) 'auth_provider': authProvider,
      if (authUserId != null) 'auth_user_id': authUserId,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  LocalAccountsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? authProvider,
    Value<String?>? authUserId,
    Value<String?>? email,
    Value<String>? displayName,
    Value<String?>? avatarUrl,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastLoginAt,
    Value<DateTime?>? deletedAt,
  }) {
    return LocalAccountsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      authProvider: authProvider ?? this.authProvider,
      authUserId: authUserId ?? this.authUserId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (authProvider.present) {
      map['auth_provider'] = Variable<String>(authProvider.value);
    }
    if (authUserId.present) {
      map['auth_user_id'] = Variable<String>(authUserId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccountsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('authProvider: $authProvider, ')
          ..write('authUserId: $authUserId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta(
    'remoteUpdatedAt',
  );
  @override
  late final GeneratedColumn<String> remoteUpdatedAt = GeneratedColumn<String>(
    'remote_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localAccountIdMeta = const VerificationMeta(
    'localAccountId',
  );
  @override
  late final GeneratedColumn<int> localAccountId = GeneratedColumn<int>(
    'local_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_accounts (id)',
    ),
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPlannerEntryMeta = const VerificationMeta(
    'isPlannerEntry',
  );
  @override
  late final GeneratedColumn<bool> isPlannerEntry = GeneratedColumn<bool>(
    'is_planner_entry',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_planner_entry" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueTimeMeta = const VerificationMeta(
    'dueTime',
  );
  @override
  late final GeneratedColumn<String> dueTime = GeneratedColumn<String>(
    'due_time_hhmm',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    remoteUpdatedAt,
    localAccountId,
    title,
    description,
    category,
    isPlannerEntry,
    dueDate,
    dueTime,
    isCompleted,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
        _remoteUpdatedAtMeta,
        remoteUpdatedAt.isAcceptableOrUnknown(
          data['remote_updated_at']!,
          _remoteUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('local_account_id')) {
      context.handle(
        _localAccountIdMeta,
        localAccountId.isAcceptableOrUnknown(
          data['local_account_id']!,
          _localAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('is_planner_entry')) {
      context.handle(
        _isPlannerEntryMeta,
        isPlannerEntry.isAcceptableOrUnknown(
          data['is_planner_entry']!,
          _isPlannerEntryMeta,
        ),
      );
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['local_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('due_time_hhmm')) {
      context.handle(
        _dueTimeMeta,
        dueTime.isAcceptableOrUnknown(data['due_time_hhmm']!, _dueTimeMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_updated_at'],
      ),
      localAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_account_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      isPlannerEntry: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_planner_entry'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_date'],
      )!,
      dueTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_time_hhmm'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final String? serverId;

  /// Exact Supabase version for CAS; local Drift DateTime values are second precision.
  final String? remoteUpdatedAt;
  final int localAccountId;
  final String title;
  final String? description;
  final String category;

  /// Separates planner entries from independent task items.
  final bool isPlannerEntry;
  final DateTime dueDate;
  final String? dueTime;
  final bool isCompleted;

  /// Completion timestamp for the task-rhythm heatmap.
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Task({
    required this.id,
    this.serverId,
    this.remoteUpdatedAt,
    required this.localAccountId,
    required this.title,
    this.description,
    required this.category,
    required this.isPlannerEntry,
    required this.dueDate,
    this.dueTime,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt);
    }
    map['local_account_id'] = Variable<int>(localAccountId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['category'] = Variable<String>(category);
    map['is_planner_entry'] = Variable<bool>(isPlannerEntry);
    map['local_date'] = Variable<DateTime>(dueDate);
    if (!nullToAbsent || dueTime != null) {
      map['due_time_hhmm'] = Variable<String>(dueTime);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
      localAccountId: Value(localAccountId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: Value(category),
      isPlannerEntry: Value(isPlannerEntry),
      dueDate: Value(dueDate),
      dueTime: dueTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dueTime),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      remoteUpdatedAt: serializer.fromJson<String?>(json['remoteUpdatedAt']),
      localAccountId: serializer.fromJson<int>(json['localAccountId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      isPlannerEntry: serializer.fromJson<bool>(json['isPlannerEntry']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      dueTime: serializer.fromJson<String?>(json['dueTime']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'remoteUpdatedAt': serializer.toJson<String?>(remoteUpdatedAt),
      'localAccountId': serializer.toJson<int>(localAccountId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String>(category),
      'isPlannerEntry': serializer.toJson<bool>(isPlannerEntry),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'dueTime': serializer.toJson<String?>(dueTime),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Task copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    Value<String?> remoteUpdatedAt = const Value.absent(),
    int? localAccountId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? category,
    bool? isPlannerEntry,
    DateTime? dueDate,
    Value<String?> dueTime = const Value.absent(),
    bool? isCompleted,
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    remoteUpdatedAt: remoteUpdatedAt.present
        ? remoteUpdatedAt.value
        : this.remoteUpdatedAt,
    localAccountId: localAccountId ?? this.localAccountId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    category: category ?? this.category,
    isPlannerEntry: isPlannerEntry ?? this.isPlannerEntry,
    dueDate: dueDate ?? this.dueDate,
    dueTime: dueTime.present ? dueTime.value : this.dueTime,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
      localAccountId: data.localAccountId.present
          ? data.localAccountId.value
          : this.localAccountId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      isPlannerEntry: data.isPlannerEntry.present
          ? data.isPlannerEntry.value
          : this.isPlannerEntry,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueTime: data.dueTime.present ? data.dueTime.value : this.dueTime,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('isPlannerEntry: $isPlannerEntry, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    remoteUpdatedAt,
    localAccountId,
    title,
    description,
    category,
    isPlannerEntry,
    dueDate,
    dueTime,
    isCompleted,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.localAccountId == this.localAccountId &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.isPlannerEntry == this.isPlannerEntry &&
          other.dueDate == this.dueDate &&
          other.dueTime == this.dueTime &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String?> remoteUpdatedAt;
  final Value<int> localAccountId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> category;
  final Value<bool> isPlannerEntry;
  final Value<DateTime> dueDate;
  final Value<String?> dueTime;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.localAccountId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.isPlannerEntry = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.localAccountId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required String category,
    this.isPlannerEntry = const Value.absent(),
    required DateTime dueDate,
    this.dueTime = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title),
       category = Value(category),
       dueDate = Value(dueDate),
       createdAt = Value(createdAt);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? remoteUpdatedAt,
    Expression<int>? localAccountId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<bool>? isPlannerEntry,
    Expression<DateTime>? dueDate,
    Expression<String>? dueTime,
    Expression<bool>? isCompleted,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (localAccountId != null) 'local_account_id': localAccountId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (isPlannerEntry != null) 'is_planner_entry': isPlannerEntry,
      if (dueDate != null) 'local_date': dueDate,
      if (dueTime != null) 'due_time_hhmm': dueTime,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String?>? remoteUpdatedAt,
    Value<int>? localAccountId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? category,
    Value<bool>? isPlannerEntry,
    Value<DateTime>? dueDate,
    Value<String?>? dueTime,
    Value<bool>? isCompleted,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      localAccountId: localAccountId ?? this.localAccountId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isPlannerEntry: isPlannerEntry ?? this.isPlannerEntry,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt.value);
    }
    if (localAccountId.present) {
      map['local_account_id'] = Variable<int>(localAccountId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isPlannerEntry.present) {
      map['is_planner_entry'] = Variable<bool>(isPlannerEntry.value);
    }
    if (dueDate.present) {
      map['local_date'] = Variable<DateTime>(dueDate.value);
    }
    if (dueTime.present) {
      map['due_time_hhmm'] = Variable<String>(dueTime.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('isPlannerEntry: $isPlannerEntry, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $MoneyTransactionsTable extends MoneyTransactions
    with TableInfo<$MoneyTransactionsTable, MoneyTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoneyTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _localAccountIdMeta = const VerificationMeta(
    'localAccountId',
  );
  @override
  late final GeneratedColumn<int> localAccountId = GeneratedColumn<int>(
    'local_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_accounts (id)',
    ),
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _counterpartyMeta = const VerificationMeta(
    'counterparty',
  );
  @override
  late final GeneratedColumn<String> counterparty = GeneratedColumn<String>(
    'counterparty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'occurred_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _detectionCandidateIdMeta =
      const VerificationMeta('detectionCandidateId');
  @override
  late final GeneratedColumn<String> detectionCandidateId =
      GeneratedColumn<String>(
        'detection_candidate_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    localAccountId,
    type,
    amount,
    currency,
    category,
    note,
    counterparty,
    date,
    source,
    detectionCandidateId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'money_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoneyTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('local_account_id')) {
      context.handle(
        _localAccountIdMeta,
        localAccountId.isAcceptableOrUnknown(
          data['local_account_id']!,
          _localAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount_minor']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('counterparty')) {
      context.handle(
        _counterpartyMeta,
        counterparty.isAcceptableOrUnknown(
          data['counterparty']!,
          _counterpartyMeta,
        ),
      );
    }
    if (data.containsKey('occurred_on')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['occurred_on']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('detection_candidate_id')) {
      context.handle(
        _detectionCandidateIdMeta,
        detectionCandidateId.isAcceptableOrUnknown(
          data['detection_candidate_id']!,
          _detectionCandidateIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoneyTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoneyTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      localAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_account_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      counterparty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_on'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      detectionCandidateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detection_candidate_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $MoneyTransactionsTable createAlias(String alias) {
    return $MoneyTransactionsTable(attachedDatabase, alias);
  }
}

class MoneyTransaction extends DataClass
    implements Insertable<MoneyTransaction> {
  final int id;
  final String? serverId;
  final int localAccountId;

  /// "expense" | "income" | "lent" | "borrowed".
  final String type;

  /// Amount in minor currency units (paise for INR). Never floating-point.
  final int amount;
  final String currency;
  final String category;
  final String? note;
  final String? counterparty;
  final DateTime date;
  final String source;

  /// Local detection provenance only; detection data remains local-only and
  /// this field is never uploaded as a cloud relationship.
  final String? detectionCandidateId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MoneyTransaction({
    required this.id,
    this.serverId,
    required this.localAccountId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.category,
    this.note,
    this.counterparty,
    required this.date,
    required this.source,
    this.detectionCandidateId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['local_account_id'] = Variable<int>(localAccountId);
    map['type'] = Variable<String>(type);
    map['amount_minor'] = Variable<int>(amount);
    map['currency'] = Variable<String>(currency);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || counterparty != null) {
      map['counterparty'] = Variable<String>(counterparty);
    }
    map['occurred_on'] = Variable<DateTime>(date);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || detectionCandidateId != null) {
      map['detection_candidate_id'] = Variable<String>(detectionCandidateId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MoneyTransactionsCompanion toCompanion(bool nullToAbsent) {
    return MoneyTransactionsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      localAccountId: Value(localAccountId),
      type: Value(type),
      amount: Value(amount),
      currency: Value(currency),
      category: Value(category),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      counterparty: counterparty == null && nullToAbsent
          ? const Value.absent()
          : Value(counterparty),
      date: Value(date),
      source: Value(source),
      detectionCandidateId: detectionCandidateId == null && nullToAbsent
          ? const Value.absent()
          : Value(detectionCandidateId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MoneyTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoneyTransaction(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      localAccountId: serializer.fromJson<int>(json['localAccountId']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<int>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      category: serializer.fromJson<String>(json['category']),
      note: serializer.fromJson<String?>(json['note']),
      counterparty: serializer.fromJson<String?>(json['counterparty']),
      date: serializer.fromJson<DateTime>(json['date']),
      source: serializer.fromJson<String>(json['source']),
      detectionCandidateId: serializer.fromJson<String?>(
        json['detectionCandidateId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'localAccountId': serializer.toJson<int>(localAccountId),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<int>(amount),
      'currency': serializer.toJson<String>(currency),
      'category': serializer.toJson<String>(category),
      'note': serializer.toJson<String?>(note),
      'counterparty': serializer.toJson<String?>(counterparty),
      'date': serializer.toJson<DateTime>(date),
      'source': serializer.toJson<String>(source),
      'detectionCandidateId': serializer.toJson<String?>(detectionCandidateId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MoneyTransaction copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    int? localAccountId,
    String? type,
    int? amount,
    String? currency,
    String? category,
    Value<String?> note = const Value.absent(),
    Value<String?> counterparty = const Value.absent(),
    DateTime? date,
    String? source,
    Value<String?> detectionCandidateId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => MoneyTransaction(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    localAccountId: localAccountId ?? this.localAccountId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    category: category ?? this.category,
    note: note.present ? note.value : this.note,
    counterparty: counterparty.present ? counterparty.value : this.counterparty,
    date: date ?? this.date,
    source: source ?? this.source,
    detectionCandidateId: detectionCandidateId.present
        ? detectionCandidateId.value
        : this.detectionCandidateId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  MoneyTransaction copyWithCompanion(MoneyTransactionsCompanion data) {
    return MoneyTransaction(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      localAccountId: data.localAccountId.present
          ? data.localAccountId.value
          : this.localAccountId,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      category: data.category.present ? data.category.value : this.category,
      note: data.note.present ? data.note.value : this.note,
      counterparty: data.counterparty.present
          ? data.counterparty.value
          : this.counterparty,
      date: data.date.present ? data.date.value : this.date,
      source: data.source.present ? data.source.value : this.source,
      detectionCandidateId: data.detectionCandidateId.present
          ? data.detectionCandidateId.value
          : this.detectionCandidateId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoneyTransaction(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('counterparty: $counterparty, ')
          ..write('date: $date, ')
          ..write('source: $source, ')
          ..write('detectionCandidateId: $detectionCandidateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    localAccountId,
    type,
    amount,
    currency,
    category,
    note,
    counterparty,
    date,
    source,
    detectionCandidateId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoneyTransaction &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.localAccountId == this.localAccountId &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.category == this.category &&
          other.note == this.note &&
          other.counterparty == this.counterparty &&
          other.date == this.date &&
          other.source == this.source &&
          other.detectionCandidateId == this.detectionCandidateId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MoneyTransactionsCompanion extends UpdateCompanion<MoneyTransaction> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<int> localAccountId;
  final Value<String> type;
  final Value<int> amount;
  final Value<String> currency;
  final Value<String> category;
  final Value<String?> note;
  final Value<String?> counterparty;
  final Value<DateTime> date;
  final Value<String> source;
  final Value<String?> detectionCandidateId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const MoneyTransactionsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.localAccountId = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.date = const Value.absent(),
    this.source = const Value.absent(),
    this.detectionCandidateId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  MoneyTransactionsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.localAccountId = const Value.absent(),
    required String type,
    required int amount,
    this.currency = const Value.absent(),
    required String category,
    this.note = const Value.absent(),
    this.counterparty = const Value.absent(),
    required DateTime date,
    this.source = const Value.absent(),
    this.detectionCandidateId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : type = Value(type),
       amount = Value(amount),
       category = Value(category),
       date = Value(date);
  static Insertable<MoneyTransaction> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<int>? localAccountId,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<String>? currency,
    Expression<String>? category,
    Expression<String>? note,
    Expression<String>? counterparty,
    Expression<DateTime>? date,
    Expression<String>? source,
    Expression<String>? detectionCandidateId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (localAccountId != null) 'local_account_id': localAccountId,
      if (type != null) 'type': type,
      if (amount != null) 'amount_minor': amount,
      if (currency != null) 'currency': currency,
      if (category != null) 'category': category,
      if (note != null) 'note': note,
      if (counterparty != null) 'counterparty': counterparty,
      if (date != null) 'occurred_on': date,
      if (source != null) 'source': source,
      if (detectionCandidateId != null)
        'detection_candidate_id': detectionCandidateId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  MoneyTransactionsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<int>? localAccountId,
    Value<String>? type,
    Value<int>? amount,
    Value<String>? currency,
    Value<String>? category,
    Value<String?>? note,
    Value<String?>? counterparty,
    Value<DateTime>? date,
    Value<String>? source,
    Value<String?>? detectionCandidateId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return MoneyTransactionsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      localAccountId: localAccountId ?? this.localAccountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      note: note ?? this.note,
      counterparty: counterparty ?? this.counterparty,
      date: date ?? this.date,
      source: source ?? this.source,
      detectionCandidateId: detectionCandidateId ?? this.detectionCandidateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (localAccountId.present) {
      map['local_account_id'] = Variable<int>(localAccountId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount_minor'] = Variable<int>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (date.present) {
      map['occurred_on'] = Variable<DateTime>(date.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (detectionCandidateId.present) {
      map['detection_candidate_id'] = Variable<String>(
        detectionCandidateId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoneyTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('counterparty: $counterparty, ')
          ..write('date: $date, ')
          ..write('source: $source, ')
          ..write('detectionCandidateId: $detectionCandidateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _localAccountIdMeta = const VerificationMeta(
    'localAccountId',
  );
  @override
  late final GeneratedColumn<int> localAccountId = GeneratedColumn<int>(
    'local_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_accounts (id)',
    ),
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    localAccountId,
    title,
    content,
    category,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('local_account_id')) {
      context.handle(
        _localAccountIdMeta,
        localAccountId.isAcceptableOrUnknown(
          data['local_account_id']!,
          _localAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      localAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_account_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final String? serverId;
  final int localAccountId;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Note({
    required this.id,
    this.serverId,
    required this.localAccountId,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['local_account_id'] = Variable<int>(localAccountId);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      localAccountId: Value(localAccountId),
      title: Value(title),
      content: Value(content),
      category: Value(category),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      localAccountId: serializer.fromJson<int>(json['localAccountId']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'localAccountId': serializer.toJson<int>(localAccountId),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Note copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    int? localAccountId,
    String? title,
    String? content,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Note(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    localAccountId: localAccountId ?? this.localAccountId,
    title: title ?? this.title,
    content: content ?? this.content,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      localAccountId: data.localAccountId.present
          ? data.localAccountId.value
          : this.localAccountId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    localAccountId,
    title,
    content,
    category,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.localAccountId == this.localAccountId &&
          other.title == this.title &&
          other.content == this.content &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<int> localAccountId;
  final Value<String> title;
  final Value<String> content;
  final Value<String> category;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.localAccountId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.localAccountId = const Value.absent(),
    required String title,
    required String content,
    required String category,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
  }) : title = Value(title),
       content = Value(content),
       category = Value(category),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<int>? localAccountId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (localAccountId != null) 'local_account_id': localAccountId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<int>? localAccountId,
    Value<String>? title,
    Value<String>? content,
    Value<String>? category,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      localAccountId: localAccountId ?? this.localAccountId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (localAccountId.present) {
      map['local_account_id'] = Variable<int>(localAccountId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _localAccountIdMeta = const VerificationMeta(
    'localAccountId',
  );
  @override
  late final GeneratedColumn<int> localAccountId = GeneratedColumn<int>(
    'local_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_accounts (id)',
    ),
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    localAccountId,
    taskId,
    notificationId,
    title,
    dueAt,
    isEnabled,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('local_account_id')) {
      context.handle(
        _localAccountIdMeta,
        localAccountId.isAcceptableOrUnknown(
          data['local_account_id']!,
          _localAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      localAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_account_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      ),
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final String? serverId;
  final int localAccountId;
  final int? taskId;
  final int notificationId;
  final String title;
  final DateTime dueAt;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Reminder({
    required this.id,
    this.serverId,
    required this.localAccountId,
    this.taskId,
    required this.notificationId,
    required this.title,
    required this.dueAt,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['local_account_id'] = Variable<int>(localAccountId);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<int>(taskId);
    }
    map['notification_id'] = Variable<int>(notificationId);
    map['title'] = Variable<String>(title);
    map['due_at'] = Variable<DateTime>(dueAt);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      localAccountId: Value(localAccountId),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      notificationId: Value(notificationId),
      title: Value(title),
      dueAt: Value(dueAt),
      isEnabled: Value(isEnabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      localAccountId: serializer.fromJson<int>(json['localAccountId']),
      taskId: serializer.fromJson<int?>(json['taskId']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
      title: serializer.fromJson<String>(json['title']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'localAccountId': serializer.toJson<int>(localAccountId),
      'taskId': serializer.toJson<int?>(taskId),
      'notificationId': serializer.toJson<int>(notificationId),
      'title': serializer.toJson<String>(title),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Reminder copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    int? localAccountId,
    Value<int?> taskId = const Value.absent(),
    int? notificationId,
    String? title,
    DateTime? dueAt,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Reminder(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    localAccountId: localAccountId ?? this.localAccountId,
    taskId: taskId.present ? taskId.value : this.taskId,
    notificationId: notificationId ?? this.notificationId,
    title: title ?? this.title,
    dueAt: dueAt ?? this.dueAt,
    isEnabled: isEnabled ?? this.isEnabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      localAccountId: data.localAccountId.present
          ? data.localAccountId.value
          : this.localAccountId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      title: data.title.present ? data.title.value : this.title,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('taskId: $taskId, ')
          ..write('notificationId: $notificationId, ')
          ..write('title: $title, ')
          ..write('dueAt: $dueAt, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    localAccountId,
    taskId,
    notificationId,
    title,
    dueAt,
    isEnabled,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.localAccountId == this.localAccountId &&
          other.taskId == this.taskId &&
          other.notificationId == this.notificationId &&
          other.title == this.title &&
          other.dueAt == this.dueAt &&
          other.isEnabled == this.isEnabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<int> localAccountId;
  final Value<int?> taskId;
  final Value<int> notificationId;
  final Value<String> title;
  final Value<DateTime> dueAt;
  final Value<bool> isEnabled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.localAccountId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.title = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.localAccountId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.notificationId = const Value.absent(),
    required String title,
    required DateTime dueAt,
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title),
       dueAt = Value(dueAt);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<int>? localAccountId,
    Expression<int>? taskId,
    Expression<int>? notificationId,
    Expression<String>? title,
    Expression<DateTime>? dueAt,
    Expression<bool>? isEnabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (localAccountId != null) 'local_account_id': localAccountId,
      if (taskId != null) 'task_id': taskId,
      if (notificationId != null) 'notification_id': notificationId,
      if (title != null) 'title': title,
      if (dueAt != null) 'due_at': dueAt,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<int>? localAccountId,
    Value<int?>? taskId,
    Value<int>? notificationId,
    Value<String>? title,
    Value<DateTime>? dueAt,
    Value<bool>? isEnabled,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      localAccountId: localAccountId ?? this.localAccountId,
      taskId: taskId ?? this.taskId,
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      dueAt: dueAt ?? this.dueAt,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (localAccountId.present) {
      map['local_account_id'] = Variable<int>(localAccountId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('taskId: $taskId, ')
          ..write('notificationId: $notificationId, ')
          ..write('title: $title, ')
          ..write('dueAt: $dueAt, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $ProfileDataTable extends ProfileData
    with TableInfo<$ProfileDataTable, ProfileDataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localAccountIdMeta = const VerificationMeta(
    'localAccountId',
  );
  @override
  late final GeneratedColumn<int> localAccountId = GeneratedColumn<int>(
    'local_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_accounts (id)',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _collegeMeta = const VerificationMeta(
    'college',
  );
  @override
  late final GeneratedColumn<String> college = GeneratedColumn<String>(
    'college',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta(
    'semester',
  );
  @override
  late final GeneratedColumn<String> semester = GeneratedColumn<String>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localAccountId,
    serverId,
    role,
    phone,
    college,
    semester,
    points,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileDataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_account_id')) {
      context.handle(
        _localAccountIdMeta,
        localAccountId.isAcceptableOrUnknown(
          data['local_account_id']!,
          _localAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('college')) {
      context.handle(
        _collegeMeta,
        college.isAcceptableOrUnknown(data['college']!, _collegeMeta),
      );
    }
    if (data.containsKey('semester')) {
      context.handle(
        _semesterMeta,
        semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localAccountId};
  @override
  ProfileDataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileDataData(
      localAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_account_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      college: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}college'],
      )!,
      semester: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProfileDataTable createAlias(String alias) {
    return $ProfileDataTable(attachedDatabase, alias);
  }
}

class ProfileDataData extends DataClass implements Insertable<ProfileDataData> {
  final int localAccountId;
  final String? serverId;
  final String role;
  final String phone;
  final String college;
  final String semester;
  final int points;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const ProfileDataData({
    required this.localAccountId,
    this.serverId,
    required this.role,
    required this.phone,
    required this.college,
    required this.semester,
    required this.points,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_account_id'] = Variable<int>(localAccountId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['role'] = Variable<String>(role);
    map['phone'] = Variable<String>(phone);
    map['college'] = Variable<String>(college);
    map['semester'] = Variable<String>(semester);
    map['points'] = Variable<int>(points);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProfileDataCompanion toCompanion(bool nullToAbsent) {
    return ProfileDataCompanion(
      localAccountId: Value(localAccountId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      role: Value(role),
      phone: Value(phone),
      college: Value(college),
      semester: Value(semester),
      points: Value(points),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ProfileDataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileDataData(
      localAccountId: serializer.fromJson<int>(json['localAccountId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      role: serializer.fromJson<String>(json['role']),
      phone: serializer.fromJson<String>(json['phone']),
      college: serializer.fromJson<String>(json['college']),
      semester: serializer.fromJson<String>(json['semester']),
      points: serializer.fromJson<int>(json['points']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localAccountId': serializer.toJson<int>(localAccountId),
      'serverId': serializer.toJson<String?>(serverId),
      'role': serializer.toJson<String>(role),
      'phone': serializer.toJson<String>(phone),
      'college': serializer.toJson<String>(college),
      'semester': serializer.toJson<String>(semester),
      'points': serializer.toJson<int>(points),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ProfileDataData copyWith({
    int? localAccountId,
    Value<String?> serverId = const Value.absent(),
    String? role,
    String? phone,
    String? college,
    String? semester,
    int? points,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ProfileDataData(
    localAccountId: localAccountId ?? this.localAccountId,
    serverId: serverId.present ? serverId.value : this.serverId,
    role: role ?? this.role,
    phone: phone ?? this.phone,
    college: college ?? this.college,
    semester: semester ?? this.semester,
    points: points ?? this.points,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ProfileDataData copyWithCompanion(ProfileDataCompanion data) {
    return ProfileDataData(
      localAccountId: data.localAccountId.present
          ? data.localAccountId.value
          : this.localAccountId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      role: data.role.present ? data.role.value : this.role,
      phone: data.phone.present ? data.phone.value : this.phone,
      college: data.college.present ? data.college.value : this.college,
      semester: data.semester.present ? data.semester.value : this.semester,
      points: data.points.present ? data.points.value : this.points,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileDataData(')
          ..write('localAccountId: $localAccountId, ')
          ..write('serverId: $serverId, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('college: $college, ')
          ..write('semester: $semester, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localAccountId,
    serverId,
    role,
    phone,
    college,
    semester,
    points,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileDataData &&
          other.localAccountId == this.localAccountId &&
          other.serverId == this.serverId &&
          other.role == this.role &&
          other.phone == this.phone &&
          other.college == this.college &&
          other.semester == this.semester &&
          other.points == this.points &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ProfileDataCompanion extends UpdateCompanion<ProfileDataData> {
  final Value<int> localAccountId;
  final Value<String?> serverId;
  final Value<String> role;
  final Value<String> phone;
  final Value<String> college;
  final Value<String> semester;
  final Value<int> points;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const ProfileDataCompanion({
    this.localAccountId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.role = const Value.absent(),
    this.phone = const Value.absent(),
    this.college = const Value.absent(),
    this.semester = const Value.absent(),
    this.points = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  ProfileDataCompanion.insert({
    this.localAccountId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.role = const Value.absent(),
    this.phone = const Value.absent(),
    this.college = const Value.absent(),
    this.semester = const Value.absent(),
    this.points = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProfileDataData> custom({
    Expression<int>? localAccountId,
    Expression<String>? serverId,
    Expression<String>? role,
    Expression<String>? phone,
    Expression<String>? college,
    Expression<String>? semester,
    Expression<int>? points,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (localAccountId != null) 'local_account_id': localAccountId,
      if (serverId != null) 'server_id': serverId,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (college != null) 'college': college,
      if (semester != null) 'semester': semester,
      if (points != null) 'points': points,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  ProfileDataCompanion copyWith({
    Value<int>? localAccountId,
    Value<String?>? serverId,
    Value<String>? role,
    Value<String>? phone,
    Value<String>? college,
    Value<String>? semester,
    Value<int>? points,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return ProfileDataCompanion(
      localAccountId: localAccountId ?? this.localAccountId,
      serverId: serverId ?? this.serverId,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      college: college ?? this.college,
      semester: semester ?? this.semester,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localAccountId.present) {
      map['local_account_id'] = Variable<int>(localAccountId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (college.present) {
      map['college'] = Variable<String>(college.value);
    }
    if (semester.present) {
      map['semester'] = Variable<String>(semester.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileDataCompanion(')
          ..write('localAccountId: $localAccountId, ')
          ..write('serverId: $serverId, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('college: $college, ')
          ..write('semester: $semester, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionDetectionEventsTable extends TransactionDetectionEvents
    with
        TableInfo<$TransactionDetectionEventsTable, TransactionDetectionEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionDetectionEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localAccountIdMeta = const VerificationMeta(
    'localAccountId',
  );
  @override
  late final GeneratedColumn<int> localAccountId = GeneratedColumn<int>(
    'local_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_accounts (id)',
    ),
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _eventKeyMeta = const VerificationMeta(
    'eventKey',
  );
  @override
  late final GeneratedColumn<String> eventKey = GeneratedColumn<String>(
    'event_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _sourcePackageMeta = const VerificationMeta(
    'sourcePackage',
  );
  @override
  late final GeneratedColumn<String> sourcePackage = GeneratedColumn<String>(
    'source_package',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bigTextMeta = const VerificationMeta(
    'bigText',
  );
  @override
  late final GeneratedColumn<String> bigText = GeneratedColumn<String>(
    'big_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<DateTime> processedAt = GeneratedColumn<DateTime>(
    'processed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localAccountId,
    eventKey,
    sourcePackage,
    sourceType,
    title,
    body,
    bigText,
    occurredAt,
    receivedAt,
    processedAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_detection_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionDetectionEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_account_id')) {
      context.handle(
        _localAccountIdMeta,
        localAccountId.isAcceptableOrUnknown(
          data['local_account_id']!,
          _localAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('event_key')) {
      context.handle(
        _eventKeyMeta,
        eventKey.isAcceptableOrUnknown(data['event_key']!, _eventKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_eventKeyMeta);
    }
    if (data.containsKey('source_package')) {
      context.handle(
        _sourcePackageMeta,
        sourcePackage.isAcceptableOrUnknown(
          data['source_package']!,
          _sourcePackageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourcePackageMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('big_text')) {
      context.handle(
        _bigTextMeta,
        bigText.isAcceptableOrUnknown(data['big_text']!, _bigTextMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionDetectionEvent map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionDetectionEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_account_id'],
      )!,
      eventKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_key'],
      )!,
      sourcePackage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_package'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      bigText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}big_text'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}processed_at'],
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $TransactionDetectionEventsTable createAlias(String alias) {
    return $TransactionDetectionEventsTable(attachedDatabase, alias);
  }
}

class TransactionDetectionEvent extends DataClass
    implements Insertable<TransactionDetectionEvent> {
  final int id;
  final int localAccountId;
  final String eventKey;
  final String sourcePackage;
  final String sourceType;
  final String? title;
  final String? body;
  final String? bigText;
  final DateTime occurredAt;
  final DateTime receivedAt;
  final DateTime? processedAt;
  final DateTime expiresAt;
  const TransactionDetectionEvent({
    required this.id,
    required this.localAccountId,
    required this.eventKey,
    required this.sourcePackage,
    required this.sourceType,
    this.title,
    this.body,
    this.bigText,
    required this.occurredAt,
    required this.receivedAt,
    this.processedAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_account_id'] = Variable<int>(localAccountId);
    map['event_key'] = Variable<String>(eventKey);
    map['source_package'] = Variable<String>(sourcePackage);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    if (!nullToAbsent || bigText != null) {
      map['big_text'] = Variable<String>(bigText);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['received_at'] = Variable<DateTime>(receivedAt);
    if (!nullToAbsent || processedAt != null) {
      map['processed_at'] = Variable<DateTime>(processedAt);
    }
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  TransactionDetectionEventsCompanion toCompanion(bool nullToAbsent) {
    return TransactionDetectionEventsCompanion(
      id: Value(id),
      localAccountId: Value(localAccountId),
      eventKey: Value(eventKey),
      sourcePackage: Value(sourcePackage),
      sourceType: Value(sourceType),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      bigText: bigText == null && nullToAbsent
          ? const Value.absent()
          : Value(bigText),
      occurredAt: Value(occurredAt),
      receivedAt: Value(receivedAt),
      processedAt: processedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(processedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory TransactionDetectionEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionDetectionEvent(
      id: serializer.fromJson<int>(json['id']),
      localAccountId: serializer.fromJson<int>(json['localAccountId']),
      eventKey: serializer.fromJson<String>(json['eventKey']),
      sourcePackage: serializer.fromJson<String>(json['sourcePackage']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      title: serializer.fromJson<String?>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      bigText: serializer.fromJson<String?>(json['bigText']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      processedAt: serializer.fromJson<DateTime?>(json['processedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localAccountId': serializer.toJson<int>(localAccountId),
      'eventKey': serializer.toJson<String>(eventKey),
      'sourcePackage': serializer.toJson<String>(sourcePackage),
      'sourceType': serializer.toJson<String>(sourceType),
      'title': serializer.toJson<String?>(title),
      'body': serializer.toJson<String?>(body),
      'bigText': serializer.toJson<String?>(bigText),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'processedAt': serializer.toJson<DateTime?>(processedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  TransactionDetectionEvent copyWith({
    int? id,
    int? localAccountId,
    String? eventKey,
    String? sourcePackage,
    String? sourceType,
    Value<String?> title = const Value.absent(),
    Value<String?> body = const Value.absent(),
    Value<String?> bigText = const Value.absent(),
    DateTime? occurredAt,
    DateTime? receivedAt,
    Value<DateTime?> processedAt = const Value.absent(),
    DateTime? expiresAt,
  }) => TransactionDetectionEvent(
    id: id ?? this.id,
    localAccountId: localAccountId ?? this.localAccountId,
    eventKey: eventKey ?? this.eventKey,
    sourcePackage: sourcePackage ?? this.sourcePackage,
    sourceType: sourceType ?? this.sourceType,
    title: title.present ? title.value : this.title,
    body: body.present ? body.value : this.body,
    bigText: bigText.present ? bigText.value : this.bigText,
    occurredAt: occurredAt ?? this.occurredAt,
    receivedAt: receivedAt ?? this.receivedAt,
    processedAt: processedAt.present ? processedAt.value : this.processedAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  TransactionDetectionEvent copyWithCompanion(
    TransactionDetectionEventsCompanion data,
  ) {
    return TransactionDetectionEvent(
      id: data.id.present ? data.id.value : this.id,
      localAccountId: data.localAccountId.present
          ? data.localAccountId.value
          : this.localAccountId,
      eventKey: data.eventKey.present ? data.eventKey.value : this.eventKey,
      sourcePackage: data.sourcePackage.present
          ? data.sourcePackage.value
          : this.sourcePackage,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      bigText: data.bigText.present ? data.bigText.value : this.bigText,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionDetectionEvent(')
          ..write('id: $id, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('eventKey: $eventKey, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('sourceType: $sourceType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('bigText: $bigText, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('processedAt: $processedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localAccountId,
    eventKey,
    sourcePackage,
    sourceType,
    title,
    body,
    bigText,
    occurredAt,
    receivedAt,
    processedAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionDetectionEvent &&
          other.id == this.id &&
          other.localAccountId == this.localAccountId &&
          other.eventKey == this.eventKey &&
          other.sourcePackage == this.sourcePackage &&
          other.sourceType == this.sourceType &&
          other.title == this.title &&
          other.body == this.body &&
          other.bigText == this.bigText &&
          other.occurredAt == this.occurredAt &&
          other.receivedAt == this.receivedAt &&
          other.processedAt == this.processedAt &&
          other.expiresAt == this.expiresAt);
}

class TransactionDetectionEventsCompanion
    extends UpdateCompanion<TransactionDetectionEvent> {
  final Value<int> id;
  final Value<int> localAccountId;
  final Value<String> eventKey;
  final Value<String> sourcePackage;
  final Value<String> sourceType;
  final Value<String?> title;
  final Value<String?> body;
  final Value<String?> bigText;
  final Value<DateTime> occurredAt;
  final Value<DateTime> receivedAt;
  final Value<DateTime?> processedAt;
  final Value<DateTime> expiresAt;
  const TransactionDetectionEventsCompanion({
    this.id = const Value.absent(),
    this.localAccountId = const Value.absent(),
    this.eventKey = const Value.absent(),
    this.sourcePackage = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.bigText = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  TransactionDetectionEventsCompanion.insert({
    this.id = const Value.absent(),
    this.localAccountId = const Value.absent(),
    required String eventKey,
    required String sourcePackage,
    required String sourceType,
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.bigText = const Value.absent(),
    required DateTime occurredAt,
    required DateTime receivedAt,
    this.processedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  }) : eventKey = Value(eventKey),
       sourcePackage = Value(sourcePackage),
       sourceType = Value(sourceType),
       occurredAt = Value(occurredAt),
       receivedAt = Value(receivedAt);
  static Insertable<TransactionDetectionEvent> custom({
    Expression<int>? id,
    Expression<int>? localAccountId,
    Expression<String>? eventKey,
    Expression<String>? sourcePackage,
    Expression<String>? sourceType,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? bigText,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? processedAt,
    Expression<DateTime>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localAccountId != null) 'local_account_id': localAccountId,
      if (eventKey != null) 'event_key': eventKey,
      if (sourcePackage != null) 'source_package': sourcePackage,
      if (sourceType != null) 'source_type': sourceType,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (bigText != null) 'big_text': bigText,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (receivedAt != null) 'received_at': receivedAt,
      if (processedAt != null) 'processed_at': processedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  TransactionDetectionEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? localAccountId,
    Value<String>? eventKey,
    Value<String>? sourcePackage,
    Value<String>? sourceType,
    Value<String?>? title,
    Value<String?>? body,
    Value<String?>? bigText,
    Value<DateTime>? occurredAt,
    Value<DateTime>? receivedAt,
    Value<DateTime?>? processedAt,
    Value<DateTime>? expiresAt,
  }) {
    return TransactionDetectionEventsCompanion(
      id: id ?? this.id,
      localAccountId: localAccountId ?? this.localAccountId,
      eventKey: eventKey ?? this.eventKey,
      sourcePackage: sourcePackage ?? this.sourcePackage,
      sourceType: sourceType ?? this.sourceType,
      title: title ?? this.title,
      body: body ?? this.body,
      bigText: bigText ?? this.bigText,
      occurredAt: occurredAt ?? this.occurredAt,
      receivedAt: receivedAt ?? this.receivedAt,
      processedAt: processedAt ?? this.processedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localAccountId.present) {
      map['local_account_id'] = Variable<int>(localAccountId.value);
    }
    if (eventKey.present) {
      map['event_key'] = Variable<String>(eventKey.value);
    }
    if (sourcePackage.present) {
      map['source_package'] = Variable<String>(sourcePackage.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (bigText.present) {
      map['big_text'] = Variable<String>(bigText.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<DateTime>(processedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionDetectionEventsCompanion(')
          ..write('id: $id, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('eventKey: $eventKey, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('sourceType: $sourceType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('bigText: $bigText, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('processedAt: $processedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionCandidatesTable extends TransactionCandidates
    with TableInfo<$TransactionCandidatesTable, TransactionCandidate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionCandidatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localAccountIdMeta = const VerificationMeta(
    'localAccountId',
  );
  @override
  late final GeneratedColumn<int> localAccountId = GeneratedColumn<int>(
    'local_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_accounts (id)',
    ),
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _candidateIdMeta = const VerificationMeta(
    'candidateId',
  );
  @override
  late final GeneratedColumn<String> candidateId = GeneratedColumn<String>(
    'candidate_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _merchantNameMeta = const VerificationMeta(
    'merchantName',
  );
  @override
  late final GeneratedColumn<String> merchantName = GeneratedColumn<String>(
    'merchant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Unknown'),
  );
  static const VerificationMeta _merchantIdentityMeta = const VerificationMeta(
    'merchantIdentity',
  );
  @override
  late final GeneratedColumn<String> merchantIdentity = GeneratedColumn<String>(
    'merchant_identity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankConfirmationStatusMeta =
      const VerificationMeta('bankConfirmationStatus');
  @override
  late final GeneratedColumn<String> bankConfirmationStatus =
      GeneratedColumn<String>(
        'bank_confirmation_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('NOT_RECEIVED'),
      );
  static const VerificationMeta _sourcePackageMeta = const VerificationMeta(
    'sourcePackage',
  );
  @override
  late final GeneratedColumn<String> sourcePackage = GeneratedColumn<String>(
    'source_package',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountHintMeta = const VerificationMeta(
    'accountHint',
  );
  @override
  late final GeneratedColumn<String> accountHint = GeneratedColumn<String>(
    'account_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _balanceAfterMinorMeta = const VerificationMeta(
    'balanceAfterMinor',
  );
  @override
  late final GeneratedColumn<int> balanceAfterMinor = GeneratedColumn<int>(
    'balance_after_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawEventIdMeta = const VerificationMeta(
    'rawEventId',
  );
  @override
  late final GeneratedColumn<String> rawEventId = GeneratedColumn<String>(
    'raw_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceScoreMeta = const VerificationMeta(
    'confidenceScore',
  );
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
    'confidence_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _duplicateStatusMeta = const VerificationMeta(
    'duplicateStatus',
  );
  @override
  late final GeneratedColumn<String> duplicateStatus = GeneratedColumn<String>(
    'duplicate_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Other'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localAccountId,
    candidateId,
    amountMinor,
    currency,
    merchantName,
    merchantIdentity,
    direction,
    transactionType,
    source,
    bankConfirmationStatus,
    sourcePackage,
    occurredAt,
    referenceId,
    accountHint,
    paymentMethod,
    balanceAfterMinor,
    rawEventId,
    confidenceScore,
    status,
    duplicateStatus,
    category,
    createdAt,
    updatedAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_candidates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionCandidate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_account_id')) {
      context.handle(
        _localAccountIdMeta,
        localAccountId.isAcceptableOrUnknown(
          data['local_account_id']!,
          _localAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('candidate_id')) {
      context.handle(
        _candidateIdMeta,
        candidateId.isAcceptableOrUnknown(
          data['candidate_id']!,
          _candidateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_candidateIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('merchant_name')) {
      context.handle(
        _merchantNameMeta,
        merchantName.isAcceptableOrUnknown(
          data['merchant_name']!,
          _merchantNameMeta,
        ),
      );
    }
    if (data.containsKey('merchant_identity')) {
      context.handle(
        _merchantIdentityMeta,
        merchantIdentity.isAcceptableOrUnknown(
          data['merchant_identity']!,
          _merchantIdentityMeta,
        ),
      );
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('bank_confirmation_status')) {
      context.handle(
        _bankConfirmationStatusMeta,
        bankConfirmationStatus.isAcceptableOrUnknown(
          data['bank_confirmation_status']!,
          _bankConfirmationStatusMeta,
        ),
      );
    }
    if (data.containsKey('source_package')) {
      context.handle(
        _sourcePackageMeta,
        sourcePackage.isAcceptableOrUnknown(
          data['source_package']!,
          _sourcePackageMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    }
    if (data.containsKey('account_hint')) {
      context.handle(
        _accountHintMeta,
        accountHint.isAcceptableOrUnknown(
          data['account_hint']!,
          _accountHintMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('balance_after_minor')) {
      context.handle(
        _balanceAfterMinorMeta,
        balanceAfterMinor.isAcceptableOrUnknown(
          data['balance_after_minor']!,
          _balanceAfterMinorMeta,
        ),
      );
    }
    if (data.containsKey('raw_event_id')) {
      context.handle(
        _rawEventIdMeta,
        rawEventId.isAcceptableOrUnknown(
          data['raw_event_id']!,
          _rawEventIdMeta,
        ),
      );
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
        _confidenceScoreMeta,
        confidenceScore.isAcceptableOrUnknown(
          data['confidence_score']!,
          _confidenceScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confidenceScoreMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('duplicate_status')) {
      context.handle(
        _duplicateStatusMeta,
        duplicateStatus.isAcceptableOrUnknown(
          data['duplicate_status']!,
          _duplicateStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_duplicateStatusMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionCandidate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionCandidate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_account_id'],
      )!,
      candidateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}candidate_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      merchantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_name'],
      )!,
      merchantIdentity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_identity'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      bankConfirmationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_confirmation_status'],
      )!,
      sourcePackage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_package'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      ),
      accountHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_hint'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      balanceAfterMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_after_minor'],
      ),
      rawEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_event_id'],
      ),
      confidenceScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence_score'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      duplicateStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duplicate_status'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $TransactionCandidatesTable createAlias(String alias) {
    return $TransactionCandidatesTable(attachedDatabase, alias);
  }
}

class TransactionCandidate extends DataClass
    implements Insertable<TransactionCandidate> {
  final int id;
  final int localAccountId;
  final String candidateId;
  final int amountMinor;
  final String currency;
  final String merchantName;
  final String merchantIdentity;
  final String direction;
  final String transactionType;
  final String source;
  final String bankConfirmationStatus;
  final String? sourcePackage;
  final DateTime occurredAt;
  final String? referenceId;
  final String? accountHint;
  final String? paymentMethod;
  final int? balanceAfterMinor;
  final String? rawEventId;
  final double confidenceScore;
  final String status;
  final String duplicateStatus;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  const TransactionCandidate({
    required this.id,
    required this.localAccountId,
    required this.candidateId,
    required this.amountMinor,
    required this.currency,
    required this.merchantName,
    required this.merchantIdentity,
    required this.direction,
    required this.transactionType,
    required this.source,
    required this.bankConfirmationStatus,
    this.sourcePackage,
    required this.occurredAt,
    this.referenceId,
    this.accountHint,
    this.paymentMethod,
    this.balanceAfterMinor,
    this.rawEventId,
    required this.confidenceScore,
    required this.status,
    required this.duplicateStatus,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_account_id'] = Variable<int>(localAccountId);
    map['candidate_id'] = Variable<String>(candidateId);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    map['merchant_name'] = Variable<String>(merchantName);
    map['merchant_identity'] = Variable<String>(merchantIdentity);
    map['direction'] = Variable<String>(direction);
    map['transaction_type'] = Variable<String>(transactionType);
    map['source'] = Variable<String>(source);
    map['bank_confirmation_status'] = Variable<String>(bankConfirmationStatus);
    if (!nullToAbsent || sourcePackage != null) {
      map['source_package'] = Variable<String>(sourcePackage);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || referenceId != null) {
      map['reference_id'] = Variable<String>(referenceId);
    }
    if (!nullToAbsent || accountHint != null) {
      map['account_hint'] = Variable<String>(accountHint);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || balanceAfterMinor != null) {
      map['balance_after_minor'] = Variable<int>(balanceAfterMinor);
    }
    if (!nullToAbsent || rawEventId != null) {
      map['raw_event_id'] = Variable<String>(rawEventId);
    }
    map['confidence_score'] = Variable<double>(confidenceScore);
    map['status'] = Variable<String>(status);
    map['duplicate_status'] = Variable<String>(duplicateStatus);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  TransactionCandidatesCompanion toCompanion(bool nullToAbsent) {
    return TransactionCandidatesCompanion(
      id: Value(id),
      localAccountId: Value(localAccountId),
      candidateId: Value(candidateId),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      merchantName: Value(merchantName),
      merchantIdentity: Value(merchantIdentity),
      direction: Value(direction),
      transactionType: Value(transactionType),
      source: Value(source),
      bankConfirmationStatus: Value(bankConfirmationStatus),
      sourcePackage: sourcePackage == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePackage),
      occurredAt: Value(occurredAt),
      referenceId: referenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceId),
      accountHint: accountHint == null && nullToAbsent
          ? const Value.absent()
          : Value(accountHint),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      balanceAfterMinor: balanceAfterMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(balanceAfterMinor),
      rawEventId: rawEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(rawEventId),
      confidenceScore: Value(confidenceScore),
      status: Value(status),
      duplicateStatus: Value(duplicateStatus),
      category: Value(category),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory TransactionCandidate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionCandidate(
      id: serializer.fromJson<int>(json['id']),
      localAccountId: serializer.fromJson<int>(json['localAccountId']),
      candidateId: serializer.fromJson<String>(json['candidateId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      merchantName: serializer.fromJson<String>(json['merchantName']),
      merchantIdentity: serializer.fromJson<String>(json['merchantIdentity']),
      direction: serializer.fromJson<String>(json['direction']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      source: serializer.fromJson<String>(json['source']),
      bankConfirmationStatus: serializer.fromJson<String>(
        json['bankConfirmationStatus'],
      ),
      sourcePackage: serializer.fromJson<String?>(json['sourcePackage']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      referenceId: serializer.fromJson<String?>(json['referenceId']),
      accountHint: serializer.fromJson<String?>(json['accountHint']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      balanceAfterMinor: serializer.fromJson<int?>(json['balanceAfterMinor']),
      rawEventId: serializer.fromJson<String?>(json['rawEventId']),
      confidenceScore: serializer.fromJson<double>(json['confidenceScore']),
      status: serializer.fromJson<String>(json['status']),
      duplicateStatus: serializer.fromJson<String>(json['duplicateStatus']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localAccountId': serializer.toJson<int>(localAccountId),
      'candidateId': serializer.toJson<String>(candidateId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'merchantName': serializer.toJson<String>(merchantName),
      'merchantIdentity': serializer.toJson<String>(merchantIdentity),
      'direction': serializer.toJson<String>(direction),
      'transactionType': serializer.toJson<String>(transactionType),
      'source': serializer.toJson<String>(source),
      'bankConfirmationStatus': serializer.toJson<String>(
        bankConfirmationStatus,
      ),
      'sourcePackage': serializer.toJson<String?>(sourcePackage),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'referenceId': serializer.toJson<String?>(referenceId),
      'accountHint': serializer.toJson<String?>(accountHint),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'balanceAfterMinor': serializer.toJson<int?>(balanceAfterMinor),
      'rawEventId': serializer.toJson<String?>(rawEventId),
      'confidenceScore': serializer.toJson<double>(confidenceScore),
      'status': serializer.toJson<String>(status),
      'duplicateStatus': serializer.toJson<String>(duplicateStatus),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  TransactionCandidate copyWith({
    int? id,
    int? localAccountId,
    String? candidateId,
    int? amountMinor,
    String? currency,
    String? merchantName,
    String? merchantIdentity,
    String? direction,
    String? transactionType,
    String? source,
    String? bankConfirmationStatus,
    Value<String?> sourcePackage = const Value.absent(),
    DateTime? occurredAt,
    Value<String?> referenceId = const Value.absent(),
    Value<String?> accountHint = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    Value<int?> balanceAfterMinor = const Value.absent(),
    Value<String?> rawEventId = const Value.absent(),
    double? confidenceScore,
    String? status,
    String? duplicateStatus,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) => TransactionCandidate(
    id: id ?? this.id,
    localAccountId: localAccountId ?? this.localAccountId,
    candidateId: candidateId ?? this.candidateId,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    merchantName: merchantName ?? this.merchantName,
    merchantIdentity: merchantIdentity ?? this.merchantIdentity,
    direction: direction ?? this.direction,
    transactionType: transactionType ?? this.transactionType,
    source: source ?? this.source,
    bankConfirmationStatus:
        bankConfirmationStatus ?? this.bankConfirmationStatus,
    sourcePackage: sourcePackage.present
        ? sourcePackage.value
        : this.sourcePackage,
    occurredAt: occurredAt ?? this.occurredAt,
    referenceId: referenceId.present ? referenceId.value : this.referenceId,
    accountHint: accountHint.present ? accountHint.value : this.accountHint,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    balanceAfterMinor: balanceAfterMinor.present
        ? balanceAfterMinor.value
        : this.balanceAfterMinor,
    rawEventId: rawEventId.present ? rawEventId.value : this.rawEventId,
    confidenceScore: confidenceScore ?? this.confidenceScore,
    status: status ?? this.status,
    duplicateStatus: duplicateStatus ?? this.duplicateStatus,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  TransactionCandidate copyWithCompanion(TransactionCandidatesCompanion data) {
    return TransactionCandidate(
      id: data.id.present ? data.id.value : this.id,
      localAccountId: data.localAccountId.present
          ? data.localAccountId.value
          : this.localAccountId,
      candidateId: data.candidateId.present
          ? data.candidateId.value
          : this.candidateId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      merchantName: data.merchantName.present
          ? data.merchantName.value
          : this.merchantName,
      merchantIdentity: data.merchantIdentity.present
          ? data.merchantIdentity.value
          : this.merchantIdentity,
      direction: data.direction.present ? data.direction.value : this.direction,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      source: data.source.present ? data.source.value : this.source,
      bankConfirmationStatus: data.bankConfirmationStatus.present
          ? data.bankConfirmationStatus.value
          : this.bankConfirmationStatus,
      sourcePackage: data.sourcePackage.present
          ? data.sourcePackage.value
          : this.sourcePackage,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      accountHint: data.accountHint.present
          ? data.accountHint.value
          : this.accountHint,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      balanceAfterMinor: data.balanceAfterMinor.present
          ? data.balanceAfterMinor.value
          : this.balanceAfterMinor,
      rawEventId: data.rawEventId.present
          ? data.rawEventId.value
          : this.rawEventId,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      status: data.status.present ? data.status.value : this.status,
      duplicateStatus: data.duplicateStatus.present
          ? data.duplicateStatus.value
          : this.duplicateStatus,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionCandidate(')
          ..write('id: $id, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('candidateId: $candidateId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('merchantName: $merchantName, ')
          ..write('merchantIdentity: $merchantIdentity, ')
          ..write('direction: $direction, ')
          ..write('transactionType: $transactionType, ')
          ..write('source: $source, ')
          ..write('bankConfirmationStatus: $bankConfirmationStatus, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('referenceId: $referenceId, ')
          ..write('accountHint: $accountHint, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('balanceAfterMinor: $balanceAfterMinor, ')
          ..write('rawEventId: $rawEventId, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('status: $status, ')
          ..write('duplicateStatus: $duplicateStatus, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    localAccountId,
    candidateId,
    amountMinor,
    currency,
    merchantName,
    merchantIdentity,
    direction,
    transactionType,
    source,
    bankConfirmationStatus,
    sourcePackage,
    occurredAt,
    referenceId,
    accountHint,
    paymentMethod,
    balanceAfterMinor,
    rawEventId,
    confidenceScore,
    status,
    duplicateStatus,
    category,
    createdAt,
    updatedAt,
    expiresAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionCandidate &&
          other.id == this.id &&
          other.localAccountId == this.localAccountId &&
          other.candidateId == this.candidateId &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.merchantName == this.merchantName &&
          other.merchantIdentity == this.merchantIdentity &&
          other.direction == this.direction &&
          other.transactionType == this.transactionType &&
          other.source == this.source &&
          other.bankConfirmationStatus == this.bankConfirmationStatus &&
          other.sourcePackage == this.sourcePackage &&
          other.occurredAt == this.occurredAt &&
          other.referenceId == this.referenceId &&
          other.accountHint == this.accountHint &&
          other.paymentMethod == this.paymentMethod &&
          other.balanceAfterMinor == this.balanceAfterMinor &&
          other.rawEventId == this.rawEventId &&
          other.confidenceScore == this.confidenceScore &&
          other.status == this.status &&
          other.duplicateStatus == this.duplicateStatus &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.expiresAt == this.expiresAt);
}

class TransactionCandidatesCompanion
    extends UpdateCompanion<TransactionCandidate> {
  final Value<int> id;
  final Value<int> localAccountId;
  final Value<String> candidateId;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<String> merchantName;
  final Value<String> merchantIdentity;
  final Value<String> direction;
  final Value<String> transactionType;
  final Value<String> source;
  final Value<String> bankConfirmationStatus;
  final Value<String?> sourcePackage;
  final Value<DateTime> occurredAt;
  final Value<String?> referenceId;
  final Value<String?> accountHint;
  final Value<String?> paymentMethod;
  final Value<int?> balanceAfterMinor;
  final Value<String?> rawEventId;
  final Value<double> confidenceScore;
  final Value<String> status;
  final Value<String> duplicateStatus;
  final Value<String> category;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> expiresAt;
  const TransactionCandidatesCompanion({
    this.id = const Value.absent(),
    this.localAccountId = const Value.absent(),
    this.candidateId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.merchantName = const Value.absent(),
    this.merchantIdentity = const Value.absent(),
    this.direction = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.source = const Value.absent(),
    this.bankConfirmationStatus = const Value.absent(),
    this.sourcePackage = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.accountHint = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.balanceAfterMinor = const Value.absent(),
    this.rawEventId = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.status = const Value.absent(),
    this.duplicateStatus = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  TransactionCandidatesCompanion.insert({
    this.id = const Value.absent(),
    this.localAccountId = const Value.absent(),
    required String candidateId,
    required int amountMinor,
    this.currency = const Value.absent(),
    this.merchantName = const Value.absent(),
    this.merchantIdentity = const Value.absent(),
    required String direction,
    required String transactionType,
    required String source,
    this.bankConfirmationStatus = const Value.absent(),
    this.sourcePackage = const Value.absent(),
    required DateTime occurredAt,
    this.referenceId = const Value.absent(),
    this.accountHint = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.balanceAfterMinor = const Value.absent(),
    this.rawEventId = const Value.absent(),
    required double confidenceScore,
    required String status,
    required String duplicateStatus,
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  }) : candidateId = Value(candidateId),
       amountMinor = Value(amountMinor),
       direction = Value(direction),
       transactionType = Value(transactionType),
       source = Value(source),
       occurredAt = Value(occurredAt),
       confidenceScore = Value(confidenceScore),
       status = Value(status),
       duplicateStatus = Value(duplicateStatus);
  static Insertable<TransactionCandidate> custom({
    Expression<int>? id,
    Expression<int>? localAccountId,
    Expression<String>? candidateId,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<String>? merchantName,
    Expression<String>? merchantIdentity,
    Expression<String>? direction,
    Expression<String>? transactionType,
    Expression<String>? source,
    Expression<String>? bankConfirmationStatus,
    Expression<String>? sourcePackage,
    Expression<DateTime>? occurredAt,
    Expression<String>? referenceId,
    Expression<String>? accountHint,
    Expression<String>? paymentMethod,
    Expression<int>? balanceAfterMinor,
    Expression<String>? rawEventId,
    Expression<double>? confidenceScore,
    Expression<String>? status,
    Expression<String>? duplicateStatus,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localAccountId != null) 'local_account_id': localAccountId,
      if (candidateId != null) 'candidate_id': candidateId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (merchantName != null) 'merchant_name': merchantName,
      if (merchantIdentity != null) 'merchant_identity': merchantIdentity,
      if (direction != null) 'direction': direction,
      if (transactionType != null) 'transaction_type': transactionType,
      if (source != null) 'source': source,
      if (bankConfirmationStatus != null)
        'bank_confirmation_status': bankConfirmationStatus,
      if (sourcePackage != null) 'source_package': sourcePackage,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (referenceId != null) 'reference_id': referenceId,
      if (accountHint != null) 'account_hint': accountHint,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (balanceAfterMinor != null) 'balance_after_minor': balanceAfterMinor,
      if (rawEventId != null) 'raw_event_id': rawEventId,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (status != null) 'status': status,
      if (duplicateStatus != null) 'duplicate_status': duplicateStatus,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  TransactionCandidatesCompanion copyWith({
    Value<int>? id,
    Value<int>? localAccountId,
    Value<String>? candidateId,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<String>? merchantName,
    Value<String>? merchantIdentity,
    Value<String>? direction,
    Value<String>? transactionType,
    Value<String>? source,
    Value<String>? bankConfirmationStatus,
    Value<String?>? sourcePackage,
    Value<DateTime>? occurredAt,
    Value<String?>? referenceId,
    Value<String?>? accountHint,
    Value<String?>? paymentMethod,
    Value<int?>? balanceAfterMinor,
    Value<String?>? rawEventId,
    Value<double>? confidenceScore,
    Value<String>? status,
    Value<String>? duplicateStatus,
    Value<String>? category,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? expiresAt,
  }) {
    return TransactionCandidatesCompanion(
      id: id ?? this.id,
      localAccountId: localAccountId ?? this.localAccountId,
      candidateId: candidateId ?? this.candidateId,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      merchantName: merchantName ?? this.merchantName,
      merchantIdentity: merchantIdentity ?? this.merchantIdentity,
      direction: direction ?? this.direction,
      transactionType: transactionType ?? this.transactionType,
      source: source ?? this.source,
      bankConfirmationStatus:
          bankConfirmationStatus ?? this.bankConfirmationStatus,
      sourcePackage: sourcePackage ?? this.sourcePackage,
      occurredAt: occurredAt ?? this.occurredAt,
      referenceId: referenceId ?? this.referenceId,
      accountHint: accountHint ?? this.accountHint,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      balanceAfterMinor: balanceAfterMinor ?? this.balanceAfterMinor,
      rawEventId: rawEventId ?? this.rawEventId,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      status: status ?? this.status,
      duplicateStatus: duplicateStatus ?? this.duplicateStatus,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localAccountId.present) {
      map['local_account_id'] = Variable<int>(localAccountId.value);
    }
    if (candidateId.present) {
      map['candidate_id'] = Variable<String>(candidateId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (merchantName.present) {
      map['merchant_name'] = Variable<String>(merchantName.value);
    }
    if (merchantIdentity.present) {
      map['merchant_identity'] = Variable<String>(merchantIdentity.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (bankConfirmationStatus.present) {
      map['bank_confirmation_status'] = Variable<String>(
        bankConfirmationStatus.value,
      );
    }
    if (sourcePackage.present) {
      map['source_package'] = Variable<String>(sourcePackage.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (accountHint.present) {
      map['account_hint'] = Variable<String>(accountHint.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (balanceAfterMinor.present) {
      map['balance_after_minor'] = Variable<int>(balanceAfterMinor.value);
    }
    if (rawEventId.present) {
      map['raw_event_id'] = Variable<String>(rawEventId.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (duplicateStatus.present) {
      map['duplicate_status'] = Variable<String>(duplicateStatus.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionCandidatesCompanion(')
          ..write('id: $id, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('candidateId: $candidateId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('merchantName: $merchantName, ')
          ..write('merchantIdentity: $merchantIdentity, ')
          ..write('direction: $direction, ')
          ..write('transactionType: $transactionType, ')
          ..write('source: $source, ')
          ..write('bankConfirmationStatus: $bankConfirmationStatus, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('referenceId: $referenceId, ')
          ..write('accountHint: $accountHint, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('balanceAfterMinor: $balanceAfterMinor, ')
          ..write('rawEventId: $rawEventId, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('status: $status, ')
          ..write('duplicateStatus: $duplicateStatus, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $MerchantCategoryRulesTable extends MerchantCategoryRules
    with TableInfo<$MerchantCategoryRulesTable, MerchantCategoryRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MerchantCategoryRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _localAccountIdMeta = const VerificationMeta(
    'localAccountId',
  );
  @override
  late final GeneratedColumn<int> localAccountId = GeneratedColumn<int>(
    'local_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_accounts (id)',
    ),
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _merchantIdentityMeta = const VerificationMeta(
    'merchantIdentity',
  );
  @override
  late final GeneratedColumn<String> merchantIdentity = GeneratedColumn<String>(
    'merchant_identity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    localAccountId,
    merchantIdentity,
    category,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merchant_category_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<MerchantCategoryRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('local_account_id')) {
      context.handle(
        _localAccountIdMeta,
        localAccountId.isAcceptableOrUnknown(
          data['local_account_id']!,
          _localAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('merchant_identity')) {
      context.handle(
        _merchantIdentityMeta,
        merchantIdentity.isAcceptableOrUnknown(
          data['merchant_identity']!,
          _merchantIdentityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantIdentityMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {localAccountId, merchantIdentity},
  ];
  @override
  MerchantCategoryRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MerchantCategoryRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      localAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_account_id'],
      )!,
      merchantIdentity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_identity'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $MerchantCategoryRulesTable createAlias(String alias) {
    return $MerchantCategoryRulesTable(attachedDatabase, alias);
  }
}

class MerchantCategoryRule extends DataClass
    implements Insertable<MerchantCategoryRule> {
  final int id;
  final String? serverId;
  final int localAccountId;
  final String merchantIdentity;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MerchantCategoryRule({
    required this.id,
    this.serverId,
    required this.localAccountId,
    required this.merchantIdentity,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['local_account_id'] = Variable<int>(localAccountId);
    map['merchant_identity'] = Variable<String>(merchantIdentity);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MerchantCategoryRulesCompanion toCompanion(bool nullToAbsent) {
    return MerchantCategoryRulesCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      localAccountId: Value(localAccountId),
      merchantIdentity: Value(merchantIdentity),
      category: Value(category),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MerchantCategoryRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MerchantCategoryRule(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      localAccountId: serializer.fromJson<int>(json['localAccountId']),
      merchantIdentity: serializer.fromJson<String>(json['merchantIdentity']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'localAccountId': serializer.toJson<int>(localAccountId),
      'merchantIdentity': serializer.toJson<String>(merchantIdentity),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MerchantCategoryRule copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    int? localAccountId,
    String? merchantIdentity,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => MerchantCategoryRule(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    localAccountId: localAccountId ?? this.localAccountId,
    merchantIdentity: merchantIdentity ?? this.merchantIdentity,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  MerchantCategoryRule copyWithCompanion(MerchantCategoryRulesCompanion data) {
    return MerchantCategoryRule(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      localAccountId: data.localAccountId.present
          ? data.localAccountId.value
          : this.localAccountId,
      merchantIdentity: data.merchantIdentity.present
          ? data.merchantIdentity.value
          : this.merchantIdentity,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MerchantCategoryRule(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('merchantIdentity: $merchantIdentity, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    localAccountId,
    merchantIdentity,
    category,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MerchantCategoryRule &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.localAccountId == this.localAccountId &&
          other.merchantIdentity == this.merchantIdentity &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MerchantCategoryRulesCompanion
    extends UpdateCompanion<MerchantCategoryRule> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<int> localAccountId;
  final Value<String> merchantIdentity;
  final Value<String> category;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const MerchantCategoryRulesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.localAccountId = const Value.absent(),
    this.merchantIdentity = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  MerchantCategoryRulesCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.localAccountId = const Value.absent(),
    required String merchantIdentity,
    required String category,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : merchantIdentity = Value(merchantIdentity),
       category = Value(category);
  static Insertable<MerchantCategoryRule> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<int>? localAccountId,
    Expression<String>? merchantIdentity,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (localAccountId != null) 'local_account_id': localAccountId,
      if (merchantIdentity != null) 'merchant_identity': merchantIdentity,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  MerchantCategoryRulesCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<int>? localAccountId,
    Value<String>? merchantIdentity,
    Value<String>? category,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return MerchantCategoryRulesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      localAccountId: localAccountId ?? this.localAccountId,
      merchantIdentity: merchantIdentity ?? this.merchantIdentity,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (localAccountId.present) {
      map['local_account_id'] = Variable<int>(localAccountId.value);
    }
    if (merchantIdentity.present) {
      map['merchant_identity'] = Variable<String>(merchantIdentity.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MerchantCategoryRulesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('merchantIdentity: $merchantIdentity, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $YoutubePlaylistsTable extends YoutubePlaylists
    with TableInfo<$YoutubePlaylistsTable, YoutubePlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $YoutubePlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _localAccountIdMeta = const VerificationMeta(
    'localAccountId',
  );
  @override
  late final GeneratedColumn<int> localAccountId = GeneratedColumn<int>(
    'local_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_accounts (id)',
    ),
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _youtubePlaylistIdMeta = const VerificationMeta(
    'youtubePlaylistId',
  );
  @override
  late final GeneratedColumn<String> youtubePlaylistId =
      GeneratedColumn<String>(
        'youtube_playlist_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _channelTitleMeta = const VerificationMeta(
    'channelTitle',
  );
  @override
  late final GeneratedColumn<String> channelTitle = GeneratedColumn<String>(
    'channel_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _totalVideosMeta = const VerificationMeta(
    'totalVideos',
  );
  @override
  late final GeneratedColumn<int> totalVideos = GeneratedColumn<int>(
    'total_videos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalDurationSecondsMeta =
      const VerificationMeta('totalDurationSeconds');
  @override
  late final GeneratedColumn<int> totalDurationSeconds = GeneratedColumn<int>(
    'total_duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    localAccountId,
    youtubePlaylistId,
    title,
    description,
    channelTitle,
    thumbnailUrl,
    totalVideos,
    totalDurationSeconds,
    createdAt,
    updatedAt,
    lastSyncedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'youtube_playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<YoutubePlaylist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('local_account_id')) {
      context.handle(
        _localAccountIdMeta,
        localAccountId.isAcceptableOrUnknown(
          data['local_account_id']!,
          _localAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('youtube_playlist_id')) {
      context.handle(
        _youtubePlaylistIdMeta,
        youtubePlaylistId.isAcceptableOrUnknown(
          data['youtube_playlist_id']!,
          _youtubePlaylistIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_youtubePlaylistIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('channel_title')) {
      context.handle(
        _channelTitleMeta,
        channelTitle.isAcceptableOrUnknown(
          data['channel_title']!,
          _channelTitleMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('total_videos')) {
      context.handle(
        _totalVideosMeta,
        totalVideos.isAcceptableOrUnknown(
          data['total_videos']!,
          _totalVideosMeta,
        ),
      );
    }
    if (data.containsKey('total_duration_seconds')) {
      context.handle(
        _totalDurationSecondsMeta,
        totalDurationSeconds.isAcceptableOrUnknown(
          data['total_duration_seconds']!,
          _totalDurationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {localAccountId, youtubePlaylistId},
  ];
  @override
  YoutubePlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return YoutubePlaylist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      localAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_account_id'],
      )!,
      youtubePlaylistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}youtube_playlist_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      channelTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_title'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      )!,
      totalVideos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_videos'],
      )!,
      totalDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_duration_seconds'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $YoutubePlaylistsTable createAlias(String alias) {
    return $YoutubePlaylistsTable(attachedDatabase, alias);
  }
}

class YoutubePlaylist extends DataClass implements Insertable<YoutubePlaylist> {
  final int id;
  final String? serverId;
  final int localAccountId;
  final String youtubePlaylistId;
  final String title;
  final String description;
  final String channelTitle;
  final String thumbnailUrl;
  final int totalVideos;
  final int totalDurationSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final DateTime? deletedAt;
  const YoutubePlaylist({
    required this.id,
    this.serverId,
    required this.localAccountId,
    required this.youtubePlaylistId,
    required this.title,
    required this.description,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.totalVideos,
    required this.totalDurationSeconds,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['local_account_id'] = Variable<int>(localAccountId);
    map['youtube_playlist_id'] = Variable<String>(youtubePlaylistId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['channel_title'] = Variable<String>(channelTitle);
    map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    map['total_videos'] = Variable<int>(totalVideos);
    map['total_duration_seconds'] = Variable<int>(totalDurationSeconds);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  YoutubePlaylistsCompanion toCompanion(bool nullToAbsent) {
    return YoutubePlaylistsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      localAccountId: Value(localAccountId),
      youtubePlaylistId: Value(youtubePlaylistId),
      title: Value(title),
      description: Value(description),
      channelTitle: Value(channelTitle),
      thumbnailUrl: Value(thumbnailUrl),
      totalVideos: Value(totalVideos),
      totalDurationSeconds: Value(totalDurationSeconds),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory YoutubePlaylist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return YoutubePlaylist(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      localAccountId: serializer.fromJson<int>(json['localAccountId']),
      youtubePlaylistId: serializer.fromJson<String>(json['youtubePlaylistId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      channelTitle: serializer.fromJson<String>(json['channelTitle']),
      thumbnailUrl: serializer.fromJson<String>(json['thumbnailUrl']),
      totalVideos: serializer.fromJson<int>(json['totalVideos']),
      totalDurationSeconds: serializer.fromJson<int>(
        json['totalDurationSeconds'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'localAccountId': serializer.toJson<int>(localAccountId),
      'youtubePlaylistId': serializer.toJson<String>(youtubePlaylistId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'channelTitle': serializer.toJson<String>(channelTitle),
      'thumbnailUrl': serializer.toJson<String>(thumbnailUrl),
      'totalVideos': serializer.toJson<int>(totalVideos),
      'totalDurationSeconds': serializer.toJson<int>(totalDurationSeconds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  YoutubePlaylist copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    int? localAccountId,
    String? youtubePlaylistId,
    String? title,
    String? description,
    String? channelTitle,
    String? thumbnailUrl,
    int? totalVideos,
    int? totalDurationSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => YoutubePlaylist(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    localAccountId: localAccountId ?? this.localAccountId,
    youtubePlaylistId: youtubePlaylistId ?? this.youtubePlaylistId,
    title: title ?? this.title,
    description: description ?? this.description,
    channelTitle: channelTitle ?? this.channelTitle,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    totalVideos: totalVideos ?? this.totalVideos,
    totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  YoutubePlaylist copyWithCompanion(YoutubePlaylistsCompanion data) {
    return YoutubePlaylist(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      localAccountId: data.localAccountId.present
          ? data.localAccountId.value
          : this.localAccountId,
      youtubePlaylistId: data.youtubePlaylistId.present
          ? data.youtubePlaylistId.value
          : this.youtubePlaylistId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      channelTitle: data.channelTitle.present
          ? data.channelTitle.value
          : this.channelTitle,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      totalVideos: data.totalVideos.present
          ? data.totalVideos.value
          : this.totalVideos,
      totalDurationSeconds: data.totalDurationSeconds.present
          ? data.totalDurationSeconds.value
          : this.totalDurationSeconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('YoutubePlaylist(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('youtubePlaylistId: $youtubePlaylistId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('channelTitle: $channelTitle, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('totalVideos: $totalVideos, ')
          ..write('totalDurationSeconds: $totalDurationSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    localAccountId,
    youtubePlaylistId,
    title,
    description,
    channelTitle,
    thumbnailUrl,
    totalVideos,
    totalDurationSeconds,
    createdAt,
    updatedAt,
    lastSyncedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is YoutubePlaylist &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.localAccountId == this.localAccountId &&
          other.youtubePlaylistId == this.youtubePlaylistId &&
          other.title == this.title &&
          other.description == this.description &&
          other.channelTitle == this.channelTitle &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.totalVideos == this.totalVideos &&
          other.totalDurationSeconds == this.totalDurationSeconds &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.deletedAt == this.deletedAt);
}

class YoutubePlaylistsCompanion extends UpdateCompanion<YoutubePlaylist> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<int> localAccountId;
  final Value<String> youtubePlaylistId;
  final Value<String> title;
  final Value<String> description;
  final Value<String> channelTitle;
  final Value<String> thumbnailUrl;
  final Value<int> totalVideos;
  final Value<int> totalDurationSeconds;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime?> deletedAt;
  const YoutubePlaylistsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.localAccountId = const Value.absent(),
    this.youtubePlaylistId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.channelTitle = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.totalVideos = const Value.absent(),
    this.totalDurationSeconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  YoutubePlaylistsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.localAccountId = const Value.absent(),
    required String youtubePlaylistId,
    required String title,
    this.description = const Value.absent(),
    this.channelTitle = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.totalVideos = const Value.absent(),
    this.totalDurationSeconds = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : youtubePlaylistId = Value(youtubePlaylistId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<YoutubePlaylist> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<int>? localAccountId,
    Expression<String>? youtubePlaylistId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? channelTitle,
    Expression<String>? thumbnailUrl,
    Expression<int>? totalVideos,
    Expression<int>? totalDurationSeconds,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (localAccountId != null) 'local_account_id': localAccountId,
      if (youtubePlaylistId != null) 'youtube_playlist_id': youtubePlaylistId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (channelTitle != null) 'channel_title': channelTitle,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (totalVideos != null) 'total_videos': totalVideos,
      if (totalDurationSeconds != null)
        'total_duration_seconds': totalDurationSeconds,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  YoutubePlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<int>? localAccountId,
    Value<String>? youtubePlaylistId,
    Value<String>? title,
    Value<String>? description,
    Value<String>? channelTitle,
    Value<String>? thumbnailUrl,
    Value<int>? totalVideos,
    Value<int>? totalDurationSeconds,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return YoutubePlaylistsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      localAccountId: localAccountId ?? this.localAccountId,
      youtubePlaylistId: youtubePlaylistId ?? this.youtubePlaylistId,
      title: title ?? this.title,
      description: description ?? this.description,
      channelTitle: channelTitle ?? this.channelTitle,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      totalVideos: totalVideos ?? this.totalVideos,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (localAccountId.present) {
      map['local_account_id'] = Variable<int>(localAccountId.value);
    }
    if (youtubePlaylistId.present) {
      map['youtube_playlist_id'] = Variable<String>(youtubePlaylistId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (channelTitle.present) {
      map['channel_title'] = Variable<String>(channelTitle.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (totalVideos.present) {
      map['total_videos'] = Variable<int>(totalVideos.value);
    }
    if (totalDurationSeconds.present) {
      map['total_duration_seconds'] = Variable<int>(totalDurationSeconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('YoutubePlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('youtubePlaylistId: $youtubePlaylistId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('channelTitle: $channelTitle, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('totalVideos: $totalVideos, ')
          ..write('totalDurationSeconds: $totalDurationSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $YoutubeVideosTable extends YoutubeVideos
    with TableInfo<$YoutubeVideosTable, YoutubeVideo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $YoutubeVideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta(
    'remoteUpdatedAt',
  );
  @override
  late final GeneratedColumn<String> remoteUpdatedAt = GeneratedColumn<String>(
    'remote_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playlistLocalIdMeta = const VerificationMeta(
    'playlistLocalId',
  );
  @override
  late final GeneratedColumn<int> playlistLocalId = GeneratedColumn<int>(
    'playlist_local_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES youtube_playlists (id)',
    ),
  );
  static const VerificationMeta _youtubeVideoIdMeta = const VerificationMeta(
    'youtubeVideoId',
  );
  @override
  late final GeneratedColumn<String> youtubeVideoId = GeneratedColumn<String>(
    'youtube_video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationIsoMeta = const VerificationMeta(
    'durationIso',
  );
  @override
  late final GeneratedColumn<String> durationIso = GeneratedColumn<String>(
    'duration_iso',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPositionSecondsMeta =
      const VerificationMeta('lastPositionSeconds');
  @override
  late final GeneratedColumn<int> lastPositionSeconds = GeneratedColumn<int>(
    'last_position_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressUpdatedAtMeta = const VerificationMeta(
    'progressUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> progressUpdatedAt =
      GeneratedColumn<DateTime>(
        'progress_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    remoteUpdatedAt,
    playlistLocalId,
    youtubeVideoId,
    title,
    thumbnailUrl,
    position,
    durationSeconds,
    durationIso,
    completed,
    watchedAt,
    lastPositionSeconds,
    createdAt,
    updatedAt,
    progressUpdatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'youtube_videos';
  @override
  VerificationContext validateIntegrity(
    Insertable<YoutubeVideo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
        _remoteUpdatedAtMeta,
        remoteUpdatedAt.isAcceptableOrUnknown(
          data['remote_updated_at']!,
          _remoteUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('playlist_local_id')) {
      context.handle(
        _playlistLocalIdMeta,
        playlistLocalId.isAcceptableOrUnknown(
          data['playlist_local_id']!,
          _playlistLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playlistLocalIdMeta);
    }
    if (data.containsKey('youtube_video_id')) {
      context.handle(
        _youtubeVideoIdMeta,
        youtubeVideoId.isAcceptableOrUnknown(
          data['youtube_video_id']!,
          _youtubeVideoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_youtubeVideoIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('duration_iso')) {
      context.handle(
        _durationIsoMeta,
        durationIso.isAcceptableOrUnknown(
          data['duration_iso']!,
          _durationIsoMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    }
    if (data.containsKey('last_position_seconds')) {
      context.handle(
        _lastPositionSecondsMeta,
        lastPositionSeconds.isAcceptableOrUnknown(
          data['last_position_seconds']!,
          _lastPositionSecondsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('progress_updated_at')) {
      context.handle(
        _progressUpdatedAtMeta,
        progressUpdatedAt.isAcceptableOrUnknown(
          data['progress_updated_at']!,
          _progressUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {playlistLocalId, youtubeVideoId},
  ];
  @override
  YoutubeVideo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return YoutubeVideo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_updated_at'],
      ),
      playlistLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_local_id'],
      )!,
      youtubeVideoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}youtube_video_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      durationIso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duration_iso'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      ),
      lastPositionSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_position_seconds'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      progressUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}progress_updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $YoutubeVideosTable createAlias(String alias) {
    return $YoutubeVideosTable(attachedDatabase, alias);
  }
}

class YoutubeVideo extends DataClass implements Insertable<YoutubeVideo> {
  final int id;
  final String? serverId;

  /// Exact Supabase version used by the sync worker's CAS updates. Drift's
  /// DateTime columns are stored at SQLite second precision.
  final String? remoteUpdatedAt;
  final int playlistLocalId;
  final String youtubeVideoId;
  final String title;
  final String thumbnailUrl;
  final int position;
  final int durationSeconds;
  final String durationIso;
  final bool completed;
  final DateTime? watchedAt;
  final int lastPositionSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? progressUpdatedAt;
  final DateTime? deletedAt;
  const YoutubeVideo({
    required this.id,
    this.serverId,
    this.remoteUpdatedAt,
    required this.playlistLocalId,
    required this.youtubeVideoId,
    required this.title,
    required this.thumbnailUrl,
    required this.position,
    required this.durationSeconds,
    required this.durationIso,
    required this.completed,
    this.watchedAt,
    required this.lastPositionSeconds,
    required this.createdAt,
    required this.updatedAt,
    this.progressUpdatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt);
    }
    map['playlist_local_id'] = Variable<int>(playlistLocalId);
    map['youtube_video_id'] = Variable<String>(youtubeVideoId);
    map['title'] = Variable<String>(title);
    map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    map['position'] = Variable<int>(position);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['duration_iso'] = Variable<String>(durationIso);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || watchedAt != null) {
      map['watched_at'] = Variable<DateTime>(watchedAt);
    }
    map['last_position_seconds'] = Variable<int>(lastPositionSeconds);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || progressUpdatedAt != null) {
      map['progress_updated_at'] = Variable<DateTime>(progressUpdatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  YoutubeVideosCompanion toCompanion(bool nullToAbsent) {
    return YoutubeVideosCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
      playlistLocalId: Value(playlistLocalId),
      youtubeVideoId: Value(youtubeVideoId),
      title: Value(title),
      thumbnailUrl: Value(thumbnailUrl),
      position: Value(position),
      durationSeconds: Value(durationSeconds),
      durationIso: Value(durationIso),
      completed: Value(completed),
      watchedAt: watchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(watchedAt),
      lastPositionSeconds: Value(lastPositionSeconds),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      progressUpdatedAt: progressUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(progressUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory YoutubeVideo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return YoutubeVideo(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      remoteUpdatedAt: serializer.fromJson<String?>(json['remoteUpdatedAt']),
      playlistLocalId: serializer.fromJson<int>(json['playlistLocalId']),
      youtubeVideoId: serializer.fromJson<String>(json['youtubeVideoId']),
      title: serializer.fromJson<String>(json['title']),
      thumbnailUrl: serializer.fromJson<String>(json['thumbnailUrl']),
      position: serializer.fromJson<int>(json['position']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      durationIso: serializer.fromJson<String>(json['durationIso']),
      completed: serializer.fromJson<bool>(json['completed']),
      watchedAt: serializer.fromJson<DateTime?>(json['watchedAt']),
      lastPositionSeconds: serializer.fromJson<int>(
        json['lastPositionSeconds'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      progressUpdatedAt: serializer.fromJson<DateTime?>(
        json['progressUpdatedAt'],
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'remoteUpdatedAt': serializer.toJson<String?>(remoteUpdatedAt),
      'playlistLocalId': serializer.toJson<int>(playlistLocalId),
      'youtubeVideoId': serializer.toJson<String>(youtubeVideoId),
      'title': serializer.toJson<String>(title),
      'thumbnailUrl': serializer.toJson<String>(thumbnailUrl),
      'position': serializer.toJson<int>(position),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'durationIso': serializer.toJson<String>(durationIso),
      'completed': serializer.toJson<bool>(completed),
      'watchedAt': serializer.toJson<DateTime?>(watchedAt),
      'lastPositionSeconds': serializer.toJson<int>(lastPositionSeconds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'progressUpdatedAt': serializer.toJson<DateTime?>(progressUpdatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  YoutubeVideo copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    Value<String?> remoteUpdatedAt = const Value.absent(),
    int? playlistLocalId,
    String? youtubeVideoId,
    String? title,
    String? thumbnailUrl,
    int? position,
    int? durationSeconds,
    String? durationIso,
    bool? completed,
    Value<DateTime?> watchedAt = const Value.absent(),
    int? lastPositionSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> progressUpdatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => YoutubeVideo(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    remoteUpdatedAt: remoteUpdatedAt.present
        ? remoteUpdatedAt.value
        : this.remoteUpdatedAt,
    playlistLocalId: playlistLocalId ?? this.playlistLocalId,
    youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
    title: title ?? this.title,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    position: position ?? this.position,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    durationIso: durationIso ?? this.durationIso,
    completed: completed ?? this.completed,
    watchedAt: watchedAt.present ? watchedAt.value : this.watchedAt,
    lastPositionSeconds: lastPositionSeconds ?? this.lastPositionSeconds,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    progressUpdatedAt: progressUpdatedAt.present
        ? progressUpdatedAt.value
        : this.progressUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  YoutubeVideo copyWithCompanion(YoutubeVideosCompanion data) {
    return YoutubeVideo(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
      playlistLocalId: data.playlistLocalId.present
          ? data.playlistLocalId.value
          : this.playlistLocalId,
      youtubeVideoId: data.youtubeVideoId.present
          ? data.youtubeVideoId.value
          : this.youtubeVideoId,
      title: data.title.present ? data.title.value : this.title,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      position: data.position.present ? data.position.value : this.position,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      durationIso: data.durationIso.present
          ? data.durationIso.value
          : this.durationIso,
      completed: data.completed.present ? data.completed.value : this.completed,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
      lastPositionSeconds: data.lastPositionSeconds.present
          ? data.lastPositionSeconds.value
          : this.lastPositionSeconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      progressUpdatedAt: data.progressUpdatedAt.present
          ? data.progressUpdatedAt.value
          : this.progressUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('YoutubeVideo(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('playlistLocalId: $playlistLocalId, ')
          ..write('youtubeVideoId: $youtubeVideoId, ')
          ..write('title: $title, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('position: $position, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('durationIso: $durationIso, ')
          ..write('completed: $completed, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('lastPositionSeconds: $lastPositionSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('progressUpdatedAt: $progressUpdatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    remoteUpdatedAt,
    playlistLocalId,
    youtubeVideoId,
    title,
    thumbnailUrl,
    position,
    durationSeconds,
    durationIso,
    completed,
    watchedAt,
    lastPositionSeconds,
    createdAt,
    updatedAt,
    progressUpdatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is YoutubeVideo &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.playlistLocalId == this.playlistLocalId &&
          other.youtubeVideoId == this.youtubeVideoId &&
          other.title == this.title &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.position == this.position &&
          other.durationSeconds == this.durationSeconds &&
          other.durationIso == this.durationIso &&
          other.completed == this.completed &&
          other.watchedAt == this.watchedAt &&
          other.lastPositionSeconds == this.lastPositionSeconds &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.progressUpdatedAt == this.progressUpdatedAt &&
          other.deletedAt == this.deletedAt);
}

class YoutubeVideosCompanion extends UpdateCompanion<YoutubeVideo> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String?> remoteUpdatedAt;
  final Value<int> playlistLocalId;
  final Value<String> youtubeVideoId;
  final Value<String> title;
  final Value<String> thumbnailUrl;
  final Value<int> position;
  final Value<int> durationSeconds;
  final Value<String> durationIso;
  final Value<bool> completed;
  final Value<DateTime?> watchedAt;
  final Value<int> lastPositionSeconds;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> progressUpdatedAt;
  final Value<DateTime?> deletedAt;
  const YoutubeVideosCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.playlistLocalId = const Value.absent(),
    this.youtubeVideoId = const Value.absent(),
    this.title = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.position = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.durationIso = const Value.absent(),
    this.completed = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.lastPositionSeconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.progressUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  YoutubeVideosCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    required int playlistLocalId,
    required String youtubeVideoId,
    required String title,
    this.thumbnailUrl = const Value.absent(),
    required int position,
    this.durationSeconds = const Value.absent(),
    this.durationIso = const Value.absent(),
    this.completed = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.lastPositionSeconds = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.progressUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : playlistLocalId = Value(playlistLocalId),
       youtubeVideoId = Value(youtubeVideoId),
       title = Value(title),
       position = Value(position),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<YoutubeVideo> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? remoteUpdatedAt,
    Expression<int>? playlistLocalId,
    Expression<String>? youtubeVideoId,
    Expression<String>? title,
    Expression<String>? thumbnailUrl,
    Expression<int>? position,
    Expression<int>? durationSeconds,
    Expression<String>? durationIso,
    Expression<bool>? completed,
    Expression<DateTime>? watchedAt,
    Expression<int>? lastPositionSeconds,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? progressUpdatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (playlistLocalId != null) 'playlist_local_id': playlistLocalId,
      if (youtubeVideoId != null) 'youtube_video_id': youtubeVideoId,
      if (title != null) 'title': title,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (position != null) 'position': position,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (durationIso != null) 'duration_iso': durationIso,
      if (completed != null) 'completed': completed,
      if (watchedAt != null) 'watched_at': watchedAt,
      if (lastPositionSeconds != null)
        'last_position_seconds': lastPositionSeconds,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (progressUpdatedAt != null) 'progress_updated_at': progressUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  YoutubeVideosCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String?>? remoteUpdatedAt,
    Value<int>? playlistLocalId,
    Value<String>? youtubeVideoId,
    Value<String>? title,
    Value<String>? thumbnailUrl,
    Value<int>? position,
    Value<int>? durationSeconds,
    Value<String>? durationIso,
    Value<bool>? completed,
    Value<DateTime?>? watchedAt,
    Value<int>? lastPositionSeconds,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? progressUpdatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return YoutubeVideosCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      playlistLocalId: playlistLocalId ?? this.playlistLocalId,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      position: position ?? this.position,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      durationIso: durationIso ?? this.durationIso,
      completed: completed ?? this.completed,
      watchedAt: watchedAt ?? this.watchedAt,
      lastPositionSeconds: lastPositionSeconds ?? this.lastPositionSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progressUpdatedAt: progressUpdatedAt ?? this.progressUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt.value);
    }
    if (playlistLocalId.present) {
      map['playlist_local_id'] = Variable<int>(playlistLocalId.value);
    }
    if (youtubeVideoId.present) {
      map['youtube_video_id'] = Variable<String>(youtubeVideoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (durationIso.present) {
      map['duration_iso'] = Variable<String>(durationIso.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    if (lastPositionSeconds.present) {
      map['last_position_seconds'] = Variable<int>(lastPositionSeconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (progressUpdatedAt.present) {
      map['progress_updated_at'] = Variable<DateTime>(progressUpdatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('YoutubeVideosCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('playlistLocalId: $playlistLocalId, ')
          ..write('youtubeVideoId: $youtubeVideoId, ')
          ..write('title: $title, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('position: $position, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('durationIso: $durationIso, ')
          ..write('completed: $completed, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('lastPositionSeconds: $lastPositionSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('progressUpdatedAt: $progressUpdatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localAccountIdMeta = const VerificationMeta(
    'localAccountId',
  );
  @override
  late final GeneratedColumn<int> localAccountId = GeneratedColumn<int>(
    'local_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_accounts (id)',
    ),
  );
  static const VerificationMeta _authUserIdMeta = const VerificationMeta(
    'authUserId',
  );
  @override
  late final GeneratedColumn<String> authUserId = GeneratedColumn<String>(
    'auth_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localRowIdMeta = const VerificationMeta(
    'localRowId',
  );
  @override
  late final GeneratedColumn<int> localRowId = GeneratedColumn<int>(
    'local_row_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _dependencyRankMeta = const VerificationMeta(
    'dependencyRank',
  );
  @override
  late final GeneratedColumn<int> dependencyRank = GeneratedColumn<int>(
    'dependency_rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _baseRemoteUpdatedAtMeta =
      const VerificationMeta('baseRemoteUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> baseRemoteUpdatedAt =
      GeneratedColumn<DateTime>(
        'base_remote_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localAccountId,
    authUserId,
    entityType,
    localRowId,
    serverId,
    operation,
    state,
    dependencyRank,
    queuedAt,
    updatedAt,
    nextAttemptAt,
    attemptCount,
    baseRemoteUpdatedAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_account_id')) {
      context.handle(
        _localAccountIdMeta,
        localAccountId.isAcceptableOrUnknown(
          data['local_account_id']!,
          _localAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localAccountIdMeta);
    }
    if (data.containsKey('auth_user_id')) {
      context.handle(
        _authUserIdMeta,
        authUserId.isAcceptableOrUnknown(
          data['auth_user_id']!,
          _authUserIdMeta,
        ),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('local_row_id')) {
      context.handle(
        _localRowIdMeta,
        localRowId.isAcceptableOrUnknown(
          data['local_row_id']!,
          _localRowIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localRowIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('dependency_rank')) {
      context.handle(
        _dependencyRankMeta,
        dependencyRank.isAcceptableOrUnknown(
          data['dependency_rank']!,
          _dependencyRankMeta,
        ),
      );
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('base_remote_updated_at')) {
      context.handle(
        _baseRemoteUpdatedAtMeta,
        baseRemoteUpdatedAt.isAcceptableOrUnknown(
          data['base_remote_updated_at']!,
          _baseRemoteUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {localAccountId, entityType, localRowId},
  ];
  @override
  SyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_account_id'],
      )!,
      authUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_user_id'],
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      localRowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_row_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      dependencyRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dependency_rank'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      baseRemoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}base_remote_updated_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }
}

class SyncOutboxData extends DataClass implements Insertable<SyncOutboxData> {
  final int id;
  final int localAccountId;
  final String? authUserId;
  final String entityType;
  final int localRowId;
  final String? serverId;
  final String operation;
  final String state;
  final int dependencyRank;
  final DateTime queuedAt;

  /// Local mutation/version timestamp for the queued row. Queue chronology is
  /// represented by [queuedAt]; this value must not be replaced by retry
  /// bookkeeping timestamps.
  final DateTime updatedAt;
  final DateTime? nextAttemptAt;
  final int attemptCount;
  final DateTime? baseRemoteUpdatedAt;
  final String? lastError;
  const SyncOutboxData({
    required this.id,
    required this.localAccountId,
    this.authUserId,
    required this.entityType,
    required this.localRowId,
    this.serverId,
    required this.operation,
    required this.state,
    required this.dependencyRank,
    required this.queuedAt,
    required this.updatedAt,
    this.nextAttemptAt,
    required this.attemptCount,
    this.baseRemoteUpdatedAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_account_id'] = Variable<int>(localAccountId);
    if (!nullToAbsent || authUserId != null) {
      map['auth_user_id'] = Variable<String>(authUserId);
    }
    map['entity_type'] = Variable<String>(entityType);
    map['local_row_id'] = Variable<int>(localRowId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['operation'] = Variable<String>(operation);
    map['state'] = Variable<String>(state);
    map['dependency_rank'] = Variable<int>(dependencyRank);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || baseRemoteUpdatedAt != null) {
      map['base_remote_updated_at'] = Variable<DateTime>(baseRemoteUpdatedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      id: Value(id),
      localAccountId: Value(localAccountId),
      authUserId: authUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(authUserId),
      entityType: Value(entityType),
      localRowId: Value(localRowId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      operation: Value(operation),
      state: Value(state),
      dependencyRank: Value(dependencyRank),
      queuedAt: Value(queuedAt),
      updatedAt: Value(updatedAt),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      attemptCount: Value(attemptCount),
      baseRemoteUpdatedAt: baseRemoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(baseRemoteUpdatedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxData(
      id: serializer.fromJson<int>(json['id']),
      localAccountId: serializer.fromJson<int>(json['localAccountId']),
      authUserId: serializer.fromJson<String?>(json['authUserId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      localRowId: serializer.fromJson<int>(json['localRowId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      operation: serializer.fromJson<String>(json['operation']),
      state: serializer.fromJson<String>(json['state']),
      dependencyRank: serializer.fromJson<int>(json['dependencyRank']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      baseRemoteUpdatedAt: serializer.fromJson<DateTime?>(
        json['baseRemoteUpdatedAt'],
      ),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localAccountId': serializer.toJson<int>(localAccountId),
      'authUserId': serializer.toJson<String?>(authUserId),
      'entityType': serializer.toJson<String>(entityType),
      'localRowId': serializer.toJson<int>(localRowId),
      'serverId': serializer.toJson<String?>(serverId),
      'operation': serializer.toJson<String>(operation),
      'state': serializer.toJson<String>(state),
      'dependencyRank': serializer.toJson<int>(dependencyRank),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'baseRemoteUpdatedAt': serializer.toJson<DateTime?>(baseRemoteUpdatedAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncOutboxData copyWith({
    int? id,
    int? localAccountId,
    Value<String?> authUserId = const Value.absent(),
    String? entityType,
    int? localRowId,
    Value<String?> serverId = const Value.absent(),
    String? operation,
    String? state,
    int? dependencyRank,
    DateTime? queuedAt,
    DateTime? updatedAt,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    int? attemptCount,
    Value<DateTime?> baseRemoteUpdatedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncOutboxData(
    id: id ?? this.id,
    localAccountId: localAccountId ?? this.localAccountId,
    authUserId: authUserId.present ? authUserId.value : this.authUserId,
    entityType: entityType ?? this.entityType,
    localRowId: localRowId ?? this.localRowId,
    serverId: serverId.present ? serverId.value : this.serverId,
    operation: operation ?? this.operation,
    state: state ?? this.state,
    dependencyRank: dependencyRank ?? this.dependencyRank,
    queuedAt: queuedAt ?? this.queuedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    attemptCount: attemptCount ?? this.attemptCount,
    baseRemoteUpdatedAt: baseRemoteUpdatedAt.present
        ? baseRemoteUpdatedAt.value
        : this.baseRemoteUpdatedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncOutboxData copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxData(
      id: data.id.present ? data.id.value : this.id,
      localAccountId: data.localAccountId.present
          ? data.localAccountId.value
          : this.localAccountId,
      authUserId: data.authUserId.present
          ? data.authUserId.value
          : this.authUserId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      localRowId: data.localRowId.present
          ? data.localRowId.value
          : this.localRowId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      operation: data.operation.present ? data.operation.value : this.operation,
      state: data.state.present ? data.state.value : this.state,
      dependencyRank: data.dependencyRank.present
          ? data.dependencyRank.value
          : this.dependencyRank,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      baseRemoteUpdatedAt: data.baseRemoteUpdatedAt.present
          ? data.baseRemoteUpdatedAt.value
          : this.baseRemoteUpdatedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxData(')
          ..write('id: $id, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('authUserId: $authUserId, ')
          ..write('entityType: $entityType, ')
          ..write('localRowId: $localRowId, ')
          ..write('serverId: $serverId, ')
          ..write('operation: $operation, ')
          ..write('state: $state, ')
          ..write('dependencyRank: $dependencyRank, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('baseRemoteUpdatedAt: $baseRemoteUpdatedAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localAccountId,
    authUserId,
    entityType,
    localRowId,
    serverId,
    operation,
    state,
    dependencyRank,
    queuedAt,
    updatedAt,
    nextAttemptAt,
    attemptCount,
    baseRemoteUpdatedAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxData &&
          other.id == this.id &&
          other.localAccountId == this.localAccountId &&
          other.authUserId == this.authUserId &&
          other.entityType == this.entityType &&
          other.localRowId == this.localRowId &&
          other.serverId == this.serverId &&
          other.operation == this.operation &&
          other.state == this.state &&
          other.dependencyRank == this.dependencyRank &&
          other.queuedAt == this.queuedAt &&
          other.updatedAt == this.updatedAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.attemptCount == this.attemptCount &&
          other.baseRemoteUpdatedAt == this.baseRemoteUpdatedAt &&
          other.lastError == this.lastError);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxData> {
  final Value<int> id;
  final Value<int> localAccountId;
  final Value<String?> authUserId;
  final Value<String> entityType;
  final Value<int> localRowId;
  final Value<String?> serverId;
  final Value<String> operation;
  final Value<String> state;
  final Value<int> dependencyRank;
  final Value<DateTime> queuedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> nextAttemptAt;
  final Value<int> attemptCount;
  final Value<DateTime?> baseRemoteUpdatedAt;
  final Value<String?> lastError;
  const SyncOutboxCompanion({
    this.id = const Value.absent(),
    this.localAccountId = const Value.absent(),
    this.authUserId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.localRowId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.operation = const Value.absent(),
    this.state = const Value.absent(),
    this.dependencyRank = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.baseRemoteUpdatedAt = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    this.id = const Value.absent(),
    required int localAccountId,
    this.authUserId = const Value.absent(),
    required String entityType,
    required int localRowId,
    this.serverId = const Value.absent(),
    required String operation,
    this.state = const Value.absent(),
    this.dependencyRank = const Value.absent(),
    required DateTime queuedAt,
    this.updatedAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.baseRemoteUpdatedAt = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : localAccountId = Value(localAccountId),
       entityType = Value(entityType),
       localRowId = Value(localRowId),
       operation = Value(operation),
       queuedAt = Value(queuedAt);
  static Insertable<SyncOutboxData> custom({
    Expression<int>? id,
    Expression<int>? localAccountId,
    Expression<String>? authUserId,
    Expression<String>? entityType,
    Expression<int>? localRowId,
    Expression<String>? serverId,
    Expression<String>? operation,
    Expression<String>? state,
    Expression<int>? dependencyRank,
    Expression<DateTime>? queuedAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? nextAttemptAt,
    Expression<int>? attemptCount,
    Expression<DateTime>? baseRemoteUpdatedAt,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localAccountId != null) 'local_account_id': localAccountId,
      if (authUserId != null) 'auth_user_id': authUserId,
      if (entityType != null) 'entity_type': entityType,
      if (localRowId != null) 'local_row_id': localRowId,
      if (serverId != null) 'server_id': serverId,
      if (operation != null) 'operation': operation,
      if (state != null) 'state': state,
      if (dependencyRank != null) 'dependency_rank': dependencyRank,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (baseRemoteUpdatedAt != null)
        'base_remote_updated_at': baseRemoteUpdatedAt,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<int>? id,
    Value<int>? localAccountId,
    Value<String?>? authUserId,
    Value<String>? entityType,
    Value<int>? localRowId,
    Value<String?>? serverId,
    Value<String>? operation,
    Value<String>? state,
    Value<int>? dependencyRank,
    Value<DateTime>? queuedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? nextAttemptAt,
    Value<int>? attemptCount,
    Value<DateTime?>? baseRemoteUpdatedAt,
    Value<String?>? lastError,
  }) {
    return SyncOutboxCompanion(
      id: id ?? this.id,
      localAccountId: localAccountId ?? this.localAccountId,
      authUserId: authUserId ?? this.authUserId,
      entityType: entityType ?? this.entityType,
      localRowId: localRowId ?? this.localRowId,
      serverId: serverId ?? this.serverId,
      operation: operation ?? this.operation,
      state: state ?? this.state,
      dependencyRank: dependencyRank ?? this.dependencyRank,
      queuedAt: queuedAt ?? this.queuedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      baseRemoteUpdatedAt: baseRemoteUpdatedAt ?? this.baseRemoteUpdatedAt,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localAccountId.present) {
      map['local_account_id'] = Variable<int>(localAccountId.value);
    }
    if (authUserId.present) {
      map['auth_user_id'] = Variable<String>(authUserId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (localRowId.present) {
      map['local_row_id'] = Variable<int>(localRowId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (dependencyRank.present) {
      map['dependency_rank'] = Variable<int>(dependencyRank.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (baseRemoteUpdatedAt.present) {
      map['base_remote_updated_at'] = Variable<DateTime>(
        baseRemoteUpdatedAt.value,
      );
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('id: $id, ')
          ..write('localAccountId: $localAccountId, ')
          ..write('authUserId: $authUserId, ')
          ..write('entityType: $entityType, ')
          ..write('localRowId: $localRowId, ')
          ..write('serverId: $serverId, ')
          ..write('operation: $operation, ')
          ..write('state: $state, ')
          ..write('dependencyRank: $dependencyRank, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('baseRemoteUpdatedAt: $baseRemoteUpdatedAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalAccountsTable localAccounts = $LocalAccountsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $MoneyTransactionsTable moneyTransactions =
      $MoneyTransactionsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $ProfileDataTable profileData = $ProfileDataTable(this);
  late final $TransactionDetectionEventsTable transactionDetectionEvents =
      $TransactionDetectionEventsTable(this);
  late final $TransactionCandidatesTable transactionCandidates =
      $TransactionCandidatesTable(this);
  late final $MerchantCategoryRulesTable merchantCategoryRules =
      $MerchantCategoryRulesTable(this);
  late final $YoutubePlaylistsTable youtubePlaylists = $YoutubePlaylistsTable(
    this,
  );
  late final $YoutubeVideosTable youtubeVideos = $YoutubeVideosTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final Index idxTasksAccountPlannerDate = Index(
    'idx_tasks_account_planner_date',
    'CREATE INDEX idx_tasks_account_planner_date ON tasks (local_account_id, is_planner_entry, local_date)',
  );
  late final Index idxTasksAccountTodoCompleted = Index(
    'idx_tasks_account_todo_completed',
    'CREATE INDEX idx_tasks_account_todo_completed ON tasks (local_account_id, is_planner_entry, is_completed, completed_at)',
  );
  late final Index idxTasksCreatedAt = Index(
    'idx_tasks_created_at',
    'CREATE INDEX idx_tasks_created_at ON tasks (local_account_id, is_planner_entry, created_at)',
  );
  late final Index idxMoneyAccountTypeDate = Index(
    'idx_money_account_type_date',
    'CREATE INDEX idx_money_account_type_date ON money_transactions (local_account_id, type, occurred_on)',
  );
  late final Index idxMoneyAccountDate = Index(
    'idx_money_account_date',
    'CREATE INDEX idx_money_account_date ON money_transactions (local_account_id, occurred_on)',
  );
  late final Index idxNotesAccountUpdated = Index(
    'idx_notes_account_updated',
    'CREATE INDEX idx_notes_account_updated ON notes (local_account_id, updated_at)',
  );
  late final Index idxRemindersAccountEnabledDue = Index(
    'idx_reminders_account_enabled_due',
    'CREATE INDEX idx_reminders_account_enabled_due ON reminders (local_account_id, is_enabled, due_at)',
  );
  late final Index idxRemindersTaskId = Index(
    'idx_reminders_task_id',
    'CREATE INDEX idx_reminders_task_id ON reminders (task_id)',
  );
  late final Index idxLocalAccountsActive = Index(
    'idx_local_accounts_active',
    'CREATE INDEX idx_local_accounts_active ON local_accounts (is_active)',
  );
  late final Index idxDetectionEventsAccountExpires = Index(
    'idx_detection_events_account_expires',
    'CREATE INDEX idx_detection_events_account_expires ON transaction_detection_events (local_account_id, expires_at)',
  );
  late final Index idxCandidatesAccountStatusDate = Index(
    'idx_candidates_account_status_date',
    'CREATE INDEX idx_candidates_account_status_date ON transaction_candidates (local_account_id, status, occurred_at)',
  );
  late final Index idxCandidatesExpiresAt = Index(
    'idx_candidates_expires_at',
    'CREATE INDEX idx_candidates_expires_at ON transaction_candidates (expires_at)',
  );
  late final Index idxMerchantRulesAccountIdentity = Index(
    'idx_merchant_rules_account_identity',
    'CREATE INDEX idx_merchant_rules_account_identity ON merchant_category_rules (local_account_id, merchant_identity)',
  );
  late final Index idxPlaylistsAccountUpdated = Index(
    'idx_playlists_account_updated',
    'CREATE INDEX idx_playlists_account_updated ON youtube_playlists (local_account_id, updated_at)',
  );
  late final Index idxVideosPlaylistCompleted = Index(
    'idx_videos_playlist_completed',
    'CREATE INDEX idx_videos_playlist_completed ON youtube_videos (playlist_local_id, completed)',
  );
  late final Index idxVideosPlaylistPosition = Index(
    'idx_videos_playlist_position',
    'CREATE INDEX idx_videos_playlist_position ON youtube_videos (playlist_local_id, position)',
  );
  late final Index idxSyncOutboxReady = Index(
    'idx_sync_outbox_ready',
    'CREATE INDEX idx_sync_outbox_ready ON sync_outbox (local_account_id, state, next_attempt_at, dependency_rank)',
  );
  late final Index idxSyncOutboxServerId = Index(
    'idx_sync_outbox_server_id',
    'CREATE INDEX idx_sync_outbox_server_id ON sync_outbox (server_id)',
  );
  late final TaskDao taskDao = TaskDao(this as AppDatabase);
  late final MoneyDao moneyDao = MoneyDao(this as AppDatabase);
  late final ReminderDao reminderDao = ReminderDao(this as AppDatabase);
  late final ProfileDao profileDao = ProfileDao(this as AppDatabase);
  late final NoteDao noteDao = NoteDao(this as AppDatabase);
  late final TransactionDetectionDao transactionDetectionDao =
      TransactionDetectionDao(this as AppDatabase);
  late final YoutubePlaylistDao youtubePlaylistDao = YoutubePlaylistDao(
    this as AppDatabase,
  );
  late final LocalAccountDao localAccountDao = LocalAccountDao(
    this as AppDatabase,
  );
  late final SyncOutboxDao syncOutboxDao = SyncOutboxDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localAccounts,
    tasks,
    moneyTransactions,
    notes,
    reminders,
    profileData,
    transactionDetectionEvents,
    transactionCandidates,
    merchantCategoryRules,
    youtubePlaylists,
    youtubeVideos,
    syncOutbox,
    idxTasksAccountPlannerDate,
    idxTasksAccountTodoCompleted,
    idxTasksCreatedAt,
    idxMoneyAccountTypeDate,
    idxMoneyAccountDate,
    idxNotesAccountUpdated,
    idxRemindersAccountEnabledDue,
    idxRemindersTaskId,
    idxLocalAccountsActive,
    idxDetectionEventsAccountExpires,
    idxCandidatesAccountStatusDate,
    idxCandidatesExpiresAt,
    idxMerchantRulesAccountIdentity,
    idxPlaylistsAccountUpdated,
    idxVideosPlaylistCompleted,
    idxVideosPlaylistPosition,
    idxSyncOutboxReady,
    idxSyncOutboxServerId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reminders', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$LocalAccountsTableCreateCompanionBuilder =
    LocalAccountsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      required String authProvider,
      Value<String?> authUserId,
      Value<String?> email,
      Value<String> displayName,
      Value<String?> avatarUrl,
      Value<bool> isActive,
      required DateTime createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastLoginAt,
      Value<DateTime?> deletedAt,
    });
typedef $$LocalAccountsTableUpdateCompanionBuilder =
    LocalAccountsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String> authProvider,
      Value<String?> authUserId,
      Value<String?> email,
      Value<String> displayName,
      Value<String?> avatarUrl,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastLoginAt,
      Value<DateTime?> deletedAt,
    });

final class $$LocalAccountsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalAccountsTable, LocalAccount> {
  $$LocalAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'local_accounts__id__tasks__local_account_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.localAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MoneyTransactionsTable, List<MoneyTransaction>>
  _moneyTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.moneyTransactions,
        aliasName: 'local_accounts__id__money_transactions__local_account_id',
      );

  $$MoneyTransactionsTableProcessedTableManager get moneyTransactionsRefs {
    final manager = $$MoneyTransactionsTableTableManager(
      $_db,
      $_db.moneyTransactions,
    ).filter((f) => f.localAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _moneyTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NotesTable, List<Note>> _notesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.notes,
    aliasName: 'local_accounts__id__notes__local_account_id',
  );

  $$NotesTableProcessedTableManager get notesRefs {
    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.localAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RemindersTable, List<Reminder>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: 'local_accounts__id__reminders__local_account_id',
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.localAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProfileDataTable, List<ProfileDataData>>
  _profileDataRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.profileData,
    aliasName: 'local_accounts__id__profile_data__local_account_id',
  );

  $$ProfileDataTableProcessedTableManager get profileDataRefs {
    final manager = $$ProfileDataTableTableManager(
      $_db,
      $_db.profileData,
    ).filter((f) => f.localAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_profileDataRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TransactionDetectionEventsTable,
    List<TransactionDetectionEvent>
  >
  _transactionDetectionEventsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.transactionDetectionEvents,
    aliasName:
        'local_accounts__id__transaction_detection_events__local_account_id',
  );

  $$TransactionDetectionEventsTableProcessedTableManager
  get transactionDetectionEventsRefs {
    final manager = $$TransactionDetectionEventsTableTableManager(
      $_db,
      $_db.transactionDetectionEvents,
    ).filter((f) => f.localAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionDetectionEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TransactionCandidatesTable,
    List<TransactionCandidate>
  >
  _transactionCandidatesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionCandidates,
        aliasName:
            'local_accounts__id__transaction_candidates__local_account_id',
      );

  $$TransactionCandidatesTableProcessedTableManager
  get transactionCandidatesRefs {
    final manager = $$TransactionCandidatesTableTableManager(
      $_db,
      $_db.transactionCandidates,
    ).filter((f) => f.localAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionCandidatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MerchantCategoryRulesTable,
    List<MerchantCategoryRule>
  >
  _merchantCategoryRulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.merchantCategoryRules,
        aliasName:
            'local_accounts__id__merchant_category_rules__local_account_id',
      );

  $$MerchantCategoryRulesTableProcessedTableManager
  get merchantCategoryRulesRefs {
    final manager = $$MerchantCategoryRulesTableTableManager(
      $_db,
      $_db.merchantCategoryRules,
    ).filter((f) => f.localAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _merchantCategoryRulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$YoutubePlaylistsTable, List<YoutubePlaylist>>
  _youtubePlaylistsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.youtubePlaylists,
    aliasName: 'local_accounts__id__youtube_playlists__local_account_id',
  );

  $$YoutubePlaylistsTableProcessedTableManager get youtubePlaylistsRefs {
    final manager = $$YoutubePlaylistsTableTableManager(
      $_db,
      $_db.youtubePlaylists,
    ).filter((f) => f.localAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _youtubePlaylistsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncOutboxTable, List<SyncOutboxData>>
  _syncOutboxRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syncOutbox,
    aliasName: 'local_accounts__id__sync_outbox__local_account_id',
  );

  $$SyncOutboxTableProcessedTableManager get syncOutboxRefs {
    final manager = $$SyncOutboxTableTableManager(
      $_db,
      $_db.syncOutbox,
    ).filter((f) => f.localAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_syncOutboxRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authProvider => $composableBuilder(
    column: $table.authProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> moneyTransactionsRefs(
    Expression<bool> Function($$MoneyTransactionsTableFilterComposer f) f,
  ) {
    final $$MoneyTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.moneyTransactions,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoneyTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.moneyTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notesRefs(
    Expression<bool> Function($$NotesTableFilterComposer f) f,
  ) {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> profileDataRefs(
    Expression<bool> Function($$ProfileDataTableFilterComposer f) f,
  ) {
    final $$ProfileDataTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileData,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileDataTableFilterComposer(
            $db: $db,
            $table: $db.profileData,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionDetectionEventsRefs(
    Expression<bool> Function($$TransactionDetectionEventsTableFilterComposer f)
    f,
  ) {
    final $$TransactionDetectionEventsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionDetectionEvents,
          getReferencedColumn: (t) => t.localAccountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionDetectionEventsTableFilterComposer(
                $db: $db,
                $table: $db.transactionDetectionEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> transactionCandidatesRefs(
    Expression<bool> Function($$TransactionCandidatesTableFilterComposer f) f,
  ) {
    final $$TransactionCandidatesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionCandidates,
          getReferencedColumn: (t) => t.localAccountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCandidatesTableFilterComposer(
                $db: $db,
                $table: $db.transactionCandidates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> merchantCategoryRulesRefs(
    Expression<bool> Function($$MerchantCategoryRulesTableFilterComposer f) f,
  ) {
    final $$MerchantCategoryRulesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.merchantCategoryRules,
          getReferencedColumn: (t) => t.localAccountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MerchantCategoryRulesTableFilterComposer(
                $db: $db,
                $table: $db.merchantCategoryRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> youtubePlaylistsRefs(
    Expression<bool> Function($$YoutubePlaylistsTableFilterComposer f) f,
  ) {
    final $$YoutubePlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.youtubePlaylists,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$YoutubePlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.youtubePlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncOutboxRefs(
    Expression<bool> Function($$SyncOutboxTableFilterComposer f) f,
  ) {
    final $$SyncOutboxTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncOutbox,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncOutboxTableFilterComposer(
            $db: $db,
            $table: $db.syncOutbox,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authProvider => $composableBuilder(
    column: $table.authProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get authProvider => $composableBuilder(
    column: $table.authProvider,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> moneyTransactionsRefs<T extends Object>(
    Expression<T> Function($$MoneyTransactionsTableAnnotationComposer a) f,
  ) {
    final $$MoneyTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.moneyTransactions,
          getReferencedColumn: (t) => t.localAccountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MoneyTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.moneyTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> notesRefs<T extends Object>(
    Expression<T> Function($$NotesTableAnnotationComposer a) f,
  ) {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> profileDataRefs<T extends Object>(
    Expression<T> Function($$ProfileDataTableAnnotationComposer a) f,
  ) {
    final $$ProfileDataTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileData,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileDataTableAnnotationComposer(
            $db: $db,
            $table: $db.profileData,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionDetectionEventsRefs<T extends Object>(
    Expression<T> Function(
      $$TransactionDetectionEventsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$TransactionDetectionEventsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionDetectionEvents,
          getReferencedColumn: (t) => t.localAccountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionDetectionEventsTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionDetectionEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> transactionCandidatesRefs<T extends Object>(
    Expression<T> Function($$TransactionCandidatesTableAnnotationComposer a) f,
  ) {
    final $$TransactionCandidatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionCandidates,
          getReferencedColumn: (t) => t.localAccountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCandidatesTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionCandidates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> merchantCategoryRulesRefs<T extends Object>(
    Expression<T> Function($$MerchantCategoryRulesTableAnnotationComposer a) f,
  ) {
    final $$MerchantCategoryRulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.merchantCategoryRules,
          getReferencedColumn: (t) => t.localAccountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MerchantCategoryRulesTableAnnotationComposer(
                $db: $db,
                $table: $db.merchantCategoryRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> youtubePlaylistsRefs<T extends Object>(
    Expression<T> Function($$YoutubePlaylistsTableAnnotationComposer a) f,
  ) {
    final $$YoutubePlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.youtubePlaylists,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$YoutubePlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.youtubePlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncOutboxRefs<T extends Object>(
    Expression<T> Function($$SyncOutboxTableAnnotationComposer a) f,
  ) {
    final $$SyncOutboxTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncOutbox,
      getReferencedColumn: (t) => t.localAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncOutboxTableAnnotationComposer(
            $db: $db,
            $table: $db.syncOutbox,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAccountsTable,
          LocalAccount,
          $$LocalAccountsTableFilterComposer,
          $$LocalAccountsTableOrderingComposer,
          $$LocalAccountsTableAnnotationComposer,
          $$LocalAccountsTableCreateCompanionBuilder,
          $$LocalAccountsTableUpdateCompanionBuilder,
          (LocalAccount, $$LocalAccountsTableReferences),
          LocalAccount,
          PrefetchHooks Function({
            bool tasksRefs,
            bool moneyTransactionsRefs,
            bool notesRefs,
            bool remindersRefs,
            bool profileDataRefs,
            bool transactionDetectionEventsRefs,
            bool transactionCandidatesRefs,
            bool merchantCategoryRulesRefs,
            bool youtubePlaylistsRefs,
            bool syncOutboxRefs,
          })
        > {
  $$LocalAccountsTableTableManager(_$AppDatabase db, $LocalAccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> authProvider = const Value.absent(),
                Value<String?> authUserId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastLoginAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => LocalAccountsCompanion(
                id: id,
                serverId: serverId,
                authProvider: authProvider,
                authUserId: authUserId,
                email: email,
                displayName: displayName,
                avatarUrl: avatarUrl,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastLoginAt: lastLoginAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String authProvider,
                Value<String?> authUserId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastLoginAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => LocalAccountsCompanion.insert(
                id: id,
                serverId: serverId,
                authProvider: authProvider,
                authUserId: authUserId,
                email: email,
                displayName: displayName,
                avatarUrl: avatarUrl,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastLoginAt: lastLoginAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalAccountsTable, LocalAccount>(table),
                  $$LocalAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                tasksRefs = false,
                moneyTransactionsRefs = false,
                notesRefs = false,
                remindersRefs = false,
                profileDataRefs = false,
                transactionDetectionEventsRefs = false,
                transactionCandidatesRefs = false,
                merchantCategoryRulesRefs = false,
                youtubePlaylistsRefs = false,
                syncOutboxRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tasksRefs) db.tasks,
                    if (moneyTransactionsRefs) db.moneyTransactions,
                    if (notesRefs) db.notes,
                    if (remindersRefs) db.reminders,
                    if (profileDataRefs) db.profileData,
                    if (transactionDetectionEventsRefs)
                      db.transactionDetectionEvents,
                    if (transactionCandidatesRefs) db.transactionCandidates,
                    if (merchantCategoryRulesRefs) db.merchantCategoryRules,
                    if (youtubePlaylistsRefs) db.youtubePlaylists,
                    if (syncOutboxRefs) db.syncOutbox,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tasksRefs)
                        await $_getPrefetchedData<
                          LocalAccount,
                          $LocalAccountsTable,
                          Task
                        >(
                          currentTable: table,
                          referencedTable: $$LocalAccountsTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).tasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (moneyTransactionsRefs)
                        await $_getPrefetchedData<
                          LocalAccount,
                          $LocalAccountsTable,
                          MoneyTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$LocalAccountsTableReferences
                              ._moneyTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).moneyTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (notesRefs)
                        await $_getPrefetchedData<
                          LocalAccount,
                          $LocalAccountsTable,
                          Note
                        >(
                          currentTable: table,
                          referencedTable: $$LocalAccountsTableReferences
                              ._notesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).notesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (remindersRefs)
                        await $_getPrefetchedData<
                          LocalAccount,
                          $LocalAccountsTable,
                          Reminder
                        >(
                          currentTable: table,
                          referencedTable: $$LocalAccountsTableReferences
                              ._remindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).remindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (profileDataRefs)
                        await $_getPrefetchedData<
                          LocalAccount,
                          $LocalAccountsTable,
                          ProfileDataData
                        >(
                          currentTable: table,
                          referencedTable: $$LocalAccountsTableReferences
                              ._profileDataRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).profileDataRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionDetectionEventsRefs)
                        await $_getPrefetchedData<
                          LocalAccount,
                          $LocalAccountsTable,
                          TransactionDetectionEvent
                        >(
                          currentTable: table,
                          referencedTable: $$LocalAccountsTableReferences
                              ._transactionDetectionEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionDetectionEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionCandidatesRefs)
                        await $_getPrefetchedData<
                          LocalAccount,
                          $LocalAccountsTable,
                          TransactionCandidate
                        >(
                          currentTable: table,
                          referencedTable: $$LocalAccountsTableReferences
                              ._transactionCandidatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionCandidatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (merchantCategoryRulesRefs)
                        await $_getPrefetchedData<
                          LocalAccount,
                          $LocalAccountsTable,
                          MerchantCategoryRule
                        >(
                          currentTable: table,
                          referencedTable: $$LocalAccountsTableReferences
                              ._merchantCategoryRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).merchantCategoryRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (youtubePlaylistsRefs)
                        await $_getPrefetchedData<
                          LocalAccount,
                          $LocalAccountsTable,
                          YoutubePlaylist
                        >(
                          currentTable: table,
                          referencedTable: $$LocalAccountsTableReferences
                              ._youtubePlaylistsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).youtubePlaylistsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncOutboxRefs)
                        await $_getPrefetchedData<
                          LocalAccount,
                          $LocalAccountsTable,
                          SyncOutboxData
                        >(
                          currentTable: table,
                          referencedTable: $$LocalAccountsTableReferences
                              ._syncOutboxRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncOutboxRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAccountsTable,
      LocalAccount,
      $$LocalAccountsTableFilterComposer,
      $$LocalAccountsTableOrderingComposer,
      $$LocalAccountsTableAnnotationComposer,
      $$LocalAccountsTableCreateCompanionBuilder,
      $$LocalAccountsTableUpdateCompanionBuilder,
      (LocalAccount, $$LocalAccountsTableReferences),
      LocalAccount,
      PrefetchHooks Function({
        bool tasksRefs,
        bool moneyTransactionsRefs,
        bool notesRefs,
        bool remindersRefs,
        bool profileDataRefs,
        bool transactionDetectionEventsRefs,
        bool transactionCandidatesRefs,
        bool merchantCategoryRulesRefs,
        bool youtubePlaylistsRefs,
        bool syncOutboxRefs,
      })
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<String?> serverId,
  Value<String?> remoteUpdatedAt,
  Value<int> localAccountId,
  required String title,
  Value<String?> description,
  required String category,
  Value<bool> isPlannerEntry,
  required DateTime dueDate,
  Value<String?> dueTime,
  Value<bool> isCompleted,
  Value<DateTime?> completedAt,
  required DateTime createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<String?> serverId,
  Value<String?> remoteUpdatedAt,
  Value<int> localAccountId,
  Value<String> title,
  Value<String?> description,
  Value<String> category,
  Value<bool> isPlannerEntry,
  Value<DateTime> dueDate,
  Value<String?> dueTime,
  Value<bool> isCompleted,
  Value<DateTime?> completedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalAccountsTable _localAccountIdTable(_$AppDatabase db) => db
      .localAccounts
      .createAlias('tasks__local_account_id__local_accounts__id');

  $$LocalAccountsTableProcessedTableManager get localAccountId {
    final $_column = $_itemColumn<int>('local_account_id')!;

    final manager = $$LocalAccountsTableTableManager(
      $_db,
      $_db.localAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RemindersTable, List<Reminder>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: 'tasks__id__reminders__task_id',
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPlannerEntry => $composableBuilder(
    column: $table.isPlannerEntry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalAccountsTableFilterComposer get localAccountId {
    final $$LocalAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableFilterComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPlannerEntry => $composableBuilder(
    column: $table.isPlannerEntry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalAccountsTableOrderingComposer get localAccountId {
    final $$LocalAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isPlannerEntry => $composableBuilder(
    column: $table.isPlannerEntry,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get dueTime =>
      $composableBuilder(column: $table.dueTime, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$LocalAccountsTableAnnotationComposer get localAccountId {
    final $$LocalAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({bool localAccountId, bool remindersRefs})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> remoteUpdatedAt = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> isPlannerEntry = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<String?> dueTime = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                serverId: serverId,
                remoteUpdatedAt: remoteUpdatedAt,
                localAccountId: localAccountId,
                title: title,
                description: description,
                category: category,
                isPlannerEntry: isPlannerEntry,
                dueDate: dueDate,
                dueTime: dueTime,
                isCompleted: isCompleted,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> remoteUpdatedAt = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required String category,
                Value<bool> isPlannerEntry = const Value.absent(),
                required DateTime dueDate,
                Value<String?> dueTime = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                serverId: serverId,
                remoteUpdatedAt: remoteUpdatedAt,
                localAccountId: localAccountId,
                title: title,
                description: description,
                category: category,
                isPlannerEntry: isPlannerEntry,
                dueDate: dueDate,
                dueTime: dueTime,
                isCompleted: isCompleted,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({localAccountId = false, remindersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (remindersRefs) db.reminders],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (localAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.localAccountId,
                            referencedTable: $$TasksTableReferences
                                ._localAccountIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._localAccountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (remindersRefs)
                        await $_getPrefetchedData<Task, $TasksTable, Reminder>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._remindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).remindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({bool localAccountId, bool remindersRefs})
    >;
typedef $$MoneyTransactionsTableCreateCompanionBuilder =
    MoneyTransactionsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<int> localAccountId,
      required String type,
      required int amount,
      Value<String> currency,
      required String category,
      Value<String?> note,
      Value<String?> counterparty,
      required DateTime date,
      Value<String> source,
      Value<String?> detectionCandidateId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$MoneyTransactionsTableUpdateCompanionBuilder =
    MoneyTransactionsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<int> localAccountId,
      Value<String> type,
      Value<int> amount,
      Value<String> currency,
      Value<String> category,
      Value<String?> note,
      Value<String?> counterparty,
      Value<DateTime> date,
      Value<String> source,
      Value<String?> detectionCandidateId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$MoneyTransactionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MoneyTransactionsTable,
          MoneyTransaction
        > {
  $$MoneyTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalAccountsTable _localAccountIdTable(_$AppDatabase db) => db
      .localAccounts
      .createAlias('money_transactions__local_account_id__local_accounts__id');

  $$LocalAccountsTableProcessedTableManager get localAccountId {
    final $_column = $_itemColumn<int>('local_account_id')!;

    final manager = $$LocalAccountsTableTableManager(
      $_db,
      $_db.localAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MoneyTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $MoneyTransactionsTable> {
  $$MoneyTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detectionCandidateId => $composableBuilder(
    column: $table.detectionCandidateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalAccountsTableFilterComposer get localAccountId {
    final $$LocalAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableFilterComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoneyTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $MoneyTransactionsTable> {
  $$MoneyTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detectionCandidateId => $composableBuilder(
    column: $table.detectionCandidateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalAccountsTableOrderingComposer get localAccountId {
    final $$LocalAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoneyTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoneyTransactionsTable> {
  $$MoneyTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get detectionCandidateId => $composableBuilder(
    column: $table.detectionCandidateId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$LocalAccountsTableAnnotationComposer get localAccountId {
    final $$LocalAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoneyTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoneyTransactionsTable,
          MoneyTransaction,
          $$MoneyTransactionsTableFilterComposer,
          $$MoneyTransactionsTableOrderingComposer,
          $$MoneyTransactionsTableAnnotationComposer,
          $$MoneyTransactionsTableCreateCompanionBuilder,
          $$MoneyTransactionsTableUpdateCompanionBuilder,
          (MoneyTransaction, $$MoneyTransactionsTableReferences),
          MoneyTransaction,
          PrefetchHooks Function({bool localAccountId})
        > {
  $$MoneyTransactionsTableTableManager(
    _$AppDatabase db,
    $MoneyTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoneyTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoneyTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoneyTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> detectionCandidateId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => MoneyTransactionsCompanion(
                id: id,
                serverId: serverId,
                localAccountId: localAccountId,
                type: type,
                amount: amount,
                currency: currency,
                category: category,
                note: note,
                counterparty: counterparty,
                date: date,
                source: source,
                detectionCandidateId: detectionCandidateId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                required String type,
                required int amount,
                Value<String> currency = const Value.absent(),
                required String category,
                Value<String?> note = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                required DateTime date,
                Value<String> source = const Value.absent(),
                Value<String?> detectionCandidateId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => MoneyTransactionsCompanion.insert(
                id: id,
                serverId: serverId,
                localAccountId: localAccountId,
                type: type,
                amount: amount,
                currency: currency,
                category: category,
                note: note,
                counterparty: counterparty,
                date: date,
                source: source,
                detectionCandidateId: detectionCandidateId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MoneyTransactionsTable, MoneyTransaction>(table),
                  $$MoneyTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localAccountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localAccountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localAccountId,
                        referencedTable: $$MoneyTransactionsTableReferences
                            ._localAccountIdTable(db),
                        referencedColumn: $$MoneyTransactionsTableReferences
                            ._localAccountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MoneyTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoneyTransactionsTable,
      MoneyTransaction,
      $$MoneyTransactionsTableFilterComposer,
      $$MoneyTransactionsTableOrderingComposer,
      $$MoneyTransactionsTableAnnotationComposer,
      $$MoneyTransactionsTableCreateCompanionBuilder,
      $$MoneyTransactionsTableUpdateCompanionBuilder,
      (MoneyTransaction, $$MoneyTransactionsTableReferences),
      MoneyTransaction,
      PrefetchHooks Function({bool localAccountId})
    >;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<String?> serverId,
  Value<int> localAccountId,
  required String title,
  required String content,
  required String category,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<String?> serverId,
  Value<int> localAccountId,
  Value<String> title,
  Value<String> content,
  Value<String> category,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

final class $$NotesTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTable, Note> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalAccountsTable _localAccountIdTable(_$AppDatabase db) => db
      .localAccounts
      .createAlias('notes__local_account_id__local_accounts__id');

  $$LocalAccountsTableProcessedTableManager get localAccountId {
    final $_column = $_itemColumn<int>('local_account_id')!;

    final manager = $$LocalAccountsTableTableManager(
      $_db,
      $_db.localAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalAccountsTableFilterComposer get localAccountId {
    final $$LocalAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableFilterComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalAccountsTableOrderingComposer get localAccountId {
    final $$LocalAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$LocalAccountsTableAnnotationComposer get localAccountId {
    final $$LocalAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, $$NotesTableReferences),
          Note,
          PrefetchHooks Function({bool localAccountId})
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                serverId: serverId,
                localAccountId: localAccountId,
                title: title,
                content: content,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                required String title,
                required String content,
                required String category,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                serverId: serverId,
                localAccountId: localAccountId,
                title: title,
                content: content,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, Note>(table),
                  $$NotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localAccountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localAccountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localAccountId,
                        referencedTable: $$NotesTableReferences
                            ._localAccountIdTable(db),
                        referencedColumn: $$NotesTableReferences
                            ._localAccountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, $$NotesTableReferences),
      Note,
      PrefetchHooks Function({bool localAccountId})
    >;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  Value<String?> serverId,
  Value<int> localAccountId,
  Value<int?> taskId,
  Value<int> notificationId,
  required String title,
  required DateTime dueAt,
  Value<bool> isEnabled,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  Value<String?> serverId,
  Value<int> localAccountId,
  Value<int?> taskId,
  Value<int> notificationId,
  Value<String> title,
  Value<DateTime> dueAt,
  Value<bool> isEnabled,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalAccountsTable _localAccountIdTable(_$AppDatabase db) => db
      .localAccounts
      .createAlias('reminders__local_account_id__local_accounts__id');

  $$LocalAccountsTableProcessedTableManager get localAccountId {
    final $_column = $_itemColumn<int>('local_account_id')!;

    final manager = $$LocalAccountsTableTableManager(
      $_db,
      $_db.localAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('reminders__task_id__tasks__id');

  $$TasksTableProcessedTableManager? get taskId {
    final $_column = $_itemColumn<int>('task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalAccountsTableFilterComposer get localAccountId {
    final $$LocalAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableFilterComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalAccountsTableOrderingComposer get localAccountId {
    final $$LocalAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$LocalAccountsTableAnnotationComposer get localAccountId {
    final $$LocalAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, $$RemindersTableReferences),
          Reminder,
          PrefetchHooks Function({bool localAccountId, bool taskId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                Value<int?> taskId = const Value.absent(),
                Value<int> notificationId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                serverId: serverId,
                localAccountId: localAccountId,
                taskId: taskId,
                notificationId: notificationId,
                title: title,
                dueAt: dueAt,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                Value<int?> taskId = const Value.absent(),
                Value<int> notificationId = const Value.absent(),
                required String title,
                required DateTime dueAt,
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                serverId: serverId,
                localAccountId: localAccountId,
                taskId: taskId,
                notificationId: notificationId,
                title: title,
                dueAt: dueAt,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, Reminder>(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localAccountId = false, taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localAccountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localAccountId,
                        referencedTable: $$RemindersTableReferences
                            ._localAccountIdTable(db),
                        referencedColumn: $$RemindersTableReferences
                            ._localAccountIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$RemindersTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$RemindersTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, $$RemindersTableReferences),
      Reminder,
      PrefetchHooks Function({bool localAccountId, bool taskId})
    >;
typedef $$ProfileDataTableCreateCompanionBuilder =
    ProfileDataCompanion Function({
      Value<int> localAccountId,
      Value<String?> serverId,
      Value<String> role,
      Value<String> phone,
      Value<String> college,
      Value<String> semester,
      Value<int> points,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$ProfileDataTableUpdateCompanionBuilder =
    ProfileDataCompanion Function({
      Value<int> localAccountId,
      Value<String?> serverId,
      Value<String> role,
      Value<String> phone,
      Value<String> college,
      Value<String> semester,
      Value<int> points,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$ProfileDataTableReferences
    extends BaseReferences<_$AppDatabase, $ProfileDataTable, ProfileDataData> {
  $$ProfileDataTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalAccountsTable _localAccountIdTable(_$AppDatabase db) => db
      .localAccounts
      .createAlias('profile_data__local_account_id__local_accounts__id');

  $$LocalAccountsTableProcessedTableManager get localAccountId {
    final $_column = $_itemColumn<int>('local_account_id')!;

    final manager = $$LocalAccountsTableTableManager(
      $_db,
      $_db.localAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProfileDataTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileDataTable> {
  $$ProfileDataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get college => $composableBuilder(
    column: $table.college,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalAccountsTableFilterComposer get localAccountId {
    final $$LocalAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableFilterComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileDataTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileDataTable> {
  $$ProfileDataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get college => $composableBuilder(
    column: $table.college,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalAccountsTableOrderingComposer get localAccountId {
    final $$LocalAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileDataTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileDataTable> {
  $$ProfileDataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get college =>
      $composableBuilder(column: $table.college, builder: (column) => column);

  GeneratedColumn<String> get semester =>
      $composableBuilder(column: $table.semester, builder: (column) => column);

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$LocalAccountsTableAnnotationComposer get localAccountId {
    final $$LocalAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileDataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileDataTable,
          ProfileDataData,
          $$ProfileDataTableFilterComposer,
          $$ProfileDataTableOrderingComposer,
          $$ProfileDataTableAnnotationComposer,
          $$ProfileDataTableCreateCompanionBuilder,
          $$ProfileDataTableUpdateCompanionBuilder,
          (ProfileDataData, $$ProfileDataTableReferences),
          ProfileDataData,
          PrefetchHooks Function({bool localAccountId})
        > {
  $$ProfileDataTableTableManager(_$AppDatabase db, $ProfileDataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileDataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileDataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileDataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> localAccountId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> college = const Value.absent(),
                Value<String> semester = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => ProfileDataCompanion(
                localAccountId: localAccountId,
                serverId: serverId,
                role: role,
                phone: phone,
                college: college,
                semester: semester,
                points: points,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> localAccountId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> college = const Value.absent(),
                Value<String> semester = const Value.absent(),
                Value<int> points = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => ProfileDataCompanion.insert(
                localAccountId: localAccountId,
                serverId: serverId,
                role: role,
                phone: phone,
                college: college,
                semester: semester,
                points: points,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfileDataTable, ProfileDataData>(table),
                  $$ProfileDataTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localAccountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localAccountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localAccountId,
                        referencedTable: $$ProfileDataTableReferences
                            ._localAccountIdTable(db),
                        referencedColumn: $$ProfileDataTableReferences
                            ._localAccountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProfileDataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileDataTable,
      ProfileDataData,
      $$ProfileDataTableFilterComposer,
      $$ProfileDataTableOrderingComposer,
      $$ProfileDataTableAnnotationComposer,
      $$ProfileDataTableCreateCompanionBuilder,
      $$ProfileDataTableUpdateCompanionBuilder,
      (ProfileDataData, $$ProfileDataTableReferences),
      ProfileDataData,
      PrefetchHooks Function({bool localAccountId})
    >;
typedef $$TransactionDetectionEventsTableCreateCompanionBuilder =
    TransactionDetectionEventsCompanion Function({
      Value<int> id,
      Value<int> localAccountId,
      required String eventKey,
      required String sourcePackage,
      required String sourceType,
      Value<String?> title,
      Value<String?> body,
      Value<String?> bigText,
      required DateTime occurredAt,
      required DateTime receivedAt,
      Value<DateTime?> processedAt,
      Value<DateTime> expiresAt,
    });
typedef $$TransactionDetectionEventsTableUpdateCompanionBuilder =
    TransactionDetectionEventsCompanion Function({
      Value<int> id,
      Value<int> localAccountId,
      Value<String> eventKey,
      Value<String> sourcePackage,
      Value<String> sourceType,
      Value<String?> title,
      Value<String?> body,
      Value<String?> bigText,
      Value<DateTime> occurredAt,
      Value<DateTime> receivedAt,
      Value<DateTime?> processedAt,
      Value<DateTime> expiresAt,
    });

final class $$TransactionDetectionEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionDetectionEventsTable,
          TransactionDetectionEvent
        > {
  $$TransactionDetectionEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalAccountsTable _localAccountIdTable(_$AppDatabase db) =>
      db.localAccounts.createAlias(
        'transaction_detection_events__local_account_id__local_accounts__id',
      );

  $$LocalAccountsTableProcessedTableManager get localAccountId {
    final $_column = $_itemColumn<int>('local_account_id')!;

    final manager = $$LocalAccountsTableTableManager(
      $_db,
      $_db.localAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionDetectionEventsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionDetectionEventsTable> {
  $$TransactionDetectionEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventKey => $composableBuilder(
    column: $table.eventKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bigText => $composableBuilder(
    column: $table.bigText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalAccountsTableFilterComposer get localAccountId {
    final $$LocalAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableFilterComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionDetectionEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionDetectionEventsTable> {
  $$TransactionDetectionEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventKey => $composableBuilder(
    column: $table.eventKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bigText => $composableBuilder(
    column: $table.bigText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalAccountsTableOrderingComposer get localAccountId {
    final $$LocalAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionDetectionEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionDetectionEventsTable> {
  $$TransactionDetectionEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventKey =>
      $composableBuilder(column: $table.eventKey, builder: (column) => column);

  GeneratedColumn<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get bigText =>
      $composableBuilder(column: $table.bigText, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  $$LocalAccountsTableAnnotationComposer get localAccountId {
    final $$LocalAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionDetectionEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionDetectionEventsTable,
          TransactionDetectionEvent,
          $$TransactionDetectionEventsTableFilterComposer,
          $$TransactionDetectionEventsTableOrderingComposer,
          $$TransactionDetectionEventsTableAnnotationComposer,
          $$TransactionDetectionEventsTableCreateCompanionBuilder,
          $$TransactionDetectionEventsTableUpdateCompanionBuilder,
          (
            TransactionDetectionEvent,
            $$TransactionDetectionEventsTableReferences,
          ),
          TransactionDetectionEvent,
          PrefetchHooks Function({bool localAccountId})
        > {
  $$TransactionDetectionEventsTableTableManager(
    _$AppDatabase db,
    $TransactionDetectionEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionDetectionEventsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TransactionDetectionEventsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransactionDetectionEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                Value<String> eventKey = const Value.absent(),
                Value<String> sourcePackage = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> bigText = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<DateTime?> processedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
              }) => TransactionDetectionEventsCompanion(
                id: id,
                localAccountId: localAccountId,
                eventKey: eventKey,
                sourcePackage: sourcePackage,
                sourceType: sourceType,
                title: title,
                body: body,
                bigText: bigText,
                occurredAt: occurredAt,
                receivedAt: receivedAt,
                processedAt: processedAt,
                expiresAt: expiresAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                required String eventKey,
                required String sourcePackage,
                required String sourceType,
                Value<String?> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> bigText = const Value.absent(),
                required DateTime occurredAt,
                required DateTime receivedAt,
                Value<DateTime?> processedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
              }) => TransactionDetectionEventsCompanion.insert(
                id: id,
                localAccountId: localAccountId,
                eventKey: eventKey,
                sourcePackage: sourcePackage,
                sourceType: sourceType,
                title: title,
                body: body,
                bigText: bigText,
                occurredAt: occurredAt,
                receivedAt: receivedAt,
                processedAt: processedAt,
                expiresAt: expiresAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TransactionDetectionEventsTable,
                    TransactionDetectionEvent
                  >(table),
                  $$TransactionDetectionEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localAccountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localAccountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localAccountId,
                        referencedTable:
                            $$TransactionDetectionEventsTableReferences
                                ._localAccountIdTable(db),
                        referencedColumn:
                            $$TransactionDetectionEventsTableReferences
                                ._localAccountIdTable(db)
                                .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionDetectionEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionDetectionEventsTable,
      TransactionDetectionEvent,
      $$TransactionDetectionEventsTableFilterComposer,
      $$TransactionDetectionEventsTableOrderingComposer,
      $$TransactionDetectionEventsTableAnnotationComposer,
      $$TransactionDetectionEventsTableCreateCompanionBuilder,
      $$TransactionDetectionEventsTableUpdateCompanionBuilder,
      (TransactionDetectionEvent, $$TransactionDetectionEventsTableReferences),
      TransactionDetectionEvent,
      PrefetchHooks Function({bool localAccountId})
    >;
typedef $$TransactionCandidatesTableCreateCompanionBuilder =
    TransactionCandidatesCompanion Function({
      Value<int> id,
      Value<int> localAccountId,
      required String candidateId,
      required int amountMinor,
      Value<String> currency,
      Value<String> merchantName,
      Value<String> merchantIdentity,
      required String direction,
      required String transactionType,
      required String source,
      Value<String> bankConfirmationStatus,
      Value<String?> sourcePackage,
      required DateTime occurredAt,
      Value<String?> referenceId,
      Value<String?> accountHint,
      Value<String?> paymentMethod,
      Value<int?> balanceAfterMinor,
      Value<String?> rawEventId,
      required double confidenceScore,
      required String status,
      required String duplicateStatus,
      Value<String> category,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> expiresAt,
    });
typedef $$TransactionCandidatesTableUpdateCompanionBuilder =
    TransactionCandidatesCompanion Function({
      Value<int> id,
      Value<int> localAccountId,
      Value<String> candidateId,
      Value<int> amountMinor,
      Value<String> currency,
      Value<String> merchantName,
      Value<String> merchantIdentity,
      Value<String> direction,
      Value<String> transactionType,
      Value<String> source,
      Value<String> bankConfirmationStatus,
      Value<String?> sourcePackage,
      Value<DateTime> occurredAt,
      Value<String?> referenceId,
      Value<String?> accountHint,
      Value<String?> paymentMethod,
      Value<int?> balanceAfterMinor,
      Value<String?> rawEventId,
      Value<double> confidenceScore,
      Value<String> status,
      Value<String> duplicateStatus,
      Value<String> category,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> expiresAt,
    });

final class $$TransactionCandidatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionCandidatesTable,
          TransactionCandidate
        > {
  $$TransactionCandidatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalAccountsTable _localAccountIdTable(_$AppDatabase db) =>
      db.localAccounts.createAlias(
        'transaction_candidates__local_account_id__local_accounts__id',
      );

  $$LocalAccountsTableProcessedTableManager get localAccountId {
    final $_column = $_itemColumn<int>('local_account_id')!;

    final manager = $$LocalAccountsTableTableManager(
      $_db,
      $_db.localAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionCandidatesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionCandidatesTable> {
  $$TransactionCandidatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get candidateId => $composableBuilder(
    column: $table.candidateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantIdentity => $composableBuilder(
    column: $table.merchantIdentity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankConfirmationStatus => $composableBuilder(
    column: $table.bankConfirmationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountHint => $composableBuilder(
    column: $table.accountHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceAfterMinor => $composableBuilder(
    column: $table.balanceAfterMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawEventId => $composableBuilder(
    column: $table.rawEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get duplicateStatus => $composableBuilder(
    column: $table.duplicateStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalAccountsTableFilterComposer get localAccountId {
    final $$LocalAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableFilterComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionCandidatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionCandidatesTable> {
  $$TransactionCandidatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get candidateId => $composableBuilder(
    column: $table.candidateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantIdentity => $composableBuilder(
    column: $table.merchantIdentity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankConfirmationStatus => $composableBuilder(
    column: $table.bankConfirmationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountHint => $composableBuilder(
    column: $table.accountHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceAfterMinor => $composableBuilder(
    column: $table.balanceAfterMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawEventId => $composableBuilder(
    column: $table.rawEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get duplicateStatus => $composableBuilder(
    column: $table.duplicateStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalAccountsTableOrderingComposer get localAccountId {
    final $$LocalAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionCandidatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionCandidatesTable> {
  $$TransactionCandidatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get candidateId => $composableBuilder(
    column: $table.candidateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchantIdentity => $composableBuilder(
    column: $table.merchantIdentity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get bankConfirmationStatus => $composableBuilder(
    column: $table.bankConfirmationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountHint => $composableBuilder(
    column: $table.accountHint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get balanceAfterMinor => $composableBuilder(
    column: $table.balanceAfterMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawEventId => $composableBuilder(
    column: $table.rawEventId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get duplicateStatus => $composableBuilder(
    column: $table.duplicateStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  $$LocalAccountsTableAnnotationComposer get localAccountId {
    final $$LocalAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionCandidatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionCandidatesTable,
          TransactionCandidate,
          $$TransactionCandidatesTableFilterComposer,
          $$TransactionCandidatesTableOrderingComposer,
          $$TransactionCandidatesTableAnnotationComposer,
          $$TransactionCandidatesTableCreateCompanionBuilder,
          $$TransactionCandidatesTableUpdateCompanionBuilder,
          (TransactionCandidate, $$TransactionCandidatesTableReferences),
          TransactionCandidate,
          PrefetchHooks Function({bool localAccountId})
        > {
  $$TransactionCandidatesTableTableManager(
    _$AppDatabase db,
    $TransactionCandidatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionCandidatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TransactionCandidatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransactionCandidatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                Value<String> candidateId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> merchantName = const Value.absent(),
                Value<String> merchantIdentity = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> bankConfirmationStatus = const Value.absent(),
                Value<String?> sourcePackage = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                Value<String?> accountHint = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<int?> balanceAfterMinor = const Value.absent(),
                Value<String?> rawEventId = const Value.absent(),
                Value<double> confidenceScore = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> duplicateStatus = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
              }) => TransactionCandidatesCompanion(
                id: id,
                localAccountId: localAccountId,
                candidateId: candidateId,
                amountMinor: amountMinor,
                currency: currency,
                merchantName: merchantName,
                merchantIdentity: merchantIdentity,
                direction: direction,
                transactionType: transactionType,
                source: source,
                bankConfirmationStatus: bankConfirmationStatus,
                sourcePackage: sourcePackage,
                occurredAt: occurredAt,
                referenceId: referenceId,
                accountHint: accountHint,
                paymentMethod: paymentMethod,
                balanceAfterMinor: balanceAfterMinor,
                rawEventId: rawEventId,
                confidenceScore: confidenceScore,
                status: status,
                duplicateStatus: duplicateStatus,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                expiresAt: expiresAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                required String candidateId,
                required int amountMinor,
                Value<String> currency = const Value.absent(),
                Value<String> merchantName = const Value.absent(),
                Value<String> merchantIdentity = const Value.absent(),
                required String direction,
                required String transactionType,
                required String source,
                Value<String> bankConfirmationStatus = const Value.absent(),
                Value<String?> sourcePackage = const Value.absent(),
                required DateTime occurredAt,
                Value<String?> referenceId = const Value.absent(),
                Value<String?> accountHint = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<int?> balanceAfterMinor = const Value.absent(),
                Value<String?> rawEventId = const Value.absent(),
                required double confidenceScore,
                required String status,
                required String duplicateStatus,
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
              }) => TransactionCandidatesCompanion.insert(
                id: id,
                localAccountId: localAccountId,
                candidateId: candidateId,
                amountMinor: amountMinor,
                currency: currency,
                merchantName: merchantName,
                merchantIdentity: merchantIdentity,
                direction: direction,
                transactionType: transactionType,
                source: source,
                bankConfirmationStatus: bankConfirmationStatus,
                sourcePackage: sourcePackage,
                occurredAt: occurredAt,
                referenceId: referenceId,
                accountHint: accountHint,
                paymentMethod: paymentMethod,
                balanceAfterMinor: balanceAfterMinor,
                rawEventId: rawEventId,
                confidenceScore: confidenceScore,
                status: status,
                duplicateStatus: duplicateStatus,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                expiresAt: expiresAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TransactionCandidatesTable,
                    TransactionCandidate
                  >(table),
                  $$TransactionCandidatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localAccountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localAccountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localAccountId,
                        referencedTable: $$TransactionCandidatesTableReferences
                            ._localAccountIdTable(db),
                        referencedColumn: $$TransactionCandidatesTableReferences
                            ._localAccountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionCandidatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionCandidatesTable,
      TransactionCandidate,
      $$TransactionCandidatesTableFilterComposer,
      $$TransactionCandidatesTableOrderingComposer,
      $$TransactionCandidatesTableAnnotationComposer,
      $$TransactionCandidatesTableCreateCompanionBuilder,
      $$TransactionCandidatesTableUpdateCompanionBuilder,
      (TransactionCandidate, $$TransactionCandidatesTableReferences),
      TransactionCandidate,
      PrefetchHooks Function({bool localAccountId})
    >;
typedef $$MerchantCategoryRulesTableCreateCompanionBuilder =
    MerchantCategoryRulesCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<int> localAccountId,
      required String merchantIdentity,
      required String category,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$MerchantCategoryRulesTableUpdateCompanionBuilder =
    MerchantCategoryRulesCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<int> localAccountId,
      Value<String> merchantIdentity,
      Value<String> category,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$MerchantCategoryRulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MerchantCategoryRulesTable,
          MerchantCategoryRule
        > {
  $$MerchantCategoryRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalAccountsTable _localAccountIdTable(_$AppDatabase db) =>
      db.localAccounts.createAlias(
        'merchant_category_rules__local_account_id__local_accounts__id',
      );

  $$LocalAccountsTableProcessedTableManager get localAccountId {
    final $_column = $_itemColumn<int>('local_account_id')!;

    final manager = $$LocalAccountsTableTableManager(
      $_db,
      $_db.localAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MerchantCategoryRulesTableFilterComposer
    extends Composer<_$AppDatabase, $MerchantCategoryRulesTable> {
  $$MerchantCategoryRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantIdentity => $composableBuilder(
    column: $table.merchantIdentity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalAccountsTableFilterComposer get localAccountId {
    final $$LocalAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableFilterComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantCategoryRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $MerchantCategoryRulesTable> {
  $$MerchantCategoryRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantIdentity => $composableBuilder(
    column: $table.merchantIdentity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalAccountsTableOrderingComposer get localAccountId {
    final $$LocalAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantCategoryRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MerchantCategoryRulesTable> {
  $$MerchantCategoryRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get merchantIdentity => $composableBuilder(
    column: $table.merchantIdentity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$LocalAccountsTableAnnotationComposer get localAccountId {
    final $$LocalAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantCategoryRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MerchantCategoryRulesTable,
          MerchantCategoryRule,
          $$MerchantCategoryRulesTableFilterComposer,
          $$MerchantCategoryRulesTableOrderingComposer,
          $$MerchantCategoryRulesTableAnnotationComposer,
          $$MerchantCategoryRulesTableCreateCompanionBuilder,
          $$MerchantCategoryRulesTableUpdateCompanionBuilder,
          (MerchantCategoryRule, $$MerchantCategoryRulesTableReferences),
          MerchantCategoryRule,
          PrefetchHooks Function({bool localAccountId})
        > {
  $$MerchantCategoryRulesTableTableManager(
    _$AppDatabase db,
    $MerchantCategoryRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MerchantCategoryRulesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MerchantCategoryRulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MerchantCategoryRulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                Value<String> merchantIdentity = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => MerchantCategoryRulesCompanion(
                id: id,
                serverId: serverId,
                localAccountId: localAccountId,
                merchantIdentity: merchantIdentity,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                required String merchantIdentity,
                required String category,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => MerchantCategoryRulesCompanion.insert(
                id: id,
                serverId: serverId,
                localAccountId: localAccountId,
                merchantIdentity: merchantIdentity,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $MerchantCategoryRulesTable,
                    MerchantCategoryRule
                  >(table),
                  $$MerchantCategoryRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localAccountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localAccountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localAccountId,
                        referencedTable: $$MerchantCategoryRulesTableReferences
                            ._localAccountIdTable(db),
                        referencedColumn: $$MerchantCategoryRulesTableReferences
                            ._localAccountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MerchantCategoryRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MerchantCategoryRulesTable,
      MerchantCategoryRule,
      $$MerchantCategoryRulesTableFilterComposer,
      $$MerchantCategoryRulesTableOrderingComposer,
      $$MerchantCategoryRulesTableAnnotationComposer,
      $$MerchantCategoryRulesTableCreateCompanionBuilder,
      $$MerchantCategoryRulesTableUpdateCompanionBuilder,
      (MerchantCategoryRule, $$MerchantCategoryRulesTableReferences),
      MerchantCategoryRule,
      PrefetchHooks Function({bool localAccountId})
    >;
typedef $$YoutubePlaylistsTableCreateCompanionBuilder =
    YoutubePlaylistsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<int> localAccountId,
      required String youtubePlaylistId,
      required String title,
      Value<String> description,
      Value<String> channelTitle,
      Value<String> thumbnailUrl,
      Value<int> totalVideos,
      Value<int> totalDurationSeconds,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$YoutubePlaylistsTableUpdateCompanionBuilder =
    YoutubePlaylistsCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<int> localAccountId,
      Value<String> youtubePlaylistId,
      Value<String> title,
      Value<String> description,
      Value<String> channelTitle,
      Value<String> thumbnailUrl,
      Value<int> totalVideos,
      Value<int> totalDurationSeconds,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime?> deletedAt,
    });

final class $$YoutubePlaylistsTableReferences
    extends
        BaseReferences<_$AppDatabase, $YoutubePlaylistsTable, YoutubePlaylist> {
  $$YoutubePlaylistsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalAccountsTable _localAccountIdTable(_$AppDatabase db) => db
      .localAccounts
      .createAlias('youtube_playlists__local_account_id__local_accounts__id');

  $$LocalAccountsTableProcessedTableManager get localAccountId {
    final $_column = $_itemColumn<int>('local_account_id')!;

    final manager = $$LocalAccountsTableTableManager(
      $_db,
      $_db.localAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$YoutubeVideosTable, List<YoutubeVideo>>
  _youtubeVideosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.youtubeVideos,
    aliasName: 'youtube_playlists__id__youtube_videos__playlist_local_id',
  );

  $$YoutubeVideosTableProcessedTableManager get youtubeVideosRefs {
    final manager = $$YoutubeVideosTableTableManager(
      $_db,
      $_db.youtubeVideos,
    ).filter((f) => f.playlistLocalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_youtubeVideosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$YoutubePlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $YoutubePlaylistsTable> {
  $$YoutubePlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get youtubePlaylistId => $composableBuilder(
    column: $table.youtubePlaylistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelTitle => $composableBuilder(
    column: $table.channelTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalVideos => $composableBuilder(
    column: $table.totalVideos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDurationSeconds => $composableBuilder(
    column: $table.totalDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalAccountsTableFilterComposer get localAccountId {
    final $$LocalAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableFilterComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> youtubeVideosRefs(
    Expression<bool> Function($$YoutubeVideosTableFilterComposer f) f,
  ) {
    final $$YoutubeVideosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.youtubeVideos,
      getReferencedColumn: (t) => t.playlistLocalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$YoutubeVideosTableFilterComposer(
            $db: $db,
            $table: $db.youtubeVideos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$YoutubePlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $YoutubePlaylistsTable> {
  $$YoutubePlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get youtubePlaylistId => $composableBuilder(
    column: $table.youtubePlaylistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelTitle => $composableBuilder(
    column: $table.channelTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalVideos => $composableBuilder(
    column: $table.totalVideos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDurationSeconds => $composableBuilder(
    column: $table.totalDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalAccountsTableOrderingComposer get localAccountId {
    final $$LocalAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$YoutubePlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $YoutubePlaylistsTable> {
  $$YoutubePlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get youtubePlaylistId => $composableBuilder(
    column: $table.youtubePlaylistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get channelTitle => $composableBuilder(
    column: $table.channelTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalVideos => $composableBuilder(
    column: $table.totalVideos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDurationSeconds => $composableBuilder(
    column: $table.totalDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$LocalAccountsTableAnnotationComposer get localAccountId {
    final $$LocalAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> youtubeVideosRefs<T extends Object>(
    Expression<T> Function($$YoutubeVideosTableAnnotationComposer a) f,
  ) {
    final $$YoutubeVideosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.youtubeVideos,
      getReferencedColumn: (t) => t.playlistLocalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$YoutubeVideosTableAnnotationComposer(
            $db: $db,
            $table: $db.youtubeVideos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$YoutubePlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $YoutubePlaylistsTable,
          YoutubePlaylist,
          $$YoutubePlaylistsTableFilterComposer,
          $$YoutubePlaylistsTableOrderingComposer,
          $$YoutubePlaylistsTableAnnotationComposer,
          $$YoutubePlaylistsTableCreateCompanionBuilder,
          $$YoutubePlaylistsTableUpdateCompanionBuilder,
          (YoutubePlaylist, $$YoutubePlaylistsTableReferences),
          YoutubePlaylist,
          PrefetchHooks Function({bool localAccountId, bool youtubeVideosRefs})
        > {
  $$YoutubePlaylistsTableTableManager(
    _$AppDatabase db,
    $YoutubePlaylistsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$YoutubePlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$YoutubePlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$YoutubePlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                Value<String> youtubePlaylistId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> channelTitle = const Value.absent(),
                Value<String> thumbnailUrl = const Value.absent(),
                Value<int> totalVideos = const Value.absent(),
                Value<int> totalDurationSeconds = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => YoutubePlaylistsCompanion(
                id: id,
                serverId: serverId,
                localAccountId: localAccountId,
                youtubePlaylistId: youtubePlaylistId,
                title: title,
                description: description,
                channelTitle: channelTitle,
                thumbnailUrl: thumbnailUrl,
                totalVideos: totalVideos,
                totalDurationSeconds: totalDurationSeconds,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                required String youtubePlaylistId,
                required String title,
                Value<String> description = const Value.absent(),
                Value<String> channelTitle = const Value.absent(),
                Value<String> thumbnailUrl = const Value.absent(),
                Value<int> totalVideos = const Value.absent(),
                Value<int> totalDurationSeconds = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => YoutubePlaylistsCompanion.insert(
                id: id,
                serverId: serverId,
                localAccountId: localAccountId,
                youtubePlaylistId: youtubePlaylistId,
                title: title,
                description: description,
                channelTitle: channelTitle,
                thumbnailUrl: thumbnailUrl,
                totalVideos: totalVideos,
                totalDurationSeconds: totalDurationSeconds,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$YoutubePlaylistsTable, YoutubePlaylist>(table),
                  $$YoutubePlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({localAccountId = false, youtubeVideosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (youtubeVideosRefs) db.youtubeVideos,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (localAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.localAccountId,
                            referencedTable: $$YoutubePlaylistsTableReferences
                                ._localAccountIdTable(db),
                            referencedColumn: $$YoutubePlaylistsTableReferences
                                ._localAccountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (youtubeVideosRefs)
                        await $_getPrefetchedData<
                          YoutubePlaylist,
                          $YoutubePlaylistsTable,
                          YoutubeVideo
                        >(
                          currentTable: table,
                          referencedTable: $$YoutubePlaylistsTableReferences
                              ._youtubeVideosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$YoutubePlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).youtubeVideosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistLocalId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$YoutubePlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $YoutubePlaylistsTable,
      YoutubePlaylist,
      $$YoutubePlaylistsTableFilterComposer,
      $$YoutubePlaylistsTableOrderingComposer,
      $$YoutubePlaylistsTableAnnotationComposer,
      $$YoutubePlaylistsTableCreateCompanionBuilder,
      $$YoutubePlaylistsTableUpdateCompanionBuilder,
      (YoutubePlaylist, $$YoutubePlaylistsTableReferences),
      YoutubePlaylist,
      PrefetchHooks Function({bool localAccountId, bool youtubeVideosRefs})
    >;
typedef $$YoutubeVideosTableCreateCompanionBuilder =
    YoutubeVideosCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String?> remoteUpdatedAt,
      required int playlistLocalId,
      required String youtubeVideoId,
      required String title,
      Value<String> thumbnailUrl,
      required int position,
      Value<int> durationSeconds,
      Value<String> durationIso,
      Value<bool> completed,
      Value<DateTime?> watchedAt,
      Value<int> lastPositionSeconds,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> progressUpdatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$YoutubeVideosTableUpdateCompanionBuilder =
    YoutubeVideosCompanion Function({
      Value<int> id,
      Value<String?> serverId,
      Value<String?> remoteUpdatedAt,
      Value<int> playlistLocalId,
      Value<String> youtubeVideoId,
      Value<String> title,
      Value<String> thumbnailUrl,
      Value<int> position,
      Value<int> durationSeconds,
      Value<String> durationIso,
      Value<bool> completed,
      Value<DateTime?> watchedAt,
      Value<int> lastPositionSeconds,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> progressUpdatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$YoutubeVideosTableReferences
    extends BaseReferences<_$AppDatabase, $YoutubeVideosTable, YoutubeVideo> {
  $$YoutubeVideosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $YoutubePlaylistsTable _playlistLocalIdTable(_$AppDatabase db) => db
      .youtubePlaylists
      .createAlias('youtube_videos__playlist_local_id__youtube_playlists__id');

  $$YoutubePlaylistsTableProcessedTableManager get playlistLocalId {
    final $_column = $_itemColumn<int>('playlist_local_id')!;

    final manager = $$YoutubePlaylistsTableTableManager(
      $_db,
      $_db.youtubePlaylists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistLocalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$YoutubeVideosTableFilterComposer
    extends Composer<_$AppDatabase, $YoutubeVideosTable> {
  $$YoutubeVideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get youtubeVideoId => $composableBuilder(
    column: $table.youtubeVideoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get durationIso => $composableBuilder(
    column: $table.durationIso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPositionSeconds => $composableBuilder(
    column: $table.lastPositionSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get progressUpdatedAt => $composableBuilder(
    column: $table.progressUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$YoutubePlaylistsTableFilterComposer get playlistLocalId {
    final $$YoutubePlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistLocalId,
      referencedTable: $db.youtubePlaylists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$YoutubePlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.youtubePlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$YoutubeVideosTableOrderingComposer
    extends Composer<_$AppDatabase, $YoutubeVideosTable> {
  $$YoutubeVideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get youtubeVideoId => $composableBuilder(
    column: $table.youtubeVideoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get durationIso => $composableBuilder(
    column: $table.durationIso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPositionSeconds => $composableBuilder(
    column: $table.lastPositionSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get progressUpdatedAt => $composableBuilder(
    column: $table.progressUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$YoutubePlaylistsTableOrderingComposer get playlistLocalId {
    final $$YoutubePlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistLocalId,
      referencedTable: $db.youtubePlaylists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$YoutubePlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.youtubePlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$YoutubeVideosTableAnnotationComposer
    extends Composer<_$AppDatabase, $YoutubeVideosTable> {
  $$YoutubeVideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get youtubeVideoId => $composableBuilder(
    column: $table.youtubeVideoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get durationIso => $composableBuilder(
    column: $table.durationIso,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);

  GeneratedColumn<int> get lastPositionSeconds => $composableBuilder(
    column: $table.lastPositionSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get progressUpdatedAt => $composableBuilder(
    column: $table.progressUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$YoutubePlaylistsTableAnnotationComposer get playlistLocalId {
    final $$YoutubePlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistLocalId,
      referencedTable: $db.youtubePlaylists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$YoutubePlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.youtubePlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$YoutubeVideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $YoutubeVideosTable,
          YoutubeVideo,
          $$YoutubeVideosTableFilterComposer,
          $$YoutubeVideosTableOrderingComposer,
          $$YoutubeVideosTableAnnotationComposer,
          $$YoutubeVideosTableCreateCompanionBuilder,
          $$YoutubeVideosTableUpdateCompanionBuilder,
          (YoutubeVideo, $$YoutubeVideosTableReferences),
          YoutubeVideo,
          PrefetchHooks Function({bool playlistLocalId})
        > {
  $$YoutubeVideosTableTableManager(_$AppDatabase db, $YoutubeVideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$YoutubeVideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$YoutubeVideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$YoutubeVideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> remoteUpdatedAt = const Value.absent(),
                Value<int> playlistLocalId = const Value.absent(),
                Value<String> youtubeVideoId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> thumbnailUrl = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> durationIso = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime?> watchedAt = const Value.absent(),
                Value<int> lastPositionSeconds = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> progressUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => YoutubeVideosCompanion(
                id: id,
                serverId: serverId,
                remoteUpdatedAt: remoteUpdatedAt,
                playlistLocalId: playlistLocalId,
                youtubeVideoId: youtubeVideoId,
                title: title,
                thumbnailUrl: thumbnailUrl,
                position: position,
                durationSeconds: durationSeconds,
                durationIso: durationIso,
                completed: completed,
                watchedAt: watchedAt,
                lastPositionSeconds: lastPositionSeconds,
                createdAt: createdAt,
                updatedAt: updatedAt,
                progressUpdatedAt: progressUpdatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> remoteUpdatedAt = const Value.absent(),
                required int playlistLocalId,
                required String youtubeVideoId,
                required String title,
                Value<String> thumbnailUrl = const Value.absent(),
                required int position,
                Value<int> durationSeconds = const Value.absent(),
                Value<String> durationIso = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime?> watchedAt = const Value.absent(),
                Value<int> lastPositionSeconds = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> progressUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => YoutubeVideosCompanion.insert(
                id: id,
                serverId: serverId,
                remoteUpdatedAt: remoteUpdatedAt,
                playlistLocalId: playlistLocalId,
                youtubeVideoId: youtubeVideoId,
                title: title,
                thumbnailUrl: thumbnailUrl,
                position: position,
                durationSeconds: durationSeconds,
                durationIso: durationIso,
                completed: completed,
                watchedAt: watchedAt,
                lastPositionSeconds: lastPositionSeconds,
                createdAt: createdAt,
                updatedAt: updatedAt,
                progressUpdatedAt: progressUpdatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$YoutubeVideosTable, YoutubeVideo>(table),
                  $$YoutubeVideosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistLocalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistLocalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistLocalId,
                        referencedTable: $$YoutubeVideosTableReferences
                            ._playlistLocalIdTable(db),
                        referencedColumn: $$YoutubeVideosTableReferences
                            ._playlistLocalIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$YoutubeVideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $YoutubeVideosTable,
      YoutubeVideo,
      $$YoutubeVideosTableFilterComposer,
      $$YoutubeVideosTableOrderingComposer,
      $$YoutubeVideosTableAnnotationComposer,
      $$YoutubeVideosTableCreateCompanionBuilder,
      $$YoutubeVideosTableUpdateCompanionBuilder,
      (YoutubeVideo, $$YoutubeVideosTableReferences),
      YoutubeVideo,
      PrefetchHooks Function({bool playlistLocalId})
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder = SyncOutboxCompanion Function({
  Value<int> id,
  required int localAccountId,
  Value<String?> authUserId,
  required String entityType,
  required int localRowId,
  Value<String?> serverId,
  required String operation,
  Value<String> state,
  Value<int> dependencyRank,
  required DateTime queuedAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> nextAttemptAt,
  Value<int> attemptCount,
  Value<DateTime?> baseRemoteUpdatedAt,
  Value<String?> lastError,
});
typedef $$SyncOutboxTableUpdateCompanionBuilder = SyncOutboxCompanion Function({
  Value<int> id,
  Value<int> localAccountId,
  Value<String?> authUserId,
  Value<String> entityType,
  Value<int> localRowId,
  Value<String?> serverId,
  Value<String> operation,
  Value<String> state,
  Value<int> dependencyRank,
  Value<DateTime> queuedAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> nextAttemptAt,
  Value<int> attemptCount,
  Value<DateTime?> baseRemoteUpdatedAt,
  Value<String?> lastError,
});

final class $$SyncOutboxTableReferences
    extends BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData> {
  $$SyncOutboxTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalAccountsTable _localAccountIdTable(_$AppDatabase db) => db
      .localAccounts
      .createAlias('sync_outbox__local_account_id__local_accounts__id');

  $$LocalAccountsTableProcessedTableManager get localAccountId {
    final $_column = $_itemColumn<int>('local_account_id')!;

    final manager = $$LocalAccountsTableTableManager(
      $_db,
      $_db.localAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localRowId => $composableBuilder(
    column: $table.localRowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dependencyRank => $composableBuilder(
    column: $table.dependencyRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get baseRemoteUpdatedAt => $composableBuilder(
    column: $table.baseRemoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalAccountsTableFilterComposer get localAccountId {
    final $$LocalAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableFilterComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localRowId => $composableBuilder(
    column: $table.localRowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dependencyRank => $composableBuilder(
    column: $table.dependencyRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get baseRemoteUpdatedAt => $composableBuilder(
    column: $table.baseRemoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalAccountsTableOrderingComposer get localAccountId {
    final $$LocalAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localRowId => $composableBuilder(
    column: $table.localRowId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get dependencyRank => $composableBuilder(
    column: $table.dependencyRank,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get baseRemoteUpdatedAt => $composableBuilder(
    column: $table.baseRemoteUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  $$LocalAccountsTableAnnotationComposer get localAccountId {
    final $$LocalAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localAccountId,
      referencedTable: $db.localAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.localAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxTable,
          SyncOutboxData,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (SyncOutboxData, $$SyncOutboxTableReferences),
          SyncOutboxData,
          PrefetchHooks Function({bool localAccountId})
        > {
  $$SyncOutboxTableTableManager(_$AppDatabase db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> localAccountId = const Value.absent(),
                Value<String?> authUserId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<int> localRowId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> dependencyRank = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> baseRemoteUpdatedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncOutboxCompanion(
                id: id,
                localAccountId: localAccountId,
                authUserId: authUserId,
                entityType: entityType,
                localRowId: localRowId,
                serverId: serverId,
                operation: operation,
                state: state,
                dependencyRank: dependencyRank,
                queuedAt: queuedAt,
                updatedAt: updatedAt,
                nextAttemptAt: nextAttemptAt,
                attemptCount: attemptCount,
                baseRemoteUpdatedAt: baseRemoteUpdatedAt,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int localAccountId,
                Value<String?> authUserId = const Value.absent(),
                required String entityType,
                required int localRowId,
                Value<String?> serverId = const Value.absent(),
                required String operation,
                Value<String> state = const Value.absent(),
                Value<int> dependencyRank = const Value.absent(),
                required DateTime queuedAt,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> baseRemoteUpdatedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                id: id,
                localAccountId: localAccountId,
                authUserId: authUserId,
                entityType: entityType,
                localRowId: localRowId,
                serverId: serverId,
                operation: operation,
                state: state,
                dependencyRank: dependencyRank,
                queuedAt: queuedAt,
                updatedAt: updatedAt,
                nextAttemptAt: nextAttemptAt,
                attemptCount: attemptCount,
                baseRemoteUpdatedAt: baseRemoteUpdatedAt,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncOutboxTable, SyncOutboxData>(table),
                  $$SyncOutboxTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localAccountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localAccountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localAccountId,
                        referencedTable: $$SyncOutboxTableReferences
                            ._localAccountIdTable(db),
                        referencedColumn: $$SyncOutboxTableReferences
                            ._localAccountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxTable,
      SyncOutboxData,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (SyncOutboxData, $$SyncOutboxTableReferences),
      SyncOutboxData,
      PrefetchHooks Function({bool localAccountId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalAccountsTableTableManager get localAccounts =>
      $$LocalAccountsTableTableManager(_db, _db.localAccounts);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$MoneyTransactionsTableTableManager get moneyTransactions =>
      $$MoneyTransactionsTableTableManager(_db, _db.moneyTransactions);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$ProfileDataTableTableManager get profileData =>
      $$ProfileDataTableTableManager(_db, _db.profileData);
  $$TransactionDetectionEventsTableTableManager
  get transactionDetectionEvents =>
      $$TransactionDetectionEventsTableTableManager(
        _db,
        _db.transactionDetectionEvents,
      );
  $$TransactionCandidatesTableTableManager get transactionCandidates =>
      $$TransactionCandidatesTableTableManager(_db, _db.transactionCandidates);
  $$MerchantCategoryRulesTableTableManager get merchantCategoryRules =>
      $$MerchantCategoryRulesTableTableManager(_db, _db.merchantCategoryRules);
  $$YoutubePlaylistsTableTableManager get youtubePlaylists =>
      $$YoutubePlaylistsTableTableManager(_db, _db.youtubePlaylists);
  $$YoutubeVideosTableTableManager get youtubeVideos =>
      $$YoutubeVideosTableTableManager(_db, _db.youtubeVideos);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
}
