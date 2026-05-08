enum ReminderFrequency {
  once,
  daily,
  weekly,
  monthly;

  String get value {
    switch (this) {
      case ReminderFrequency.once:
        return 'once';
      case ReminderFrequency.daily:
        return 'daily';
      case ReminderFrequency.weekly:
        return 'weekly';
      case ReminderFrequency.monthly:
        return 'monthly';
    }
  }

  String get label {
    switch (this) {
      case ReminderFrequency.once:
        return 'Bir kez';
      case ReminderFrequency.daily:
        return 'Günlük';
      case ReminderFrequency.weekly:
        return 'Haftalık';
      case ReminderFrequency.monthly:
        return 'Aylık';
    }
  }

  static ReminderFrequency fromValue(String? value) {
    switch (value) {
      case 'daily':
        return ReminderFrequency.daily;
      case 'weekly':
        return ReminderFrequency.weekly;
      case 'monthly':
        return ReminderFrequency.monthly;
      default:
        return ReminderFrequency.once;
    }
  }
}

class ReminderModel {
  final int? id;
  final String title;
  final String? note;
  final String remindAt;
  final bool isDone;
  final String createdAt;

  const ReminderModel({
    this.id,
    required this.title,
    this.note,
    required this.remindAt,
    required this.isDone,
    required this.createdAt,
  });

  DateTime get dateTime => DateTime.parse(remindAt);

  bool get enabled => !isDone;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'remind_at': remindAt,
      'is_done': isDone ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      note: map['note'] as String?,
      remindAt: map['remind_at'] as String,
      isDone: (map['is_done'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  ReminderModel copyWith({
    int? id,
    String? title,
    String? note,
    String? remindAt,
    bool? isDone,
    String? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      remindAt: remindAt ?? this.remindAt,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
