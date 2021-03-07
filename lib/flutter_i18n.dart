import 'dart:async';
import 'package:flutter/foundation.dart' as Foundation;
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/loaders/file_translation_loader.dart';
import 'package:flutter_i18n/loaders/translation_loader.dart';
import 'package:flutter_i18n/utils/loading_status_stream.dart';
import 'package:flutter_i18n/utils/plural_translator.dart';
import 'package:flutter_i18n/utils/simple_translator.dart';
import 'package:intl/intl.dart' as intl;
import 'loaders/translation_loader.dart';
import 'models/loading_status.dart';
import 'utils/message_printer.dart';
export 'flutter_i18n_delegate.dart';
export 'loaders/e2e_file_translation_loader.dart';
export 'loaders/file_translation_loader.dart';
export 'loaders/namespace_file_translation_loader.dart';
export 'loaders/network_file_translation_loader.dart';
export 'loaders/translation_loader.dart';
export 'widgets/I18nPlural.dart';
export 'widgets/I18nText.dart';

typedef void MissingTranslationHandler(String key, Locale locale);

/// Facade used to hide the loading and translations logic
class FlutterI18n {
  TranslationLoader translationLoader;
  MissingTranslationHandler missingTranslationHandler;
  String keySeparator;

  Map<dynamic, dynamic> get decodedMap => translationLoader.getTranslation();

  // ignore: close_sinks
  static final _localeStream = StreamController<Locale>.broadcast();

  static Stream<Locale> get localeStream => _localeStream.stream;

  static final loadingStream = LoadingStatusStream();

  static Stream<bool> get isLoadedStream => loadingStream.stream
      .map((loadingStatus) => loadingStatus == LoadingStatus.loaded);

  static Future<bool> get isLoadedFuture =>
      loadingStream.stream.any((e) => e == LoadingStatus.loaded);

  FlutterI18n(
    TranslationLoader translationLoader,
    String keySeparator, {
    MissingTranslationHandler missingTranslationHandler,
  }) {
    this.translationLoader = translationLoader ?? FileTranslationLoader();
    this.missingTranslationHandler =
        missingTranslationHandler ?? (key, locale) {};
    this.keySeparator = keySeparator;
    MessagePrinter.setMustPrintMessage(!Foundation.kReleaseMode);
  }

  /// Used to load the locale translation file
  Future<bool> load() async {
    try {
      loadingStream.setState(LoadingStatus.notLoaded);
      await translationLoader.load();
      _localeStream.sink.add(locale);
      loadingStream.setState(LoadingStatus.loaded);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Map<dynamic, dynamic> currentTranslation(BuildContext context) {
    final FlutterI18n currentInstance = _retrieveCurrentInstance(context);
    return currentInstance.decodedMap;
  }

  /// The locale used for the translation logic
  Locale get locale => this.translationLoader.locale;

  /// Facade method to the plural translation logic
  static String plural(final BuildContext context, final String translationKey,
      final int pluralValue) {
    final FlutterI18n currentInstance = _retrieveCurrentInstance(context);
    final PluralTranslator pluralTranslator = PluralTranslator(
      currentInstance.decodedMap,
      translationKey,
      currentInstance.keySeparator,
      pluralValue,
      missingKeyTranslationHandler: (key) {
        currentInstance.missingTranslationHandler(key, currentInstance.locale);
      },
    );
    return pluralTranslator.plural();
  }

  /// Facade method to force the load of a new locale
  static Future refresh(
    final BuildContext context,
    final Locale forcedLocale,
  ) async {
    final FlutterI18n currentInstance = _retrieveCurrentInstance(context);
    currentInstance.translationLoader.forcedLocale = forcedLocale;
    await currentInstance.load();
  }

  /// Facade method to the simple translation logic
  static String translate(
    final BuildContext context,
    final String key, {
    final String fallbackKey,
    final Map<String, String> translationParams,
  }) {
    final FlutterI18n currentInstance = _retrieveCurrentInstance(context);
    final SimpleTranslator simpleTranslator = SimpleTranslator(
      currentInstance.decodedMap,
      key,
      currentInstance.keySeparator,
      fallbackKey: fallbackKey,
      translationParams: translationParams,
      missingKeyTranslationHandler: (key) {
        currentInstance.missingTranslationHandler(
          key,
          currentInstance.locale,
        );
      },
    );
    return simpleTranslator.translate();
  }

  /// Same as `get locale`, but this can be invoked from widgets
  static Locale currentLocale(final BuildContext context) {
    final FlutterI18n currentInstance = _retrieveCurrentInstance(context);
    return currentInstance?.translationLoader?.locale;
  }

  static FlutterI18n _retrieveCurrentInstance(BuildContext context) {
    return Localizations.of<FlutterI18n>(context, FlutterI18n);
  }

  /// Build for root widget, to support RTL languages
  static Function(BuildContext, Widget) rootAppBuilder() {
    return (BuildContext context, Widget child) {
      return StreamBuilder<Locale>(
        stream: localeStream,
        builder: (context, snapshot) {
          return Directionality(
            textDirection: _findTextDirection(snapshot.data),
            child: child,
          );
        },
      );
    };
  }

  static _findTextDirection(final Locale locale) {
    return intl.Bidi.isRtlLanguage(locale?.languageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}
