import 'dart:ui';

import 'package:flutter/material.dart';

import '../localization/localization.dart';
import '../theme/app_theme.dart';

class FloatingIslandNav extends StatefulWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingIslandNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FloatingIslandNav> createState() => _FloatingIslandNavState();
}

class _FloatingIslandNavState extends State<FloatingIslandNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<double> _slideAnim;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant FloatingIslandNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _slideCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.items.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final pillWidth = (screenWidth * 0.88).clamp(280.0, 520.0);
    final itemWidth = pillWidth / itemCount;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Center(
        child: SizedBox(
          width: pillWidth,
          height: 64,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kAccent.withOpacity(0.22),
                          blurRadius: 28,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 18,
                          spreadRadius: -2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _slideAnim,
                builder: (context, child) {
                  final start = _previousIndex * itemWidth;
                  final end = widget.currentIndex * itemWidth;
                  final x = lerpDouble(start, end, _slideAnim.value) ?? end;
                  return Positioned(
                    left: x + (itemWidth * 0.2),
                    bottom: 10,
                    child: Container(
                      width: itemWidth * 0.6,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: AppTheme.kAccent,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.kAccent.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: List.generate(itemCount, (index) {
                  final item = widget.items[index];
                  final isSelected = index == widget.currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onTap(index),
                      child: SizedBox(
                        height: 64,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    key: ValueKey(isSelected),
                                    size: 22,
                                    color: isSelected
                                        ? AppTheme.kAccent
                                        : Colors.white.withOpacity(0.4),
                                  ),
                                ),
                                if ((item.badgeCount ?? 0) > 0)
                                  Positioned(
                                    top: -4,
                                    right: -6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.kAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.kBg,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        item.badgeCount! > 99
                                            ? '99+'
                                            : item.badgeCount.toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppTheme.kBg,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            TranslatedText(
                              item.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.kAccent
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}
