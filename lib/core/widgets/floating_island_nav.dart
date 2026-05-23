import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../localization/localization.dart';

/// A Dynamic-Island–style floating pill navigation bar.
///
/// Drop this into a [Scaffold]'s body inside a [Stack] at the bottom,
/// OR use [FloatingIslandNavScaffold] as a convenience wrapper that handles
/// the [Stack] + safe-area padding automatically.
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
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(FloatingIslandNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _prevIndex = old.currentIndex;
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
    final n = widget.items.length;
    final screenW = MediaQuery.of(context).size.width;
    // pill width: at most 92% of screen, at least 280
    final pillW = (screenW * 0.88).clamp(280.0, 520.0);
    final itemW = pillW / n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Center(
        child: SizedBox(
          width: pillW,
          height: 64,
          child: Stack(
            children: [
              // ── Frosted glass pill ─────────────────────────────────────────
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
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kAccent.withOpacity(0.22),
                          blurRadius: 28,
                          spreadRadius: 0,
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

              // ── Animated gold indicator bar ───────────────────────────────
              AnimatedBuilder(
                animation: _slideAnim,
                builder: (context, child) {
                  final from = _prevIndex * itemW;
                  final to = widget.currentIndex * itemW;
                  final x = lerpDouble(from, to, _slideAnim.value)!;
                  return Positioned(
                    left: x + (itemW * 0.2),
                    bottom: 10,
                    child: Container(
                      width: itemW * 0.6,
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

              // ── Nav items ──────────────────────────────────────────────────
              Row(
                children: List.generate(n, (i) {
                  final item = widget.items[i];
                  final isSelected = widget.currentIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        height: 64,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.kAccent
                                : Colors.white.withOpacity(0.4),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        isSelected
                                            ? item.activeIcon
                                            : item.icon,
                                        key: ValueKey(isSelected),
                                        size: 22,
                                        color: isSelected
                                            ? AppTheme.kAccent
                                            : Colors.white.withOpacity(0.4),
                                      ),
                                      if (item.badgeCount != null &&
                                          item.badgeCount! > 0)
                                        Positioned(
                                          top: -4,
                                          right: -6,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.kAccent,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppTheme.kBg,
                                                width: 1.5,
                                              ),
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Text(
                                              item.badgeCount! > 99
                                                  ? '99+'
                                                  : item.badgeCount.toString(),
                                              style: const TextStyle(
                                                color: AppTheme.kBg,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
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
