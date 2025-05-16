// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as int,
      name: fields[1] as String,
      stock: fields[2] as int,
      price: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.stock)
      ..writeByte(3)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 2;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      id: fields[0] as int,
      clientId: fields[1] as int,
      date: fields[2] as DateTime,
      items: (fields[3] as List).cast<OrderItem>(),
      clientName: fields[6] as String,
      status: fields[4] as OrderStatus,
      employeeId: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.employeeId)
      ..writeByte(6)
      ..write(obj.clientName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderItemAdapter extends TypeAdapter<OrderItem> {
  @override
  final int typeId = 3;

  @override
  OrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderItem(
      productId: fields[0] as int,
      name: fields[1] as String,
      quantity: fields[2] as int,
      price: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, OrderItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 4;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      username: fields[0] as String,
      password: fields[1] as String,
      role: fields[2] as String,
      name: fields[3] as String,
      clientId: fields[4] as int?,
      employeeId: fields[5] as int?,
      status: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.password)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.clientId)
      ..writeByte(5)
      ..write(obj.employeeId)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttendanceLogAdapter extends TypeAdapter<AttendanceLog> {
  @override
  final int typeId = 5;

  @override
  AttendanceLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceLog(
      username: fields[0] as String,
      role: fields[1] as String,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.role)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderStatusAdapter extends TypeAdapter<OrderStatus> {
  @override
  final int typeId = 1;

  @override
  OrderStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OrderStatus.pending;
      case 1:
        return OrderStatus.processing;
      case 2:
        return OrderStatus.shipped;
      case 3:
        return OrderStatus.delivered;
      case 4:
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, OrderStatus obj) {
    switch (obj) {
      case OrderStatus.pending:
        writer.writeByte(0);
        break;
      case OrderStatus.processing:
        writer.writeByte(1);
        break;
      case OrderStatus.shipped:
        writer.writeByte(2);
        break;
      case OrderStatus.delivered:
        writer.writeByte(3);
        break;
      case OrderStatus.cancelled:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
