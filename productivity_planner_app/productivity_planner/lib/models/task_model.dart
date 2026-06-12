import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  int queueId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String? dueDate;

  @HiveField(4)
  bool isComplete;

  @HiveField(5)
  bool isArchived;

  @HiveField(6)
  int preferredOrder;

  @HiveField(7)
  String? description;

  @HiveField(8)
  int homeOrder;

  @HiveField(9)
  int completedAt;

  @HiveField(10)
  bool isFiled;

  Task({
    this.id,
    required this.queueId,
    required this.title,
    this.dueDate,
    this.isComplete = false,
    this.isArchived = false,
    this.preferredOrder = 0,
    this.description,
    this.homeOrder = -1,
    this.completedAt = 0,
    this.isFiled = false,
  });

  Task copyWith({
    int? id,
    int? queueId,
    String? title,
    String? dueDate,
    bool? isComplete,
    bool? isArchived,
    int? preferredOrder,
    String? description,
    int? homeOrder,
    int? completedAt,
    bool? isFiled,
  }) {
    return Task(
      id: id ?? this.id,
      queueId: queueId ?? this.queueId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      isComplete: isComplete ?? this.isComplete,
      isArchived: isArchived ?? this.isArchived,
      preferredOrder: preferredOrder ?? this.preferredOrder,
      description: description ?? this.description,
      homeOrder: homeOrder ?? this.homeOrder,
      completedAt: completedAt ?? this.completedAt,
      isFiled: isFiled ?? this.isFiled,
    );
  }
}