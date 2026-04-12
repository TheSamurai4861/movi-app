import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:movi/src/core/images/image_loading_policy.dart';
import 'package:movi/src/core/images/image_pipeline_telemetry.dart';
import 'package:movi/src/core/images/safe_image_cache_manager.dart';

typedef MoviImageErrorBuilder =
    Widget Function(BuildContext context, Object error, StackTrace? stackTrace);

class MoviNetworkImage extends StatefulWidget {
  const MoviNetworkImage(
    this.imageUrl, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = false,
    this.cacheWidth,
    this.cacheHeight,
    this.placeholder,
    this.errorBuilder,
    this.preferCachePath = true,
    this.allowRuntimeFallback = true,
    this.failurePlaceholder,
    this.allowInsecureHttp = true,
    this.loadTimeout = const Duration(seconds: 15),
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final int? cacheWidth;
  final int? cacheHeight;
  final Widget? placeholder;
  final MoviImageErrorBuilder? errorBuilder;
  final bool preferCachePath;
  final bool allowRuntimeFallback;
  final Widget? failurePlaceholder;
  final bool allowInsecureHttp;
  final Duration loadTimeout;

  @override
  State<MoviNetworkImage> createState() => _MoviNetworkImageState();
}

class _MoviNetworkImageState extends State<MoviNetworkImage> {
  bool _reportedAttempt = false;
  bool _reportedCacheSuccess = false;
  bool _reportedFallbackSuccess = false;
  bool _reportedFailure = false;
  bool _fallbackForcedByTimeout = false;
  Timer? _fallbackTimer;

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.imageUrl.trim();
    final validation = _validateUrl(
      trimmed,
      allowHttp: widget.allowInsecureHttp,
    );
    if (!validation.isValid) {
      return _buildFailure(
        context,
        StateError(validation.reason ?? 'invalid_url'),
        StackTrace.current,
        errorKind: validation.reason ?? 'invalid_url',
      );
    }

    final uri = Uri.parse(trimmed);
    if (!_reportedAttempt) {
      _reportedAttempt = true;
      ImagePipelineTelemetry.trackAttempt(context, uri);
    }

    final policy = ImageLoadingPolicyService.resolve();
    final resolvedCacheWidth =
        widget.cacheWidth ??
        _deriveDecodeDimension(context, widget.width, max: 1920);
    final resolvedCacheHeight =
        widget.cacheHeight ??
        _deriveDecodeDimension(context, widget.height, max: 1920);

    final bool forceFallbackOnly = policy.forceNetworkFallbackOnly;
    final bool canUseCachePath =
        widget.preferCachePath &&
        !forceFallbackOnly &&
        policy.enableCachedNetworkPath;

    final BaseCacheManager? cacheManager = SafeImageCacheManager.tryGet(
      enabled: policy.enableDiskCache,
    );

    if (!canUseCachePath || _fallbackForcedByTimeout) {
      return _buildNetworkFallback(
        context,
        trimmed,
        uri,
        resolvedCacheWidth: resolvedCacheWidth,
        resolvedCacheHeight: resolvedCacheHeight,
        reason: forceFallbackOnly
            ? 'flag_force_fallback'
            : 'cache_path_disabled',
      );
    }

    _fallbackTimer?.cancel();
    if (widget.allowRuntimeFallback) {
      _fallbackTimer = Timer(widget.loadTimeout, () {
        if (!mounted || _fallbackForcedByTimeout) return;
        setState(() => _fallbackForcedByTimeout = true);
      });
    }

    return CachedNetworkImage(
      imageUrl: trimmed,
      cacheManager: cacheManager,
      maxWidthDiskCache: resolvedCacheWidth,
      maxHeightDiskCache: resolvedCacheHeight,
      placeholder: (context, _) =>
          widget.placeholder ??
          SizedBox(width: widget.width, height: widget.height),
      errorWidget: (context, _, error) {
        if (!widget.allowRuntimeFallback) {
          return _buildFailure(
            context,
            error,
            StackTrace.current,
            errorKind: 'cache_path_error',
          );
        }
        return _buildNetworkFallback(
          context,
          trimmed,
          uri,
          resolvedCacheWidth: resolvedCacheWidth,
          resolvedCacheHeight: resolvedCacheHeight,
          reason: 'cache_path_error',
          cachePathError: error,
        );
      },
      imageBuilder: (context, imageProvider) {
        _fallbackTimer?.cancel();
        if (!_reportedCacheSuccess) {
          _reportedCacheSuccess = true;
          ImagePipelineTelemetry.trackCacheSuccess(context, uri);
        }
        return Image(
          image: imageProvider,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          filterQuality: widget.filterQuality,
          gaplessPlayback: widget.gaplessPlayback,
        );
      },
    );
  }

  Widget _buildNetworkFallback(
    BuildContext context,
    String url,
    Uri uri, {
    required int? resolvedCacheWidth,
    required int? resolvedCacheHeight,
    required String reason,
    Object? cachePathError,
  }) {
    if (cachePathError != null && !_reportedFailure) {
      _reportedFailure = true;
      ImagePipelineTelemetry.trackFailure(
        context,
        uri,
        errorKind: reason,
        error: cachePathError,
        stackTrace: StackTrace.current,
      );
    }

    return Image.network(
      url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      filterQuality: widget.filterQuality,
      gaplessPlayback: widget.gaplessPlayback,
      cacheWidth: resolvedCacheWidth,
      cacheHeight: resolvedCacheHeight,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if ((frame != null || wasSynchronouslyLoaded) &&
            !_reportedFallbackSuccess) {
          _reportedFallbackSuccess = true;
          ImagePipelineTelemetry.trackFallbackSuccess(context, uri);
        }
        return child;
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return widget.placeholder ??
            SizedBox(width: widget.width, height: widget.height);
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildFailure(
          context,
          error,
          stackTrace,
          errorKind: 'network_fallback_error',
        );
      },
    );
  }

  Widget _buildFailure(
    BuildContext context,
    Object error,
    StackTrace? stackTrace, {
    required String errorKind,
  }) {
    final trimmed = widget.imageUrl.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && !_reportedFailure) {
      _reportedFailure = true;
      ImagePipelineTelemetry.trackFailure(
        context,
        uri,
        errorKind: errorKind,
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error, stackTrace);
    }
    return widget.failurePlaceholder ??
        widget.placeholder ??
        SizedBox(width: widget.width, height: widget.height);
  }

  static int? _deriveDecodeDimension(
    BuildContext context,
    double? logicalSize, {
    required int max,
  }) {
    if (logicalSize == null || !logicalSize.isFinite || logicalSize <= 0) {
      return null;
    }
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final px = (logicalSize * dpr).round();
    return math.max(120, math.min(max, px));
  }

  _UrlValidation _validateUrl(String value, {required bool allowHttp}) {
    if (value.isEmpty) return const _UrlValidation.invalid('empty_url');
    if (value.length > 4096) {
      return const _UrlValidation.invalid('url_too_long');
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return const _UrlValidation.invalid('invalid_url');
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'https') return const _UrlValidation.valid();
    if (scheme == 'http' && allowHttp) return const _UrlValidation.valid();
    return const _UrlValidation.invalid('unsupported_scheme');
  }
}

class _UrlValidation {
  const _UrlValidation.valid() : isValid = true, reason = null;
  const _UrlValidation.invalid(this.reason) : isValid = false;

  final bool isValid;
  final String? reason;
}
