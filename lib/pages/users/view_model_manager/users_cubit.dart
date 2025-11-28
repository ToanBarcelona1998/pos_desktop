import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:pos_final/api_end_points.dart';
import 'package:pos_final/models/system.dart';
import 'package:logging/logging.dart';

part 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  final Logger _logger = Logger('UsersCubit');
  UsersCubit() : super(UsersInitial());

  Future<void> fetchUsers({int page = 1, int pageSize = 10}) async {
    try {
      emit(UsersLoading());
      final token = await System().getToken();
      if (token == null) {
        emit(const UsersError('No token available'));
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/user?per_page=$pageSize&page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        emit(UsersLoaded(users: List<Map<String, dynamic>>.from(data), filteredUsers: List<Map<String, dynamic>>.from(data)));
      } else {
        emit(UsersError('Failed to fetch users: ${response.statusCode}'));
      }
    } catch (e) {
      _logger.severe('Error in fetchUsers: $e');
      emit(UsersError('Error fetching users: $e'));
    }
  }

  void searchUsers(String query) {
    final state = this.state;
    if (state is UsersLoaded) {
      final filteredUsers = state.users.where((user) {
        final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) || email.contains(query.toLowerCase());
      }).toList();
      emit(UsersLoaded(users: state.users, filteredUsers: filteredUsers));
    }
  }

  Future<void> addUser(Map<String, dynamic> userData) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        emit(const UsersError('No token available'));
        return;
      }
      final response = await http.post(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/user-registration'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == 1) {
          await fetchUsers(); // Refresh the list after adding
        } else {
          emit(UsersError(data['msg']));
        }
      } else {
        emit(UsersError('Failed to add user: ${response.statusCode}'));
      }
    } catch (e) {
      _logger.severe('Error in addUser: $e');
      emit(UsersError('Error adding user: $e'));
    }
  }

  Future<void> updatePassword(int userId, String currentPassword, String newPassword) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        emit(const UsersError('No token available'));
        return;
      }
      final response = await http.post(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/update-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == 1) {
          emit(state); // No need to refresh the list
        } else {
          emit(UsersError(data['msg']));
        }
      } else {
        emit(UsersError('Failed to update password: ${response.statusCode}'));
      }
    } catch (e) {
      _logger.severe('Error in updatePassword: $e');
      emit(UsersError('Error updating password: $e'));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        emit(const UsersError('No token available'));
        return;
      }
      final response = await http.post(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/forget-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == 1) {
          emit(state); // No need to refresh the list
        } else {
          emit(UsersError(data['msg']));
        }
      } else {
        emit(UsersError('Failed to reset password: ${response.statusCode}'));
      }
    } catch (e) {
      _logger.severe('Error in resetPassword: $e');
      emit(UsersError('Error resetting password: $e'));
    }
  }
}