// =============================================================================
// FILE        : counter_security_card.dart
// MODULE      : Dashboard / Counter Security Check
// LAYER       : UI
// DESCRIPTION : Jewellery counter ke liye item handout security check.
//               Customer ko item dene se pehle weight + pieces lock karo,
//               wapas aane pe verify karo.
//
//               3 STATES:
//               ┌──────────────────────────────────────────────────┐
//               │ 🔒 COUNTER SECURITY CHECK    [GOLD][SILVER]...   │
//               │ ─────────────────────────────────────────────    │
//               │ IDLE STATE:                                       │
//               │  STEP 1: GIVE ITEMS                               │
//               │  [Pieces  ] [Weight (gm)]  [🔒 LOCK & GIVE]      │
//               ├──────────────────────────────────────────────────┤
//               │ LOCKED STATE:                                     │
//               │  🔒 GOLD | 5 Pcs | 15.250 gm                     │
//               │  STEP 2: TAKE BACK                                │
//               │  [Return Pcs] [Scale Wt]   [✓ VERIFY]            │
//               ├──────────────────────────────────────────────────┤
//               │ RESULT — MATCHED:                                 │
//               │  ✅ MATCHED: 100% Accurate!          [FINISH]     │
//               ├──────────────────────────────────────────────────┤
//               │ RESULT — MISMATCH:                                │
//               │  ⚠ 2 Pcs Missing | 0.500 gm KAM HAI  [RESET]    │
//               └──────────────────────────────────────────────────┘
//
//               ANIMATIONS:
//               • Card entry slide + fade
//               • State transitions — AnimatedSwitcher
//               • Locked badge — scale bounce
//               • Result box — slide up + scale
//               • Metal chip — AnimatedContainer
//               • Error shake on validation fail
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/dashboard/counter_security/counter_security_logic.dart';
import '../../models/dashboard/counter_security_model.dart';
import '../../theme/dashboard/counter_security/counter_security_theme.dart';

class CounterSecurityCard extends StatefulWidget {
  const CounterSecurityCard({super.key});

  @override
  State<CounterSecurityCard> createState() => _CounterSecurityCardState();
}

class _CounterSecurityCardState extends State<CounterSecurityCard>
    with TickerProviderStateMixin {

  late final CounterSecurityLogic _logic;

  // Entry animation
  late final AnimationController _entryCtrl;
  late final Animation<double>   _entrySlide;
  late final Animation<double>   _entryFade;

  // Result pop animation
  late final AnimationController _resultCtrl;
  late final Animation<double>   _resultScale;
  late final Animation<double>   _resultSlide;

  // Input controllers — Step 1
  final _issuePcsCtrl = TextEditingController();
  final _issueWtCtrl  = TextEditingController();

  // Input controllers — Step 2
  final _retPcsCtrl = TextEditingController();
  final _retWtCtrl  = TextEditingController();

  // Focus nodes
  final _issuePcsFocus = FocusNode();
  final _issueWtFocus  = FocusNode();
  final _retPcsFocus   = FocusNode();
  final _retWtFocus    = FocusNode();

  // Error states
  String? _step1Error;
  String? _step2Error;

  // Shake animation key
  final _shakeKey1 = GlobalKey();
  final _shakeKey2 = GlobalKey();

  @override
  void initState() {
    super.initState();
    _logic = CounterSecurityLogic();
    _logic.addListener(_onStateChanged);

    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _entrySlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _resultCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));
    _resultScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut));
    _resultSlide = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entryCtrl.forward();
    });

    // Focus listeners for border color
    for (final fn in [_issuePcsFocus, _issueWtFocus, _retPcsFocus, _retWtFocus]) {
      fn.addListener(() => setState(() {}));
    }
  }

  void _onStateChanged() {
    if (!mounted) return;
    if (_logic.data.hasResult) {
      _resultCtrl.forward(from: 0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _logic.removeListener(_onStateChanged);
    _logic.dispose();
    _entryCtrl.dispose();
    _resultCtrl.dispose();
    _issuePcsCtrl.dispose();
    _issueWtCtrl.dispose();
    _retPcsCtrl.dispose();
    _retWtCtrl.dispose();
    _issuePcsFocus.dispose();
    _issueWtFocus.dispose();
    _retPcsFocus.dispose();
    _retWtFocus.dispose();
    super.dispose();
  }

  // ==========================================
  // ACTIONS
  // ==========================================
  void _onLock() {
    setState(() => _step1Error = null);
    final error = _logic.lockAndIssue(
      pcsStr:    _issuePcsCtrl.text,
      weightStr: _issueWtCtrl.text,
    );
    if (error != null) {
      setState(() => _step1Error = error);
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _onVerify() {
    setState(() => _step2Error = null);
    final error = _logic.verifyReturn(
      pcsStr:    _retPcsCtrl.text,
      weightStr: _retWtCtrl.text,
    );
    if (error != null) {
      setState(() => _step2Error = error);
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _onReset() {
    _issuePcsCtrl.clear();
    _issueWtCtrl.clear();
    _retPcsCtrl.clear();
    _retWtCtrl.clear();
    setState(() {
      _step1Error = null;
      _step2Error = null;
    });
    _logic.reset();
    _resultCtrl.reset();
    HapticFeedback.selectionClick();
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _entrySlide.value),
        child: Opacity(opacity: _entryFade.value, child: child),
      ),
      child: Container(
        decoration: CounterSecurityStyles.cardDecoration,
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(CounterSecurityStyles.cardBorderRadius),
          child: Stack(children: [
            const Positioned.fill(child: _AmbientGlows()),
            Padding(
              padding: CounterSecurityStyles.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  _buildMetalSelector(),
                  const SizedBox(height: 14),
                  _buildBody(),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: CounterSecurityColors.accentGold.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: CounterSecurityColors.accentGold.withOpacity(0.25)),
        ),
        child: Center(
          child: ShaderMask(
            shaderCallback: (b) =>
                CounterSecurityColors.goldGradient.createShader(b),
            child: const Icon(CounterSecurityIcons.header,
                size: 18, color: Colors.white),
          ),
        ),
      ),
      const SizedBox(width: 10),
      ShaderMask(
        shaderCallback: (b) =>
            CounterSecurityColors.goldGradient.createShader(b),
        child: const Text('COUNTER SECURITY CHECK',
            style: CounterSecurityStyles.headerStyle),
      ),
      const Spacer(),
      // Status indicator
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _logic.data.isLocked
              ? CounterSecurityColors.lockedBg
              : _logic.data.hasResult
                  ? (_logic.data.isMatched
                      ? CounterSecurityColors.matchedBg
                      : CounterSecurityColors.mismatchBg)
                  : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _logic.data.isLocked
                ? CounterSecurityColors.lockedBorder.withOpacity(0.5)
                : _logic.data.hasResult
                    ? (_logic.data.isMatched
                        ? CounterSecurityColors.matchedBorder.withOpacity(0.4)
                        : CounterSecurityColors.mismatchBorder.withOpacity(0.4))
                    : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          _logic.data.isIdle
              ? 'READY'
              : _logic.data.isLocked
                  ? 'LOCKED 🔒'
                  : _logic.data.isMatched
                      ? 'MATCHED ✅'
                      : 'ALERT ⚠️',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: _logic.data.isIdle
                ? CounterSecurityColors.textMuted
                : _logic.data.isLocked
                    ? CounterSecurityColors.lockedBorder
                    : _logic.data.isMatched
                        ? CounterSecurityColors.matchedText
                        : CounterSecurityColors.mismatchText,
            letterSpacing: 0.8,
          ),
        ),
      ),
    ]);
  }

  // ── METAL SELECTOR ────────────────────────────────────────────────────────
  Widget _buildMetalSelector() {
    return Row(
      children: SecurityMetal.values.map((metal) {
        final isActive = _logic.data.selectedMetal == metal;
        final isDisabled = _logic.data.isLocked;
        final activeColor =
            CounterSecurityColors.metalActiveColor(metal);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: isDisabled ? null : () => _logic.selectMetal(metal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: CounterSecurityStyles.chipHeight,
                decoration: CounterSecurityStyles.metalChip(
                  isActive: isActive,
                  activeColor: activeColor,
                ).copyWith(
                  color: isDisabled
                      ? (isActive
                          ? activeColor.withOpacity(0.5)
                          : CounterSecurityColors.chipInactive
                              .withOpacity(0.5))
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${metal.emoji} ${metal.label}',
                    style: CounterSecurityStyles.metalChipStyle.copyWith(
                      color: isDisabled
                          ? Colors.white.withOpacity(0.4)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList()
        ..last = Expanded(
          child: GestureDetector(
            onTap: _logic.data.isLocked
                ? null
                : () => _logic.selectMetal(SecurityMetal.values.last),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: CounterSecurityStyles.chipHeight,
              decoration: CounterSecurityStyles.metalChip(
                isActive: _logic.data.selectedMetal == SecurityMetal.values.last,
                activeColor: CounterSecurityColors
                    .metalActiveColor(SecurityMetal.values.last),
              ),
              child: Center(
                child: Text(
                  '${SecurityMetal.values.last.emoji} ${SecurityMetal.values.last.label}',
                  style: CounterSecurityStyles.metalChipStyle,
                ),
              ),
            ),
          ),
        ),
    );
  }

  // ── BODY — STATE SWITCHER ─────────────────────────────────────────────────
  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: _logic.data.hasResult
          ? _buildResultBox()
          : _logic.data.isLocked
              ? _buildStep2()
              : _buildStep1(),
    );
  }

  // ── STEP 1 — GIVE ITEMS ───────────────────────────────────────────────────
  Widget _buildStep1() {
    return Container(
      key: const ValueKey('step1'),
      padding: CounterSecurityStyles.innerPadding,
      decoration: CounterSecurityStyles.innerDecoration(
        bg: CounterSecurityColors.idleBg,
        border: CounterSecurityColors.idleBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step label
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CounterSecurityColors.accentGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: CounterSecurityColors.accentGold.withOpacity(0.3)),
              ),
              child: const Text('STEP 1 : GIVE ITEMS',
                  style: CounterSecurityStyles.stepLabelStyle),
            ),
          ]),

          const SizedBox(height: 14),

          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pieces input
              Expanded(
                child: _buildInput(
                  controller: _issuePcsCtrl,
                  focus: _issuePcsFocus,
                  label: 'PIECES',
                  hint: 'e.g. 5',
                  isNumeric: true,
                  isDecimal: false,
                ),
              ),
              const SizedBox(width: 12),
              // Weight input
              Expanded(
                flex: 2,
                child: _buildInput(
                  controller: _issueWtCtrl,
                  focus: _issueWtFocus,
                  label: 'WEIGHT (gm)',
                  hint: 'e.g. 15.250',
                  isNumeric: true,
                  isDecimal: true,
                ),
              ),
              const SizedBox(width: 12),
              // Lock button
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _buildLockButton(),
              ),
            ],
          ),

          // Error
          if (_step1Error != null) ...[
            const SizedBox(height: 8),
            _buildError(_step1Error!),
          ],
        ],
      ),
    );
  }

  // ── STEP 2 — TAKE BACK ────────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      children: [
        // Locked badge
        AnimatedBuilder(
          animation: _entryCtrl,
          builder: (_, child) => child!,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: CounterSecurityStyles.lockedBadge,
            child: Row(children: [
              const Icon(CounterSecurityIcons.lock,
                  size: 15, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _logic.data.lockedBadgeText,
                  style: CounterSecurityStyles.lockedBadgeStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 12),

        // Step 2 input
        Container(
          padding: CounterSecurityStyles.innerPadding,
          decoration: CounterSecurityStyles.innerDecoration(
            bg: CounterSecurityColors.lockedBg,
            border: CounterSecurityColors.lockedBorder.withOpacity(0.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Text('STEP 2 : TAKE BACK & VERIFY',
                      style: CounterSecurityStyles.stepLabelStyle),
                ),
              ]),

              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInput(
                      controller: _retPcsCtrl,
                      focus: _retPcsFocus,
                      label: 'RETURN PCS',
                      hint: 'e.g. 5',
                      isNumeric: true,
                      isDecimal: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildInput(
                      controller: _retWtCtrl,
                      focus: _retWtFocus,
                      label: 'SCALE WEIGHT (gm)',
                      hint: 'e.g. 15.250',
                      isNumeric: true,
                      isDecimal: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: _buildVerifyButton(),
                  ),
                ],
              ),

              if (_step2Error != null) ...[
                const SizedBox(height: 8),
                _buildError(_step2Error!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── RESULT BOX ────────────────────────────────────────────────────────────
  Widget _buildResultBox() {
    final matched = _logic.data.isMatched;

    return AnimatedBuilder(
      animation: _resultCtrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _resultSlide.value),
        child: Transform.scale(scale: _resultScale.value, child: child),
      ),
      child: Container(
        key: const ValueKey('result'),
        padding: const EdgeInsets.all(18),
        decoration: CounterSecurityStyles.resultBox(matched: matched),
        child: Row(
          children: [
            // Icon
            Icon(
              matched
                  ? CounterSecurityIcons.verify
                  : CounterSecurityIcons.warning,
              size: 28,
              color: matched
                  ? CounterSecurityColors.matchedIcon
                  : CounterSecurityColors.mismatchIcon,
            ),
            const SizedBox(width: 12),

            // Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matched ? 'MATCHED: 100% Accurate!' : 'MISMATCH DETECTED!',
                    style: CounterSecurityStyles.resultMainStyle.copyWith(
                      color: matched
                          ? CounterSecurityColors.matchedText
                          : CounterSecurityColors.mismatchText,
                    ),
                  ),
                  if (!matched) ...[
                    const SizedBox(height: 3),
                    Text(
                      _logic.data.mismatchMessage,
                      style: CounterSecurityStyles.resultSubStyle,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Action button
            GestureDetector(
              onTap: _onReset,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: matched ? Colors.white : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  matched ? 'FINISH' : 'RESET',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: matched
                        ? CounterSecurityColors.matchedBorder
                        : CounterSecurityColors.mismatchBorder,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── INPUT WIDGET ──────────────────────────────────────────────────────────
  Widget _buildInput({
    required TextEditingController controller,
    required FocusNode focus,
    required String label,
    required String hint,
    required bool isNumeric,
    required bool isDecimal,
  }) {
    return SizedBox(
      height: CounterSecurityStyles.inputHeight + 20,
      child: TextFormField(
        controller: controller,
        focusNode: focus,
        style: const TextStyle(
          color: CounterSecurityColors.inputText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        keyboardType: isNumeric
            ? (isDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number)
            : TextInputType.text,
        inputFormatters: isNumeric
            ? [
                isDecimal
                    ? FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,3}'))
                    : FilteringTextInputFormatter.digitsOnly,
              ]
            : null,
        decoration: CounterSecurityStyles.inputDecoration(
          label: label,
          hint: hint,
          isFocused: focus.hasFocus,
        ),
        onFieldSubmitted: (_) => focus.nextFocus(),
      ),
    );
  }

  // ── LOCK BUTTON ───────────────────────────────────────────────────────────
  Widget _buildLockButton() {
    return SizedBox(
      height: CounterSecurityStyles.btnHeight,
      child: ElevatedButton.icon(
        onPressed: _onLock,
        icon: const Icon(CounterSecurityIcons.lock, size: 15),
        label: const Text('LOCK\n& GIVE',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: CounterSecurityColors.lockBtnBg,
          foregroundColor: CounterSecurityColors.lockBtnText,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(CounterSecurityStyles.btnBorderRadius)),
          elevation: 4,
        ),
      ),
    );
  }

  // ── VERIFY BUTTON ─────────────────────────────────────────────────────────
  Widget _buildVerifyButton() {
    return SizedBox(
      height: CounterSecurityStyles.btnHeight,
      child: ElevatedButton.icon(
        onPressed: _onVerify,
        icon: const Icon(CounterSecurityIcons.verify, size: 15),
        label: const Text('VERIFY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: CounterSecurityColors.verifyBtnBg,
          foregroundColor: CounterSecurityColors.verifyBtnText,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(CounterSecurityStyles.btnBorderRadius)),
          elevation: 4,
        ),
      ),
    );
  }

  // ── ERROR TEXT ────────────────────────────────────────────────────────────
  Widget _buildError(String msg) {
    return Row(children: [
      const Icon(Icons.error_outline_rounded, size: 13, color: Color(0xFFFC8181)),
      const SizedBox(width: 5),
      Text(msg,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFFFC8181),
            fontWeight: FontWeight.w500,
          )),
    ]);
  }
}

// ── Ambient Glows ─────────────────────────────────────────────────────────────
class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(children: [
        Positioned(
          top: -30, right: -20,
          child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CounterSecurityColors.accentGold.withOpacity(0.04),
              boxShadow: [BoxShadow(
                color: CounterSecurityColors.accentGold.withOpacity(0.06),
                blurRadius: 60,
              )],
            ),
          ),
        ),
      ]),
    );
  }
}