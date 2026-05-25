// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnostic_result.dart';

class DiagnosticResultAdapter extends TypeAdapter<DiagnosticResult> {
  @override
  final int typeId = 1;

  @override
  DiagnosticResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiagnosticResult(
      id: fields[0] as String,
      type: fields[1] as String,
      target: fields[2] as String,
      data: (fields[3] as Map).cast<String, dynamic>(),
      success: fields[4] as bool,
      error: fields[5] as String?,
      timestamp: fields[6] as DateTime,
      durationMs: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DiagnosticResult obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.target)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.success)
      ..writeByte(5)
      ..write(obj.error)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.durationMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
