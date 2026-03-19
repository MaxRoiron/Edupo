import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.getAllUsers();
    if (response.success && response.data != null) {
      final list = response.data!['list'] as List<dynamic>;
      setState(() {
        _users = list.map((u) => User.fromJson(u)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Erreur inconnue';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchUsers,
                        child: const Text('Réessayer'),
                      )
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(child: Text('Aucun utilisateur trouvé.'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              child: Text(
                                user.username.isNotEmpty
                                    ? user.username[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(user.username),
                            subtitle: Text(user.email),
                            trailing: user.role == 'admin'
                                ? const Chip(
                                    label: Text('Admin'),
                                    backgroundColor: Colors.redAccent,
                                  )
                                : const Chip(
                                    label: Text('User'),
                                  ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('ID', user.id.toString()),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Username', user.username),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Email', user.email),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Rôle', user.role),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Âge', user.age != null ? '${user.age} ans' : 'Non renseigné'),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Genre', user.gender ?? 'Non renseigné'),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Profession', user.profession ?? 'Non renseigné'),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Téléphone', user.phoneNumber ?? 'Non renseigné'),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Création', user.createdAt),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label : ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
