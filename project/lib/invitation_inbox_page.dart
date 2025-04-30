import 'package:flutter/material.dart';
import 'package:project/widgets/custom_scaffold_workspace.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project/services/local_storage.dart';

class InvitationInboxPage extends StatefulWidget {
  const InvitationInboxPage({Key? key}) : super(key: key);

  @override
  _InvitationInboxPageState createState() => _InvitationInboxPageState();
}

class _InvitationInboxPageState extends State<InvitationInboxPage> {
  List<Map<String, dynamic>> invitations = [];
  bool isLoading = true;
  String error = '';
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    fetchInvitations();
  }

  Future<void> _loadUserId() async {
    currentUserId = await LocalStorage.getUserId();
    print('Debug - Current User ID: $currentUserId');
  }

  Future<void> fetchInvitations() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        setState(() {
          error = 'Not authenticated';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:8000/api/work/invitations/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Debug - Invitations data: $data');
        setState(() {
          invitations = data.map((invitation) {
            print('Debug - Individual invitation: $invitation');
            print('Debug - Sender ID: ${invitation['sender']['id']}');
            print('Debug - Recipient ID: ${invitation['recipient']['id']}');
            return {
              'id': invitation['id'],
              'project': invitation['project'],
              'sender': invitation['sender'],
              'recipient': invitation['recipient'],
              'status': invitation['status'],
              'created_at': invitation['created_at'],
              'responded_at': invitation['responded_at'],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load invitations';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error connecting to server';
        isLoading = false;
      });
    }
  }

  Future<void> respondToInvitation(int invitationId, String action) async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/work/invitations/$invitationId/respond/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'action': action}),
      );

      if (response.statusCode == 200) {
        await fetchInvitations();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation ${action}ed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to respond to invitation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error connecting to server'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusChip(String status, Map<String, dynamic>? recipient, String? respondedAt) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case 'accepted':
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        icon = Icons.check_circle;
        text = 'Accepted';
        break;
      case 'rejected':
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        icon = Icons.cancel;
        text = 'Rejected';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        icon = Icons.schedule;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (status != 'pending' && recipient != null) ...[
                const SizedBox(height: 2),
                Text(
                  'by ${recipient['full_name']}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                  ),
                ),
                if (respondedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'on ${DateTime.parse(respondedAt).toLocal().toString().split('.')[0]}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldWorkspace(
      selectedPage: 'Inbox',
      onItemSelected: (page) {},
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: const BoxDecoration(
              color: Color(0xFF255DE1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Text(
              'Inbox',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invitations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (error.isNotEmpty)
                    Center(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else if (invitations.isEmpty)
                    const Center(
                      child: Text(
                        'No invitations',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: invitations.length,
                        itemBuilder: (context, index) {
                          final invitation = invitations[index];
                          final project = invitation['project'];
                          final sender = invitation['sender'];
                          final status = invitation['status'];
                          final recipient = invitation['recipient'];
                          final respondedAt = invitation['responded_at'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          project['name'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _buildStatusChip(status, recipient, respondedAt),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (status == 'pending') ...[
                                    Text(
                                      'From: ${sender['full_name']}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      project['description'],
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ] else ...[
                                    Text(
                                      'From: ${sender['full_name']}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (context) {
                                        print('Debug - Comparing IDs:');
                                        print('Debug - Current User ID: $currentUserId');
                                        print('Debug - Recipient ID: ${recipient['id']}');
                                        print('Debug - Are they equal? ${currentUserId == recipient['id'].toString()}');
                                        
                                        return Text(
                                          currentUserId == recipient['id'].toString()
                                              ? 'You ${status == 'accepted' ? 'accepted' : 'rejected'} the invitation'
                                              : '${recipient['full_name']} ${status == 'accepted' ? 'accepted' : 'rejected'} the invitation',
                                          style: TextStyle(
                                            color: status == 'accepted' ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }
                                    ),
                                    if (respondedAt != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'on ${DateTime.parse(respondedAt).toLocal().toString().split('.')[0]}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 16),
                                  if (status == 'pending')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => respondToInvitation(
                                            invitation['id'],
                                            'reject',
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Reject'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => respondToInvitation(
                                            invitation['id'],
                                            'accept',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text('Accept'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 