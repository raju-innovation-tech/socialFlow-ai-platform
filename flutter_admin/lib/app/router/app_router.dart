import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive_scaffold.dart';

// Module 1: Auth
import '../../features/authentication/screens/login_screen.dart';
import '../../features/authentication/screens/register_screen.dart';
import '../../features/authentication/screens/otp_verification_screen.dart';
import '../../features/authentication/screens/forgot_password_screen.dart';
import '../../features/authentication/screens/reset_password_screen.dart';

// Module 2: Dashboard
import '../../features/dashboard/screens/dashboard_screen.dart';

// Module 3: Social Accounts
import '../../features/social_accounts/screens/connected_accounts_screen.dart';
import '../../features/social_accounts/screens/connect_platform_screen.dart';
import '../../features/social_accounts/screens/account_details_screen.dart';
import '../../features/social_accounts/screens/permissions_status_screen.dart';

// Module 4: Content Publishing & Calendar
import '../../features/publishing/screens/create_post_screen.dart';
import '../../features/publishing/screens/platform_editor_screen.dart';
import '../../features/publishing/screens/multi_preview_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/publishing/screens/publishing_queue_screen.dart';
import '../../features/publishing/screens/drafts_screen.dart';
import '../../features/publishing/screens/publishing_history_screen.dart';

// Module 5: Media Library
import '../../features/media_library/screens/media_gallery_screen.dart';
import '../../features/media_library/screens/media_upload_screen.dart';
import '../../features/media_library/screens/folder_management_screen.dart';

// Module 6: Campaigns
import '../../features/campaigns/screens/campaign_overview_screen.dart';
import '../../features/campaigns/screens/create_campaign_screen.dart';
import '../../features/campaigns/screens/campaign_details_screen.dart';

// Module 7: WhatsApp
import '../../features/whatsapp/screens/whatsapp_business_screen.dart';
import '../../features/whatsapp/screens/whatsapp_channels_screen.dart';
import '../../features/whatsapp/screens/whatsapp_groups_screen.dart';
import '../../features/whatsapp/screens/whatsapp_communities_screen.dart';

// Module 8: Telegram
import '../../features/telegram/screens/telegram_channels_screen.dart';
import '../../features/telegram/screens/telegram_groups_screen.dart';
import '../../features/telegram/screens/telegram_bot_connection_screen.dart';

// Module 9: Analytics
import '../../features/analytics/screens/analytics_overview_screen.dart';
import '../../features/analytics/screens/platform_analytics_screen.dart';
import '../../features/analytics/screens/reports_export_screen.dart';

// Module 10: Approvals & Team
import '../../features/approvals/screens/approval_inbox_screen.dart';
import '../../features/approvals/screens/approval_details_screen.dart';
import '../../features/team/screens/team_members_screen.dart';
import '../../features/team/screens/invite_member_screen.dart';

// Module 11: Settings & Billing
import '../../features/settings/screens/profile_settings_screen.dart';
import '../../features/settings/screens/workspace_settings_screen.dart';
import '../../features/settings/screens/roles_permissions_screen.dart';
import '../../features/billing/screens/subscription_usage_screen.dart';
import '../../features/billing/screens/billing_history_screen.dart';

// Module 12: Super Admin
import '../../features/super_admin/screens/super_admin_dashboard_screen.dart';
import '../../features/super_admin/screens/user_management_screen.dart';
import '../../features/super_admin/screens/workspace_management_screen.dart';
import '../../features/super_admin/screens/api_health_screen.dart';
import '../../features/super_admin/screens/system_logs_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    // Module 1: Auth Standalone Routes (Screens 01 - 05)
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) => const OtpVerificationScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),

    // Shell Route for Main Application Layout (Screens 06 - 47)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ResponsiveScaffold(
          currentRoute: state.uri.toString(),
          child: child,
        );
      },
      routes: [
        // Module 2: Main Dashboard (Screen 06)
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),

        // Module 3: Social Accounts (Screens 07 - 10)
        GoRoute(
          path: '/social-accounts',
          builder: (context, state) => const ConnectedAccountsScreen(),
        ),
        GoRoute(
          path: '/social-accounts/connect',
          builder: (context, state) => const ConnectPlatformScreen(),
        ),
        GoRoute(
          path: '/social-accounts/details/:id',
          builder: (context, state) => AccountDetailsScreen(
            accountId: state.pathParameters['id'] ?? 'acc_1',
          ),
        ),
        GoRoute(
          path: '/social-accounts/permissions',
          builder: (context, state) => const PermissionsStatusScreen(),
        ),

        // Module 4: Content Publishing (Screens 11 - 17)
        GoRoute(
          path: '/publishing/create',
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/publishing/editor',
          builder: (context, state) => const PlatformEditorScreen(),
        ),
        GoRoute(
          path: '/publishing/preview',
          builder: (context, state) => const MultiPreviewScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/publishing/queue',
          builder: (context, state) => const PublishingQueueScreen(),
        ),
        GoRoute(
          path: '/publishing/drafts',
          builder: (context, state) => const DraftsScreen(),
        ),
        GoRoute(
          path: '/publishing/history',
          builder: (context, state) => const PublishingHistoryScreen(),
        ),

        // Module 5: Media Library (Screens 18 - 20)
        GoRoute(
          path: '/media',
          builder: (context, state) => const MediaGalleryScreen(),
        ),
        GoRoute(
          path: '/media/upload',
          builder: (context, state) => const MediaUploadScreen(),
        ),
        GoRoute(
          path: '/media/folders',
          builder: (context, state) => const FolderManagementScreen(),
        ),

        // Module 6: Campaigns (Screens 21 - 23)
        GoRoute(
          path: '/campaigns',
          builder: (context, state) => const CampaignOverviewScreen(),
        ),
        GoRoute(
          path: '/campaigns/create',
          builder: (context, state) => const CreateCampaignScreen(),
        ),
        GoRoute(
          path: '/campaigns/details/:id',
          builder: (context, state) => CampaignDetailsScreen(
            campaignId: state.pathParameters['id'] ?? 'camp_1',
          ),
        ),

        // Module 7: WhatsApp (Screens 24 - 27)
        GoRoute(
          path: '/whatsapp/business',
          builder: (context, state) => const WhatsAppBusinessScreen(),
        ),
        GoRoute(
          path: '/whatsapp/channels',
          builder: (context, state) => const WhatsAppChannelsScreen(),
        ),
        GoRoute(
          path: '/whatsapp/groups',
          builder: (context, state) => const WhatsAppGroupsScreen(),
        ),
        GoRoute(
          path: '/whatsapp/communities',
          builder: (context, state) => const WhatsAppCommunitiesScreen(),
        ),

        // Module 8: Telegram (Screens 28 - 30)
        GoRoute(
          path: '/telegram/channels',
          builder: (context, state) => const TelegramChannelsScreen(),
        ),
        GoRoute(
          path: '/telegram/groups',
          builder: (context, state) => const TelegramGroupsScreen(),
        ),
        GoRoute(
          path: '/telegram/connect-bot',
          builder: (context, state) => const TelegramBotConnectionScreen(),
        ),

        // Module 9: Analytics (Screens 31 - 33)
        GoRoute(
          path: '/analytics/overview',
          builder: (context, state) => const AnalyticsOverviewScreen(),
        ),
        GoRoute(
          path: '/analytics/platforms',
          builder: (context, state) => const PlatformAnalyticsScreen(),
        ),
        GoRoute(
          path: '/analytics/reports',
          builder: (context, state) => const ReportsExportScreen(),
        ),

        // Module 10: Approvals & Team (Screens 34 - 37)
        GoRoute(
          path: '/approvals',
          builder: (context, state) => const ApprovalInboxScreen(),
        ),
        GoRoute(
          path: '/approvals/details/:id',
          builder: (context, state) => ApprovalDetailsScreen(
            postId: state.pathParameters['id'] ?? 'post_1',
          ),
        ),
        GoRoute(
          path: '/team',
          builder: (context, state) => const TeamMembersScreen(),
        ),
        GoRoute(
          path: '/team/invite',
          builder: (context, state) => const InviteMemberScreen(),
        ),

        // Module 11: Settings & Billing (Screens 38 - 42)
        GoRoute(
          path: '/settings/profile',
          builder: (context, state) => const ProfileSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/workspace',
          builder: (context, state) => const WorkspaceSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/roles',
          builder: (context, state) => const RolesPermissionsScreen(),
        ),
        GoRoute(
          path: '/billing/subscription',
          builder: (context, state) => const SubscriptionUsageScreen(),
        ),
        GoRoute(
          path: '/billing/invoices',
          builder: (context, state) => const BillingHistoryScreen(),
        ),

        // Module 12: Super Admin (Screens 43 - 47)
        GoRoute(
          path: '/super-admin/dashboard',
          builder: (context, state) => const SuperAdminDashboardScreen(),
        ),
        GoRoute(
          path: '/super-admin/users',
          builder: (context, state) => const UserManagementScreen(),
        ),
        GoRoute(
          path: '/super-admin/workspaces',
          builder: (context, state) => const WorkspaceManagementScreen(),
        ),
        GoRoute(
          path: '/super-admin/api-health',
          builder: (context, state) => const ApiHealthScreen(),
        ),
        GoRoute(
          path: '/super-admin/logs',
          builder: (context, state) => const SystemLogsScreen(),
        ),
      ],
    ),
  ],
);

