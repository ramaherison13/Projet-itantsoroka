import 'package:flutter/material.dart';

/// Modèle d'un item de navigation
class RoleNavItem {
  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;

  const RoleNavItem({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
  });
}

/// Modèle d'un module de tableau de bord
class RoleModule {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String path;

  const RoleModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.path,
  });
}

/// Service centralisé de navigation par rôle.
/// Toute la logique de "qui voit quoi" est ici.
class RoleNavigationService {
  // ─── Slugs de rôles ────────────────────────────────────────────────────────
  static const String chefDistrict    = 'CHEF_DISTRICT';
  static const String adjointDistrict = 'ADJOINT_DISTRICT';
  static const String std             = 'STD';
  static const String ctd             = 'CTD';
  static const String partenaire      = 'PARTENAIRE';
  static const String citoyen         = 'CITOYEN';

  // ─── Détermination du rôle principal ───────────────────────────────────────

  /// Retourne la route d'accueil selon les slugs de rôles de l'utilisateur.
  static String getHomeRoute(List<String> slugs) {
    final upper = slugs
        .map((s) => s.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_').trim())
        .toSet();
    if (upper.contains('SUPER_ADMIN') || upper.contains('ADMIN') || upper.contains('ADMINISTRATEUR')) {
      return '/admin';
    }
    if (upper.contains(chefDistrict))    return '/dashboard/chef-district';
    if (upper.contains(adjointDistrict)) return '/dashboard/adjoint-district';
    if (upper.contains(std))             return '/dashboard/std';
    if (upper.contains(ctd))             return '/dashboard/ctd';
    if (upper.contains(partenaire))      return '/dashboard/partenaire';
    return '/';
  }

  /// Retourne le nom du rôle principal pour l'affichage
  static String getRoleDisplayName(List<String> slugs) {
    final upper = slugs.map((s) => s.toUpperCase().trim()).toSet();
    if (upper.contains(chefDistrict))    return 'Chef de District';
    if (upper.contains(adjointDistrict)) return 'Adjoint de District';
    if (upper.contains(std))             return 'STD';
    if (upper.contains(ctd))             return 'CTD';
    if (upper.contains(partenaire))      return 'Partenaire';
    if (upper.contains(citoyen))         return 'Citoyen';
    return 'Utilisateur';
  }

  // ─── Items de navigation par rôle ──────────────────────────────────────────

  /// Retourne les items de navigation (barre latérale / bas) selon les rôles.
  static List<RoleNavItem> getAllowedNavItems(List<String> slugs) {
    final upper = slugs.map((s) => s.toUpperCase().trim()).toSet();

    if (upper.contains(chefDistrict)) {
      return const [
        RoleNavItem(label: 'Monographie',  path: '/itantsorika/monographie',      icon: Icons.map_outlined,             selectedIcon: Icons.map_rounded),
        RoleNavItem(label: 'Ressources',   path: '/itantsorika/gestion-ressource', icon: Icons.inventory_2_outlined,    selectedIcon: Icons.inventory_2_rounded),
        RoleNavItem(label: 'Publications', path: '/itantsorika/publier',           icon: Icons.campaign_outlined,       selectedIcon: Icons.campaign_rounded),
        RoleNavItem(label: 'Documents',    path: '/itantsorika/documents',         icon: Icons.folder_outlined,         selectedIcon: Icons.folder_rounded),
      ];
    }

    if (upper.contains(adjointDistrict)) {
      return const [
        RoleNavItem(label: 'Tournées',     path: '/idistrika/calendrier',          icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month_rounded),
        RoleNavItem(label: 'Collecte',     path: '/idistrika/collecte-besoins',    icon: Icons.inbox_outlined,          selectedIcon: Icons.inbox_rounded),
        RoleNavItem(label: 'Doléances',    path: '/idistrika/doleance',            icon: Icons.feedback_outlined,       selectedIcon: Icons.feedback_rounded),
        RoleNavItem(label: 'Tableau bord', path: '/idistrika/tableaux_bord',       icon: Icons.dashboard_outlined,      selectedIcon: Icons.dashboard_rounded),
        RoleNavItem(label: 'Rapports',     path: '/idistrika/Generer-rapport',     icon: Icons.summarize_outlined,      selectedIcon: Icons.summarize_rounded),
      ];
    }

    if (upper.contains(std)) {
      return const [
        RoleNavItem(label: 'Offres',       path: '/itantsorika/offres-appui',      icon: Icons.handshake_outlined,      selectedIcon: Icons.handshake_rounded),
        RoleNavItem(label: 'Affiliation',  path: '/admin/affiliation',             icon: Icons.link_outlined,           selectedIcon: Icons.link_rounded),
        RoleNavItem(label: 'Documents',    path: '/itantsorika/documents',         icon: Icons.folder_outlined,         selectedIcon: Icons.folder_rounded),
        RoleNavItem(label: 'Ressources',   path: '/centreRessource',               icon: Icons.inventory_2_outlined,    selectedIcon: Icons.inventory_2_rounded),
      ];
    }

    if (upper.contains(ctd)) {
      return const [
        RoleNavItem(label: 'Monographie',  path: '/itantsorika/monographie',       icon: Icons.map_outlined,            selectedIcon: Icons.map_rounded),
        RoleNavItem(label: 'Publications', path: '/itantsorika/publier',           icon: Icons.campaign_outlined,       selectedIcon: Icons.campaign_rounded),
        RoleNavItem(label: 'Documents',    path: '/itantsorika/documents',         icon: Icons.folder_outlined,         selectedIcon: Icons.folder_rounded),
        RoleNavItem(label: 'Offres',       path: '/offres-appui',                  icon: Icons.handshake_outlined,      selectedIcon: Icons.handshake_rounded),
      ];
    }

    if (upper.contains(partenaire)) {
      return const [
        RoleNavItem(label: 'Monographie',  path: '/monographie',                   icon: Icons.map_outlined,            selectedIcon: Icons.map_rounded),
        RoleNavItem(label: 'Actualités',   path: '/actualites',                    icon: Icons.newspaper_outlined,      selectedIcon: Icons.newspaper_rounded),
        RoleNavItem(label: 'Événements',   path: '/actualites',                    icon: Icons.event_outlined,          selectedIcon: Icons.event_rounded),
        RoleNavItem(label: 'Projets',      path: '/officeprojet',                  icon: Icons.business_center_outlined,selectedIcon: Icons.business_center_rounded),
      ];
    }

    // Citoyen ou non authentifié : navigation publique standard
    return const [
      RoleNavItem(label: 'Accueil',      path: '/',             icon: Icons.home_outlined,            selectedIcon: Icons.home_rounded),
      RoleNavItem(label: 'Monographie',  path: '/monographie',  icon: Icons.map_outlined,             selectedIcon: Icons.map_rounded),
      RoleNavItem(label: 'Documents',    path: '/document',     icon: Icons.folder_outlined,          selectedIcon: Icons.folder_rounded),
      RoleNavItem(label: 'Offres',       path: '/offres-appui', icon: Icons.handshake_outlined,       selectedIcon: Icons.handshake_rounded),
      RoleNavItem(label: 'Actualités',   path: '/actualites',   icon: Icons.newspaper_outlined,       selectedIcon: Icons.newspaper_rounded),
      RoleNavItem(label: 'Projets',      path: '/officeprojet', icon: Icons.business_center_outlined, selectedIcon: Icons.business_center_rounded),
    ];
  }

  // ─── Modules de tableau de bord par rôle ───────────────────────────────────

  /// Retourne les modules à afficher sur le dashboard selon les rôles.
  static List<RoleModule> getDashboardModules(List<String> slugs) {
    final upper = slugs.map((s) => s.toUpperCase().trim()).toSet();

    if (upper.contains(chefDistrict)) {
      return const [
        RoleModule(
          title: 'Monographie',
          description: 'Fiches synthétiques et statistiques territoriales.',
          icon: Icons.map_rounded,
          color: Color(0xFF098E00),
          path: '/itantsorika/monographie',
        ),
        RoleModule(
          title: 'Gestion des Ressources',
          description: 'Gérez les ressources humaines et matérielles du district.',
          icon: Icons.inventory_2_rounded,
          color: Color(0xFF1565C0),
          path: '/itantsorika/gestion-ressource',
        ),
        RoleModule(
          title: 'Publications',
          description: 'Publiez des événements, projets et actualités.',
          icon: Icons.campaign_rounded,
          color: Color(0xFF6A1B9A),
          path: '/itantsorika/publier',
        ),
        RoleModule(
          title: 'Documents',
          description: 'Consultez et gérez les documents officiels.',
          icon: Icons.folder_rounded,
          color: Color(0xFFE65100),
          path: '/itantsorika/documents',
        ),
      ];
    }

    if (upper.contains(adjointDistrict)) {
      return const [
        RoleModule(
          title: 'Planification de Tournée',
          description: 'Organisez et planifiez les tournées de terrain.',
          icon: Icons.calendar_month_rounded,
          color: Color(0xFF098E00),
          path: '/idistrika/calendrier',
        ),
        RoleModule(
          title: 'Collecte des Besoins',
          description: 'Saisissez et suivez les besoins collectés sur le terrain.',
          icon: Icons.inbox_rounded,
          color: Color(0xFF1565C0),
          path: '/idistrika/collecte-besoins',
        ),
        RoleModule(
          title: 'Suivi des Doléances',
          description: 'Gérez les doléances des citoyens et communes.',
          icon: Icons.feedback_rounded,
          color: Color(0xFF6A1B9A),
          path: '/idistrika/doleance',
        ),
        RoleModule(
          title: 'Tableau de Bord',
          description: "Vue d'ensemble des indicateurs et statistiques.",
          icon: Icons.dashboard_rounded,
          color: Color(0xFFE65100),
          path: '/idistrika/tableaux_bord',
        ),
        RoleModule(
          title: 'Rapports',
          description: "Générez et consultez les rapports d'activité.",
          icon: Icons.summarize_rounded,
          color: Color(0xFF00838F),
          path: '/idistrika/Generer-rapport',
        ),
      ];
    }

    if (upper.contains(std)) {
      return const [
        RoleModule(
          title: "Offres d'Appui",
          description: "Gérez les offres de services et d'appui technique.",
          icon: Icons.handshake_rounded,
          color: Color(0xFF098E00),
          path: '/itantsorika/offres-appui',
        ),
        RoleModule(
          title: 'Affiliation',
          description: 'Gérez les affiliations et associations de votre entité.',
          icon: Icons.link_rounded,
          color: Color(0xFF1565C0),
          path: '/admin/affiliation',
        ),
        RoleModule(
          title: 'Documents',
          description: 'Consultez et gérez les documents officiels.',
          icon: Icons.folder_rounded,
          color: Color(0xFF6A1B9A),
          path: '/itantsorika/documents',
        ),
        RoleModule(
          title: 'Ressources Disponibles',
          description: 'Accédez aux ressources disponibles dans votre zone.',
          icon: Icons.inventory_2_rounded,
          color: Color(0xFFE65100),
          path: '/centreRessource',
        ),
      ];
    }

    if (upper.contains(ctd)) {
      return const [
        RoleModule(
          title: 'Monographie',
          description: 'Fiches territoriales et statistiques locales.',
          icon: Icons.map_rounded,
          color: Color(0xFF098E00),
          path: '/itantsorika/monographie',
        ),
        RoleModule(
          title: 'Publications',
          description: 'Publiez des informations pour votre collectivité.',
          icon: Icons.campaign_rounded,
          color: Color(0xFF1565C0),
          path: '/itantsorika/publier',
        ),
        RoleModule(
          title: 'Documents',
          description: 'Gérez les actes et documents administratifs.',
          icon: Icons.folder_rounded,
          color: Color(0xFF6A1B9A),
          path: '/itantsorika/documents',
        ),
        RoleModule(
          title: "Demandes d'Offre d'Appui",
          description: 'Soumettez et suivez vos demandes d\'appui.',
          icon: Icons.request_page_rounded,
          color: Color(0xFFE65100),
          path: '/offres-appui',
        ),
      ];
    }

    if (upper.contains(partenaire)) {
      return const [
        RoleModule(
          title: 'Monographies',
          description: 'Consultez les monographies de districts et communes.',
          icon: Icons.map_rounded,
          color: Color(0xFF098E00),
          path: '/monographie',
        ),
        RoleModule(
          title: 'Actualités',
          description: 'Dernières actualités des districts et communes.',
          icon: Icons.newspaper_rounded,
          color: Color(0xFF1565C0),
          path: '/actualites',
        ),
        RoleModule(
          title: 'Événements',
          description: 'Événements à venir dans les territoires.',
          icon: Icons.event_rounded,
          color: Color(0xFF6A1B9A),
          path: '/actualites',
        ),
        RoleModule(
          title: 'Projets & Initiatives',
          description: 'Suivez les projets et initiatives en cours.',
          icon: Icons.business_center_rounded,
          color: Color(0xFFE65100),
          path: '/officeprojet',
        ),
      ];
    }

    // Citoyen : liste vide (redirigé vers accueil public)
    return const [];
  }
}
