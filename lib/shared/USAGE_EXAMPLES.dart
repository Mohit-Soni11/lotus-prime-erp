// =============================================================================
// FILE        : USAGE_EXAMPLES.dart
// PURPOSE     : Existing screens mein SmartInputField kaise lagaen
//               Yeh file apne project mein mat daalein — sirf reference hai.
// =============================================================================

// ════════════════════════════════════════════════════════════════════════════
// EXAMPLE 1: AddCustomerScreen mein (First Name, Last Name, Address, Notes)
// Location: lib/ui/customer/add_customer/add_customer_screen.dart
// ════════════════════════════════════════════════════════════════════════════

/*

// Step 1: Import karo
import 'package:lotus_erp/shared/smart_input/ui/smart_input_field.dart';
import 'package:lotus_erp/shared/smart_input/logic/smart_input_controller.dart';
import 'package:lotus_erp/shared/smart_input/config/smart_field_type.dart';

class AddCustomerScreen extends StatefulWidget { ... }

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  
  // Step 2: Controller create karo — har field ka alag controller
  late final SmartInputController _firstNameCtrl;
  late final SmartInputController _lastNameCtrl;
  late final SmartInputController _addressCtrl;
  late final SmartInputController _cityCtrl;
  late final SmartInputController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = SmartInputController(fieldType: SmartFieldType.name);
    _lastNameCtrl  = SmartInputController(fieldType: SmartFieldType.name);
    _addressCtrl   = SmartInputController(fieldType: SmartFieldType.address);
    _cityCtrl      = SmartInputController(fieldType: SmartFieldType.address);
    _notesCtrl     = SmartInputController(fieldType: SmartFieldType.remark);
  }

  @override
  void dispose() {
    // ALWAYS dispose karo!
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // Step 3: Build mein SmartInputField use karo
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          
          // ── First Name ──────────────────────────────────────────────────
          SmartInputField(
            controller: _firstNameCtrl,
            label: 'First Name *',
            hint: 'e.g. Ramesh, Priya...',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            onNameSelected: (name) => _logic.onFirstNameChanged(name),
            onChanged: (name) => _logic.onFirstNameChanged(name),
          ),

          const SizedBox(height: 16),

          // ── Last Name ───────────────────────────────────────────────────
          SmartInputField(
            controller: _lastNameCtrl,
            label: 'Last Name',
            hint: 'e.g. Sharma, Gupta...',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            onChanged: (name) => _logic.onLastNameChanged(name),
          ),

          const SizedBox(height: 16),

          // ── Address Line 1 ──────────────────────────────────────────────
          SmartInputField(
            controller: _addressCtrl,
            label: 'Address Line 1',
            hint: 'House/Shop No., Street...',
            prefixIcon: const Icon(Icons.home_outlined),
            onChanged: (val) => _logic.onAddressLine1Changed(val),
          ),

          const SizedBox(height: 16),

          // ── City ────────────────────────────────────────────────────────
          SmartInputField(
            controller: _cityCtrl,
            label: 'City',
            hint: 'e.g. Patna, Mumbai...',
            prefixIcon: const Icon(Icons.location_city_outlined),
            onChanged: (val) => _logic.onCityChanged(val),
          ),

          const SizedBox(height: 16),

          // ── Internal Notes ──────────────────────────────────────────────
          SmartInputField(
            controller: _notesCtrl,
            label: 'Internal Notes',
            hint: 'Koi remark...',
            prefixIcon: const Icon(Icons.note_outlined),
            maxLines: 3,
            onChanged: (val) => _logic.onNotesChanged(val),
          ),

          // ── Family Members mein bhi (name field) ────────────────────────
          // FamilyMemberRow widget mein:
          SmartInputField(
            controller: SmartInputController(fieldType: SmartFieldType.name),
            label: 'Member Name',
            hint: 'Family member ka naam...',
            onChanged: (name) => _updateMember(id, name: name),
          ),
        ],
      ),
    );
  }
}
*/

// ════════════════════════════════════════════════════════════════════════════
// EXAMPLE 2: AddKarigarScreen mein (Name field)
// Location: lib/ui/karigar/add_karigar/add_karigar_screen.dart
// ════════════════════════════════════════════════════════════════════════════

/*
  late final SmartInputController _karigarNameCtrl;
  
  initState() {
    _karigarNameCtrl = SmartInputController(fieldType: SmartFieldType.name);
  }

  SmartInputField(
    controller: _karigarNameCtrl,
    label: 'Karigar Name *',
    prefixIcon: const Icon(Icons.engineering_outlined),
    onChanged: (val) => _logic.onNameChanged(val),
  ),
*/

// ════════════════════════════════════════════════════════════════════════════
// EXAMPLE 3: Sales POS mein Item field
// Location: lib/ui/sales/... (sales item entry)
// ════════════════════════════════════════════════════════════════════════════

/*
  late final SmartInputController _itemNameCtrl;
  
  initState() {
    _itemNameCtrl = SmartInputController(fieldType: SmartFieldType.item);
  }

  SmartInputField(
    controller: _itemNameCtrl,
    label: 'Item Name',
    hint: 'e.g. Gold Ring, Silver Chain...',
    prefixIcon: const Icon(Icons.diamond_outlined),
    onChanged: (val) => _logic.onItemNameChanged(val),
  ),
*/

// ════════════════════════════════════════════════════════════════════════════
// EXAMPLE 4: Girvi Screen mein (Customer name + Remark)
// ════════════════════════════════════════════════════════════════════════════

/*
  late final SmartInputController _girviCustomerCtrl;
  late final SmartInputController _girviRemarkCtrl;
  
  initState() {
    _girviCustomerCtrl = SmartInputController(fieldType: SmartFieldType.name);
    _girviRemarkCtrl   = SmartInputController(fieldType: SmartFieldType.remark);
  }

  SmartInputField(
    controller: _girviCustomerCtrl,
    label: 'Customer Name',
    onChanged: (val) => ...,
  ),
  
  SmartInputField(
    controller: _girviRemarkCtrl,
    label: 'Notice / Remark',
    maxLines: 2,
    onChanged: (val) => ...,
  ),
*/

// ════════════════════════════════════════════════════════════════════════════
// EXAMPLE 5: Supplier Screen mein (Company name)
// ════════════════════════════════════════════════════════════════════════════

/*
  late final SmartInputController _supplierNameCtrl;
  
  initState() {
    _supplierNameCtrl = SmartInputController(fieldType: SmartFieldType.company);
  }

  SmartInputField(
    controller: _supplierNameCtrl,
    label: 'Supplier Company Name',
    hint: 'e.g. Rajesh Gold Suppliers...',
    prefixIcon: const Icon(Icons.business_outlined),
    onChanged: (val) => _logic.onCompanyNameChanged(val),
  ),
*/
