import 'package:collection/collection.dart';

class CreneauHoraireData {
  final int hour;
  final int minute;
  final int lengthInMinutes;
  const CreneauHoraireData(this.hour, this.minute, {this.lengthInMinutes = 60});

  Map<String, dynamic> toJson() {
    return {
      "hour": hour,
      "minute": minute,
      "lengthInMinutes": lengthInMinutes,
    };
  }

  factory CreneauHoraireData.fromJson(Map<String, dynamic> json) {
    return CreneauHoraireData(json["hour"], json["minute"],
        lengthInMinutes: json["lengthInMinutes"] ?? 60);
  }

  @override
  bool operator ==(Object other) =>
      other is CreneauHoraireData &&
      other.runtimeType == runtimeType &&
      other.hour == hour &&
      other.minute == minute &&
      other.lengthInMinutes == lengthInMinutes;

  @override
  int get hashCode =>
      hour.hashCode + minute.hashCode + lengthInMinutes.hashCode;
}

class CreneauHoraireProvider {
  final List<CreneauHoraireData> values;
  const CreneauHoraireProvider(this.values);

  List<dynamic> toJson() {
    return values.map((e) => e.toJson()).toList();
  }

  factory CreneauHoraireProvider.fromJson(dynamic json) {
    return CreneauHoraireProvider(
        (json as List).map((e) => CreneauHoraireData.fromJson(e)).toList());
  }

  CreneauHoraireProvider copy() {
    return CreneauHoraireProvider(values.map((e) => e).toList());
  }

  bool equals(CreneauHoraireProvider other) {
    return values.equals(other.values);
  }

  int get firstHour => values.first.hour;
  int get lastHour {
    final last = values.last;
    return (last.hour.toDouble() + (last.minute + last.lengthInMinutes) / 60)
        .ceil();
  }

  double get oneHourRatio => 1 / (lastHour - firstHour);
}

const defautHoraires = CreneauHoraireProvider([
  CreneauHoraireData(8, 15),
  CreneauHoraireData(9, 15),
  CreneauHoraireData(10, 20),
  CreneauHoraireData(11, 20),
  CreneauHoraireData(12, 25),
  CreneauHoraireData(13, 25),
  CreneauHoraireData(14, 25),
  CreneauHoraireData(15, 30),
  CreneauHoraireData(16, 30),
  CreneauHoraireData(17, 30),
]);
