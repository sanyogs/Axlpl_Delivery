import 'dart:io';

import 'package:axlpl_delivery/common_widget/common_appbar.dart';
import 'package:axlpl_delivery/common_widget/common_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Standard outbound page shell (app bar + scroll + busy state).
class OutboundScreen extends StatelessWidget {
  const OutboundScreen({
    super.key,
    required this.title,
    required this.children,
    this.busy = false,
    this.onRefresh,
    this.scrollController,
  });

  final String title;
  final List<Widget> children;
  final bool busy;
  final Future<void> Function()? onRefresh;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      appBar: commonAppbar(title),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: busy,
            child: _OutboundScrollBody(
              onRefresh: busy ? null : onRefresh,
              scrollController: scrollController,
              children: children,
            ),
          ),
          if (busy)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _OutboundScrollBody extends StatelessWidget {
  const _OutboundScrollBody({
    required this.children,
    this.onRefresh,
    this.scrollController,
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      controller: scrollController,
      physics: onRefresh != null
          ? const AlwaysScrollableScrollPhysics()
          : null,
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (Platform.isIOS) SizedBox(height: 2.h),
          ...children,
          SizedBox(height: 24.h),
        ],
      ),
    );
    if (onRefresh == null) return scroll;
    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: scroll,
    );
  }
}
