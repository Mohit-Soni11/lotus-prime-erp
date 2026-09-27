import 'package:flutter/material.dart';

import '../../../theme/girvi/girvi_theme.dart';
import '../shared/girvi_shared_widgets.dart';

class NoticeAuctionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;

  const NoticeAuctionAppBar({
    super.key,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return GirviAppBar(
      screenTitle: GirviStrings.noticeTitle,
      screenSubtitle: GirviStrings.noticeSub,
      moduleIcon: GirviIcons.warning,
      onBack: onBack,
    );
  }
}
