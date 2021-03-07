import 'dart:async';

import 'package:flutter_i18n/models/loading_status.dart';

class LoadingStatusStream {
  // ignore: close_sinks
  final _loadingStream = StreamController<LoadingStatus>.broadcast();

  LoadingStatus _lastState = LoadingStatus.notLoaded;

  Stream<LoadingStatus> get stream => _loadingStream.stream;

  LoadingStatus propagateState() {
    _loadingStream.sink.add(_lastState);
    return _lastState;
  }

  void setState(LoadingStatus state) {
    _lastState = state;
    _loadingStream.sink.add(state);
  }
}
