import 'package:flutter/material.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/application/shop_identity_controller.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/data/shop_identity_repository.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/domain/shop_identity.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/presentation/shop_identity_card_theme.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/presentation/shop_identity_detail_row.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/presentation/shop_identity_logo.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopIdentityCard extends StatefulWidget {
  const ShopIdentityCard({super.key, required this.reader});

  final ShopIdentityReader reader;

  @override
  State<ShopIdentityCard> createState() => _ShopIdentityCardState();
}

class _ShopIdentityCardState extends State<ShopIdentityCard> {
  late final ShopIdentityController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ShopIdentityController(widget.reader);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isInitialLoading) {
          return _buildLoadingState();
        }
        if (_controller.hasError && !_controller.identity.isConfigured) {
          return _buildErrorState();
        }
        if (!_controller.identity.isConfigured) {
          return _buildNotConfiguredState();
        }
        return _buildIdentityCard(_controller.identity);
      },
    );
  }

  Widget _buildIdentityCard(ShopIdentity identity) {
    return Container(
      decoration: ShopIdentityCardTheme.decoration,
      child: Padding(
        padding: ShopIdentityCardTheme.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 330;
                final profileDetails = _buildProfileSummary(identity);
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: ShopIdentityLogo(identity: identity)),
                      const SizedBox(height: 16),
                      profileDetails,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: profileDetails),
                    const SizedBox(width: 12),
                    ShopIdentityLogo(identity: identity),
                  ],
                );
              },
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _controller.isExpanded
                    ? _buildExpandedDetails(identity)
                    : const SizedBox.shrink(),
              ),
            ),
            if (_controller.isRefreshing) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(
                minHeight: 2,
                color: ShopIdentityCardTheme.gold,
                backgroundColor: Colors.white12,
              ),
            ],
            if (_controller.hasError) _buildInlineError(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary(ShopIdentity identity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          identity.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ShopIdentityCardTheme.gold,
            letterSpacing: 0.2,
          ),
        ),
        if (identity.ownerName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            identity.ownerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
        if (identity.formattedLocation.isNotEmpty)
          Text(
            identity.formattedLocation,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: ShopIdentityCardTheme.mutedText,
            ),
          ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: _controller.isExpanded
              ? 'Hide shop details'
              : 'View shop details',
          child: OutlinedButton.icon(
            onPressed: _controller.toggleExpanded,
            icon: Icon(
              _controller.isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
            ),
            label:
                Text(_controller.isExpanded ? 'Hide Details' : 'View Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ShopIdentityCardTheme.gold,
              side: const BorderSide(color: ShopIdentityCardTheme.goldBorder),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(ShopIdentity identity) {
    final rows = <Widget>[
      if (identity.mobile.isNotEmpty)
        ShopIdentityDetailRow(
          icon: Icons.phone_android_rounded,
          label: 'Mobile',
          value: identity.mobile,
        ),
      if (identity.email.isNotEmpty)
        ShopIdentityDetailRow(
          icon: Icons.email_rounded,
          label: 'Email',
          value: identity.email,
        ),
      if (identity.website.isNotEmpty)
        ShopIdentityDetailRow(
          icon: Icons.language_rounded,
          label: 'Website',
          value: identity.website,
          onTap: () => _openWebsite(identity.website),
        ),
      if (identity.gstin.isNotEmpty)
        ShopIdentityDetailRow(
          icon: Icons.verified_user_rounded,
          label: 'GSTIN',
          value: 'GSTIN: ${identity.gstin}',
        ),
      if (identity.bisLicense.isNotEmpty)
        ShopIdentityDetailRow(
          icon: Icons.workspace_premium_rounded,
          label: 'BIS licence',
          value: 'BIS: ${identity.bisLicense}',
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          const Divider(color: Colors.white12),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 160,
      decoration: ShopIdentityCardTheme.decoration,
      alignment: Alignment.center,
      child: Semantics(
        label: 'Loading shop profile',
        child:
            const CircularProgressIndicator(color: ShopIdentityCardTheme.gold),
      ),
    );
  }

  Widget _buildNotConfiguredState() {
    return Container(
      decoration: ShopIdentityCardTheme.decoration,
      padding: ShopIdentityCardTheme.padding,
      child: const Row(
        children: [
          Icon(Icons.storefront_outlined,
              color: ShopIdentityCardTheme.gold, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Shop profile is not configured yet.',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: ShopIdentityCardTheme.decoration,
      padding: ShopIdentityCardTheme.padding,
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFFC16B), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _controller.errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _controller.load,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFFFC16B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _controller.errorMessage!,
              style: const TextStyle(color: Color(0xFFFFD39A), fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _controller.load,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWebsite(String rawWebsite) async {
    final normalized =
        rawWebsite.contains('://') ? rawWebsite : 'https://$rawWebsite';
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) {
      _showWebsiteError();
      return;
    }
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) _showWebsiteError();
    } catch (_) {
      _showWebsiteError();
    }
  }

  void _showWebsiteError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Website could not be opened.')),
    );
  }
}
