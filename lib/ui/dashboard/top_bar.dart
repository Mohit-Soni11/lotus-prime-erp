import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/dashboard/topbar/topbar_theme.dart';
import '../../models/dashboard/user_profile.dart';
import '../../logic/dashboard/dashboard_repository.dart';
import '../../models/dashboard/notification_item.dart';
import '../../models/dashboard/search_result.dart';
import '../../constants/enums.dart';
import '../auth/services/auth_service.dart';

class TopBar extends StatefulWidget {
  final Function(String) onNavChange;
  final UserProfile currentUser;
  final DashboardRepository repository;

  const TopBar({
    super.key,
    required this.onNavChange,
    required this.currentUser,
    required this.repository,
  });

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> with TickerProviderStateMixin {
  // --- STATE ---
  SearchScope selectedScope = SearchScope.all;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final AuthService _authService = AuthService();

  // ðŸ”¥ SENIOR UPGRADE: Debounce Timer (Performance Saver)
  Timer? _debounce;

  // KEYS
  final GlobalKey _searchBarKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<NotificationItem> _cachedNotifications = [];
  StreamSubscription? _notifSubscription;

  String _searchHintText = "Search here...";
  TextInputType _keyboardType = TextInputType.text;
  List<TextInputFormatter>? _inputFormatters;

  // --- ANIMATIONS ---
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _bellController;
  late AnimationController _profileGlowController;

  @override
  void initState() {
    super.initState();

    // 1. System Pulse (Online Indicator)
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);

    // 2. Bell Animation
    _bellController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    // 3. Premium Profile Glow
    _profileGlowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);

    _onScopeChanged(selectedScope);

    // Listener for Search
    _searchController.addListener(_onSearchChanged);

    // Focus Listener to close overlay
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        Future.delayed(
            const Duration(milliseconds: 200), () => _removeOverlay());
      }
    });

    // Real-time Notifications
    _notifSubscription = widget.repository.notificationsStream.listen((data) {
      if (mounted) {
        setState(() {
          _cachedNotifications = data;
          if (data.any((n) => !n.isRead)) {
            _bellController.forward(from: 0);
          }
        });
      }
    });

    widget.repository.loadNotifications(widget.currentUser.role);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pulseController.dispose();
    _bellController.dispose();
    _profileGlowController.dispose();
    _notifSubscription?.cancel();
    _debounce?.cancel(); // âœ… Clean up timer
    _removeOverlay();
    super.dispose();
  }

  // ==========================================
  // ðŸ”¥ SEARCH LOGIC (Optimized)
  // ==========================================
  void _onSearchChanged() {
    // 1. Agar debounce timer chal raha hai, to cancel karo
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 2. Naya timer shuru karo (500ms wait)
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty) {
        _showOverlay(); // Show Loading immediately
        _updateSearchResults(_searchController.text);
      } else {
        _removeOverlay();
      }
    });
  }

  void _updateSearchResults(String query) async {
    // Safety check
    if (!mounted) return;

    List<SearchResult> results = await widget.repository
        .searchUniversal(query, selectedScope, limit: 10);

    if (mounted && _overlayEntry != null) {
      // Refresh Overlay with Data
      _overlayEntry!.markNeedsBuild();
      _showOverlay(results: results, isLoading: false);
    }
  }

  void _showOverlay({List<SearchResult>? results, bool isLoading = true}) {
    // Remove existing to avoid duplicates
    _removeOverlay();

    final renderBox =
        _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 55),
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            child: _buildGlassOverlay(results ?? [], isLoading),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  Widget _buildGlassOverlay(List<SearchResult> results, bool isLoading) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
              color: TopBarColors.background.withValues(alpha: 0.95),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ]),
          constraints: const BoxConstraints(maxHeight: 400),
          child: isLoading
              ? const SizedBox(
                  height: 100,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: TopBarColors.accentGold)))
              : results.isEmpty
                  ? _buildNoResultsFound()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (c, i) => Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.05)),
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return ListTile(
                          hoverColor: Colors.white.withValues(alpha: 0.05),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: TopBarColors.accentGold
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getIconForType(item.type),
                                color: TopBarColors.accentGold, size: 18),
                          ),
                          title: Text(item.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          subtitle: Text(item.subtitle,
                              style: const TextStyle(
                                  color: TopBarColors.textSecondary,
                                  fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.grey, size: 12),
                          onTap: () {
                            _searchController.clear();
                            _removeOverlay();
                            _searchFocusNode.unfocus();
                            // Navigate Logic Here if needed
                          },
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(width: 10),
          Text("No results found",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  void _onScopeChanged(SearchScope value) {
    setState(() {
      selectedScope = value;
      if (value == SearchScope.mobile) {
        _searchHintText = "Enter Mobile Number...";
        _keyboardType = TextInputType.number;
        _inputFormatters = [FilteringTextInputFormatter.digitsOnly];
      } else {
        _searchHintText = "Search ${value.label}...";
        _keyboardType = TextInputType.text;
        _inputFormatters = [];
      }
    });
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'customer':
        return Icons.person;
      case 'invoice':
        return Icons.receipt_long;
      case 'loan':
        return Icons.diamond_outlined;
      default:
        return Icons.search;
    }
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: TopBarColors.background,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Notifications",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              TextButton(
                onPressed: () {
                  widget.repository.markAllRead(widget.currentUser.role);
                  Navigator.pop(context); // Close dialog
                },
                child: const Text("Mark all read",
                    style: TextStyle(
                        color: TopBarColors.accentGold, fontSize: 12)),
              )
            ],
          ),
          content: SizedBox(
            width: 350,
            height: 300,
            child: StreamBuilder<List<NotificationItem>>(
              stream: widget.repository.notificationsStream,
              initialData: _cachedNotifications,
              builder: (context, snapshot) {
                final alerts = snapshot.data ?? [];
                if (alerts.isEmpty) {
                  return const Center(
                      child: Text("All caught up!",
                          style: TextStyle(color: Colors.grey)));
                }
                return ListView.separated(
                  itemCount: alerts.length,
                  separatorBuilder: (c, i) =>
                      Divider(color: Colors.white.withValues(alpha: 0.1)),
                  itemBuilder: (context, index) {
                    final item = alerts[index];
                    return ListTile(
                      leading: Icon(Icons.notifications,
                          color: item.isRead
                              ? Colors.grey
                              : TopBarColors.accentGold),
                      title: Text(item.title,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: item.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold)),
                      subtitle: Text(item.desc,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showProfileMenu() async {
    final RenderBox? button =
        _profileKey.currentContext?.findRenderObject() as RenderBox?;
    final OverlayState overlay = Overlay.of(context);

    if (button == null) return;

    final RenderBox overlayBox =
        overlay.context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlayBox),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlayBox),
      ),
      Offset.zero & overlayBox.size,
    );

    final String? selectedValue = await showMenu<String>(
      context: context,
      position: position,
      color: TopBarColors.sidebarLabelBg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      elevation: 10,
      items: [
        const PopupMenuItem(
            value: "profile",
            child: Row(children: [
              Icon(Icons.person, color: TopBarColors.accentGold),
              SizedBox(width: 10),
              Text("My Profile", style: TextStyle(color: Colors.white))
            ])),
        const PopupMenuItem(
            value: "logout",
            child: Row(children: [
              Icon(Icons.logout, color: TopBarColors.notificationRed),
              SizedBox(width: 10),
              Text("Logout", style: TextStyle(color: Colors.white))
            ])),
      ],
    );

    if (selectedValue == "logout") {
      await _authService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isDesktop = constraints.maxWidth > 900;

      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: TopBarStyles.height + 10,
            decoration: BoxDecoration(
              color: TopBarColors.background.withValues(alpha: 0.85),
              border: Border(
                  bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08), width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBranding(),
                Expanded(
                    child: Center(
                  child: isDesktop
                      ? _buildAdvancedSearchBar()
                      : InkWell(
                          onTap: () {
                            // Mobile Search Trigger
                            // Implement mobile specific search dialog if needed
                            _onSearchChanged();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: TopBarColors.accentGold
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(TopBarIcons.search,
                                color: TopBarColors.accentGold),
                          ),
                        ),
                )),
                const SizedBox(width: 20),
                _buildActions(context, isDesktop),
              ],
            ),
          ),
        ),
      );
    });
  }

  // --- Sub-Widgets (Branding, SearchBar, Actions) Same as before ---
  // (Assuming you have the buildBranding, buildAdvancedSearchBar, buildActions from your previous file.
  //  I kept the structure same, just logic updated above.)

  Widget _buildBranding() {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
              color: TopBarColors.sidebarLabelBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]),
          child: const Icon(TopBarIcons.dashboard,
              color: TopBarColors.accentGold, size: 22),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("DASHBOARD",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Row(
              children: [
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: TopBarColors.systemOnline,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: TopBarColors.systemOnline, blurRadius: 6)
                          ])),
                ),
                const SizedBox(width: 8),
                const Text("System Online",
                    style: TextStyle(
                        color: TopBarColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            )
          ],
        )
      ],
    );
  }

  Widget _buildAdvancedSearchBar() {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        key: _searchBarKey,
        height: 50,
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
            color: TopBarColors.searchBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ]),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: PopupMenuButton<SearchScope>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: TopBarColors.background,
                onSelected: _onScopeChanged,
                itemBuilder: (context) => SearchScope.values
                    .map((scope) => PopupMenuItem(
                        value: scope,
                        child: Text(scope.label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))))
                    .toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(selectedScope.label,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white54, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            Container(
                width: 1,
                height: 20,
                color: Colors.white.withValues(alpha: 0.1)),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
                cursorColor: TopBarColors.accentGold,
                keyboardType: _keyboardType,
                inputFormatters: _inputFormatters,
                decoration: InputDecoration(
                  hintText: _searchHintText,
                  hintStyle: TextStyle(
                      color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  isDense: true,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onSearchChanged(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      color: TopBarColors.accentGold,
                      borderRadius: BorderRadius.circular(11),
                      gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFF9A825)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)),
                  child: const Icon(TopBarIcons.search,
                      color: Colors.black, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDesktop) {
    return Row(
      children: [
        if (isDesktop)
          ElevatedButton(
            onPressed: () => widget.onNavChange("New Sale"),
            style: ElevatedButton.styleFrom(
                backgroundColor: TopBarColors.accentGold,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                shadowColor: TopBarColors.accentGold.withValues(alpha: 0.5),
                elevation: 8,
                minimumSize: const Size(0, 46)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(TopBarIcons.newSale, color: Colors.black, size: 18),
                SizedBox(width: 8),
                Text("NEW SALE",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ],
            ),
          ),
        const SizedBox(width: 20),
        InkWell(
          onTap: () => _showNotifications(context),
          borderRadius: BorderRadius.circular(50),
          child: AnimatedBuilder(
            animation: _bellController,
            builder: (context, child) {
              double offset = 0;
              if (_bellController.isAnimating) {
                offset = 4 *
                    (1 - _bellController.value) *
                    (0.5 - (0.5 - _bellController.value).abs()).sign;
              }
              return Transform.translate(
                  offset: Offset(offset, 0), child: child);
            },
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle),
                  child: const Icon(TopBarIcons.notification,
                      color: Colors.white70),
                ),
                if (_cachedNotifications.any((n) => !n.isRead))
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: TopBarColors.notificationRed,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: TopBarColors.background, width: 2))),
                  )
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        _buildProfileCard(context),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    bool isOwner = widget.currentUser.role == UserRole.owner.name;
    Color primaryColor =
        isOwner ? TopBarColors.accentGold : const Color(0xFF64B5F6);
    String roleDisplay = UserRole.fromString(widget.currentUser.role).label;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _profileGlowController,
        builder: (context, child) {
          double glowOpacity = 0.1 + (0.2 * _profileGlowController.value);
          double spread = 2 * _profileGlowController.value;

          return InkWell(
            onTap: () => _showProfileMenu(),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              key: _profileKey,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFF1A1D24),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                        color: primaryColor.withValues(alpha: glowOpacity),
                        blurRadius: 12,
                        spreadRadius: spread)
                  ]),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(colors: [
                                  primaryColor,
                                  Colors.transparent
                                ]))),
                        CircleAvatar(
                            radius: 17,
                            backgroundColor: const Color(0xFF1A1D24),
                            child: CircleAvatar(
                                radius: 15,
                                backgroundColor: primaryColor,
                                child: Text(widget.currentUser.initials,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900)))),
                        Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF00E676),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFF1A1D24),
                                        width: 1.5))))
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.currentUser.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              height: 1.0)),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.7)
                            ]),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 4)
                            ]),
                        child: Text(roleDisplay,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                height: 1.0)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white54, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
