import 'package:aves/model/filters/favourite.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/widgets/collection/collection_page.dart';
import 'package:aves/widgets/navigation/drawer/tile.dart';
import 'package:aves/widgets/navigation/nav_display.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AvesBottomNavItem extends Equatable {
  final String route;
  final CollectionFilter? filter;

  @override
  List<Object?> get props => [route, filter];

  const AvesBottomNavItem({
    required this.route,
    this.filter,
  });

  Widget icon(BuildContext context) {
    if (route == CollectionPage.routeName) {
      return DrawerFilterIcon(filter: filter);
    }

    final textScaler = MediaQuery.textScalerOf(context);
    final iconSize = textScaler.scale(22);
    return Icon(NavigationDisplay.getPageIcon(route), size: iconSize);
  }

  Widget navIcon(BuildContext context) {
    final ico = Padding(padding: const EdgeInsets.only(top: 4), child: icon(context));

    return route == CollectionPage.routeName && filter == FavouriteFilter.instance
        ? GestureDetector(
            onLongPress: () => {androidFileUtils.goToDonate([])}, behavior: HitTestBehavior.opaque, child: SizedBox(width: 80, height: 48, child: ico))
        : ico;
  }

  String label(BuildContext context) {
    if (route == CollectionPage.routeName) {
      return NavigationDisplay.getFilterTitle(context, filter);
    }
    return NavigationDisplay.getPageTitle(context, route);
  }
}
