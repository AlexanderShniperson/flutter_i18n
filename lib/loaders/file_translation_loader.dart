import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/loaders/decoders/base_decode_strategy.dart';
import 'package:flutter_i18n/loaders/decoders/json_decode_strategy.dart';
import 'package:flutter_i18n/loaders/decoders/xml_decode_strategy.dart';
import 'package:flutter_i18n/loaders/decoders/yaml_decode_strategy.dart';
import 'package:flutter_i18n/loaders/file_content.dart';
import 'package:flutter_i18n/loaders/translation_loader.dart';
import '../utils/message_printer.dart';

/// Loads translation files from JSON, YAML or XML format
class FileTranslationLoader extends TranslationLoader implements IFileContent {
  final String fallbackFile;
  final String basePath;
  final bool useCountryCode;
  AssetBundle assetBundle = rootBundle;

  Map<dynamic, dynamic> _decodedMap = Map();
  late List<BaseDecodeStrategy> _decodeStrategies;

  set decodeStrategies(List<BaseDecodeStrategy>? decodeStrategies) =>
      _decodeStrategies = decodeStrategies ??
          [
            JsonDecodeStrategy(),
            YamlDecodeStrategy(),
            XmlDecodeStrategy(),
          ];

  FileTranslationLoader({
    this.fallbackFile = "en",
    this.basePath = "assets/flutter_i18n",
    this.useCountryCode = false,
    forcedLocale,
    decodeStrategies,
  }) {
    this.forcedLocale = forcedLocale;
    this.decodeStrategies = decodeStrategies;
  }

  Map<dynamic, dynamic> getTranslation() {
    return Map.from(_decodedMap);
  }

  /// Return the translation Map
  Future<Map> load() async {
    _decodedMap = Map();
    try {
      _decodedMap = await (_loadCurrentTranslation()
          .catchError((onError) => _loadFallback()));
    } on Exception catch (e) {
      print(">>> load $e");
    }
    return _decodedMap;
  }

  /// Load the file using the AssetBundle rootBundle
  @override
  Future<String> loadString(final String fileName, final String extension) {
    return assetBundle.loadString(
      '$basePath/$fileName.$extension',
      cache: false,
    );
  }

  Future<Map<dynamic, dynamic>> _loadCurrentTranslation() async {
    try {
      this.locale = locale ?? await findDeviceLocale();
      MessagePrinter.info("The current locale is ${this.locale}");
      return loadFile(composeFileName());
    } catch (e) {
      MessagePrinter.debug('Error loading translation $e');
      return Future.error(e);
    }
  }

  Future<Map<dynamic, dynamic>> _loadFallback() async {
    try {
      return loadFile(fallbackFile);
    } catch (e) {
      MessagePrinter.debug('Error loading translation fallback $e');
      return Future.error(e);
    }
  }

  /// Load the fileName using one of the strategies provided
  @protected
  Future<Map> loadFile(final String fileName) async {
    final List<Future<Map?>> strategiesFutures = _executeStrategies(fileName);
    final strategies = await Future.wait(strategiesFutures);
    return strategies.firstWhere(
          (map) => map != null,
          orElse: null,
        ) ??
        Map();
  }

  List<Future<Map?>> _executeStrategies(final String fileName) {
    return _decodeStrategies.map((e) => e.decode(fileName, this)).toList();
  }

  /// Compose the file name using the format languageCode_countryCode
  @protected
  String composeFileName() {
    return "${locale!.languageCode}${composeCountryCode()}";
  }

  /// Return the country code to attach to the file name, if required
  @protected
  String composeCountryCode() {
    String countryCode = "";
    if (useCountryCode && locale!.countryCode != null) {
      countryCode = "_${locale!.countryCode}";
    }
    return countryCode;
  }
}
