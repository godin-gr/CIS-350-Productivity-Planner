import 'package:hive/hive.dart';

part 'task_model.g.dart';

/// Data model for a task inside a queue.
///
/// A task stores its title, optional due date and description, completion state,
/// archive state, ordering values, and whether it has been moved into the
/// Completed section.
@HiveType(typeId: 1)
class Task extends HiveObject {
  /// Hive-generated id for this task.
  @HiveField(0)
  int? id;

  /// Id of the queue this task belongs to.
  @HiveField(1)
  int queueId;

  /// Main title displayed for the task.
  @HiveField(2)
  String title;

  /// Optional due date stored as a formatted string.
  @HiveField(3)
  String? dueDate;

  /// Whether the task has been marked complete.
  @HiveField(4)
  bool isComplete;

  /// Whether the task has been archived.
  @HiveField(5)
  bool isArchived;

  /// Saved order for preferred task sorting inside a queue.
  @HiveField(6)
  int preferredOrder;

  /// Optional longer description for the task.
  @HiveField(7)
  String? description;

  /// Saved order for the task on the Home page.
  ///
  /// A value of -1 means no custom Home order is currently set.
  @HiveField(8)
  int homeOrder;

  /// Time the task was completed, stored as milliseconds since epoch.
  ///
  /// A value of 0 means the task is not currently completed.
  @HiveField(9)
  int completedAt;

  /// Whether the task has been moved into the Completed section.
  @HiveField(10)
  bool isFiled;

  /// Creates a task with optional due date, description, and status values.
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

  /// Creates a copy of this task with selected fields replaced.
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