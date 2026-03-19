import 'package:flutter/material.dart';

class VintaideAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final Color iconColor;

  const VintaideAppBar({
    super.key,
    this.showBack = true,
    this.iconColor = Colors.white, // ✅ par défaut blanc
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF11114E);

    return AppBar(
      backgroundColor: primary,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 76,
      automaticallyImplyLeading: showBack,
      iconTheme: IconThemeData(color: iconColor), // ✅ ici
      title: LayoutBuilder(
        builder: (context, constraints) {
          final logoW = (constraints.maxWidth * 0.40).clamp(120.0, 220.0);
          return Image.asset(
            'assets/logo.png',
            width: logoW,
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(76);
}
