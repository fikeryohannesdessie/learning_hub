import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/localization.dart';
import '../theme/app_theme.dart';
import 'heritage_logo.dart';

class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final PreferredSizeWidget? bottom;
  final List<Widget>? extraActions;
  final Widget? leading;
  final bool switcherOnRight;

  const SharedAppBar({
    super.key,
    this.title,
    this.bottom,
    this.extraActions,
    this.leading,
    this.switcherOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      toolbarHeight: title != null ? 72 : kToolbarHeight,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!switcherOnRight) const LanguageSwitcher(),
          if (title != null) ...[
            if (!switcherOnRight) const SizedBox(height: 2),
            TranslatedText(
              title!.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.kParchment,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ],
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppTheme.kParchment),
      leadingWidth: 64,
      leading:
          leading ??
          (Navigator.of(context).canPop()
              ? null
              : const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Center(child: HeritageLogoWidget(size: 32)),
                )),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.kAccent.withOpacity(0.07),
                  Colors.transparent,
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.kAccent.withOpacity(0.18),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      bottom: bottom,
      actions: [
        if (extraActions != null) ...extraActions!,
        if (switcherOnRight) ...[
          const Center(child: LanguageSwitcher()),
          const SizedBox(width: 12),
        ],
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => context.push('/profile'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    (title != null ? 72 : kToolbarHeight) +
        (bottom?.preferredSize.height ?? 0.0),
  );
}
