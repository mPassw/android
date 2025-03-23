// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class PasswordAdapter extends TypeAdapter<Password> {
  @override
  final int typeId = 0;

  @override
  Password read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Password(
      id: fields[0] as String?,
      title: fields[1] as String?,
      username: fields[2] as String?,
      password: fields[3] as String?,
      note: fields[4] as String?,
      tags: (fields[5] as List?)?.cast<String>(),
      websites: (fields[6] as List?)?.cast<String>(),
      createdAt: fields[7] as String?,
      updatedAt: fields[8] as String?,
      inTrash: fields[9] == null ? false : fields[9] as bool,
      decrypted: fields[10] == null ? false : fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Password obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.websites)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.inTrash)
      ..writeByte(10)
      ..write(obj.decrypted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
