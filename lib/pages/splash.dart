import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart'; // افترض أن هذا الملف موجود ومُعرف
import '../helpers/app_theme.dart'; // افترض أن هذا الملف موجود ومُعرف
import '../helpers/size_config.dart'; // افترض أن هذا الملف موجود ومُعرف
import '../helpers/other_helpers.dart'; // افترض أن هذا الملف موجود ومُعرف
import '../locale/my_localizations.dart'; // افترض أن هذا الملف موجود ومُعرف

class Splash extends StatefulWidget {
  static int themeType = 1; // سيبقى كما هو بناءً على الكود الأصلي

  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  ThemeData themeData = AppTheme.getThemeFromThemeMode(Splash.themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(Splash.themeType);
  bool isLoading = true;
  AnimationController? _animationController;

  // حركات جديدة للأيقونة والنص والأزرار
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _buttonsFadeAnimation;
  late Animation<Offset> _buttonsSlideAnimation;

  @override
  void initState() {
    super.initState();
    // تهيئة وحدة التحكم في الحركة
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // زيادة المدة لإعطاء مساحة للحركات المتتالية
    );

    // تعريف حركات الأيقونة (ظهور وتكبير بشكل مرن)
    _iconScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut), // تأثير مرن
      ),
    );
    _iconFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // تعريف حركات النص الترحيبي (ظهور وانزلاق لأعلى)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );
    _textSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // تعريف حركات الأزرار (ظهور وانزلاق لأعلى)
    _buttonsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );
    _buttonsSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // بدء الحركات
    _animationController!.forward();

    // محاكاة التحميل
    _simulateLoading();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 2)); // نفس مدة التحميل
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    MySize().init(context); // من الكود الأصلي
    themeData = AppTheme.getThemeFromThemeMode(Splash.themeType); // إعادة تحميل الثيم لضمان التحديثات
    customAppTheme = AppTheme.getCustomAppTheme(Splash.themeType);

    return Scaffold(
      body: Container(
        // تحديث تصميم الخلفية بتدرج لوني أكثر حيوية واحترافية
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeData.colorScheme.primary.withOpacity(0.85),
              Color.lerp(themeData.colorScheme.primary, themeData.colorScheme.secondary, 0.4)!,
              themeData.colorScheme.secondary.withOpacity(0.8),
              Color.lerp(themeData.colorScheme.secondary, themeData.colorScheme.primaryContainer, 0.6)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                themeData.colorScheme.onPrimary),
            strokeWidth: 3,
          ),
        )
            : LayoutBuilder(
          builder: (context, constraints) {
            double maxContentWidth =
            constraints.maxWidth > 1200 ? 1100 : constraints.maxWidth * 0.85; // تعديل بسيط للعرض
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // أيقونة متحركة بتصميم محدث
                      ScaleTransition(
                        scale: _iconScaleAnimation,
                        child: FadeTransition(
                          opacity: _iconFadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(25), // زيادة الحشو
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeData.colorScheme.primaryContainer.withOpacity(0.2), // لون أكثر تناسقًا
                              boxShadow: [
                                BoxShadow(
                                  color: themeData.colorScheme.secondary.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: themeData.colorScheme.onPrimary.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.atom, // تغيير الأيقونة إلى شيء أكثر إبداعًا
                              size: constraints.maxWidth > 800 ? 100 : 70,
                              color: themeData.colorScheme.onPrimary,
                              // إزالة الظل المباشر للاعتماد على ظل الحاوية
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // نص ترحيبي بحركة وتصميم محدث
                      FadeTransition(
                        opacity: _textFadeAnimation,
                        child: SlideTransition(
                          position: _textSlideAnimation,
                          child: Text(
                            AppLocalizations.of(context).translate('welcome'),
                            style: TextStyle(
                              fontFamily: 'Cairo', // الحفاظ على الخط
                              color: themeData.colorScheme.onPrimary,
                              fontSize: constraints.maxWidth > 800 ? 48 : 38, // تكبير الخط قليلاً
                              fontWeight: FontWeight.bold, // خط أعرض
                              letterSpacing: 0.8,
                              shadows: [ // ظل أنعم وأكثر احترافية
                                Shadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 56), // زيادة المسافة

                      // صف الأزرار بحركة وتصميم محدث
                      FadeTransition(
                        opacity: _buttonsFadeAnimation,
                        child: SlideTransition(
                          position: _buttonsSlideAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // استخدام الويدجت الجديد للأزرار التفاعلية
                              InteractiveButton(
                                label: AppLocalizations.of(context).translate('login'),
                                icon: FontAwesomeIcons.rightToBracket,
                                themeData: themeData,
                                onPressed: () async {
                                  if (!Platform.isWindows &&
                                      !Platform.isMacOS &&
                                      !Platform.isLinux) {
                                    await Helper().requestAppPermission();
                                  }
                                  SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                                  if (prefs.getInt('userId') != null) {
                                    Config.userId = prefs.getInt('userId');
                                    Helper().jobScheduler();
                                    Navigator.of(context)
                                        .pushReplacementNamed('/layout');
                                  } else {
                                    Navigator.of(context)
                                        .pushReplacementNamed('/login');
                                  }
                                },
                              ),
                              const SizedBox(width: 28), // زيادة المسافة بين الأزرار
                              InteractiveButton(
                                label: AppLocalizations.of(context).translate('register'),
                                icon: FontAwesomeIcons.userPlus,
                                themeData: themeData,
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/register');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ويدجت جديد للأزرار بتصميم تفاعلي واحترافي
class InteractiveButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final ThemeData themeData;

  const InteractiveButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.themeData,
  }) : super(key: key);

  @override
  _InteractiveButtonState createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isDesktop ? 230 : 200, // عرض متجاوب
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 22, vertical: isDesktop ? 18 : 14), // حشو متجاوب
          decoration: BoxDecoration(
              color: _isHovering
                  ? widget.themeData.colorScheme.secondaryContainer.withOpacity(0.9) // لون مختلف عند المرور
                  : widget.themeData.colorScheme.secondary, // اللون الأساسي
              borderRadius: BorderRadius.circular(12), // زوايا أقل دائرية لمظهر أحدث
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovering ? 0.3 : 0.2),
                  blurRadius: _isHovering ? 10 : 6,
                  offset: Offset(0, _isHovering ? 5 : 3),
                ),
              ],
              border: Border.all( // إضافة حدود تظهر عند المرور
                  color: _isHovering ? widget.themeData.colorScheme.onSecondary.withOpacity(0.7) : Colors.transparent,
                  width: 1.5
              )
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                widget.icon,
                color: widget.themeData.colorScheme.onSecondary, // لون الأيقونة ليتناسب مع الخلفية
                size: isDesktop ? 22 : 18, // حجم أيقونة متجاوب
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: widget.themeData.colorScheme.onSecondary, // لون النص ليتناسب مع الخلفية
                  fontWeight: FontWeight.w600,
                  fontSize: isDesktop ? 17 : 15, // حجم خط متجاوب
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
