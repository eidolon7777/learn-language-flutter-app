import 'package:hive/hive.dart';

enum ModelType {
  asr,
  tts,
  vad,
  speakerId,
  punctuation,
  audioTagging,
  enhancement,
  separation,
  kws,
  lid,
  diarization
}

class ModelTypeAdapter extends TypeAdapter<ModelType> {
  @override
  final int typeId = 0;

  @override
  ModelType read(BinaryReader reader) {
    return ModelType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ModelType obj) {
    writer.writeByte(obj.index);
  }
}

class SherpaModel {
  final String id;
  final String name;
  final ModelType type;
  final String url;
  final String sha256;
  final int compressedSize;
  final int uncompressedSize;
  final String localPath;
  final bool isInstalled;

  const SherpaModel({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.sha256,
    required this.compressedSize,
    required this.uncompressedSize,
    this.localPath = '',
    this.isInstalled = false,
  });

  SherpaModel copyWith({
    String? localPath,
    bool? isInstalled,
  }) {
    return SherpaModel(
      id: id,
      name: name,
      type: type,
      url: url,
      sha256: sha256,
      compressedSize: compressedSize,
      uncompressedSize: uncompressedSize,
      localPath: localPath ?? this.localPath,
      isInstalled: isInstalled ?? this.isInstalled,
    );
  }
}

class SherpaModelAdapter extends TypeAdapter<SherpaModel> {
  @override
  final int typeId = 1;

  @override
  SherpaModel read(BinaryReader reader) {
    return SherpaModel(
      id: reader.readString(),
      name: reader.readString(),
      type: ModelType.values[reader.readByte()],
      url: reader.readString(),
      sha256: reader.readString(),
      compressedSize: reader.readInt(),
      uncompressedSize: reader.readInt(),
      localPath: reader.readString(),
      isInstalled: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, SherpaModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeByte(obj.type.index);
    writer.writeString(obj.url);
    writer.writeString(obj.sha256);
    writer.writeInt(obj.compressedSize);
    writer.writeInt(obj.uncompressedSize);
    writer.writeString(obj.localPath);
    writer.writeBool(obj.isInstalled);
  }
}
