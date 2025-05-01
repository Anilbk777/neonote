import 'package:flutter/material.dart';
import 'package:project/widgets/custom_scaffold_workspace.dart';
import 'package:project/work_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project/services/local_storage.dart';

class ProjectDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final int projectId;
  final bool isHostedByUser;

  const ProjectDetailPage({
    Key? key,
    required this.title,
    required this.description,
    required this.projectId,
    required this.isHostedByUser,
  }) : super(key: key);

  @override
  _ProjectDetailPageState createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchProjectDetails();
  }

  Future<void> fetchProjectDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      final token = await LocalStorage.getToken();
      if (token == null) {
        setState(() {
          error = 'Not authenticated';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:8000/api/work/projects/${widget.projectId}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          setState(() {
            members = List<Map<String, dynamic>>.from(data['members'] ?? []);
            if (data['owner'] != null) {
              members.insert(0, {...data['owner'], 'isOwner': true});
            }
            isLoading = false;
          });
        } catch (e) {
          setState(() {
            error = 'Error parsing response: ${e.toString()}';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load project details: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error connecting to server: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _inviteTeamMember(BuildContext context, String email) async {
    final persistentContext = context; // Use the local context instead

    if (persistentContext == null) {
      return; // Exit if the context is not available
    }

    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not authenticated')),
          );
        }
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/work/projects/${widget.projectId}/invite_member/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invitation sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        String errorMessage = errorData['error'] ?? 'Failed to send invitation';
        if (errorMessage.contains('You are the host')) {
          showDialog(
            context: persistentContext,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Host Action'),
                content: const Text('You are the host of this project and cannot invite yourself.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else if (errorMessage.contains('already a member')) {
          showDialog(
            context: persistentContext,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('User Already a Member'),
                content: const Text('The user you are trying to invite is already a member of this project.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          showDialog(
            context: persistentContext,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(errorMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = errorData['error'] ?? 'Failed to send invitation';
        if (mounted) {
          showDialog(
            context: persistentContext,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(errorMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invite Team Member'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter team member\'s email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (emailController.text.isNotEmpty) {
                  _inviteTeamMember(context, emailController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Send Invitation'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberChip(Map<String, dynamic> member) {
    final bool isOwner = member['isOwner'] == true;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isOwner 
          ? const Color(0xFF255DE1).withOpacity(0.15)
          : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOwner 
            ? const Color(0xFF255DE1).withOpacity(0.4)
            : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOwner ? Icons.star : Icons.person,
            size: 16,
            color: isOwner 
              ? const Color(0xFF255DE1)
              : Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Text(
            member['full_name'] ?? 'Unknown',
            style: TextStyle(
              fontSize: 14,
              color: isOwner 
                ? const Color(0xFF255DE1)
                : Colors.blue[700],
              fontWeight: isOwner 
                ? FontWeight.bold
                : FontWeight.w500,
            ),
          ),
          if (isOwner) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF255DE1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Host',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF255DE1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: CustomScaffoldWorkspace(
        selectedPage: 'Work',
        onItemSelected: (String page) {
          if (page == 'Work') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const WorkPage(),
              ),
            );
          }
        },
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      onPressed: () => _showInviteDialog(context),
                    ),
                    if (widget.isHostedByUser) // Show delete icon only for hosted projects
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _showDeleteConfirmationDialog(context),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Team',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (isLoading)
                            const Center(
                              child: CircularProgressIndicator(),
                            )
                          else if (error.isNotEmpty)
                            Text(
                              error,
                              style: const TextStyle(color: Colors.red),
                            )
                          else if (members.isEmpty)
                            const Text(
                              'No team members yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            )
                          else ...[
                            // Host header and chip
                            const Text(
                              'Host',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildMemberChip(members.first),
                            const SizedBox(height: 20),
                            if (members.length > 1) ...[
                              const Text(
                                'Team Members',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: members.skip(1).map((member) => _buildMemberChip(member)).toList(),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: const Text('Are you sure you want to delete this project?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteProject();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProject() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('http://localhost:8000/api/work/projects/${widget.projectId}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WorkPage(),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete project: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}