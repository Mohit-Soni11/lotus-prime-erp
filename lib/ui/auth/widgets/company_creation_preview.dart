import 'package:flutter/material.dart';

import '../../../theme/dashboard/app/uv.dart';

/// Shows the former showroom registration fields without changing account data.
class CompanyCreationPreview extends StatefulWidget {
  const CompanyCreationPreview({super.key});

  @override
  State<CompanyCreationPreview> createState() => _CompanyCreationPreviewState();
}

class _CompanyCreationPreviewState extends State<CompanyCreationPreview> {
  final _owner = TextEditingController();
  final _mobile = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _owner.dispose();
    _mobile.dispose();
    _company.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This is the original Create Company form for review. Entries are not saved.',
            style: UV.styles.body.copyWith(color: UV.colors.textSecondary),
          ),
          SizedBox(height: UV.layout.pMd),
          LayoutBuilder(builder: (context, constraints) {
            final owner = _field('Owner Name', _owner, Icons.person_outline);
            final mobile = _field('Mobile', _mobile, Icons.phone_outlined,
                keyboardType: TextInputType.phone);
            if (constraints.maxWidth < 440) {
              return Column(children: [
                owner,
                SizedBox(height: UV.layout.pMd),
                mobile,
              ]);
            }
            return Row(children: [
              Expanded(child: owner),
              SizedBox(width: UV.layout.pSm),
              Expanded(child: mobile),
            ]);
          }),
          SizedBox(height: UV.layout.pMd),
          _field('Company Name', _company, Icons.storefront_outlined),
          SizedBox(height: UV.layout.pMd),
          _field('Email Address', _email, Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          SizedBox(height: UV.layout.pMd),
          _field('Password', _password, Icons.lock_outline,
              obscureText: !_showPassword,
              suffix: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(_showPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              )),
          SizedBox(height: UV.layout.pLg),
          OutlinedButton.icon(
            onPressed: () => _showWorkflow(context),
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('View original workflow'),
          ),
        ],
      );

  Widget _field(String label, TextEditingController controller, IconData icon,
          {TextInputType? keyboardType,
          bool obscureText = false,
          Widget? suffix}) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: UV.styles.body,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: UV.colors.primary),
          suffixIcon: suffix,
          filled: true,
          fillColor: UV.colors.bgSecondary,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(UV.layout.radiusSm)),
        ),
      );

  void _showWorkflow(BuildContext context) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Original company creation flow'),
          content: const SizedBox(
            width: 440,
            child: Text(
              '1. Enter owner name, mobile, company name, email and password.\n\n'
              '2. The old Firebase registration created a sign-in account, a company record, a head-office unit and an owner profile.\n\n'
              '3. The current Lotus ERP uses a local owner account and a separate five-step Shop Setup: Basic Info, Address, GST & Legal, Banking and Branding.\n\n'
              'This preview does not register an account or save any entries.',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ],
        ),
      );
}
