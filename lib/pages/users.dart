import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/home/home_logic.dart';
import 'package:pos_final/pages/home/widgets/sidebar.dart';
import 'package:pos_final/pages/users/view_model_manager/users_cubit.dart';

class UsersScreen extends StatefulWidget {
  final HomeLogic logic;

  const UsersScreen({super.key, required this.logic});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _pageSize = 10;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<UsersCubit>().searchUsers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => UsersCubit()..fetchUsers(page: _currentPage, pageSize: _pageSize),
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          elevation: 0,
          title: Row(
            children: [
              const Icon(FontAwesomeIcons.users, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                localizations?.translate('users') ?? 'Users',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.sync, color: Colors.white),
              onPressed: () => context.read<UsersCubit>().fetchUsers(page: _currentPage, pageSize: _pageSize),
              tooltip: localizations?.translate('refresh') ?? 'Refresh',
            ),
          ],
        ),
        body: Row(
          children: [
            Sidebar(logic: widget.logic),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildSearchBar(context),
                    const SizedBox(height: 16),
                    Expanded(child: _buildUsersTable(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddUserDialog(context),
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(FontAwesomeIcons.userPlus, color: Colors.white),
          tooltip: localizations?.translate('add_user') ?? 'Add User',
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.9)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        localizations?.translate('manage_users') ?? 'Manage Users',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: localizations?.translate('search_users') ?? 'Search users...',
            hintStyle: TextStyle(
              fontFamily: 'Cairo',
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            border: InputBorder.none,
            prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass, color: Theme.of(context).colorScheme.primary, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(FontAwesomeIcons.xmark, color: Colors.redAccent),
              onPressed: () {
                _searchController.clear();
                context.read<UsersCubit>().searchUsers('');
              },
            )
                : null,
          ),
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildUsersTable(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        if (state is UsersLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is UsersError) {
          return Center(
            child: Card(
              elevation: 4,
              color: Colors.redAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  state.message,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, color: Colors.redAccent),
                ),
              ),
            ),
          );
        } else if (state is UsersLoaded) {
          return Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: PaginatedDataTable(
              header: null,
              rowsPerPage: _pageSize,
              onRowsPerPageChanged: (value) {
                setState(() {
                  _pageSize = value!;
                  _currentPage = 1; // Reset to first page
                });
                context.read<UsersCubit>().fetchUsers(page: _currentPage, pageSize: _pageSize);
              },
              availableRowsPerPage: const [10, 20, 50],
              onPageChanged: (pageIndex) {
                setState(() {
                  _currentPage = (pageIndex / _pageSize).floor() + 1;
                });
                context.read<UsersCubit>().fetchUsers(page: _currentPage, pageSize: _pageSize);
              },
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columns: [
                _buildDataColumn(context, 'name', 0),
                _buildDataColumn(context, 'username', 1),
                _buildDataColumn(context, 'email', 2),
                _buildDataColumn(context, 'user_type', 3),
                _buildDataColumn(context, 'status', 4),
                _buildDataColumn(context, 'created_at', 5),
                DataColumn(
                  label: Text(
                    localizations?.translate('actions') ?? 'Actions',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              source: UsersDataSource(
                users: state.filteredUsers,
                context: context,
                onView: _showUserDetailsDialog,
                onEdit: _showEditUserDialog,
                onReset: _showResetPasswordDialog,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  DataColumn _buildDataColumn(BuildContext context, String key, int index) {
    final localizations = AppLocalizations.of(context);
    return DataColumn(
      label: Text(
        localizations?.translate(key) ?? key.replaceAll('_', ' ').capitalize(),
        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      onSort: (columnIndex, ascending) {
        setState(() {
          _sortColumnIndex = columnIndex;
          _sortAscending = ascending;
        });
        final state = context.read<UsersCubit>().state;
        if (state is UsersLoaded) {
          final sortedUsers = List<Map<String, dynamic>>.from(state.filteredUsers);
          sortedUsers.sort((a, b) {
            final aValue = a[key] ?? '';
            final bValue = b[key] ?? '';
            return ascending
                ? aValue.toString().compareTo(bValue.toString())
                : bValue.toString().compareTo(aValue.toString());
          });
          context.read<UsersCubit>().emit(UsersLoaded(users: state.users, filteredUsers: sortedUsers));
        }
      },
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final surnameController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String status = 'active';
    String userType = 'user';
    bool allowLogin = true;
    final dobController = TextEditingController();
    String gender = 'male';
    String maritalStatus = 'unmarried';
    String bloodGroup = 'O+';
    final contactNumberController = TextEditingController();
    final fbLinkController = TextEditingController();
    final twitterLinkController = TextEditingController();
    final permanentAddressController = TextEditingController();
    final currentAddressController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.translate('add_user') ?? 'Add User',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFormSection(context, 'Basic Information', [
                    TextFormField(
                      controller: surnameController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('surname') ?? 'Surname',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('first_name') ?? 'First Name',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('last_name') ?? 'Last Name',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('email') ?? 'Email',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('username') ?? 'Username',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.length < 5 ? 'Minimum 5 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('password') ?? 'Password',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      obscureText: true,
                      validator: (value) => allowLogin && value!.length < 6 ? 'Minimum 6 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('status') ?? 'Status',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['active', 'inactive', 'terminated'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Cairo')));
                      }).toList(),
                      onChanged: (value) {
                        status = value!;
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: userType,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('user_type') ?? 'User Type',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['user', 'user_customer'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontFamily: 'Cairo')));
                      }).toList(),
                      onChanged: (value) {
                        userType = value!;
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: Text(
                        localizations?.translate('allow_login') ?? 'Allow Login',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      value: allowLogin,
                      onChanged: (value) {
                        allowLogin = value!;
                        setState(() {});
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildFormSection(context, 'Personal Details', [
                    TextFormField(
                      controller: dobController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('dob') ?? 'Date of Birth (YYYY-MM-DD)',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                        return regex.hasMatch(value) ? null : 'Invalid format (YYYY-MM-DD)';
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('gender') ?? 'Gender',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['male', 'female', 'others'].map((g) {
                        return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontFamily: 'Cairo')));
                      }).toList(),
                      onChanged: (value) {
                        gender = value!;
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: maritalStatus,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('marital_status') ?? 'Marital Status',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['married', 'unmarried', 'divorced'].map((m) {
                        return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontFamily: 'Cairo')));
                      }).toList(),
                      onChanged: (value) {
                        maritalStatus = value!;
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: bloodGroup,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('blood_group') ?? 'Blood Group',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'].map((b) {
                        return DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontFamily: 'Cairo')));
                      }).toList(),
                      onChanged: (value) {
                        bloodGroup = value!;
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactNumberController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('contact_number') ?? 'Contact Number',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final regex = RegExp(r'^\+?\d{10,15}$');
                        return regex.hasMatch(value) ? null : 'Invalid phone number';
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildFormSection(context, 'Social Media', [
                    TextFormField(
                      controller: fbLinkController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('fb_link') ?? 'Facebook Link',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final regex = RegExp(r'^https?://(www\.)?facebook\.com/.+$');
                        return regex.hasMatch(value) ? null : 'Invalid Facebook URL';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: twitterLinkController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('twitter_link') ?? 'Twitter Link',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final regex = RegExp(r'^https?://(www\.)?twitter\.com/.+$');
                        return regex.hasMatch(value) ? null : 'Invalid Twitter URL';
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildFormSection(context, 'Address', [
                    TextFormField(
                      controller: permanentAddressController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('permanent_address') ?? 'Permanent Address',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: currentAddressController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('current_address') ?? 'Current Address',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          localizations?.translate('cancel') ?? 'Cancel',
                          style: const TextStyle(fontFamily: 'Cairo', color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final userData = {
                              'surname': surnameController.text.isEmpty ? null : surnameController.text,
                              'first_name': firstNameController.text,
                              'last_name': lastNameController.text.isEmpty ? null : lastNameController.text,
                              'email': emailController.text,
                              'username': usernameController.text,
                              'password': passwordController.text.isEmpty ? null : passwordController.text,
                              'status': status,
                              'user_type': userType,
                              'allow_login': allowLogin ? 1 : 0,
                              'dob': dobController.text.isEmpty ? null : dobController.text,
                              'gender': gender,
                              'marital_status': maritalStatus,
                              'blood_group': bloodGroup,
                              'contact_number': contactNumberController.text.isEmpty ? null : contactNumberController.text,
                              'fb_link': fbLinkController.text.isEmpty ? null : fbLinkController.text,
                              'twitter_link': twitterLinkController.text.isEmpty ? null : twitterLinkController.text,
                              'permanent_address': permanentAddressController.text.isEmpty ? null : permanentAddressController.text,
                              'current_address': currentAddressController.text.isEmpty ? null : currentAddressController.text,
                            };
                            context.read<UsersCubit>().addUser(userData);
                            Navigator.pop(dialogContext);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          localizations?.translate('add') ?? 'Add',
                          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUserDetailsDialog(BuildContext context, Map<String, dynamic> user) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations?.translate('user_details') ?? 'User Details',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDetailCard(context, user),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        localizations?.translate('close') ?? 'Close',
                        style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    final localizations = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final surnameController = TextEditingController(text: user['surname']);
    final firstNameController = TextEditingController(text: user['first_name']);
    final lastNameController = TextEditingController(text: user['last_name']);
    final emailController = TextEditingController(text: user['email']);
    final usernameController = TextEditingController(text: user['username']);
    String status = user['status'] ?? 'active';
    String userType = user['user_type'] ?? 'user';
    bool allowLogin = user['allow_login'] == 1;
    final dobController = TextEditingController(text: user['dob']);
    String gender = user['gender'] ?? 'male';
    String maritalStatus = user['marital_status'] ?? 'unmarried';
    String bloodGroup = user['blood_group'] ?? 'O+';
    final contactNumberController = TextEditingController(text: user['contact_number']);
    final fbLinkController = TextEditingController(text: user['fb_link']);
    final twitterLinkController = TextEditingController(text: user['twitter_link']);
    final permanentAddressController = TextEditingController(text: user['permanent_address']);
    final currentAddressController = TextEditingController(text: user['current_address']);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.translate('edit_user') ?? 'Edit User',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFormSection(context, 'Basic Information', [
                    TextFormField(
                      controller: surnameController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('surname') ?? 'Surname',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('first_name') ?? 'First Name',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('last_name') ?? 'Last Name',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('email') ?? 'Email',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('username') ?? 'Username',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.length < 5 ? 'Minimum 5 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('status') ?? 'Status',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['active', 'inactive', 'terminated'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Cairo')));
                      }).toList(),
                      onChanged: (value) {
                        status = value!;
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: userType,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('user_type') ?? 'User Type',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['user', 'user_customer'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontFamily: 'Cairo')));
                      }).toList(),
                      onChanged: (value) {
                        userType = value!;
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: Text(
                        localizations?.translate('allow_login') ?? 'Allow Login',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      value: allowLogin,
                      onChanged: (value) {
                        allowLogin = value!;
                        setState(() {});
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildFormSection(context, 'Personal Details', [
                    TextFormField(
                      controller: dobController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('dob') ?? 'Date of Birth (YYYY-MM-DD)',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                        return regex.hasMatch(value) ? null : 'Invalid format (YYYY-MM-DD)';
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('gender') ?? 'Gender',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['male', 'female', 'others'].map((g) {
                        return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontFamily: 'Cairo')));
                      }).toList(),
                      onChanged: (value) {
                        gender = value!;
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: maritalStatus,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('marital_status') ?? 'Marital Status',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['married', 'unmarried', 'divorced'].map((m) {
                        return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontFamily: 'Cairo')));
                      }).toList(),
                      onChanged: (value) {
                        maritalStatus = value!;
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: bloodGroup,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('blood_group') ?? 'Blood Group',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'].map((b) {
                        return DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontFamily: 'Cairo')));
                      }).toList(),
                      onChanged: (value) {
                        bloodGroup = value!;
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactNumberController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('contact_number') ?? 'Contact Number',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final regex = RegExp(r'^\+?\d{10,15}$');
                        return regex.hasMatch(value) ? null : 'Invalid phone number';
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildFormSection(context, 'Social Media', [
                    TextFormField(
                      controller: fbLinkController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('fb_link') ?? 'Facebook Link',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final regex = RegExp(r'^https?://(www\.)?facebook\.com/.+$');
                        return regex.hasMatch(value) ? null : 'Invalid Facebook URL';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: twitterLinkController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('twitter_link') ?? 'Twitter Link',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final regex = RegExp(r'^https?://(www\.)?twitter\.com/.+$');
                        return regex.hasMatch(value) ? null : 'Invalid Twitter URL';
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildFormSection(context, 'Address', [
                    TextFormField(
                      controller: permanentAddressController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('permanent_address') ?? 'Permanent Address',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: currentAddressController,
                      decoration: InputDecoration(
                        labelText: localizations?.translate('current_address') ?? 'Current Address',
                        labelStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          localizations?.translate('cancel') ?? 'Cancel',
                          style: const TextStyle(fontFamily: 'Cairo', color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final userData = {
                              'surname': surnameController.text.isEmpty ? null : surnameController.text,
                              'first_name': firstNameController.text,
                              'last_name': lastNameController.text.isEmpty ? null : lastNameController.text,
                              'email': emailController.text,
                              'username': usernameController.text,
                              'status': status,
                              'user_type': userType,
                              'allow_login': allowLogin ? 1 : 0,
                              'dob': dobController.text.isEmpty ? null : dobController.text,
                              'gender': gender,
                              'marital_status': maritalStatus,
                              'blood_group': bloodGroup,
                              'contact_number': contactNumberController.text.isEmpty ? null : contactNumberController.text,
                              'fb_link': fbLinkController.text.isEmpty ? null : fbLinkController.text,
                              'twitter_link': twitterLinkController.text.isEmpty ? null : twitterLinkController.text,
                              'permanent_address': permanentAddressController.text.isEmpty ? null : permanentAddressController.text,
                              'current_address': currentAddressController.text.isEmpty ? null : currentAddressController.text,
                            };
                            context.read<UsersCubit>().addUser(userData);
                            Navigator.pop(dialogContext);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          localizations?.translate('update') ?? 'Update',
                          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, String email) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations?.translate('reset_password') ?? 'Reset Password',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                (localizations?.translate('reset_password_confirm') ?? 'Are you sure you want to reset the password for %s?').replaceAll('%s', email),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      localizations?.translate('cancel') ?? 'Cancel',
                      style: const TextStyle(fontFamily: 'Cairo', color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      context.read<UsersCubit>().resetPassword(email);
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      localizations?.translate('reset') ?? 'Reset',
                      style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(BuildContext context, Map<String, dynamic> user) {
    final localizations = AppLocalizations.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, localizations?.translate('name') ?? 'Name', '${user['surname'] ?? ''} ${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'),
            _buildDetailRow(context, localizations?.translate('username') ?? 'Username', user['username'] ?? ''),
            _buildDetailRow(context, localizations?.translate('email') ?? 'Email', user['email'] ?? ''),
            _buildDetailRow(context, localizations?.translate('user_type') ?? 'User Type', user['user_type'] ?? ''),
            _buildDetailRow(context, localizations?.translate('status') ?? 'Status', user['status'] ?? '', color: user['status'] == 'active' ? Colors.green : Colors.red),
            _buildDetailRow(context, localizations?.translate('created_at') ?? 'Created At', user['created_at'] ?? ''),
            _buildDetailRow(context, localizations?.translate('dob') ?? 'Date of Birth', user['dob'] ?? ''),
            _buildDetailRow(context, localizations?.translate('gender') ?? 'Gender', user['gender'] ?? ''),
            _buildDetailRow(context, localizations?.translate('marital_status') ?? 'Marital Status', user['marital_status'] ?? ''),
            _buildDetailRow(context, localizations?.translate('blood_group') ?? 'Blood Group', user['blood_group'] ?? ''),
            _buildDetailRow(context, localizations?.translate('contact_number') ?? 'Contact Number', user['contact_number'] ?? ''),
            _buildDetailRow(context, localizations?.translate('fb_link') ?? 'Facebook', user['fb_link'] ?? ''),
            _buildDetailRow(context, localizations?.translate('twitter_link') ?? 'Twitter', user['twitter_link'] ?? ''),
            _buildDetailRow(context, localizations?.translate('permanent_address') ?? 'Permanent Address', user['permanent_address'] ?? ''),
            _buildDetailRow(context, localizations?.translate('current_address') ?? 'Current Address', user['current_address'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$label:',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: color ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class UsersDataSource extends DataTableSource {
  final List<Map<String, dynamic>> users;
  final BuildContext context;
  final Function(BuildContext, Map<String, dynamic>) onView;
  final Function(BuildContext, Map<String, dynamic>) onEdit;
  final Function(BuildContext, String) onReset;

  UsersDataSource({
    required this.users,
    required this.context,
    required this.onView,
    required this.onEdit,
    required this.onReset,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= users.length) return null;
    final user = users[index];
    return DataRow(
      cells: [
        DataCell(Text('${user['surname'] ?? ''} ${user['first_name'] ?? ''} ${user['last_name'] ?? ''}', style: const TextStyle(fontFamily: 'Cairo'))),
        DataCell(Text(user['username'] ?? '', style: const TextStyle(fontFamily: 'Cairo'))),
        DataCell(Text(user['email'] ?? '', style: const TextStyle(fontFamily: 'Cairo'))),
        DataCell(Text(user['user_type'] ?? '', style: const TextStyle(fontFamily: 'Cairo'))),
        DataCell(Text(user['status'] ?? '', style: TextStyle(fontFamily: 'Cairo', color: user['status'] == 'active' ? Colors.green : Colors.red))),
        DataCell(Text(user['created_at'] ?? '', style: const TextStyle(fontFamily: 'Cairo'))),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(FontAwesomeIcons.eye, color: Colors.blue),
                onPressed: () => onView(context, user),
                tooltip: 'View Details',
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.penToSquare, color: Colors.orange),
                onPressed: () => onEdit(context, user),
                tooltip: 'Edit User',
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.key, color: Colors.red),
                onPressed: () => onReset(context, user['email']),
                tooltip: 'Reset Password',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}