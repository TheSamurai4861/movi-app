class NetworkTimeouts {
  const NetworkTimeouts({
    this.connect = const Duration(seconds: 10),
    this.receive = const Duration(seconds: 15),
    this.send = const Duration(seconds: 10),
  });

  final Duration connect;
  final Duration receive;
  final Duration send;

  NetworkTimeouts copyWith({
    Duration? connect,
    Duration? receive,
    Duration? send,
  }) {
    return NetworkTimeouts(
      connect: connect ?? this.connect,
      receive: receive ?? this.receive,
      send: send ?? this.send,
    );
  }
}

class NetworkEndpoints {
  const NetworkEndpoints({
    required this.restBaseUrl,
    required this.imageBaseUrl,
    this.tmdbApiKey,
    this.timeouts = const NetworkTimeouts(),
  });

  final String restBaseUrl;
  final String imageBaseUrl;
  final String? tmdbApiKey;
  final NetworkTimeouts timeouts;

  NetworkEndpoints copyWith({
    String? restBaseUrl,
    String? imageBaseUrl,
    String? tmdbApiKey,
    NetworkTimeouts? timeouts,
  }) {
    return NetworkEndpoints(
      restBaseUrl: restBaseUrl ?? this.restBaseUrl,
      imageBaseUrl: imageBaseUrl ?? this.imageBaseUrl,
      tmdbApiKey: tmdbApiKey ?? this.tmdbApiKey,
      timeouts: timeouts ?? this.timeouts,
    );
  }
}
