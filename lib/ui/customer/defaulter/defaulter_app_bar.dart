import 'package:flutter/material.dart';

import '../../../theme/customer/defaulter/defaulter_theme.dart';
import '../../girvi/shared/girvi_shared_widgets.dart';

class DefaulterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

  const DefaulterAppBar({
    super.key,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return GirviAppBar(
      screenTitle: DefaulterStrings.moduleTitle,
      screenSubtitle: DefaulterStrings.moduleSubtitle,
      moduleIcon: DefaulterIcons.module,
      onBack: onBack,
    );
  }
}
