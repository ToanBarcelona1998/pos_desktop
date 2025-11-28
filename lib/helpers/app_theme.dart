import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_final/constants.dart';


class AppTheme {
  static const int themeLight = 1;
  static const int themeDark = 2;

  AppTheme._();

  static CustomAppTheme getCustomAppTheme(int themeMode) {
    if (themeMode == themeLight) {
      return lightCustomAppTheme;
    } else if (themeMode == themeDark) {
      return darkCustomAppTheme;
    }
    return darkCustomAppTheme;
  }

  static FontWeight _getFontWeight(int weight) {
    switch (weight) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w300;
      case 500:
        return FontWeight.w400;
      case 600:
        return FontWeight.w500;
      case 700:
        return FontWeight.w600;
      case 800:
        return FontWeight.w700;
      case 900:
        return FontWeight.w900;
    }
    return FontWeight.w400;
  }

  static TextStyle getTextStyle(TextStyle? textStyle,
      {int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double letterSpacing = 0.15,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double wordSpacing = 0,
      double? fontSize}) {
    double? finalFontSize = fontSize ?? textStyle!.fontSize;

    Color finalColor;
    if (color == null) {
      finalColor = (xMuted
          ? textStyle!.color!.withAlpha(160)
          : (muted ? textStyle!.color!.withAlpha(200) : textStyle!.color))!;
    } else {
      finalColor = xMuted
          ? color.withAlpha(160)
          : (muted ? color.withAlpha(200) : color);
    }

    return TextStyle(
        fontSize: finalFontSize!,
        fontWeight: _getFontWeight(fontWeight),
        letterSpacing: letterSpacing,
        color: finalColor,
        decoration: decoration,
        fontFamily: 'Cairo',
        height: height,
        wordSpacing: wordSpacing);
  }

  //App Bar Text
  static final TextTheme lightAppBarTextTheme = TextTheme(
    displayLarge: const TextStyle(fontSize: 102, color: Color(0xff495057),  fontFamily: 'Cairo',),
    displayMedium: const TextStyle(fontSize: 64, color: Color(0xff495057),  fontFamily: 'Cairo',),
    displaySmall: const TextStyle(fontSize: 51, color: Color(0xff495057),  fontFamily: 'Cairo',),
    headlineMedium: const TextStyle(fontSize: 36, color: Color(0xff495057),  fontFamily: 'Cairo',),
    headlineSmall: const TextStyle(fontSize: 25, color: Color(0xff495057),  fontFamily: 'Cairo',),
    titleLarge: const TextStyle(fontSize: 18, color: Color(0xff495057),  fontFamily: 'Cairo',),
    titleMedium: const TextStyle(fontSize: 17, color: Color(0xff495057),  fontFamily: 'Cairo',),
    titleSmall: const TextStyle(fontSize: 15, color: Color(0xff495057),  fontFamily: 'Cairo',),
    bodyLarge: const TextStyle(fontSize: 16, color: Color(0xff495057),  fontFamily: 'Cairo',),
    bodyMedium: const TextStyle(fontSize: 14, color: Color(0xff495057),  fontFamily: 'Cairo',),
    labelLarge: const TextStyle(fontSize: 15, color: Color(0xff495057),  fontFamily: 'Cairo',),
    bodySmall: const TextStyle(fontSize: 13, color: Color(0xff495057),  fontFamily: 'Cairo',),
    labelSmall: const TextStyle(fontSize: 11, color: Color(0xff495057),  fontFamily: 'Cairo',),
  );
  static final TextTheme darkAppBarTextTheme = TextTheme(
    displayLarge: const TextStyle(fontSize: 102, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    displayMedium: const TextStyle(fontSize: 64, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    displaySmall: const TextStyle(fontSize: 51, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    headlineMedium: const TextStyle(fontSize: 36, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    headlineSmall: const TextStyle(fontSize: 25, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    titleLarge: const TextStyle(fontSize: 20, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    titleMedium: const TextStyle(fontSize: 17, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    titleSmall: const TextStyle(fontSize: 15, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    bodyLarge: const TextStyle(fontSize: 16, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    bodyMedium: const TextStyle(fontSize: 14, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    labelLarge: const TextStyle(fontSize: 15, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    bodySmall: const TextStyle(fontSize: 13, color: Color(0xffffffff),  fontFamily: 'Cairo',),
    labelSmall: const TextStyle(fontSize: 11, color: Color(0xffffffff),  fontFamily: 'Cairo',),
  );

  //Text Themes
  static final TextTheme lightTextTheme = TextTheme(
    displayLarge: const TextStyle(fontSize: 102, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    displayMedium: const TextStyle(fontSize: 64, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    displaySmall: const TextStyle(fontSize: 51, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    headlineMedium: const TextStyle(fontSize: 36, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    headlineSmall: const TextStyle(fontSize: 25, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    titleLarge: const TextStyle(fontSize: 18, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    titleMedium: const TextStyle(fontSize: 17, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    titleSmall: const TextStyle(fontSize: 15, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    bodyLarge: const TextStyle(fontSize: 16, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    bodyMedium: const TextStyle(fontSize: 14, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    labelLarge: const TextStyle(fontSize: 15, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    bodySmall: const TextStyle(fontSize: 13, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
    labelSmall: const TextStyle(fontSize: 11, color: Color(0xff4a4c4f),  fontFamily: 'Cairo',),
  );
  static final TextTheme darkTextTheme = TextTheme(
    displayLarge: const TextStyle(fontSize: 102, color: Colors.white,  fontFamily: 'Cairo',),
    displayMedium: const TextStyle(fontSize: 64, color: Colors.white,  fontFamily: 'Cairo',),
    displaySmall: const TextStyle(fontSize: 51, color: Colors.white,  fontFamily: 'Cairo',),
    headlineMedium: const TextStyle(fontSize: 36, color: Colors.white,  fontFamily: 'Cairo',),
    headlineSmall: const TextStyle(fontSize: 25, color: Colors.white,  fontFamily: 'Cairo',),
    titleLarge: const TextStyle(fontSize: 18, color: Colors.white,  fontFamily: 'Cairo',),
    titleMedium: const TextStyle(fontSize: 17, color: Colors.white,  fontFamily: 'Cairo',),
    titleSmall: const TextStyle(fontSize: 15, color: Colors.white,  fontFamily: 'Cairo',),
    bodyLarge: const TextStyle(fontSize: 16, color: Colors.white,  fontFamily: 'Cairo',),
    bodyMedium: const TextStyle(fontSize: 14, color: Colors.white,  fontFamily: 'Cairo',),
    labelLarge: const TextStyle(fontSize: 15, color: Colors.white,  fontFamily: 'Cairo',),
    bodySmall: const TextStyle(fontSize: 13, color: Colors.white,  fontFamily: 'Cairo',),
    labelSmall: const TextStyle(fontSize: 11, color: Colors.white,  fontFamily: 'Cairo',),
  );

  //Color Themes
  static final ThemeData lightTheme = ThemeData(
    fontFamily: 'Cairo',
    brightness: Brightness.light,
    primaryColor:kDefaultColor,
    canvasColor: Colors.transparent,
    scaffoldBackgroundColor: const Color(0xffffffff),
    appBarTheme: const AppBarTheme(
      actionsIconTheme: IconThemeData(
        color: Color(0xff495057),
      ),
      color: Color(0xffffffff),
      iconTheme: IconThemeData(color: Color(0xff495057), size: 24),
    ),
    navigationRailTheme: const NavigationRailThemeData(
        selectedIconTheme:
            IconThemeData(color:kDefaultColor, opacity: 1, size: 24),
        unselectedIconTheme:
            IconThemeData(color: Color(0xff495057), opacity: 1, size: 24),
        backgroundColor: Color(0xffffffff),
        elevation: 3,
        selectedLabelTextStyle: TextStyle(color:kDefaultColor),
        unselectedLabelTextStyle: TextStyle(color: Color(0xff495057))),
    cardTheme: CardThemeData(
      color: Colors.white,
      shadowColor: Colors.black.withAlpha((0.4 * 256).toInt()),
      elevation: 1,
      margin: const EdgeInsets.all(0),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(fontSize: 15, color: Color(0xaa495057)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(width: 1, color:kDefaultColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(width: 1, color: Colors.black54),
      ),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: Colors.black54)),
    ),
    splashColor: Colors.white.withAlpha(100),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    textTheme: lightTextTheme,
    disabledColor: const Color(0xffdcc7ff),
    highlightColor: Colors.white,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor:kDefaultColor,
        splashColor: Colors.white.withAlpha(100),
        highlightElevation: 8,
        elevation: 4,
        focusColor:kDefaultColor,
        hoverColor:kDefaultColor,
        foregroundColor: Colors.white),
    dividerColor: const Color(0xffd1d1d1),
    cardColor: Colors.white,
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xffffffff),
      textStyle:
          lightTextTheme.bodyMedium!.merge(const TextStyle(color: Color(0xff495057))),
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
        color: Color(0xffffffff), elevation: 2
    ),
    tabBarTheme: const TabBarThemeData(
      unselectedLabelColor: Color(0xff495057),
      labelColor:kDefaultColor,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color:kDefaultColor, width: 2.0),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor:kDefaultColor,
      inactiveTrackColor:kDefaultColor.withAlpha(140),
      trackShape: const RoundedRectSliderTrackShape(),
      trackHeight: 4.0,
      thumbColor:kDefaultColor,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
      tickMarkShape: const RoundSliderTickMarkShape(),
      inactiveTickMarkColor: Colors.red[100],
      valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
      valueIndicatorTextStyle: const TextStyle(
        color: Colors.white,
      ),
    ), colorScheme: const ColorScheme.light(
            primary:kDefaultColor,
            onPrimary: Colors.white,
            secondary: Color(0xff495057),
            onSecondary: Colors.white,
            surface: Color(0xffe2e7f1),
            onSurface: Color(0xff495057))
        .copyWith(secondary:kDefaultColor).copyWith(surface: Colors.white),
  );
  static ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      canvasColor: Colors.transparent,
      primaryColor:kDefaultColor,
      scaffoldBackgroundColor: const Color(0xff464c52),
      appBarTheme: const AppBarTheme(
        actionsIconTheme: IconThemeData(
          color: Color(0xffffffff),
        ),
        color: Color(0xff2e343b),
        iconTheme: IconThemeData(color: Color(0xffffffff), size: 24),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xff37404a),
        shadowColor: Color(0xff000000),
        elevation: 1,
        margin: EdgeInsets.all(0),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      textTheme: darkTextTheme,
      disabledColor: const Color(0xffa3a3a3),
      highlightColor: Colors.white,
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color:kDefaultColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: Colors.white70),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(width: 1, color: Colors.white70)),
      ),
      dividerColor: const Color(0xffd1d1d1),
      cardColor: const Color(0xff282a2b),
      splashColor: Colors.white.withAlpha(100),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor:kDefaultColor,
          splashColor: Colors.white.withAlpha(100),
          highlightElevation: 8,
          elevation: 4,
          focusColor:kDefaultColor,
          hoverColor:kDefaultColor,
          foregroundColor: Colors.white),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xff37404a),
        textStyle: lightTextTheme.bodyMedium!
            .merge(const TextStyle(color: Color(0xffffffff))),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(color: Color(0xff464c52), elevation: 2),
      tabBarTheme: const TabBarThemeData(
        unselectedLabelColor: Color(0xff495057),
        labelColor:kDefaultColor,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color:kDefaultColor, width: 2.0),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor:kDefaultColor,
        inactiveTrackColor:kDefaultColor.withAlpha(100),
        trackShape: const RoundedRectSliderTrackShape(),
        trackHeight: 4.0,
        thumbColor:kDefaultColor,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
        tickMarkShape: const RoundSliderTickMarkShape(),
        inactiveTickMarkColor: Colors.red[100],
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
        ),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(), colorScheme: const ColorScheme.dark(
        primary:kDefaultColor,
        secondary: Color(0xff00cc77),
        onPrimary: Colors.white,
        onSurface: Colors.white,
        onSecondary: Colors.white,
        surface: Color(0xff585e63),
      ).copyWith(secondary:kDefaultColor).copyWith(surface: const Color(0xff464c52)));

  static ThemeData getThemeFromThemeMode(int themeMode) {
    if (themeMode == themeLight) {
      return lightTheme;
    } else if (themeMode == themeDark) {
      return darkTheme;
    }
    return lightTheme;
  }

  static final CustomAppTheme lightCustomAppTheme = CustomAppTheme(
    bgLayer1: const Color(0xffffffff),
    bgLayer2: const Color(0xfff9f9f9),
    bgLayer3: const Color(0xffe8ecf4),
    bgLayer4: const Color(0xffdcdee3),
    disabledColor: const Color(0xff636363),
    onDisabled: const Color(0xffffffff),
    colorInfo: const Color(0xffff784b),
    colorWarning: const Color(0xffffc837),
    colorSuccess: const Color(0xff3cd278),
    shadowColor: const Color(0xffeaeaea),
    onInfo: const Color(0xffffffff),
    onSuccess: const Color(0xffffffff),
    onWarning: const Color(0xffffffff),
    colorError: const Color(0xfff0323c),
    onError: const Color(0xffffffff),
  );
  static final CustomAppTheme darkCustomAppTheme = CustomAppTheme(
      bgLayer1: const Color(0xff212429),
      bgLayer2: const Color(0xff282930),
      bgLayer3: const Color(0xff303138),
      bgLayer4: const Color(0xff383942),
      disabledColor: const Color(0xffbababa),
      onDisabled: const Color(0xff000000),
      colorInfo: const Color(0xffff784b),
      colorWarning: const Color(0xffffc837),
      colorSuccess: const Color(0xff3cd278),
      shadowColor: const Color(0xff1a1a1a),
      onInfo: const Color(0xffffffff),
      onSuccess: const Color(0xffffffff),
      onWarning: const Color(0xffffffff),
      colorError: const Color(0xfff0323c),
      onError: const Color(0xffffffff));
}

class CustomAppTheme {
  final Color bgLayer1,
      bgLayer2,
      bgLayer3,
      bgLayer4,
      disabledColor,
      onDisabled,
      colorInfo,
      colorWarning,
      colorSuccess,
      colorError,
      shadowColor,
      onInfo,
      onWarning,
      onSuccess,
      onError;

  CustomAppTheme({
    this.bgLayer1 = const Color(0xffffffff),
    this.bgLayer2 = const Color(0xfff8faff),
    this.bgLayer3 = const Color(0xffeef2fa),
    this.bgLayer4 = const Color(0xffdcdee3),
    this.disabledColor = const Color(0xffdcc7ff),
    this.onDisabled = const Color(0xffffffff),
    this.colorWarning = const Color(0xffffc837),
    this.colorInfo = const Color(0xffff784b),
    this.colorSuccess = const Color(0xff3cd278),
    this.shadowColor = const Color(0xff1f1f1f),
    this.onInfo = const Color(0xffffffff),
    this.onWarning = const Color(0xffffffff),
    this.onSuccess = const Color(0xffffffff),
    this.colorError = const Color(0xfff0323c),
    this.onError = const Color(0xffffffff),
  });
}
