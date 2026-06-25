import 'package:hive/hive.dart';

part 'queue_model.g.dart';

/// Ordering options for tasks inside a queue.
enum OrderMode { preferred, dueDate }

/// Data model for a productivity queue.
///
/// A queue groups related tasks together and stores display, sorting, archive,
/// completion, and Home page visibility information.
@HiveType(typeId: 0)
class Queue extends HiveObject {
  /// Hive-generated id for this queue.
  @HiveField(0)
  int? id;

  /// Name displayed for the queue.
  @HiveField(1)
  String name;

  /// Whether this queue has been archived.
  @HiveField(2)
  bool isArchived;

  /// Whether this queue has been marked complete.
  @HiveField(3)
  bool isComplete;

  /// Stored index for the queue's selected task ordering mode.
  @HiveField(4)
  int orderModeIndex;

  /// Optional longer description for the queue.
  @HiveField(5)
  String? description;

  /// Saved order used when displaying queues in a custom order.
  @HiveField(6)
  int sortOrder;

  /// Whether this queue should be hidden from the Home page summary.
  @HiveField(7)
  bool hiddenFromHome;

  /// Creates a queue with optional status and display settings.
  Queue({
    this.id,
    required this.name,
    this.isArchived = false,
    this.isComplete = false,
    this.orderModeIndex = 1,
    this.description,
    this.sortOrder = 0,
    this.hiddenFromHome = false,
  });

  /// Returns the stored order mode as an [OrderMode] enum value.
  OrderMode get orderMode => OrderMode.values[orderModeIndex];

  /// Saves an [OrderMode] enum value as its index.
  set orderMode(OrderMode mode) => orderModeIndex = mode.index;

  /// Creates a copy of this queue with selected fields replaced.
  Queue copyWith({
    int? id,
    String? name,
    bool? isArchived,
    bool? isComplete,
    int? orderModeIndex,
    String? description,
    int? sortOrder,
    bool? hiddenFromHome,
  }) {
    return Queue(
      id: id ?? this.id,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      isComplete: isComplete ?? this.isComplete,
      orderModeIndex: orderModeIndex ?? this.orderModeIndex,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      hiddenFromHome: hiddenFromHome ?? this.hiddenFromHome,
    );
  }
}