import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Layouts
import '../layouts/admin/admin_layout.dart';
import '../layouts/main_layout.dart';

// Écrans - Post / Actualités
import '../screens/post/post_page.dart';
import '../services/territory_service.dart';

// Auth & Rôles
import '../providers/auth_provider.dart';
import '../screens/home/role_dashboard_screen.dart';

// Écrans - Offre & Bureau de Projet
import '../screens/offre_std/offre_std_page.dart';
import '../screens/office_projet/office_projet_screen_state.dart';

// Écrans - Publications
import '../screens/publications/manage_publication_screen.dart';
import '../screens/publications/publish_page_principal_screen.dart';
import '../screens/publications/publish_actu_screen.dart';
import '../screens/publications/publish_event_screen.dart';
import '../screens/publications/publish_project_screen.dart';

// Écrans - Administration & Gestion
import '../screens/administration/admin_dashboard_screen.dart';
import '../screens/administration/admin_user_list_screen.dart';
import '../screens/administration/acte_type_management_screen.dart';
import '../screens/administration/role_screen.dart';
import '../screens/administration/user_password_management_screen.dart';
import '../screens/administration/affiliation_page.dart';

// Écrans - Authentification
import '../screens/authentification/check_id_card_screen.dart';
import '../screens/authentification/edit_profile_screen.dart';
import '../screens/authentification/reset_password.dart';
import '../screens/authentification/forgot_password_screen.dart';
import '../screens/authentification/login_screen.dart';
import '../screens/authentification/register_screen.dart';
import '../screens/authentification/register_with_citizen_screen.dart';

// Écrans - Contrôle de Légalité
import '../screens/controle_legalite/admin_controle_legalite_page.dart';
import '../screens/controle_legalite/commune_controle_legalite.dart';
import '../screens/controle_legalite/soumission_acte.dart';
import '../screens/controle_legalite/tableaux_bord.dart';

// Écrans - Accueil & Navigation
import '../screens/home/home_screen.dart';
import '../screens/home/monography_screen.dart';
import '../screens/navigation/navigation_page.dart';

// Écrans - Modules de services
import '../screens/module/administration_services_screen.dart';
import '../screens/module/itantsorika_services_screen.dart';
import '../screens/module/platform_module_screen.dart';
import '../constants/api_constants.dart';

// Widgets
import '../widgets/controle_legalite/archivage_widget.dart';
import '../widgets/controle_legalite/dashboard_widget.dart';
import '../widgets/gestion_document/gerer_document_widget.dart';
import '../widgets/gestion_document/ajout_document_widget.dart';
import '../widgets/gestion_document/tous_documents_widget.dart';

class AppRouter {
  // Définition des routes de l'application
  // NOTE: Ne pas ajouter de navigatorKey manuels sur GoRouter ou ShellRoute en
  // go_router v17+ — cela crée des collisions de GlobalObjectKey internes.
  static final GoRouter router = GoRouter(
    initialLocation: '/admin',
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Error'))),

    // ── Redirect global basé sur les rôles ────────────────────────────────
    redirect: (context, state) {
      final path = state.uri.path;

      // Ne pas intercepter les routes d'authentification ni d'erreur
      if (path.startsWith('/auth/') || path == '/unauthorized') return null;

      // Lire l'état d'authentification depuis le provider
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (!auth.isInitialized) return null;

        // Si non authentifié, laisser passer vers les pages publiques
        if (!auth.isAuthenticated || auth.user == null) return null;

        // Après la connexion (retour de /auth/login vers /), rediriger vers homeRoute
        if (path == '/' && auth.isAuthenticated) {
          final homeRoute = auth.homeRoute;
          if (homeRoute != '/') return homeRoute;
        }
      } catch (_) {
        // Provider non disponible dans ce contexte
      }
      return null;
    },

    routes: [
      // Routes principales avec le Layout principal
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/collecte',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('CollecteBesoins Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/actualites',
            builder: (context, state) => PostPageWidget(
              baseUrl: "https://gateway.tsirylab.com",
              getCommunesBasic: () async {
                final List<dynamic>? list =
                    await TerritoryService.getCommunesBasic();
                return (list ?? [])
                    .map((c) => TerritoryModel.fromJson(c))
                    .toList();
              },
              getDistrictsBasic: () async {
                final List<dynamic>? list =
                    await TerritoryService.getDistrictsBasic();
                return (list ?? [])
                    .map((d) => TerritoryModel.fromJson(d))
                    .toList();
              },
            ),
          ),
          GoRoute(
            path: '/officeprojet',
            builder: (context, state) => const OfficeProjetScreen(),
          ),
          GoRoute(
            path: '/monographie',
            builder: (context, state) => const MonographieScreen(),
          ),
          GoRoute(
            path: '/monography',
            builder: (context, state) => const MonographieScreen(),
          ),
          // Route /monographie avec paramètres dynamiques
          GoRoute(
            path: '/monographie/:types/:territoires/:id',
            builder: (context, state) {
              final types = state.pathParameters['types'];
              final territoires = state.pathParameters['territoires'];
              final id = state.pathParameters['id'];
              return MonographieScreen(
                type: types,
                territoire: territoires,
                id: id,
              );
            },
          ),
          GoRoute(
            path: '/doleance',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Doleances Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/footer',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Footer Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/doleances',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('SuiviDoleanceUser Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/centreRessource',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('CentreRessource Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/document',
            builder: (context, state) =>
                TousDocumentsWidget(baseUrl: "https://gateway.tsirylab.com"),
          ),
          GoRoute(
            path: '/theme/:themeId',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('ThemePage Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/das',
            builder: (context, state) =>
                DashboardWidget(loading: false, stats: {}),
          ),
          GoRoute(
            path: '/gestion',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Gestion Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/offres-appui',
            builder: (context, state) => OffreStdPage(
              baseUrl: "https://gateway.tsirylab.com",
              currentUser: {},
            ),
          ),
        ],
      ),

      // Routes d'authentification
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/check-id-card',
        builder: (context, state) => const CheckIDCardScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) {
          final cin =
              (state.extra as String?) ??
              state.uri.queryParameters['cin'] ??
              '';
          return RegisterScreen(globalCin: cin);
        },
      ),
      GoRoute(
        path: '/auth/register-with-citizen',
        builder: (context, state) {
          final citizenId =
              (state.extra as String?) ??
              state.uri.queryParameters['citizenId'] ??
              '';
          return RegisterWithCitizenScreen(citizenId: citizenId);
        },
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // Pages utilitaires ou indépendantes
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 64, color: Color(0xFFE65100)),
                const SizedBox(height: 16),
                const Text('Accès non autorisé', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Vous n\'avez pas les permissions nécessaires.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Retour à l\'accueil'),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // ── Tableaux de bord par rôle (/dashboard/*) ───────────────────────
      GoRoute(
        path: '/dashboard/chef-district',
        builder: (context, state) =>
            const RoleDashboardScreen(role: 'CHEF_DISTRICT'),
      ),
      GoRoute(
        path: '/dashboard/adjoint-district',
        builder: (context, state) =>
            const RoleDashboardScreen(role: 'ADJOINT_DISTRICT'),
      ),
      GoRoute(
        path: '/dashboard/std',
        builder: (context, state) =>
            const RoleDashboardScreen(role: 'STD'),
      ),
      GoRoute(
        path: '/dashboard/ctd',
        builder: (context, state) =>
            const RoleDashboardScreen(role: 'CTD'),
      ),
      GoRoute(
        path: '/dashboard/partenaire',
        builder: (context, state) =>
            const RoleDashboardScreen(role: 'PARTENAIRE'),
      ),
      GoRoute(
        path: '/modules',
        builder: (context, state) => PlatformModuleWidget(
          apiUrl: ApiConstants.gatewayBaseUrl,
          onNavigate: (s) => context.go(s),
          onBack: () => context.go('/admin'),
        ),
      ),
      GoRoute(
        path: '/idistrika-services',
        builder: (context, state) => AdministrationServicesWidget(
          onNavigate: (s) => context.go(s),
          user: const {},
        ),
      ),
      GoRoute(
        path: '/itantsorika-services',
        builder: (context, state) =>
            ItantsorikaServicesWidget(onNavigate: (s) => context.go(s)),
      ),

      // Espace Admin / Idistrika / Itantsorika (AdminLayout)
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/idistrika/dashboardMission',
            builder: (context, state) =>
                DashboardWidget(loading: false, stats: {}),
          ),
          GoRoute(
            path: '/idistrika/calendrier',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Calendrier Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/idistrika/rapportTpg',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('RapportTPG Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/idistrika/Generer-rapport',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('GenererRapport Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/idistrika/Details-rapport',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('DetailsRapport Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/idistrika/reunion',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('MeetingModule Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/idistrika/admin-controle-legalite',
            builder: (context, state) => AdminControleLegalitePage(
              baseUrl: "https://gateway.tsirylab.com/servicecontroledelegalite",
              currentUser: {},
            ),
          ),
          GoRoute(
            path: '/idistrika/commune-controle-legalite',
            builder: (context, state) => CommuneControleLegalite(
              baseUrl: "https://gateway.tsirylab.com/servicecontroledelegalite",
              currentUser: {},
            ),
          ),
          GoRoute(
            path: '/idistrika/soumission-acte',
            builder: (context, state) => SoumissionActe(
              baseUrl: "https://gateway.tsirylab.com/servicecontroledelegalite",
              currentUser: {},
            ),
          ),
          GoRoute(
            path: '/idistrika/archive',
            builder: (context, state) => const ArchivageWidget(),
          ),
          GoRoute(
            path: '/idistrika/tableaux_bord',
            builder: (context, state) => const TableauxBordPage(),
          ),
          GoRoute(
            path: '/idistrika/doleance',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('DoleanceModule Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/idistrika/collecte-besoins',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('CollecteBesoins Not Implemented')),
            ),
          ),

          // Enfants Itantsorika / Itantsoroka
          GoRoute(
            path: '/itantsorika/publier',
            builder: (context, state) => const PublishPagePrincipalScreen(),
          ),
          GoRoute(
            path: '/itantsorika/publier/projet',
            builder: (context, state) => const PublishProjectScreen(),
          ),
          GoRoute(
            path: '/itantsorika/publier/evenement',
            builder: (context, state) => const PublishEventScreen(),
          ),
          GoRoute(
            path: '/itantsorika/publier/actualite',
            builder: (context, state) => const PublishActuScreen(),
          ),
          GoRoute(
            path: '/itantsorika/offres-appui',
            builder: (context, state) => OffreStdPage(
              baseUrl: "https://gateway.tsirylab.com/serviceaffiliation",
              currentUser: {},
            ),
          ),
          GoRoute(
            path: '/itantsorika/gererPublication',
            builder: (context, state) => const ManagePublicationScreen(),
          ),
          GoRoute(
            path: '/itantsorika/monographie',
            builder: (context, state) => const MonographieScreen(),
          ),
          GoRoute(
            path: '/itantsorika/reunion',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('MeetingModule Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/itantsorika/editPublication/:type/:id',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('EditPublication Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/itantsorika/gestion-ressource',
            builder: (context, state) => const Scaffold(
              body: Center(
                child: Text('ManageRessourcesProtected Not Implemented'),
              ),
            ),
          ),
          GoRoute(
            path: '/itantsorika/documents',
            builder: (context, state) => GererDocumentWidget(
              baseUrl: "https://gateway.tsirylab.com/servicebiblio",
            ),
          ),
          GoRoute(
            path: '/itantsorika/ajoutdocument',
            builder: (context, state) => const AjoutDocumentWidget(),
          ),
        ],
      ),

      // Routes Back-office Admin Général (/admin)
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUserListScreen(),
          ),
          GoRoute(
            path: '/admin/passwords',
            builder: (context, state) => const UserPasswordManagementScreen(),
          ),
          GoRoute(
            path: '/admin/acte-type-management/type',
            builder: (context, state) => const ActeTypeManagementScreen(),
          ),
          GoRoute(
            path: '/admin/acte-type-management/sous-type',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('ActeSousType Not Implemented')),
            ),
          ),
          GoRoute(
            path: '/admin/navigations',
            builder: (context, state) =>
                const NavigationPage(appId: 8, baseUrl: ApiConstants.serviceAuth),
          ),
          GoRoute(
            path: '/admin/roles',
            builder: (context, state) => const RoleScreen(),
          ),
          GoRoute(
            path: '/admin/affiliation',
            builder: (context, state) => const AffiliationPage(),
          ),
        ],
      ),
    ],
  );
}
