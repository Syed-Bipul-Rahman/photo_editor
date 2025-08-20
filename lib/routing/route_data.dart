import 'dart:async';

class RouteData {
  RouteData._internal();
  static final RouteData _instance = RouteData._internal();
  static RouteData get instance => _instance;

  final Map<String, dynamic> _data = {};
  final Map<String, StreamController<dynamic>> _streams = {};

  void set<T>(String key, T value) {
    _data[key] = value;
    
    if (_streams.containsKey(key) && !_streams[key]!.isClosed) {
      _streams[key]!.add(value);
    }
  }

  T? get<T>(String key) {
    return _data[key] as T?;
  }

  T getOrDefault<T>(String key, T defaultValue) {
    return _data[key] as T? ?? defaultValue;
  }

  bool has(String key) {
    return _data.containsKey(key);
  }

  void remove(String key) {
    _data.remove(key);
    if (_streams.containsKey(key)) {
      _streams[key]!.close();
      _streams.remove(key);
    }
  }

  void clear() {
    _data.clear();
    for (final controller in _streams.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _streams.clear();
  }

  Stream<T> watch<T>(String key) {
    if (!_streams.containsKey(key)) {
      _streams[key] = StreamController<T>.broadcast();
    }
    return _streams[key]!.stream.cast<T>();
  }

  void setTemporary<T>(String key, T value, {Duration? expiration}) {
    set<T>(key, value);
    
    final duration = expiration ?? const Duration(minutes: 5);
    Timer(duration, () {
      if (has(key) && get<T>(key) == value) {
        remove(key);
      }
    });
  }

  Map<String, dynamic> getAll() {
    return Map<String, dynamic>.from(_data);
  }

  void setMultiple(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      set(entry.key, entry.value);
    }
  }

  void dispose() {
    clear();
  }
}