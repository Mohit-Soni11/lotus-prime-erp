import '../../shared/live_camera_dialog.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';

class PurchaseSellerCameraDialog extends LiveCameraDialog {
  const PurchaseSellerCameraDialog({super.key})
      : super(
          title: 'Capture Seller Photo',
          guidance:
              'Choose an internal or external camera, then capture the seller.',
          accentColor: PurchaseEntryColors.purchaseAccent,
        );
}
