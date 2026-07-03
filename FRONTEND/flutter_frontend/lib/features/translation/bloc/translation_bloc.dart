import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/backend_service.dart';

// ─── State ────────────────────────────────────────────────────
class TranslationState extends Equatable {
  /// Accumulated translation words/phrases
  final String translationText;

  /// Current sign-level confidence (0.0–1.0)
  final double confidence;

  /// Hand landmarks from last backend response (normalised 0..1)
  final List<Offset> landmarks;

  /// Whether the WebSocket is connected
  final bool backendConnected;

  /// Status string shown in the "auto-detecting" pill
  final String statusLabel;

  const TranslationState({
    this.translationText = '',
    this.confidence = 0.0,
    this.landmarks = const [],
    this.backendConnected = false,
    this.statusLabel = 'Auto-detecting...',
  });

  TranslationState copyWith({
    String? translationText,
    double? confidence,
    List<Offset>? landmarks,
    bool? backendConnected,
    String? statusLabel,
  }) {
    return TranslationState(
      translationText:  translationText  ?? this.translationText,
      confidence:       confidence       ?? this.confidence,
      landmarks:        landmarks        ?? this.landmarks,
      backendConnected: backendConnected ?? this.backendConnected,
      statusLabel:      statusLabel      ?? this.statusLabel,
    );
  }

  @override
  List<Object?> get props => [
    translationText, confidence, landmarks, backendConnected, statusLabel,
  ];
}

// ─── Events ───────────────────────────────────────────────────
abstract class TranslationEvent extends Equatable {
  const TranslationEvent();
  @override List<Object?> get props => [];
}

class TranslationStarted extends TranslationEvent {
  final String language;
  const TranslationStarted(this.language);
  @override List<Object?> get props => [language];
}

class TranslationStopped extends TranslationEvent {
  const TranslationStopped();
}

class FrameCaptured extends TranslationEvent {
  final Uint8List jpegBytes;
  const FrameCaptured(this.jpegBytes);
  @override List<Object?> get props => [jpegBytes];
}

class TranslationResultReceived extends TranslationEvent {
  final TranslationResult result;
  const TranslationResultReceived(this.result);
  @override List<Object?> get props => [result];
}

class TranslationCleared extends TranslationEvent {
  const TranslationCleared();
}

// ─── BLoC ─────────────────────────────────────────────────────
class TranslationBloc extends Bloc<TranslationEvent, TranslationState> {
  final BackendService _backend;
  StreamSubscription<TranslationResult>? _resultSub;

  TranslationBloc({BackendService? backend})
      : _backend = backend ?? BackendService.instance,
        super(const TranslationState()) {
    on<TranslationStarted>(_onStarted);
    on<TranslationStopped>(_onStopped);
    on<FrameCaptured>(_onFrame);
    on<TranslationResultReceived>(_onResult);
    on<TranslationCleared>(_onCleared);
  }

  Future<void> _onStarted(
    TranslationStarted event,
    Emitter<TranslationState> emit,
  ) async {
    emit(state.copyWith(
      backendConnected: false,
      statusLabel: 'Connecting...',
    ));

    try {
      await _backend.connect(language: event.language);

      emit(state.copyWith(
        backendConnected: true,
        statusLabel: 'Auto-detecting...',
      ));

      _resultSub?.cancel();
      _resultSub = _backend.resultsStream.listen((result) {
        add(TranslationResultReceived(result));
      });
    } catch (e) {
      emit(state.copyWith(
        backendConnected: false,
        statusLabel: 'Offline mode',
      ));
    }
  }

  Future<void> _onStopped(
    TranslationStopped event,
    Emitter<TranslationState> emit,
  ) async {
    await _resultSub?.cancel();
    await _backend.disconnect();
    emit(state.copyWith(
      backendConnected: false,
      statusLabel: 'Paused',
      landmarks: [],
    ));
  }

  void _onFrame(FrameCaptured event, Emitter<TranslationState> emit) {
    _backend.sendFrame(event.jpegBytes);
  }

  void _onResult(
    TranslationResultReceived event,
    Emitter<TranslationState> emit,
  ) {
    final result = event.result;
    final newText = state.translationText.isEmpty
        ? result.text
        : '${state.translationText} — ${result.text}';

    // Convert landmark triples List<List<double>> → List<Offset> (x,y only)
    final offsets = result.landmarks
        .map((pt) => Offset(
              pt.isNotEmpty ? pt[0] : 0.0,
              pt.length > 1 ? pt[1] : 0.0,
            ))
        .toList();

    emit(state.copyWith(
      translationText: newText,
      confidence: result.confidence,
      landmarks: offsets,
      statusLabel: result.confidence > 0.5 ? 'Translating...' : 'Auto-detecting...',
    ));
  }

  void _onCleared(TranslationCleared event, Emitter<TranslationState> emit) {
    emit(state.copyWith(
      translationText: '',
      confidence: 0.0,
      landmarks: [],
      statusLabel: 'Auto-detecting...',
    ));
  }

  @override
  Future<void> close() async {
    await _resultSub?.cancel();
    await _backend.disconnect();
    return super.close();
  }
}
