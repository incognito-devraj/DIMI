import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persistent, local-first image cache shared by thumbnails and avatars.
class PersistentImageCache {
  PersistentImageCache._();

  static final instance = PersistentImageCache._();

  final Map<String, Future<File?>> _inFlight = {};
  final Set<String> _refreshedThisSession = {};
  Directory? _directory;

  Future<File?> fileFor(String url) async {
    if (url.isEmpty) return null;
    final file = File(p.join(await _cacheDirectory(), _keyFor(url)));
    return await file.exists() ? file : null;
  }

  Future<File?> load(String url, {bool refresh = false}) async {
    if (url.isEmpty) return null;
    final cached = await fileFor(url);
    if (cached != null && (!refresh || !_refreshedThisSession.add(url))) {
      return cached;
    }

    final existing = _inFlight[url];
    if (existing != null) return existing;

    final future = _download(url, cached);
    _inFlight[url] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(url);
    }
  }

  Future<String> _cacheDirectory() async {
    final current = _directory;
    if (current != null) return current.path;
    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'dimi_image_cache'));
    await directory.create(recursive: true);
    _directory = directory;
    return directory.path;
  }

  Future<File?> _download(String url, File? existing) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return existing;
      }

      final directory = await _cacheDirectory();
      final destination = File(p.join(directory, _keyFor(url)));
      final temporary = File('${destination.path}.part');
      await temporary.writeAsBytes(response.bodyBytes, flush: true);
      await temporary.rename(destination.path);
      return destination;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[DIMI image cache] failed for $url: $error');
      }
      return existing;
    }
  }

  String _keyFor(String url) {
    final encoded = base64UrlEncode(utf8.encode(url)).replaceAll('=', '');
    return '$encoded.img';
  }
}

/// Renders a cached file immediately and downloads missing images in the
/// background. The fallback is kept visible until a valid file is available.
class DimiCachedImage extends StatefulWidget {
  const DimiCachedImage({
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.refreshInBackground = false,
    super.key,
  });

  final String url;
  final Widget fallback;
  final BoxFit fit;
  final Alignment alignment;
  final bool refreshInBackground;

  @override
  State<DimiCachedImage> createState() => _DimiCachedImageState();
}

class _DimiCachedImageState extends State<DimiCachedImage> {
  File? _file;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DimiCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _file = null;
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final cached = await PersistentImageCache.instance.fileFor(widget.url);
    if (mounted && generation == _loadGeneration && cached != null) {
      setState(() => _file = cached);
    }

    final file = await PersistentImageCache.instance.load(
      widget.url,
      refresh: widget.refreshInBackground,
    );
    if (mounted && generation == _loadGeneration && file != null) {
      setState(() => _file = file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file == null) return widget.fallback;
    return Image.file(
      file,
      fit: widget.fit,
      alignment: widget.alignment,
      errorBuilder: (_, _, _) => widget.fallback,
    );
  }
}
