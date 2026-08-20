import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service Auth Users Endpoints (liste_des_services.txt) :
/// - POST   https://gateway.tsirylab.com/serviceauth/users (Créer, lister les utilisateurs)
/// - GET    https://gateway.tsirylab.com/serviceauth/users/{id} (Obtenir par Id, modifier, supprimer un utilisateur)
/// - POST   https://gateway.tsirylab.com/serviceauth/users/{id}/role (Assigner, retirer des roles par un utilisateur)
/// - POST   https://gateway.tsirylab.com/serviceauth/users/create-with-role (Créer un utilisateur avec role)
/// - GET    https://gateway.tsirylab.com/serviceauth/citizen/{id} (Utilisateur avec citoyen associé)
/// - POST   https://gateway.tsirylab.com/serviceauth/users/register-with-citizen-short (Créer utilisateur + citoyen)
/// - POST   https://gateway.tsirylab.com/serviceauth/users/register-with-citizen-short-role (Créer utilisateur + citoyen avec role)
/// - GET    https://gateway.tsirylab.com/serviceauth/users/user-citizen/{id-citizen} (Utilisateur avec citoyen associé)
/// - GET    https://gateway.tsirylab.com/serviceauth/users/application/{appId} (Lister les utilisateurs liés à une application)
class UserService {
  static const String baseUrl = "https://gateway.tsirylab.com/serviceauth";
  static const String citizenBaseUrl = "https://gateway.tsirylab.com/servicecitoyen";
  static const int appId = 1;
  static const int defaultRoleId = 0;

  static const Set<String> _invalidCitizenIds = {
    "",
    "00000000-0000-0000-0000-000000000000",
    "550e8400-e29b-41d4-a716-446655440000",
  };

  static Future<dynamic> assignDefaultRole(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/roles'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "role_ids": [defaultRoleId]
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Erreur lors de l'assignations de role: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getAllUsersByApplicationRole({
    int page = 1,
    String search = "",
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': '1',
        'limit': '100',
      };
      if (search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$baseUrl/users').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final resData = jsonDecode(response.body);
      List allUsers = [];
      int total = 0;
      int limit = 100;

      if (resData is List) {
        allUsers = resData;
      } else if (resData is Map) {
        if (resData['data'] is List) {
          allUsers = List.from(resData['data']);
        } else if (resData['users'] is List) {
          allUsers = List.from(resData['users']);
        }
        total = resData['total'] ?? resData['count'] ?? allUsers.length;
        limit = resData['limit'] ?? 100;
      }

      if (limit > 0 && total > allUsers.length) {
        final int numberOfPages = (total / limit).ceil();
        List<Future<http.Response>> requests = [];
        for (int i = 2; i <= numberOfPages; i++) {
          final pUri = Uri.parse('$baseUrl/users').replace(
            queryParameters: {
              'page': i.toString(),
              'limit': limit.toString(),
              if (search.trim().isNotEmpty) 'search': search.trim(),
            },
          );
          requests.add(http.get(pUri));
        }

        final responses = await Future.wait(requests);
        for (var res in responses) {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            final pageData = jsonDecode(res.body);
            if (pageData is Map && pageData['data'] is List) {
              allUsers.addAll(pageData['data']);
            } else if (pageData is List) {
              allUsers.addAll(pageData);
            }
          }
        }
      }

      final usersWithCitizens = await enrichUsersWithCitizens(allUsers);

      usersWithCitizens.sort((a, b) {
        final dateA = a['citoyen']?['created_at'] != null
            ? DateTime.parse(a['citoyen']['created_at']).millisecondsSinceEpoch
            : 0;
        final dateB = b['citoyen']?['created_at'] != null
            ? DateTime.parse(b['citoyen']['created_at']).millisecondsSinceEpoch
            : 0;

        return dateB.compareTo(dateA);
      });

      return usersWithCitizens;
    } catch (e) {
      debugPrint("Erreur lors de la récupération des utilisateurs: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getAllUsersByApplicationRole2({
    int page = 1,
    String search = "",
  }) async {
    return getAllUsersByApplicationRole(page: page, search: search);
  }

  static Future<List<Map<String, dynamic>>> enrichUsersWithCitizens(List<dynamic> usersList) async {
    const headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final List<Future<Map<String, dynamic>>> futures = usersList.map((u) async {
      if (u is! Map) return {'user': u, 'citoyen': null, 'appUserRoles': []};

      dynamic userObj = u['user'] is Map ? u['user'] : u;
      dynamic citoyenObj = u['citoyen'] is Map ? u['citoyen'] : (u['citizen'] is Map ? u['citizen'] : null);

      final citizenId = userObj['id_citizen'] ?? userObj['citizen_id'] ?? u['id_citizen'] ?? u['citizen_id'];
      final cinNumber = citoyenObj?['citizen_national_card_number'] ?? userObj['user_cin'] ?? userObj['cin'] ?? u['user_cin'] ?? u['cin'];
      final userId = userObj['user_id'] ?? userObj['id_user'] ?? userObj['id'] ?? u['user_id'] ?? u['id_user'];

      // Si le citoyen n'est pas encore présent, tenter de le récupérer
      if (citoyenObj == null) {
        // 1. Essayer avec citizenId (UUID) sur servicecitoyen
        if (citizenId != null && !_invalidCitizenIds.contains(citizenId.toString())) {
          try {
            final res = await http.get(
              Uri.parse('$citizenBaseUrl/citizens/getCitizenById/$citizenId'),
              headers: headers,
            ).timeout(const Duration(seconds: 2));

            if (res.statusCode >= 200 && res.statusCode < 300) {
              final body = jsonDecode(res.body);
              if (body is Map) {
                citoyenObj = body['data'] is Map ? body['data'] : (body['citizen'] is Map ? body['citizen'] : body);
              } else if (body is List && body.isNotEmpty) {
                citoyenObj = body.first;
              }
            }
          } catch (_) {}
        }

        // 2. Si toujours nul, essayer avec le numéro de CIN (Card ID) sur servicecitoyen
        if (citoyenObj == null &&
            cinNumber != null && cinNumber.toString().trim().isNotEmpty) {
          final cleanCin = cinNumber.toString().replaceAll(' ', '').trim();
          try {
            final res = await http.get(
              Uri.parse('$citizenBaseUrl/citizens/$cleanCin'),
              headers: headers,
            ).timeout(const Duration(seconds: 2));

            if (res.statusCode >= 200 && res.statusCode < 300) {
              final body = jsonDecode(res.body);
              if (body is Map) {
                citoyenObj = body['data'] is Map ? body['data'] : (body['citizen'] is Map ? body['citizen'] : body);
              } else if (body is List && body.isNotEmpty) {
                citoyenObj = body.first;
              }
            }
          } catch (_) {}
        }

        // 3. Si toujours nul, essayer via la route serviceauth /users/user-citizen/{id}
        if (citoyenObj == null &&
            userId != null && userId.toString().trim().isNotEmpty) {
          try {
            final userRes = await http.get(
              Uri.parse('$baseUrl/users/user-citizen/$userId'),
              headers: headers,
            ).timeout(const Duration(seconds: 2));

            if (userRes.statusCode >= 200 && userRes.statusCode < 300) {
              final body = jsonDecode(userRes.body);
              if (body is Map) {
                final fetchedCitizen = body['citoyen'] ?? body['citizen'] ?? body['data'];
                if (fetchedCitizen is Map) {
                  citoyenObj = fetchedCitizen;
                }
              }
            }
          } catch (_) {}
        }
      }

      return {
        'user': userObj,
        'citoyen': citoyenObj,
        'appUserRoles': userObj['appUserRoles'] ?? u['appUserRoles'] ?? userObj['roles'] ?? u['roles'],
      };
    }).toList();

    return await Future.wait(futures);
  }

  static Future<Map<String, dynamic>?> getAllUsersByApplicationRole2Paged({
    int page = 1,
    String search = "",
    int limit = 10,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$baseUrl/users').replace(
        queryParameters: queryParams,
      );

      final prefs = await SharedPreferences.getInstance();
      final rawToken = prefs.getString("access_token");
      String? token;
      if (rawToken != null && rawToken.isNotEmpty) {
        try {
          final parsed = jsonDecode(rawToken);
          if (parsed is String) {
            token = parsed;
          } else if (parsed is Map) {
            token = parsed['access_token'] ?? parsed['token'];
          }
        } catch (_) {
          token = rawToken;
        }
      }

      final Map<String, String> headers = {
        "Content-Type": "application/json",
      };
      if (token != null && token.trim().isNotEmpty) {
        headers["Authorization"] = "Bearer ${token.trim()}";
      }

      var response = await http.get(uri, headers: headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        try {
          response = await http.get(uri);
        } catch (_) {}
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final resData = jsonDecode(response.body);
      List usersList = [];
      int total = 0;
      int pageLimit = limit;

      if (resData is List) {
        usersList = resData;
        total = usersList.length;
      } else if (resData is Map) {
        if (resData['data'] is List) {
          usersList = resData['data'];
        } else if (resData['users'] is List) {
          usersList = resData['users'];
        } else if (resData['data'] is Map && resData['data']['users'] is List) {
          usersList = resData['data']['users'];
        }
        total = resData['total'] ?? resData['count'] ?? usersList.length;
        pageLimit = resData['limit'] ?? limit;
      }

      final int numberOfPages = (pageLimit > 0 && total > 0) ? (total / pageLimit).ceil() : 1;
      final usersWithCitizens = await enrichUsersWithCitizens(usersList);

      return {
        'data': usersWithCitizens,
        'currentPage': page,
        'numberOfPages': numberOfPages,
        'total': total,
        'limit': pageLimit,
      };
    } catch (e) {
      debugPrint("Erreur lors de la récupération des utilisateurs: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getAllUsersBySpecificRole(String roleSlug) async {
    try {
      final firstUri = Uri.parse('$baseUrl/users?limit=100&page=1');
      final firstResponse = await http.get(firstUri);
      
      if (firstResponse.statusCode < 200 || firstResponse.statusCode >= 300) {
        return null;
      }

      final firstResData = jsonDecode(firstResponse.body);
      final int limit = firstResData['limit'] ?? 100;
      final int total = firstResData['total'] ?? 0;
      final List firstPageUsers = firstResData['data'] ?? [];

      final int numberOfPages = (total / limit).ceil() > 0 ? (total / limit).ceil() : 1;

      List<Future<http.Response>> requests = [];
      for (int i = 2; i <= numberOfPages; i++) {
        requests.add(http.get(Uri.parse('$baseUrl/users?limit=100&page=$i')));
      }

      final responses = await Future.wait(requests);

      List allUsers = [...firstPageUsers];
      for (var res in responses) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final resData = jsonDecode(res.body);
          if (resData['data'] is List) {
            allUsers.addAll(resData['data']);
          }
        }
      }

      final filteredUsers = allUsers.where((u) {
        final roles = u['appUserRoles'] as List? ?? [];
        return roles.any((r) => r['role'] != null && r['role']['role_slug'] == roleSlug);
      }).toList();

      List<Map<String, dynamic>> usersWithCitizens = [];

      for (var user in filteredUsers) {
        final citizenId = user['id_citizen'] ?? user['citizen_id'];

        if (citizenId == null || _invalidCitizenIds.contains(citizenId.toString())) {
          usersWithCitizens.add({'user': user, 'citoyen': null});
        } else {
          try {
            final citizenResponse = await http.get(
              Uri.parse('$citizenBaseUrl/citizens/getCitizenById/$citizenId'),
            );

            dynamic citoyenData;
            if (citizenResponse.statusCode >= 200 && citizenResponse.statusCode < 300) {
              citoyenData = jsonDecode(citizenResponse.body);
            }

            usersWithCitizens.add({'user': user, 'citoyen': citoyenData});
          } catch (error) {
            if (kDebugMode) {
              debugPrint("Impossible de récupérer les informations citoyen pour $citizenId");
            }
            usersWithCitizens.add({'user': user, 'citoyen': null});
          }
        }
      }

      usersWithCitizens.sort((a, b) {
        final dateA = a['citoyen']?['created_at'] != null
            ? DateTime.parse(a['citoyen']['created_at']).millisecondsSinceEpoch
            : double.infinity;
        final dateB = b['citoyen']?['created_at'] != null
            ? DateTime.parse(b['citoyen']['created_at']).millisecondsSinceEpoch
            : double.infinity;

        return (dateB).compareTo(dateA);
      });

      debugPrint("Utilisateurs avec rôle $roleSlug: $usersWithCitizens");

      return usersWithCitizens;
    } catch (e) {
      debugPrint("Erreur lors de la récupération des utilisateurs avec rôle $roleSlug: $e");
      return null;
    }
  }
}
