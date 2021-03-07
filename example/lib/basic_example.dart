import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/widgets/I18nPlural.dart';
import 'package:flutter_i18n/widgets/I18nText.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future main() async {
  final flutterI18nDelegate = FlutterI18nDelegate(
    translationLoader: FileTranslationLoader(
      useCountryCode: false,
      fallbackFile: 'en',
      basePath: 'assets/i18n',
      forcedLocale: Locale('es'),
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();
  flutterI18nDelegate.load(null);
  runApp(MyApp(flutterI18nDelegate));
}

class MyApp extends StatelessWidget {
  final FlutterI18nDelegate flutterI18nDelegate;

  MyApp(this.flutterI18nDelegate);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        return StreamBuilder<bool>(
          stream: FlutterI18n.isLoadedStream,
          builder: (_, snapshot) {
            if (snapshot.data ?? false == true) {
              return MaterialApp(
                title: 'Flutter Demo',
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                ),
                home: MyHomePage(),
                localizationsDelegates: [
                  flutterI18nDelegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate
                ],
                builder: FlutterI18n.rootAppBuilder(),
              );
            } else {
              return Container(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomeState createState() => MyHomeState();
}

class MyHomeState extends State<MyHomePage> {
  Locale currentLang;
  int clicked = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      setState(() {
        currentLang = FlutterI18n.currentLocale(context);
      });
    });
  }

  void changeLanguage() {
    currentLang =
        currentLang.languageCode == 'en' ? Locale('it') : Locale('en');
    FlutterI18n.refresh(context, currentLang);
  }

  incrementCounter() {
    setState(() {
      clicked++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(FlutterI18n.translate(context, "title"))),
      body: Builder(builder: (BuildContext context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              I18nText("label.main",
                  translationParams: {"user": "Flutter lover"}),
              I18nPlural("clicked.times", clicked),
              TextButton(
                  key: Key('incrementCounter'),
                  onPressed: () async {
                    incrementCounter();
                  },
                  child: Text(FlutterI18n.translate(
                      context, "button.label.clickMea",
                      fallbackKey: "button.label.clickMe"))),
              TextButton(
                  key: Key('changeLanguage'),
                  onPressed: () {
                    Scaffold.of(context)
                        .showSnackBar(SnackBar(
                          content: Text(FlutterI18n.translate(
                              context, "button.toastMessage")),
                        ))
                        .closed
                        .then((value) {
                      changeLanguage();
                    });
                  },
                  child: Text(
                      FlutterI18n.translate(context, "button.label.language")))
            ],
          ),
        );
      }),
    );
  }
}
