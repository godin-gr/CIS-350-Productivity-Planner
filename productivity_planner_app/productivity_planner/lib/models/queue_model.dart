import 'package:hive/hive.dart';

part 'queue_model.g.dart';

enum OrderMode { preferred, dueDate }

@HiveType(typeId: 0)
class Queue extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isArchived;

  @HiveField(3)
  bool isComplete;

  @HiveField(4)
  int orderModeIndex;

  @HiveField(5)
  String? description;

  @HiveField(6)
  int sortOrder;

  Queue({
    this.id,
    required this.name,
    this.isArchived = false,
    this.isComplete = false,
    this.orderModeIndex = 0,
    this.description,
    this.sortOrder = 0,
  });

  OrderMode get orderMode => OrderMode.values[orderModeIndex];
  set orderMode(OrderMode mode) => orderModeIndex = mode.index;

  Queue copyWith({
    int? id,
    String? name,
    bool? isArchived,
    bool? isComplete,
    int? orderModeIndex,
    String? description,
    int? sortOrder,
  }) {
    return Queue(
      id: id ?? this.id,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      isComplete: isComplete ?? this.isComplete,
      orderModeIndex: orderModeIndex ?? this.orderModeIndex,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}