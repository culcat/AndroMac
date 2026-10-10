import 'package:meta/meta.dart';

/// Hardware navigation buttons on Android.
enum AndroidNavButton {
  back,
  home,
  recents,
  volumeUp,
  volumeDown,
  power;

  static AndroidNavButton fromString(String str) {
    return AndroidNavButton.values.firstWhere(
      (e) => e.name.toLowerCase() == str.toLowerCase(),
      orElse: () => AndroidNavButton.back,
    );
  }
}

/// Type of remote input action.
enum RemoteInputType {
  down,
  up,
  move,
  scroll,
  text,
}

/// Dispatched input event normalized to screen dimensions.
@immutable
class RemoteInputEvent {
  final RemoteInputType type;
  final double? xRatio; // Normalized 0.0 - 1.0
  final double? yRatio; // Normalized 0.0 - 1.0
  final double? scrollX;
  final double? scrollY;
  final String? text;
  final int button; // 0: primary/left, 1: middle, 2: secondary/right

  const RemoteInputEvent({
    required this.type,
    this.xRatio,
    this.yRatio,
    this.scrollX,
    this.scrollY,
    this.text,
    this.button = 0,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      if (xRatio != null) 'x': xRatio,
      if (yRatio != null) 'y': yRatio,
      if (scrollX != null) 'scrollX': scrollX,
      if (scrollY != null) 'scrollY': scrollY,
      if (text != null) 'text': text,
      'button': button,
    };
  }

  factory RemoteInputEvent.fromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? 'move';
    final type = RemoteInputType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => RemoteInputType.move,
    );

    return RemoteInputEvent(
      type: type,
      xRatio: (map['x'] as num?)?.toDouble(),
      yRatio: (map['y'] as num?)?.toDouble(),
      scrollX: (map['scrollX'] as num?)?.toDouble(),
      scrollY: (map['scrollY'] as num?)?.toDouble(),
      text: map['text'] as String?,
      button: map['button'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'RemoteInputEvent(type: ${type.name}, x: $xRatio, y: $yRatio, text: $text)';
}

/// Streaming and encoding parameters for scrcpy-server or native media projection.
@immutable
class RemoteControlProfile {
  final int maxFps;
  final int bitRateMbps;
  final int maxResolution;
  final bool audioEnabled;

  const RemoteControlProfile({
    this.maxFps = 60,
    this.bitRateMbps = 8,
    this.maxResolution = 1920,
    this.audioEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'maxFps': maxFps,
      'bitRateMbps': bitRateMbps,
      'maxResolution': maxResolution,
      'audioEnabled': audioEnabled,
    };
  }

  factory RemoteControlProfile.fromMap(Map<String, dynamic> map) {
    return RemoteControlProfile(
      maxFps: map['maxFps'] as int? ?? 60,
      bitRateMbps: map['bitRateMbps'] as int? ?? 8,
      maxResolution: map['maxResolution'] as int? ?? 1920,
      audioEnabled: map['audioEnabled'] as bool? ?? true,
    );
  }
}
