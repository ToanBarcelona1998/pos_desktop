import 'package:flutter/material.dart';
import 'package:pos_final/helpers/size_config.dart';

class Block extends StatelessWidget {
  const Block({
    super.key,
    this.backgroundColor, // لون الخلفية الافتراضي (اختياري)
    this.subject, // عنوان البطاقة
    this.icon, // الأيقونة بدلاً من الصورة
    this.amount, // القيمة (مثل المبلغ)
    required this.themeData, // الثيم
  });

  final Color? backgroundColor;
  final String? subject;
  final IconData? icon; // تغيير من image إلى icon
  final String? amount;
  final ThemeData themeData;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16), // زوايا أكبر للديسكتوب
      ),
      elevation: 6, // زيادة الظل لمظهر احترافي
      shadowColor: Colors.black.withOpacity(0.2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // تأثير المؤشر عند التمرير
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                backgroundColor?.withOpacity(0.1) ?? themeData.colorScheme.primary.withOpacity(0.1),
                backgroundColor?.withOpacity(0.05) ?? themeData.colorScheme.primary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
          ),
          child: Container(
            padding: EdgeInsets.all(isDesktop ? MySize.size16! : MySize.size12!), // حشوة أكبر للديسكتوب
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (icon != null)
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 14 : 12),
                    decoration: BoxDecoration(
                      color: backgroundColor?.withOpacity(0.2) ?? themeData.colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: backgroundColor?.withOpacity(0.3) ?? themeData.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: isDesktop ? 40 : 36, // أيقونة أكبر للديسكتوب
                      color: backgroundColor ?? themeData.colorScheme.primary,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  subject ?? '',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isDesktop ? 20 : 18, // نص أكبر للديسكتوب
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // لون داكن للتباين
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  amount ?? '',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isDesktop ? 24 : 20, // نص القيمة أكبر
                    fontWeight: FontWeight.bold,
                    color: backgroundColor ?? themeData.colorScheme.primary,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}