import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_routes.dart';
import '../../../core/router/app_router.dart';
// ✅ Manager Import
import '../../../theme/sidebar/sidebar_theme.dart';

class CustomSidebar extends StatefulWidget {
  final String? activePageRouteId;
  final ValueChanged<String>? onPageSelected;
  final VoidCallback? onExitApp;

  const CustomSidebar({
    super.key,
    this.activePageRouteId,
    this.onPageSelected,
    this.onExitApp,
  });

  @override
  State<CustomSidebar> createState() => _CustomSidebarState();
}

class _CustomSidebarState extends State<CustomSidebar> {
  final Map<String, ExpansibleController> _controllers = {};
  int? _expandedIndex;
  bool _isCollapsed = false;
  int? _hoveredIndex;
  String? _hoveredSubItemRouteId;

  String get _activeRouteId {
    final legacyRouteId = widget.activePageRouteId;
    if (legacyRouteId != null) return legacyRouteId;
    final location = GoRouterState.of(context).matchedLocation;
    return RouteMapper.toRouteId(location);
  }

  void _navigate(String routeId) {
    final legacyNavigation = widget.onPageSelected;
    if (legacyNavigation != null) {
      legacyNavigation(routeId);
      return;
    }
    if (routeId == AppRoutes.exitAppRoute) {
      widget.onExitApp?.call();
      return;
    }
    final path = RouteMapper.toPath(routeId);
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      // âœ… FIX 1: Faster Animation (250ms -> 150ms)
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      width: _isCollapsed ? 70 : 260,
      decoration: const BoxDecoration(
        color: SidebarColors.background,
        border: Border(
            right: BorderSide(color: SidebarColors.glassBorder, width: 1)),
      ),
      child: ClipRect(
        // Prevents content from bleeding during animation
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                // âœ… FIX 2: Overflow Error Fixed
                // Jab chhota ho, toh padding kam kar do (12 -> 8)
                padding: EdgeInsets.symmetric(
                    horizontal: _isCollapsed ? 8 : 12, vertical: 10),
                itemCount: SidebarMenu.menuItems.length + 1,
                itemBuilder: (context, index) {
                  // Dashboard Item
                  if (index == 0) {
                    return _buildSingleTile(
                      title: AppRoutes.getTitle(AppRoutes.dashboardRoute),
                      icon: SidebarIcons.dashboard,
                      routeId: AppRoutes.dashboardRoute,
                      index: -1,
                    );
                  }

                  final menuIndex = index - 1;
                  final item = SidebarMenu.menuItems[menuIndex];
                  return _isCollapsed
                      ? _buildCollapsedIcon(item, menuIndex)
                      : _buildExpandableTile(item, menuIndex);
                },
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SidebarColors.glassBorder)),
      ),
      child: Row(
        mainAxisAlignment:
            _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (!_isCollapsed) ...[
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "LOTUS ERP",
                style: SidebarStyles.hero,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          IconButton(
            icon: Icon(
                _isCollapsed ? SidebarIcons.expand : SidebarIcons.collapse,
                color: _isCollapsed
                    ? SidebarColors.primary
                    : SidebarColors.textSecondary),
            onPressed: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
                if (_isCollapsed) _closeAllExpandables();
              });
            },
          ),
          if (!_isCollapsed) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // --- SINGLE TILE ---
  Widget _buildSingleTile(
      {required String title,
      required IconData icon,
      required String routeId,
      required int index}) {
    bool isActive = _activeRouteId == routeId;
    bool isHovered = _hoveredIndex == index;

    Widget tileContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150), // Fast
      margin: EdgeInsets.only(bottom: (index >= 99) ? 2 : 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? SidebarColors.primary.withValues(alpha: 0.15)
            : (isHovered
                ? SidebarColors.textPrimary.withValues(alpha: 0.05)
                : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
        border: (!_isCollapsed && isActive)
            ? const Border(
                left: BorderSide(color: SidebarColors.primary, width: 4))
            : null,
      ),
      child: Row(
        mainAxisAlignment:
            _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                isActive ? SidebarColors.primary : SidebarColors.textSecondary,
            size: 22,
          ),
          if (!_isCollapsed) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: isActive ? SidebarStyles.action : SidebarStyles.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]
        ],
      ),
    );

    if (_isCollapsed) {
      tileContent = Tooltip(
          message: title,
          textStyle: SidebarStyles.tooltip,
          decoration: BoxDecoration(
              color: Colors.grey[900], borderRadius: BorderRadius.circular(4)),
          child: tileContent);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          _closeAllExpandables();
          _navigate(routeId);
        },
        child: tileContent,
      ),
    );
  }

  // --- COLLAPSED ICON ---
  Widget _buildCollapsedIcon(SidebarItem item, int index) {
    bool isParentActive =
        item.subItems.any((sub) => sub.routeId == _activeRouteId);
    bool isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Tooltip(
          message: item.title,
          textStyle: SidebarStyles.tooltip,
          decoration: BoxDecoration(
              color: Colors.grey[900], borderRadius: BorderRadius.circular(4)),
          child: InkWell(
            onTap: () {
              setState(() {
                _isCollapsed = false;
                _expandedIndex = index;
              });
              // âœ… FIX 3: Reduced Delay drastically (250ms -> 50ms)
              // Ab ye "lag" nahi karega, almost instant open hoga.
              Future.delayed(const Duration(milliseconds: 50), () {
                final String itemKey = item.title;
                _controllers[itemKey]?.expand();
                for (var key in _controllers.keys) {
                  if (key != itemKey) _controllers[key]?.collapse();
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(
                  10), // Reduced padding slightly to prevent overflow
              decoration: BoxDecoration(
                  color: (isParentActive || isHovered)
                      ? SidebarColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isParentActive
                      ? const Border(
                          left: BorderSide(
                              color: SidebarColors.primary, width: 3))
                      : null),
              child: Icon(item.icon,
                  color: (isParentActive || isHovered)
                      ? SidebarColors.primary
                      : SidebarColors.textSecondary,
                  size: 24),
            ),
          ),
        ),
      ),
    );
  }

  // --- EXPANDABLE TILE ---
  Widget _buildExpandableTile(SidebarItem item, int index) {
    bool isParentActive =
        item.subItems.any((sub) => sub.routeId == _activeRouteId);
    final String itemKey = item.title;

    _controllers.putIfAbsent(itemKey, () => ExpansibleController());

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        controller: _controllers[itemKey],
        key: PageStorageKey(itemKey),
        initiallyExpanded: isParentActive,
        onExpansionChanged: (isOpen) {
          // âœ… FIX: setState during build error â€” addPostFrameCallback use karo
          // ExpansionTile initiallyExpanded=true hone par initState mein
          // expand hota hai jo build ke dauran setState trigger karta hai.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (isOpen) {
              setState(() => _expandedIndex = index);
              for (var key in _controllers.keys) {
                if (key != itemKey) _controllers[key]?.collapse();
              }
            } else if (_expandedIndex == index) {
              setState(() => _expandedIndex = null);
            }
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(item.icon,
            size: 20,
            color: (_expandedIndex == index || isParentActive)
                ? SidebarColors.primary
                : SidebarColors.textSecondary),
        title: Text(
          item.title,
          style: (_expandedIndex == index || isParentActive)
              ? SidebarStyles.action
              : SidebarStyles.body,
        ),
        iconColor: SidebarColors.primary,
        collapsedIconColor: SidebarColors.textSecondary,
        children: item.subItems.map((subItemData) {
          return _buildSubMenuTile(subItemData);
        }).toList(),
      ),
    );
  }

  // --- SUB MENU TILE ---
  Widget _buildSubMenuTile(MenuItemData data) {
    bool isActive = _activeRouteId == data.routeId;
    bool isHovered = _hoveredSubItemRouteId == data.routeId;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredSubItemRouteId = data.routeId),
      onExit: (_) => setState(() => _hoveredSubItemRouteId = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigate(data.routeId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(left: 12, bottom: 4, right: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isActive
                ? SidebarColors.primary.withValues(alpha: 0.1)
                : (isHovered
                    ? SidebarColors.textPrimary.withValues(alpha: 0.03)
                    : Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? SidebarColors.primary
                      : SidebarColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.displayTitle,
                  style: isActive
                      ? SidebarStyles.action.copyWith(fontSize: 13)
                      : SidebarStyles.body.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeAllExpandables() {
    setState(() => _expandedIndex = null);
    for (var controller in _controllers.values) {
      controller.collapse();
    }
  }

  // --- FOOTER ---
  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.symmetric(
          // âœ… FIX 2: Dynamic Padding for Footer too
          horizontal: _isCollapsed ? 8 : 12,
          vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: SidebarColors.glassBorder, height: 1),
          const SizedBox(height: 10),
          _buildSingleTile(
              title: AppRoutes.getTitle(AppRoutes.settingsRoute),
              icon: SidebarIcons.settings,
              routeId: AppRoutes.settingsRoute,
              index: 99),
          _buildSingleTile(
              title: AppRoutes.getTitle(AppRoutes.exitAppRoute),
              icon: SidebarIcons.logout,
              routeId: AppRoutes.exitAppRoute,
              index: 100),
        ],
      ),
    );
  }
}
