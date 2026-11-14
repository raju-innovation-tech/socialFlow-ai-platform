import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import 'app_sidebar.dart';
import 'app_topbar.dart';

class ResponsiveScaffold extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const ResponsiveScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 850;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: isMobile
          ? Drawer(
              backgroundColor: AppColors.sidebar,
              child: SafeArea(
                child: AppSidebar(currentRoute: widget.currentRoute),
              ),
            )
          : null,
      bottomNavigationBar: isMobile
          ? Container(
              decoration: const BoxDecoration(
                color: AppColors.sidebar,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: BottomNavigationBar(
                backgroundColor: AppColors.sidebar,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textSecondary,
                currentIndex: _getMobileIndex(widget.currentRoute),
                onTap: (index) {
                  switch (index) {
                    case 0:
                      context.go('/dashboard');
                      break;
                    case 1:
                      context.go('/calendar');
                      break;
                    case 2:
                      context.go('/publishing/create');
                      break;
                    case 3:
                      context.go('/analytics/overview');
                      break;
                    case 4:
                      context.go('/settings/profile');
                      break;
                  }
                },
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(LucideIcons.layoutDashboard),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(LucideIcons.calendar),
                    label: 'Calendar',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(LucideIcons.plusCircle),
                    label: 'Create',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(LucideIcons.barChart2),
                    label: 'Stats',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(LucideIcons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            AppSidebar(currentRoute: widget.currentRoute),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  isMobile: isMobile,
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getMobileIndex(String route) {
    if (route.startsWith('/calendar')) return 1;
    if (route.startsWith('/publishing/create')) return 2;
    if (route.startsWith('/analytics')) return 3;
    if (route.startsWith('/settings')) return 4;
    return 0;
  }
}
