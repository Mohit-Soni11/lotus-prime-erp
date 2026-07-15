part of '../stock_search_screen.dart';

class _StockSearchBody extends StatefulWidget {
  final StockSearchController controller;

  const _StockSearchBody({required this.controller});

  @override
  State<_StockSearchBody> createState() => _StockSearchBodyState();
}

class _StockSearchBodyState extends State<_StockSearchBody> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.controller.searchText,
    );
  }

  @override
  void didUpdateWidget(covariant _StockSearchBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.controller.searchText) {
      _searchController.text = widget.controller.searchText;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), () {
      widget.controller.setSearchText(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchHero(summary: controller.summary),
          const SizedBox(height: 18),
          _SearchFilterPanel(
            controller: controller,
            searchController: _searchController,
            onSearchChanged: _searchChanged,
          ),
          const SizedBox(height: 18),
          _SearchResultsPanel(controller: controller),
        ],
      ),
    );
  }
}
