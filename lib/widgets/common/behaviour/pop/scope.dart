import 'dart:async';

import 'package:aves/model/settings/enums/home_page.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/collection/collection_page.dart';
import 'package:aves/widgets/common/behaviour/pop/double_back.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/explorer/explorer_page.dart';
import 'package:aves/widgets/filter_grids/albums_page.dart';
import 'package:aves/widgets/filter_grids/tags_page.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

// this widget combines multiple pop handlers with a guaranteed order
class AvesPopScope extends StatelessWidget {
  final List<PopHandler> handlers;
  final Widget child;

  const AvesPopScope({
    super.key,
    required this.handlers,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final blocker = handlers.firstWhereOrNull((v) => !v.canPop(context));
    debugPrint('>>>> blocker calld $blocker');
    return PopScopeExt(
      blocker: blocker,
      child: child,
    );
  }
}

class PopScopeExt extends StatefulWidget {
  final Widget child;
  final PopHandler? blocker;

  const PopScopeExt({
    super.key,
    required this.child,
    this.blocker,
  });
  @override
  State<StatefulWidget> createState() => PopScopeState();

  static bool _isHome(BuildContext context) {
    final homePage = settings.homePage;
    final currentRoute = context.currentRouteName;

    if (currentRoute != homePage.routeName) return false;

    return switch (homePage) {
      HomePageSetting.collection => context.read<CollectionLens>().filters.isEmpty,
      HomePageSetting.albums || HomePageSetting.tags || HomePageSetting.explorer => true,
    };
  }

  static Route _getHomeRoute() {
    final homePage = settings.homePage;
    Route buildRoute(WidgetBuilder builder) => MaterialPageRoute(
          settings: RouteSettings(name: homePage.routeName),
          builder: builder,
        );

    return switch (homePage) {
      HomePageSetting.collection => buildRoute((context) => CollectionPage(source: context.read<CollectionSource>(), filters: null)),
      HomePageSetting.albums => buildRoute((context) => const AlbumListPage()),
      HomePageSetting.tags => buildRoute((context) => const TagListPage()),
      HomePageSetting.explorer => buildRoute((context) => const ExplorerPage()),
    };
  }
}

class PopScopeState extends State<PopScopeExt> {
  bool shouldExit = false;
  Timer? _backTimer;

  @override
  Widget build(BuildContext context) {
    final blocker = widget.blocker;
    return PopScope(
      canPop: blocker == null || shouldExit,
      onPopInvokedWithResult: (didPop, result) {
        if (blocker is DoubleBackPopHandler) {
          // debugPrint('>>>> blocked once $blocker.backOnce');
          if (!PopScopeExt._isHome(context)) {
            Navigator.maybeOf(context)?.pushAndRemoveUntil(
              PopScopeExt._getHomeRoute(),
              (route) => false,
            );
            return;
          }
          setState(() {
            shouldExit = true;
          });
          _backTimer?.cancel();
          _backTimer = Timer(
              ADurations.doubleBackTimerDelay * 1.5,
              () => setState(() {
                    shouldExit = false;
                  }));
          toast(
            context.l10n.doubleBackExitMessage,
            duration: ADurations.doubleBackTimerDelay,
          );
        } else if (!didPop) {
          blocker?.onPopBlocked(context);
        }
      },
      child: widget.child,
    );
  }
}

abstract class PopHandler {
  bool canPop(BuildContext context);

  void onPopBlocked(BuildContext context);
}

class APopHandler implements PopHandler {
  final bool Function(BuildContext context) _canPop;
  final void Function(BuildContext context) _onPopBlocked;

  APopHandler({
    required bool Function(BuildContext context) canPop,
    required void Function(BuildContext context) onPopBlocked,
  })  : _canPop = canPop,
        _onPopBlocked = onPopBlocked;

  @override
  bool canPop(BuildContext context) => _canPop(context);

  @override
  void onPopBlocked(BuildContext context) => _onPopBlocked(context);
}

@immutable
class PopExitNotification extends Notification {}
