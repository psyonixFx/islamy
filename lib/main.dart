import 'package:country_code_picker/country_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:islamy/generated/l10n/l10n.dart';
import 'package:islamy/quran/quran_manager.dart';
import 'package:islamy/theme.dart';
import 'package:islamy/utils/api/api_handler.dart';
import 'package:islamy/utils/helper.dart';
import 'package:islamy/utils/routes.dart';
import 'package:islamy/utils/store.dart';
import 'live.dart' as live;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  ApiHandler.init();
  await QuranManager.init();
  await Helper.init();
  // return live.main();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Islamy App',
      builder: (context, child) => ScrollConfiguration(
        behavior: const CupertinoScrollBehavior(),
        child: CupertinoTheme(
          data: ThemeBuilder.toCupertino(Theme.of(context)),
          child: Material(
            color: Colors.transparent,
            type: MaterialType.canvas,
            elevation: 0.0,
            child: child,
          ),
        ),
      ),
      localizationsDelegates: const [
        S.delegate,
        CountryLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeBuilder.lightTheme,
      debugShowCheckedModeBanner: false,
      supportedLocales: S.delegate.supportedLocales,
      onGenerateRoute: Routes.onGenerateRoute,
      initialRoute: 'main',
    );
  }
}
