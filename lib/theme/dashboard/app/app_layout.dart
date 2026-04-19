// ✅ Yahan humne 'material.dart' hata diya kyunki sirf numbers hain
// Isse Yellow line gayab ho jayegi.

class AppLayout {
  const AppLayout();

  // --- 1. SPACING & PADDING ---
  double get pXss => 4.0;
  double get pXs  => 8.0;
  double get pSm  => 12.0;
  double get pMd  => 20.0;
  double get pLg  => 40.0;
  double get pXl  => 60.0;

  // --- 2. BORDER RADIUS ---
  double get radiusSm => 12.0;
  double get radiusMd => 16.0;
  double get radiusLg => 24.0;
  double get radiusCircular => 100.0;

  // --- 3. ICON SIZES ---
  double get iconSm => 16.0;
  double get iconMd => 20.0;
  double get iconLg => 32.0;
  double get iconXl => 80.0;

  // --- 4. LAYOUT CONSTRAINTS (Ye MISSING tha aapke code mein) ---
  double get cardMaxWidth => 1100.0; 
  double get cardMaxHeight => 700.0; 
  double get glowOrbSize => 400.0;   

  // --- 5. EFFECTS (Ye bhi missing tha) ---
  double get blurSm => 5.0;
  double get blurMd => 10.0;
  double get blurGlow => 80.0; 
}