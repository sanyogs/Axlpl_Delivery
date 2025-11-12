import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Strongly-typed isolate filter model
class _FilterArgs<T> {
  final List<T> items;
  final String query;
  final String Function(T) labelFn;

  const _FilterArgs({
    required this.items,
    required this.query,
    required this.labelFn,
  });
}

/// Background isolate filtering (fallback)
List<T> _runFiltering<T>(_FilterArgs<T> args) {
  final q = args.query.toLowerCase();
  if (q.isEmpty) return args.items;
  return args.items
      .where((item) => args.labelFn(item).toLowerCase().contains(q))
      .toList(growable: false);
}

class PaginatedDropdown<T> extends StatefulWidget {
  final String hint;
  final T? selectedValue;
  final List<T> items;
  final String Function(T) itemLabel;
  final dynamic Function(T) itemValue;
  final Function(T?) onChanged;
  final bool isLoading;        // first load/refresh loader
  final bool isLoadingMore;    // pagination loader (bottom row only)
  final bool hasMoreData;
  final VoidCallback? onLoadMore;
  final bool isSearchable;

  /// minimum characters before search triggers
  final int minSearchLength;

  /// server search callback (optional)
  final Future<void> Function(String query)? onSearch;

  const PaginatedDropdown({
    super.key,
    required this.hint,
    this.selectedValue,
    required this.items,
    required this.itemLabel,
    required this.itemValue,
    required this.onChanged,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreData = false,
    this.onLoadMore,
    this.isSearchable = true,
    this.minSearchLength = 1,
    this.onSearch,
  });

  @override
  State<PaginatedDropdown<T>> createState() => _PaginatedDropdownState<T>();
}

class _PaginatedDropdownState<T> extends State<PaginatedDropdown<T>> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<T> _filteredItems = [];
  bool _isDropdownOpen = false;

  /// FULL overlay loader when user is typing/searching.
  bool _isFiltering = false;

  Timer? _debounceTimer;

  /// Guard against race conditions between async filters.
  int _activeFilterToken = 0;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant PaginatedDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _onItemsUpdated(); // keep scroll; don't show global loader
    }
  }

  void _onItemsUpdated() {
    final q = _searchController.text.trim();
    if (q.isEmpty || q.length < widget.minSearchLength) {
      if (!mounted) return;
      setState(() {
        _filteredItems = widget.items; // adopt new/append items
      });
    } else {
      _refilterSilently(q); // async, no overlay loader
    }
  }

  Future<void> _refilterSilently(String query) async {
    final int token = ++_activeFilterToken; // prevent stale results
    try {
      final result = await compute<_FilterArgs<T>, List<T>>(
        _runFiltering<T>,
        _FilterArgs<T>(
          items: widget.items,
          query: query,
          labelFn: widget.itemLabel,
        ),
      );
      if (!mounted || token != _activeFilterToken) return;
      setState(() {
        _filteredItems = result; // do NOT touch _isFiltering here
      });
    } catch (e) {
      debugPrint('Filtering error: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (widget.hasMoreData &&
          !widget.isLoadingMore &&
          widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final query = _searchController.text.trim();

      // User is typing: show FULL overlay loader and jump to top immediately.
      if (mounted) {
        setState(() => _isFiltering = true);
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0); // kick back to top on typing
        }
      }

      try {
        if (widget.onSearch != null) {
          await widget.onSearch!(query);
          // Parent updates 'items'; didUpdateWidget -> _onItemsUpdated will refresh _filteredItems
        } else {
          await _updateFilteredItems(showOverlayAlreadyTrue: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isFiltering = false); // hide overlay after search completes
        }
      }
    });
  }

  Future<void> _updateFilteredItems({bool showOverlayAlreadyTrue = false}) async {
    final query = _searchController.text.trim();

    // Reset immediately if too short.
    if (query.isEmpty || query.length < widget.minSearchLength) {
      if (!mounted) return;
      setState(() {
        _filteredItems = widget.items;
        if (!showOverlayAlreadyTrue) _isFiltering = false;
      });
      return;
    }

    final int token = ++_activeFilterToken;

    // If not triggered by typing path, only show overlay for initial search (no items yet).
    if (!showOverlayAlreadyTrue && mounted && _filteredItems.isEmpty) {
      setState(() => _isFiltering = true);
    }

    try {
      final result = await compute<_FilterArgs<T>, List<T>>(
        _runFiltering<T>,
        _FilterArgs<T>(
          items: widget.items,
          query: query,
          labelFn: widget.itemLabel,
        ),
      );

      if (!mounted || token != _activeFilterToken) return;

      setState(() {
        _filteredItems = result;
        if (!showOverlayAlreadyTrue) _isFiltering = false;
      });
    } catch (e) {
      debugPrint('Filtering error: $e');
      if (!mounted || token != _activeFilterToken) return;
      if (!showOverlayAlreadyTrue) {
        setState(() => _isFiltering = false);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isDropdownOpen = !_isDropdownOpen),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.r),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.selectedValue != null
                        ? widget.itemLabel(widget.selectedValue!)
                        : widget.hint,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: widget.selectedValue != null
                          ? Colors.black87
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                Icon(
                  _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
        if (_isDropdownOpen)
          Container(
            margin: EdgeInsets.only(top: 6.h),
            constraints: BoxConstraints(maxHeight: 180.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.r),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (widget.isSearchable)
                  Padding(
                    padding: EdgeInsets.all(8.w),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                        'Search (min ${widget.minSearchLength} chars)...',
                        prefixIcon: Icon(Icons.search, size: 20.sp),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                      ),
                    ),
                  ),
                Divider(height: 1, color: Colors.grey.shade300),

                // Big loader cases:
                // - initial/refresh when there are no items yet (widget.isLoading && items.isEmpty)
                // - user typing (_isFiltering) – ALWAYS full overlay
                Expanded(
                  child: (((widget.isLoading && items.isEmpty) || _isFiltering))
                      ? const Center(child: CircularProgressIndicator())
                      : (items.isEmpty)
                      ? const Center(child: Text('No items found'))
                      : ListView.builder(
                    controller: _scrollController,
                    itemCount:
                    items.length + (widget.hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        // Bottom loader row for pagination (keeps scroll position).
                        return Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Center(
                            child: widget.isLoadingMore
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                              CircularProgressIndicator(),
                            )
                                : const Text('Scroll to load more'),
                          ),
                        );
                      }

                      final item = items[index];
                      final isSelected = widget.selectedValue != null &&
                          widget.itemValue(item) ==
                              widget.itemValue(
                                  widget.selectedValue!);

                      return InkWell(
                        onTap: () {
                          widget.onChanged(item);
                          setState(() => _isDropdownOpen = false);
                        },
                        child: Container(
                          color: isSelected
                              ? Colors.blue.shade50
                              : Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.itemLabel(item),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: isSelected
                                        ? Colors.blue.shade700
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: Colors.blue.shade700,
                                  size: 18.sp,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
