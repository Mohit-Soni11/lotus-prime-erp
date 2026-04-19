import 'package:flutter/foundation.dart';
import '../../../models/dashboard/shop_profile_model.dart';
import '../../dashboard/dashboard_repository.dart'; // ✅ Import Repository

class ShopCardLogic extends ChangeNotifier {
  
  // Dependencies
  final DashboardRepository _repository; // ✅ Dependency Injection

  // State Variables
  ShopProfileModel _data = ShopProfileModel.empty();
  bool _isLoading = true;
  bool _isExpanded = false;
  String? _errorMessage;

  // Getters
  ShopProfileModel get data => _data;
  bool get isLoading => _isLoading;
  bool get isExpanded => _isExpanded;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // ✅ Constructor me Repository Inject kiya
  ShopCardLogic(this._repository) {
    _fetchShopData();
  }

  // --- CORE LOGIC: Real Data Fetching ---
  Future<void> _fetchShopData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ Ab ye Repository se asli data layega
      final result = await _repository.fetchFullShopDetails();
      
      _data = result;
      
    } catch (e) {
      debugPrint("🔴 Error in Logic: $e");
      _errorMessage = "Unable to load profile. Please check connection.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void retryFetch() {
    _fetchShopData();
  }

  void toggleCardExpansion() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  // --- FORMATTERS ---
  String get formattedLocation {
    if (_data.city.isEmpty && _data.state.isEmpty) return "Location Not Set";
    if (_data.city.isEmpty) return _data.state;
    return "${_data.city}, ${_data.state}";
  }

  String get shopInitials {
    final name = _data.displayName.trim();
    if (name.isEmpty) return "SH";
    List<String> words = name.split(" ");
    if (words.length >= 2) {
      return "${words[0][0]}${words[1][0]}".toUpperCase();
    }
    return name.substring(0, (name.length > 2 ? 2 : name.length)).toUpperCase();
  }
}