import 'dart:math';

import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/widgets/aves_app.dart';
import 'package:aves/widgets/common/basic/font_size_icon_theme.dart';
import 'package:aves/widgets/common/basic/insets.dart';
import 'package:aves/widgets/common/fx/blurred.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AvesAppBar extends StatelessWidget {
  final double contentHeight;
  final bool pinned;
  final Widget? leading;
  final Widget title;
  final List<Widget> Function(BuildContext context, double maxWidth) actions;
  final Widget? bottom;
  final Object? transitionKey;

  static const leadingHeroTag = 'appbar-leading';
  static const titleHeroTag = 'appbar-title';
  static const double _titleMinWidth = 96;

  const AvesAppBar({
    super.key,
    required this.contentHeight,
    required this.pinned,
    required this.leading,
    required this.title,
    required this.actions,
    this.bottom,
    this.transitionKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final useTvLayout = settings.useTvLayout;

    Widget? _leading = leading;
    if (_leading != null) {
      _leading = FontSizeIconTheme(
        child: _leading,
      );
    }

    Widget _title = FontSizeIconTheme(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            key: ValueKey(transitionKey),
            children: [
              Expanded(child: title),
              ...(actions(context, max(0, constraints.maxWidth - _titleMinWidth))),
            ],
          );
        },
      ),
    );

    final animate = context.select<Settings, bool>((v) => v.animate);
    if (animate) {
      _title = Hero(
        tag: titleHeroTag,
        flightShuttleBuilder: _flightShuttleBuilder,
        transitionOnUserGestures: true,
        child: AnimatedSwitcher(
          duration: context.read<DurationsData>().iconAnimation,
          child: _title,
        ),
      );

      if (_leading != null) {
        _leading = Hero(
          tag: leadingHeroTag,
          flightShuttleBuilder: _flightShuttleBuilder,
          transitionOnUserGestures: true,
          child: _leading,
        );
      }
    }

    return SliverPersistentHeader(
      floating: !useTvLayout,
      pinned: pinned,
      delegate: _SliverAppBarDelegate(
        height: MediaQuery.paddingOf(context).top + appBarHeightForContentHeight(contentHeight),
        child: AvesFloatingBar(
          builder: (context, backgroundColor, child) => Material(
            color: backgroundColor,
            child: InkWell(
              // absorb taps while providing visual feedback
              onTap: () {},
              onLongPress: () {},
              child: child,
            ),
          ),
          child: DirectionalSafeArea(
            start: !useTvLayout,
            bottom: false,
            child: Theme(
              data: theme.copyWith(
                colorScheme: colorScheme.copyWith(
                  onSurfaceVariant: colorScheme.onSurface,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: textScaler.scale(kToolbarHeight),
                    child: Row(
                      children: [
                        _leading != null
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _leading,
                              )
                            : const SizedBox(width: 16),
                        Expanded(
                          child: DefaultTextStyle(
                            style: theme.appBarTheme.titleTextStyle!,
                            child: _title,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (bottom != null) bottom!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHero,
    BuildContext toHero,
  ) {
    final pushing = direction == HeroFlightDirection.push;
    Widget popBuilder(context, child) => Opacity(opacity: 1 - animation.value, child: child);
    Widget pushBuilder(context, child) => Opacity(opacity: animation.value, child: child);
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(toHero).style,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: animation,
              builder: pushing ? popBuilder : pushBuilder,
              child: fromHero.widget,
            ),
            AnimatedBuilder(
              animation: animation,
              builder: pushing ? pushBuilder : popBuilder,
              child: toHero.widget,
            ),
          ],
        ),
      ),
    );
  }

  static double appBarHeightForContentHeight(double contentHeight) => AvesFloatingBar.margin.vertical + contentHeight;
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _SliverAppBarDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) => true;
}

class AvesFloatingBar extends StatefulWidget {
  final Widget Function(BuildContext context, Color backgroundColor, Widget? child) builder;
  final Widget? child;

  static const margin = EdgeInsets.all(0);
  static const borderRadius = BorderRadius.all(Radius.circular(0));

  const AvesFloatingBar({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  State<AvesFloatingBar> createState() => _AvesFloatingBarState();
}

class _AvesFloatingBarState extends State<AvesFloatingBar> with RouteAware {
  // prevent expensive blurring when the current page is hidden
  final ValueNotifier<bool> _isBlurAllowedNotifier = ValueNotifier(true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AvesApp.pageRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    AvesApp.pageRouteObserver.unsubscribe(this);
    _isBlurAllowedNotifier.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // post to prevent single frame flash during hero
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isBlurAllowedNotifier.value = true;
    });
  }

  @override
  void didPushNext() {
    // post to prevent single frame flash during hero
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isBlurAllowedNotifier.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.appBarTheme.backgroundColor ?? Themes.firstLayerColor(context);
    final border = widget.child == null
        ? Border(
            top: BorderSide(
            color: theme.dividerColor.withOpacity(0.6),
          ))
        : Border(
            bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.6),
          ));
    return ValueListenableBuilder<bool>(
      valueListenable: _isBlurAllowedNotifier,
      builder: (context, isBlurAllowed, child) {
        final blurred = isBlurAllowed && context.select<Settings, bool>((s) => s.enableBlurEffect);
        return Container(
          foregroundDecoration: BoxDecoration(
            border: border,
            borderRadius: AvesFloatingBar.borderRadius,
          ),
          margin: AvesFloatingBar.margin,
          child: BlurredRRect(
            enabled: blurred,
            borderRadius: AvesFloatingBar.borderRadius,
            child: widget.builder(
              context,
              blurred ? backgroundColor.withOpacity(.85) : backgroundColor,
              widget.child,
            ),
          ),
        );
      },
    );
  }
}
