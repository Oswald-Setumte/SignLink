import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

/// ─────────────────────────────────────────────────────────────
///  BackendService
///  Manages the WebSocket connection to the SignLink CV/ML server.
///
///  PROTOCOL (agree with backend team):
///  ─ Client sends: binary frame (JPEG bytes) every N ms
///  ─ Server sends: JSON  { "text": "Hello", "confidence": 0.92,
///                          "landmarks": [[x,y,z], ...] }
///
///  Replace [wsUrl] with your actual server address before running.
/// ─────────────────────────────────────────────────────────────

class TranslationResult {
  final String text;
  final double confidence;
  final List<List<double>> landmarks; // 21 × 3 per hand

  const TranslationResult({
    required this.text,
    required this.confidence,
    this.landmarks = const [],
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    final rawLandmarks = json['landmarks'] as List<dynamic>? ?? [];
    return TranslationResult(
      text: json['text'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      landmarks: rawLandmarks
          .map((pt) => (pt as List).map((v) => (v as num).toDouble()).toList())
          .toList(),
    );
  }
}

class BackendService {
  BackendService._();
  static final BackendService instance = BackendService._();

  // ── CONFIG — replace with real backend URL ───────────────────
  static const String wsUrl = 'ws://YOUR_BACKEND_HOST:8000/ws/translate';
  // ────────────────────────────────────────────────────────────

  WebSocketChannel? _channel;
  StreamController<TranslationResult>? _controller;
  bool _connected = false;

  bool get isConnected => _connected;

  /// Open the WebSocket connection.
  /// [language] is the sign language code, e.g. 'ASL', 'GSL'.
  Future<void> connect({String language = 'ASL'}) async {
    if (_connected) return;

    _controller = StreamController<TranslationResult>.broadcast();

    try {
      final uri = Uri.parse('$wsUrl?lang=$language');
      _channel = WebSocketChannel.connect(uri);
      _connected = true;

      _channel!.stream.listen(
        (data) {
          if (data is String) {
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final result = TranslationResult.fromJson(json);
              _controller?.add(result);
            } catch (e) {
              // Malformed JSON — ignore silently
            }
          }
        },
        onError: (error) {
          _connected = false;
          _controller?.addError(error);
        },
        onDone: () {
          _connected = false;
        },
      );
    } catch (e) {
      _connected = false;
      rethrow;
    }
  }

  /// Send a raw JPEG frame to the backend.
  /// Call this at your desired frame rate (e.g. every 100ms = 10fps).
  void sendFrame(Uint8List jpegBytes) {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(jpegBytes);
  }

  /// Stream of [TranslationResult] objects received from the backend.
  Stream<TranslationResult> get resultsStream =>
      _controller?.stream ?? const Stream.empty();

  /// Gracefully close the connection.
  Future<void> disconnect() async {
    await _channel?.sink.close(ws_status.normalClosure);
    await _controller?.close();
    _connected = false;
    _channel = null;
    _controller = null;
  }
}
