// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountType>($AccountsTable.$convertertype);
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _closedMeta = const VerificationMeta('closed');
  @override
  late final GeneratedColumn<bool> closed = GeneratedColumn<bool>(
    'closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("closed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, type, balance, closed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    if (data.containsKey('closed')) {
      context.handle(
        _closedMeta,
        closed.isAcceptableOrUnknown(data['closed']!, _closedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $AccountsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      closed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}closed'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $convertertype =
      const EnumNameConverter<AccountType>(AccountType.values);
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String name;
  final AccountType type;
  final double balance;

  /// Closed accounts keep their statements but take no new ones.
  final bool closed;
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.closed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($AccountsTable.$convertertype.toSql(type));
    }
    map['balance'] = Variable<double>(balance);
    map['closed'] = Variable<bool>(closed);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      balance: Value(balance),
      closed: Value(closed),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $AccountsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      balance: serializer.fromJson<double>(json['balance']),
      closed: serializer.fromJson<bool>(json['closed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $AccountsTable.$convertertype.toJson(type),
      ),
      'balance': serializer.toJson<double>(balance),
      'closed': serializer.toJson<bool>(closed),
    };
  }

  Account copyWith({
    int? id,
    String? name,
    AccountType? type,
    double? balance,
    bool? closed,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    balance: balance ?? this.balance,
    closed: closed ?? this.closed,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      balance: data.balance.present ? data.balance.value : this.balance,
      closed: data.closed.present ? data.closed.value : this.closed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('balance: $balance, ')
          ..write('closed: $closed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, balance, closed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.balance == this.balance &&
          other.closed == this.closed);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> name;
  final Value<AccountType> type;
  final Value<double> balance;
  final Value<bool> closed;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.balance = const Value.absent(),
    this.closed = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required AccountType type,
    this.balance = const Value.absent(),
    this.closed = const Value.absent(),
  }) : name = Value(name),
       type = Value(type);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<double>? balance,
    Expression<bool>? closed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (balance != null) 'balance': balance,
      if (closed != null) 'closed': closed,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<AccountType>? type,
    Value<double>? balance,
    Value<bool>? closed,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      closed: closed ?? this.closed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AccountsTable.$convertertype.toSql(type.value),
      );
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (closed.present) {
      map['closed'] = Variable<bool>(closed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('balance: $balance, ')
          ..write('closed: $closed')
          ..write(')'))
        .toString();
  }
}

class $RecurrencesTable extends Recurrences
    with TableInfo<$RecurrencesTable, Recurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurrencesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecurrenceUnit, String> unit =
      GeneratedColumn<String>(
        'unit',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecurrenceUnit>($RecurrencesTable.$converterunit);
  static const VerificationMeta _everyMeta = const VerificationMeta('every');
  @override
  late final GeneratedColumn<int> every = GeneratedColumn<int>(
    'every',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedMeta = const VerificationMeta(
    'generated',
  );
  @override
  late final GeneratedColumn<int> generated = GeneratedColumn<int>(
    'generated',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aheadMeta = const VerificationMeta('ahead');
  @override
  late final GeneratedColumn<bool> ahead = GeneratedColumn<bool>(
    'ahead',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ahead" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    start,
    unit,
    every,
    generated,
    ahead,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('every')) {
      context.handle(
        _everyMeta,
        every.isAcceptableOrUnknown(data['every']!, _everyMeta),
      );
    } else if (isInserting) {
      context.missing(_everyMeta);
    }
    if (data.containsKey('generated')) {
      context.handle(
        _generatedMeta,
        generated.isAcceptableOrUnknown(data['generated']!, _generatedMeta),
      );
    } else if (isInserting) {
      context.missing(_generatedMeta);
    }
    if (data.containsKey('ahead')) {
      context.handle(
        _aheadMeta,
        ahead.isAcceptableOrUnknown(data['ahead']!, _aheadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recurrence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start'],
      )!,
      unit: $RecurrencesTable.$converterunit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit'],
        )!,
      ),
      every: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}every'],
      )!,
      generated: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generated'],
      )!,
      ahead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ahead'],
      )!,
    );
  }

  @override
  $RecurrencesTable createAlias(String alias) {
    return $RecurrencesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RecurrenceUnit, String, String> $converterunit =
      const EnumNameConverter<RecurrenceUnit>(RecurrenceUnit.values);
}

class Recurrence extends DataClass implements Insertable<Recurrence> {
  final int id;

  /// Payment date of occurrence 0; occurrence n is `unit.occurrence(start,
  /// every, n)`. Counting from a fixed start avoids drift from clamped days.
  final DateTime start;
  final RecurrenceUnit unit;
  final int every;

  /// Occurrences already created, i.e. the index of the next one.
  final int generated;

  /// Create the next statement up to a month before it is due (only one).
  final bool ahead;
  const Recurrence({
    required this.id,
    required this.start,
    required this.unit,
    required this.every,
    required this.generated,
    required this.ahead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start'] = Variable<DateTime>(start);
    {
      map['unit'] = Variable<String>(
        $RecurrencesTable.$converterunit.toSql(unit),
      );
    }
    map['every'] = Variable<int>(every);
    map['generated'] = Variable<int>(generated);
    map['ahead'] = Variable<bool>(ahead);
    return map;
  }

  RecurrencesCompanion toCompanion(bool nullToAbsent) {
    return RecurrencesCompanion(
      id: Value(id),
      start: Value(start),
      unit: Value(unit),
      every: Value(every),
      generated: Value(generated),
      ahead: Value(ahead),
    );
  }

  factory Recurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recurrence(
      id: serializer.fromJson<int>(json['id']),
      start: serializer.fromJson<DateTime>(json['start']),
      unit: $RecurrencesTable.$converterunit.fromJson(
        serializer.fromJson<String>(json['unit']),
      ),
      every: serializer.fromJson<int>(json['every']),
      generated: serializer.fromJson<int>(json['generated']),
      ahead: serializer.fromJson<bool>(json['ahead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'start': serializer.toJson<DateTime>(start),
      'unit': serializer.toJson<String>(
        $RecurrencesTable.$converterunit.toJson(unit),
      ),
      'every': serializer.toJson<int>(every),
      'generated': serializer.toJson<int>(generated),
      'ahead': serializer.toJson<bool>(ahead),
    };
  }

  Recurrence copyWith({
    int? id,
    DateTime? start,
    RecurrenceUnit? unit,
    int? every,
    int? generated,
    bool? ahead,
  }) => Recurrence(
    id: id ?? this.id,
    start: start ?? this.start,
    unit: unit ?? this.unit,
    every: every ?? this.every,
    generated: generated ?? this.generated,
    ahead: ahead ?? this.ahead,
  );
  Recurrence copyWithCompanion(RecurrencesCompanion data) {
    return Recurrence(
      id: data.id.present ? data.id.value : this.id,
      start: data.start.present ? data.start.value : this.start,
      unit: data.unit.present ? data.unit.value : this.unit,
      every: data.every.present ? data.every.value : this.every,
      generated: data.generated.present ? data.generated.value : this.generated,
      ahead: data.ahead.present ? data.ahead.value : this.ahead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recurrence(')
          ..write('id: $id, ')
          ..write('start: $start, ')
          ..write('unit: $unit, ')
          ..write('every: $every, ')
          ..write('generated: $generated, ')
          ..write('ahead: $ahead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, start, unit, every, generated, ahead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recurrence &&
          other.id == this.id &&
          other.start == this.start &&
          other.unit == this.unit &&
          other.every == this.every &&
          other.generated == this.generated &&
          other.ahead == this.ahead);
}

class RecurrencesCompanion extends UpdateCompanion<Recurrence> {
  final Value<int> id;
  final Value<DateTime> start;
  final Value<RecurrenceUnit> unit;
  final Value<int> every;
  final Value<int> generated;
  final Value<bool> ahead;
  const RecurrencesCompanion({
    this.id = const Value.absent(),
    this.start = const Value.absent(),
    this.unit = const Value.absent(),
    this.every = const Value.absent(),
    this.generated = const Value.absent(),
    this.ahead = const Value.absent(),
  });
  RecurrencesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime start,
    required RecurrenceUnit unit,
    required int every,
    required int generated,
    this.ahead = const Value.absent(),
  }) : start = Value(start),
       unit = Value(unit),
       every = Value(every),
       generated = Value(generated);
  static Insertable<Recurrence> custom({
    Expression<int>? id,
    Expression<DateTime>? start,
    Expression<String>? unit,
    Expression<int>? every,
    Expression<int>? generated,
    Expression<bool>? ahead,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (start != null) 'start': start,
      if (unit != null) 'unit': unit,
      if (every != null) 'every': every,
      if (generated != null) 'generated': generated,
      if (ahead != null) 'ahead': ahead,
    });
  }

  RecurrencesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? start,
    Value<RecurrenceUnit>? unit,
    Value<int>? every,
    Value<int>? generated,
    Value<bool>? ahead,
  }) {
    return RecurrencesCompanion(
      id: id ?? this.id,
      start: start ?? this.start,
      unit: unit ?? this.unit,
      every: every ?? this.every,
      generated: generated ?? this.generated,
      ahead: ahead ?? this.ahead,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(
        $RecurrencesTable.$converterunit.toSql(unit.value),
      );
    }
    if (every.present) {
      map['every'] = Variable<int>(every.value);
    }
    if (generated.present) {
      map['generated'] = Variable<int>(generated.value);
    }
    if (ahead.present) {
      map['ahead'] = Variable<bool>(ahead.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrencesCompanion(')
          ..write('id: $id, ')
          ..write('start: $start, ')
          ..write('unit: $unit, ')
          ..write('every: $every, ')
          ..write('generated: $generated, ')
          ..write('ahead: $ahead')
          ..write(')'))
        .toString();
  }
}

class $StatementsTable extends Statements
    with TableInfo<$StatementsTable, Statement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StatementsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentDateMeta = const VerificationMeta(
    'paymentDate',
  );
  @override
  late final GeneratedColumn<DateTime> paymentDate = GeneratedColumn<DateTime>(
    'payment_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountMeta = const VerificationMeta(
    'account',
  );
  @override
  late final GeneratedColumn<int> account = GeneratedColumn<int>(
    'account',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _useDateMeta = const VerificationMeta(
    'useDate',
  );
  @override
  late final GeneratedColumn<DateTime> useDate = GeneratedColumn<DateTime>(
    'use_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($StatementsTable.$convertertags);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recurrenceMeta = const VerificationMeta(
    'recurrence',
  );
  @override
  late final GeneratedColumn<int> recurrence = GeneratedColumn<int>(
    'recurrence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recurrences (id)',
    ),
  );
  static const VerificationMeta _transferMeta = const VerificationMeta(
    'transfer',
  );
  @override
  late final GeneratedColumn<int> transfer = GeneratedColumn<int>(
    'transfer',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES statements (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    title,
    paymentDate,
    account,
    useDate,
    amount,
    tags,
    note,
    recurrence,
    transfer,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'statements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Statement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('payment_date')) {
      context.handle(
        _paymentDateMeta,
        paymentDate.isAcceptableOrUnknown(
          data['payment_date']!,
          _paymentDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentDateMeta);
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    } else if (isInserting) {
      context.missing(_accountMeta);
    }
    if (data.containsKey('use_date')) {
      context.handle(
        _useDateMeta,
        useDate.isAcceptableOrUnknown(data['use_date']!, _useDateMeta),
      );
    } else if (isInserting) {
      context.missing(_useDateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('recurrence')) {
      context.handle(
        _recurrenceMeta,
        recurrence.isAcceptableOrUnknown(data['recurrence']!, _recurrenceMeta),
      );
    }
    if (data.containsKey('transfer')) {
      context.handle(
        _transferMeta,
        transfer.isAcceptableOrUnknown(data['transfer']!, _transferMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Statement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Statement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      paymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}payment_date'],
      )!,
      account: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account'],
      )!,
      useDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}use_date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      tags: $StatementsTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      recurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence'],
      ),
      transfer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transfer'],
      ),
    );
  }

  @override
  $StatementsTable createAlias(String alias) {
    return $StatementsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertertags =
      const ListConverter<String>();
}

class Statement extends DataClass implements Insertable<Statement> {
  final int id;
  final DateTime createdAt;
  final String title;
  final DateTime paymentDate;
  final int account;
  final DateTime useDate;
  final double amount;
  final List<String> tags;
  final String note;
  final int? recurrence;

  /// The other side of a transfer between two accounts; both point at each
  /// other.
  final int? transfer;
  const Statement({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.paymentDate,
    required this.account,
    required this.useDate,
    required this.amount,
    required this.tags,
    required this.note,
    this.recurrence,
    this.transfer,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['title'] = Variable<String>(title);
    map['payment_date'] = Variable<DateTime>(paymentDate);
    map['account'] = Variable<int>(account);
    map['use_date'] = Variable<DateTime>(useDate);
    map['amount'] = Variable<double>(amount);
    {
      map['tags'] = Variable<String>(
        $StatementsTable.$convertertags.toSql(tags),
      );
    }
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || recurrence != null) {
      map['recurrence'] = Variable<int>(recurrence);
    }
    if (!nullToAbsent || transfer != null) {
      map['transfer'] = Variable<int>(transfer);
    }
    return map;
  }

  StatementsCompanion toCompanion(bool nullToAbsent) {
    return StatementsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      title: Value(title),
      paymentDate: Value(paymentDate),
      account: Value(account),
      useDate: Value(useDate),
      amount: Value(amount),
      tags: Value(tags),
      note: Value(note),
      recurrence: recurrence == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrence),
      transfer: transfer == null && nullToAbsent
          ? const Value.absent()
          : Value(transfer),
    );
  }

  factory Statement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Statement(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      title: serializer.fromJson<String>(json['title']),
      paymentDate: serializer.fromJson<DateTime>(json['paymentDate']),
      account: serializer.fromJson<int>(json['account']),
      useDate: serializer.fromJson<DateTime>(json['useDate']),
      amount: serializer.fromJson<double>(json['amount']),
      tags: serializer.fromJson<List<String>>(json['tags']),
      note: serializer.fromJson<String>(json['note']),
      recurrence: serializer.fromJson<int?>(json['recurrence']),
      transfer: serializer.fromJson<int?>(json['transfer']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'title': serializer.toJson<String>(title),
      'paymentDate': serializer.toJson<DateTime>(paymentDate),
      'account': serializer.toJson<int>(account),
      'useDate': serializer.toJson<DateTime>(useDate),
      'amount': serializer.toJson<double>(amount),
      'tags': serializer.toJson<List<String>>(tags),
      'note': serializer.toJson<String>(note),
      'recurrence': serializer.toJson<int?>(recurrence),
      'transfer': serializer.toJson<int?>(transfer),
    };
  }

  Statement copyWith({
    int? id,
    DateTime? createdAt,
    String? title,
    DateTime? paymentDate,
    int? account,
    DateTime? useDate,
    double? amount,
    List<String>? tags,
    String? note,
    Value<int?> recurrence = const Value.absent(),
    Value<int?> transfer = const Value.absent(),
  }) => Statement(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    title: title ?? this.title,
    paymentDate: paymentDate ?? this.paymentDate,
    account: account ?? this.account,
    useDate: useDate ?? this.useDate,
    amount: amount ?? this.amount,
    tags: tags ?? this.tags,
    note: note ?? this.note,
    recurrence: recurrence.present ? recurrence.value : this.recurrence,
    transfer: transfer.present ? transfer.value : this.transfer,
  );
  Statement copyWithCompanion(StatementsCompanion data) {
    return Statement(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      title: data.title.present ? data.title.value : this.title,
      paymentDate: data.paymentDate.present
          ? data.paymentDate.value
          : this.paymentDate,
      account: data.account.present ? data.account.value : this.account,
      useDate: data.useDate.present ? data.useDate.value : this.useDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      tags: data.tags.present ? data.tags.value : this.tags,
      note: data.note.present ? data.note.value : this.note,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      transfer: data.transfer.present ? data.transfer.value : this.transfer,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Statement(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('title: $title, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('account: $account, ')
          ..write('useDate: $useDate, ')
          ..write('amount: $amount, ')
          ..write('tags: $tags, ')
          ..write('note: $note, ')
          ..write('recurrence: $recurrence, ')
          ..write('transfer: $transfer')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    title,
    paymentDate,
    account,
    useDate,
    amount,
    tags,
    note,
    recurrence,
    transfer,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Statement &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.title == this.title &&
          other.paymentDate == this.paymentDate &&
          other.account == this.account &&
          other.useDate == this.useDate &&
          other.amount == this.amount &&
          other.tags == this.tags &&
          other.note == this.note &&
          other.recurrence == this.recurrence &&
          other.transfer == this.transfer);
}

class StatementsCompanion extends UpdateCompanion<Statement> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String> title;
  final Value<DateTime> paymentDate;
  final Value<int> account;
  final Value<DateTime> useDate;
  final Value<double> amount;
  final Value<List<String>> tags;
  final Value<String> note;
  final Value<int?> recurrence;
  final Value<int?> transfer;
  const StatementsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.title = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.account = const Value.absent(),
    this.useDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.tags = const Value.absent(),
    this.note = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.transfer = const Value.absent(),
  });
  StatementsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required String title,
    required DateTime paymentDate,
    required int account,
    required DateTime useDate,
    required double amount,
    required List<String> tags,
    required String note,
    this.recurrence = const Value.absent(),
    this.transfer = const Value.absent(),
  }) : createdAt = Value(createdAt),
       title = Value(title),
       paymentDate = Value(paymentDate),
       account = Value(account),
       useDate = Value(useDate),
       amount = Value(amount),
       tags = Value(tags),
       note = Value(note);
  static Insertable<Statement> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? title,
    Expression<DateTime>? paymentDate,
    Expression<int>? account,
    Expression<DateTime>? useDate,
    Expression<double>? amount,
    Expression<String>? tags,
    Expression<String>? note,
    Expression<int>? recurrence,
    Expression<int>? transfer,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (title != null) 'title': title,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (account != null) 'account': account,
      if (useDate != null) 'use_date': useDate,
      if (amount != null) 'amount': amount,
      if (tags != null) 'tags': tags,
      if (note != null) 'note': note,
      if (recurrence != null) 'recurrence': recurrence,
      if (transfer != null) 'transfer': transfer,
    });
  }

  StatementsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? createdAt,
    Value<String>? title,
    Value<DateTime>? paymentDate,
    Value<int>? account,
    Value<DateTime>? useDate,
    Value<double>? amount,
    Value<List<String>>? tags,
    Value<String>? note,
    Value<int?>? recurrence,
    Value<int?>? transfer,
  }) {
    return StatementsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      paymentDate: paymentDate ?? this.paymentDate,
      account: account ?? this.account,
      useDate: useDate ?? this.useDate,
      amount: amount ?? this.amount,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      recurrence: recurrence ?? this.recurrence,
      transfer: transfer ?? this.transfer,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<DateTime>(paymentDate.value);
    }
    if (account.present) {
      map['account'] = Variable<int>(account.value);
    }
    if (useDate.present) {
      map['use_date'] = Variable<DateTime>(useDate.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $StatementsTable.$convertertags.toSql(tags.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<int>(recurrence.value);
    }
    if (transfer.present) {
      map['transfer'] = Variable<int>(transfer.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StatementsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('title: $title, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('account: $account, ')
          ..write('useDate: $useDate, ')
          ..write('amount: $amount, ')
          ..write('tags: $tags, ')
          ..write('note: $note, ')
          ..write('recurrence: $recurrence, ')
          ..write('transfer: $transfer')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<BigInt> id = GeneratedColumn<BigInt>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF9E9E9E),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final BigInt id;
  final String name;
  final int color;
  const Tag({required this.id, required this.name, required this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<BigInt>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), name: Value(name), color: Value(color));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<BigInt>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<BigInt>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
    };
  }

  Tag copyWith({BigInt? id, String? name, int? color}) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<BigInt> id;
  final Value<String> name;
  final Value<int> color;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Tag> custom({
    Expression<BigInt>? id,
    Expression<String>? name,
    Expression<int>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
  }

  TagsCompanion copyWith({
    Value<BigInt>? id,
    Value<String>? name,
    Value<int>? color,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<BigInt>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $RecurrencesTable recurrences = $RecurrencesTable(this);
  late final $StatementsTable statements = $StatementsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    recurrences,
    statements,
    tags,
    settings,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required String name,
      required AccountType type,
      Value<double> balance,
      Value<bool> closed,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<AccountType> type,
      Value<double> balance,
      Value<bool> closed,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StatementsTable, List<Statement>>
  _statementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.statements,
    aliasName: 'accounts__id__statements__account',
  );

  $$StatementsTableProcessedTableManager get statementsRefs {
    final manager = $$StatementsTableTableManager(
      $_db,
      $_db.statements,
    ).filter((f) => f.account.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_statementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccountType, AccountType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> statementsRefs(
    Expression<bool> Function($$StatementsTableFilterComposer f) f,
  ) {
    final $$StatementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.statements,
      getReferencedColumn: (t) => t.account,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StatementsTableFilterComposer(
            $db: $db,
            $table: $db.statements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<bool> get closed =>
      $composableBuilder(column: $table.closed, builder: (column) => column);

  Expression<T> statementsRefs<T extends Object>(
    Expression<T> Function($$StatementsTableAnnotationComposer a) f,
  ) {
    final $$StatementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.statements,
      getReferencedColumn: (t) => t.account,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StatementsTableAnnotationComposer(
            $db: $db,
            $table: $db.statements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool statementsRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AccountType> type = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<bool> closed = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                type: type,
                balance: balance,
                closed: closed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required AccountType type,
                Value<double> balance = const Value.absent(),
                Value<bool> closed = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                type: type,
                balance: balance,
                closed: closed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, Account>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({statementsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (statementsRefs) db.statements],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (statementsRefs)
                    await $_getPrefetchedDataByColumns<
                      Account,
                      $AccountsTable,
                      Statement,
                      $StatementsTable
                    >(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences
                          ._statementsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(
                        db,
                        table,
                        p0,
                      ).statementsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'account',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool statementsRefs})
    >;
typedef $$RecurrencesTableCreateCompanionBuilder =
    RecurrencesCompanion Function({
      Value<int> id,
      required DateTime start,
      required RecurrenceUnit unit,
      required int every,
      required int generated,
      Value<bool> ahead,
    });
typedef $$RecurrencesTableUpdateCompanionBuilder =
    RecurrencesCompanion Function({
      Value<int> id,
      Value<DateTime> start,
      Value<RecurrenceUnit> unit,
      Value<int> every,
      Value<int> generated,
      Value<bool> ahead,
    });

final class $$RecurrencesTableReferences
    extends BaseReferences<_$AppDatabase, $RecurrencesTable, Recurrence> {
  $$RecurrencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StatementsTable, List<Statement>>
  _statementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.statements,
    aliasName: 'recurrences__id__statements__recurrence',
  );

  $$StatementsTableProcessedTableManager get statementsRefs {
    final manager = $$StatementsTableTableManager(
      $_db,
      $_db.statements,
    ).filter((f) => f.recurrence.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_statementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableFilterComposer({
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

  ColumnFilters<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RecurrenceUnit, RecurrenceUnit, String>
  get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get every => $composableBuilder(
    column: $table.every,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generated => $composableBuilder(
    column: $table.generated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ahead => $composableBuilder(
    column: $table.ahead,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> statementsRefs(
    Expression<bool> Function($$StatementsTableFilterComposer f) f,
  ) {
    final $$StatementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.statements,
      getReferencedColumn: (t) => t.recurrence,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StatementsTableFilterComposer(
            $db: $db,
            $table: $db.statements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get every => $composableBuilder(
    column: $table.every,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generated => $composableBuilder(
    column: $table.generated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ahead => $composableBuilder(
    column: $table.ahead,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RecurrenceUnit, String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get every =>
      $composableBuilder(column: $table.every, builder: (column) => column);

  GeneratedColumn<int> get generated =>
      $composableBuilder(column: $table.generated, builder: (column) => column);

  GeneratedColumn<bool> get ahead =>
      $composableBuilder(column: $table.ahead, builder: (column) => column);

  Expression<T> statementsRefs<T extends Object>(
    Expression<T> Function($$StatementsTableAnnotationComposer a) f,
  ) {
    final $$StatementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.statements,
      getReferencedColumn: (t) => t.recurrence,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StatementsTableAnnotationComposer(
            $db: $db,
            $table: $db.statements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurrencesTable,
          Recurrence,
          $$RecurrencesTableFilterComposer,
          $$RecurrencesTableOrderingComposer,
          $$RecurrencesTableAnnotationComposer,
          $$RecurrencesTableCreateCompanionBuilder,
          $$RecurrencesTableUpdateCompanionBuilder,
          (Recurrence, $$RecurrencesTableReferences),
          Recurrence,
          PrefetchHooks Function({bool statementsRefs})
        > {
  $$RecurrencesTableTableManager(_$AppDatabase db, $RecurrencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> start = const Value.absent(),
                Value<RecurrenceUnit> unit = const Value.absent(),
                Value<int> every = const Value.absent(),
                Value<int> generated = const Value.absent(),
                Value<bool> ahead = const Value.absent(),
              }) => RecurrencesCompanion(
                id: id,
                start: start,
                unit: unit,
                every: every,
                generated: generated,
                ahead: ahead,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime start,
                required RecurrenceUnit unit,
                required int every,
                required int generated,
                Value<bool> ahead = const Value.absent(),
              }) => RecurrencesCompanion.insert(
                id: id,
                start: start,
                unit: unit,
                every: every,
                generated: generated,
                ahead: ahead,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurrencesTable, Recurrence>(table),
                  $$RecurrencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({statementsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (statementsRefs) db.statements],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (statementsRefs)
                    await $_getPrefetchedDataByColumns<
                      Recurrence,
                      $RecurrencesTable,
                      Statement,
                      $StatementsTable
                    >(
                      currentTable: table,
                      referencedTable: $$RecurrencesTableReferences
                          ._statementsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RecurrencesTableReferences(
                            db,
                            table,
                            p0,
                          ).statementsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'recurrence',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurrencesTable,
      Recurrence,
      $$RecurrencesTableFilterComposer,
      $$RecurrencesTableOrderingComposer,
      $$RecurrencesTableAnnotationComposer,
      $$RecurrencesTableCreateCompanionBuilder,
      $$RecurrencesTableUpdateCompanionBuilder,
      (Recurrence, $$RecurrencesTableReferences),
      Recurrence,
      PrefetchHooks Function({bool statementsRefs})
    >;
typedef $$StatementsTableCreateCompanionBuilder =
    StatementsCompanion Function({
      Value<int> id,
      required DateTime createdAt,
      required String title,
      required DateTime paymentDate,
      required int account,
      required DateTime useDate,
      required double amount,
      required List<String> tags,
      required String note,
      Value<int?> recurrence,
      Value<int?> transfer,
    });
typedef $$StatementsTableUpdateCompanionBuilder =
    StatementsCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<String> title,
      Value<DateTime> paymentDate,
      Value<int> account,
      Value<DateTime> useDate,
      Value<double> amount,
      Value<List<String>> tags,
      Value<String> note,
      Value<int?> recurrence,
      Value<int?> transfer,
    });

final class $$StatementsTableReferences
    extends BaseReferences<_$AppDatabase, $StatementsTable, Statement> {
  $$StatementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountTable(_$AppDatabase db) =>
      db.accounts.createAlias('statements__account__accounts__id');

  $$AccountsTableProcessedTableManager get account {
    final $_column = $_itemColumn<int>('account')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RecurrencesTable _recurrenceTable(_$AppDatabase db) =>
      db.recurrences.createAlias('statements__recurrence__recurrences__id');

  $$RecurrencesTableProcessedTableManager? get recurrence {
    final $_column = $_itemColumn<int>('recurrence');
    if ($_column == null) return null;
    final manager = $$RecurrencesTableTableManager(
      $_db,
      $_db.recurrences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recurrenceTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StatementsTable _transferTable(_$AppDatabase db) =>
      db.statements.createAlias('statements__transfer__statements__id');

  $$StatementsTableProcessedTableManager? get transfer {
    final $_column = $_itemColumn<int>('transfer');
    if ($_column == null) return null;
    final manager = $$StatementsTableTableManager(
      $_db,
      $_db.statements,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transferTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StatementsTableFilterComposer
    extends Composer<_$AppDatabase, $StatementsTable> {
  $$StatementsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get useDate => $composableBuilder(
    column: $table.useDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get account {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.account,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurrencesTableFilterComposer get recurrence {
    final $$RecurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurrence,
      referencedTable: $db.recurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurrencesTableFilterComposer(
            $db: $db,
            $table: $db.recurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StatementsTableFilterComposer get transfer {
    final $$StatementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transfer,
      referencedTable: $db.statements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StatementsTableFilterComposer(
            $db: $db,
            $table: $db.statements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StatementsTableOrderingComposer
    extends Composer<_$AppDatabase, $StatementsTable> {
  $$StatementsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get useDate => $composableBuilder(
    column: $table.useDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get account {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.account,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurrencesTableOrderingComposer get recurrence {
    final $$RecurrencesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurrence,
      referencedTable: $db.recurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurrencesTableOrderingComposer(
            $db: $db,
            $table: $db.recurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StatementsTableOrderingComposer get transfer {
    final $$StatementsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transfer,
      referencedTable: $db.statements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StatementsTableOrderingComposer(
            $db: $db,
            $table: $db.statements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StatementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StatementsTable> {
  $$StatementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get useDate =>
      $composableBuilder(column: $table.useDate, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$AccountsTableAnnotationComposer get account {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.account,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurrencesTableAnnotationComposer get recurrence {
    final $$RecurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurrence,
      referencedTable: $db.recurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurrencesTableAnnotationComposer(
            $db: $db,
            $table: $db.recurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StatementsTableAnnotationComposer get transfer {
    final $$StatementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transfer,
      referencedTable: $db.statements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StatementsTableAnnotationComposer(
            $db: $db,
            $table: $db.statements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StatementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StatementsTable,
          Statement,
          $$StatementsTableFilterComposer,
          $$StatementsTableOrderingComposer,
          $$StatementsTableAnnotationComposer,
          $$StatementsTableCreateCompanionBuilder,
          $$StatementsTableUpdateCompanionBuilder,
          (Statement, $$StatementsTableReferences),
          Statement,
          PrefetchHooks Function({bool account, bool recurrence, bool transfer})
        > {
  $$StatementsTableTableManager(_$AppDatabase db, $StatementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StatementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StatementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StatementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> paymentDate = const Value.absent(),
                Value<int> account = const Value.absent(),
                Value<DateTime> useDate = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int?> recurrence = const Value.absent(),
                Value<int?> transfer = const Value.absent(),
              }) => StatementsCompanion(
                id: id,
                createdAt: createdAt,
                title: title,
                paymentDate: paymentDate,
                account: account,
                useDate: useDate,
                amount: amount,
                tags: tags,
                note: note,
                recurrence: recurrence,
                transfer: transfer,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime createdAt,
                required String title,
                required DateTime paymentDate,
                required int account,
                required DateTime useDate,
                required double amount,
                required List<String> tags,
                required String note,
                Value<int?> recurrence = const Value.absent(),
                Value<int?> transfer = const Value.absent(),
              }) => StatementsCompanion.insert(
                id: id,
                createdAt: createdAt,
                title: title,
                paymentDate: paymentDate,
                account: account,
                useDate: useDate,
                amount: amount,
                tags: tags,
                note: note,
                recurrence: recurrence,
                transfer: transfer,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StatementsTable, Statement>(table),
                  $$StatementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({account = false, recurrence = false, transfer = false}) {
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
                        if (account) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.account,
                                    referencedTable: $$StatementsTableReferences
                                        ._accountTable(db),
                                    referencedColumn:
                                        $$StatementsTableReferences
                                            ._accountTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (recurrence) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.recurrence,
                                    referencedTable: $$StatementsTableReferences
                                        ._recurrenceTable(db),
                                    referencedColumn:
                                        $$StatementsTableReferences
                                            ._recurrenceTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (transfer) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.transfer,
                                    referencedTable: $$StatementsTableReferences
                                        ._transferTable(db),
                                    referencedColumn:
                                        $$StatementsTableReferences
                                            ._transferTable(db)
                                            .id,
                                  )
                                  as T;
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

typedef $$StatementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StatementsTable,
      Statement,
      $$StatementsTableFilterComposer,
      $$StatementsTableOrderingComposer,
      $$StatementsTableAnnotationComposer,
      $$StatementsTableCreateCompanionBuilder,
      $$StatementsTableUpdateCompanionBuilder,
      (Statement, $$StatementsTableReferences),
      Statement,
      PrefetchHooks Function({bool account, bool recurrence, bool transfer})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      Value<BigInt> id,
      required String name,
      Value<int> color,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<BigInt> id,
      Value<String> name,
      Value<int> color,
    });

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<BigInt> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<BigInt> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<BigInt> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<BigInt> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
              }) => TagsCompanion(id: id, name: name, color: color),
          createCompanionCallback:
              ({
                Value<BigInt> id = const Value.absent(),
                required String name,
                Value<int> color = const Value.absent(),
              }) => TagsCompanion.insert(id: id, name: name, color: color),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  BaseReferences<_$AppDatabase, $TagsTable, Tag>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$RecurrencesTableTableManager get recurrences =>
      $$RecurrencesTableTableManager(_db, _db.recurrences);
  $$StatementsTableTableManager get statements =>
      $$StatementsTableTableManager(_db, _db.statements);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
