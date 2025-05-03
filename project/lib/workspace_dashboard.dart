import 'package:flutter/material.dart';
import 'package:project/widgets/custom_scaffold_workspace.dart';
import 'package:project/work_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:project/services/local_storage.dart';
import 'package:project/project_detail_page.dart'; // Import ProjectDetailPage

class WorkspaceDashboardScreen extends StatefulWidget {
  const WorkspaceDashboardScreen({super.key});

  @override
  _WorkspaceDashboardScreenState createState() =>
      _WorkspaceDashboardScreenState();
}

class _WorkspaceDashboardScreenState extends State<WorkspaceDashboardScreen> {
  String _selectedPage = "Home";
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _overallTeamMembers = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldWorkspace(
      selectedPage: _selectedPage,
      onItemSelected: (page) {
        if (page == 'Work') {
          // Navigate to the Work page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WorkPage()),
          );
        } else {
          setState(() {
            _selectedPage = page;
          });
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Container(
            color: const Color.fromARGB(255, 37, 93, 225),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(), // This pushes the text to the center
                const Text(
                  'Workspace Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(), // This ensures the text stays centered
                // Removed Settings Icon Button
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RefreshIndicator( // Added RefreshIndicator
                onRefresh: _fetchDashboardData,
                child: SingleChildScrollView( // Wrap content in SingleChildScrollView
                  physics: const AlwaysScrollableScrollPhysics(), // Ensure scrollability for RefreshIndicator
                  child: Column( // Add Column here
                  crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left
                  children: [
                    const Center( // Center the Welcome text
                      child: Text(
                        'Welcome to Workspace',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center( // Center the description text
                      child: Text(
                        'Collaborate with your team and manage projects efficiently.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Recent Projects Section
                    const Text(
                      'Recent Projects', // Updated title for clarity
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_error.isNotEmpty)
                      Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                    else if (_projects.isEmpty)
                      const Center(child: Text('No projects found.'))
                    else
                      _buildProjectsGrid(),

                    const SizedBox(height: 32),
                    // Team Members Section
                    const Text(
                      'Overall Team Members', // Updated title for clarity
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()) // Show loader here too initially
                    else if (_error.isNotEmpty)
                      Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red))) // Error can affect both
                    else if (_overallTeamMembers.isEmpty)
                      const Center(child: Text('No team members found.'))
                    else
                      _buildTeamMembersList(),
                  ],
                ),
                ), // Close Column
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        // Assuming the same endpoint returns all projects for the user
        Uri.parse('http://localhost:8000/api/work/projects/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> fetchedProjects = data.map((project) => {
          'id': project['id'],
          'name': project['name'] ?? 'Unnamed Project',
          'description': project['description'] ?? '',
          'members': project['members'] ?? [],
          'is_hosted_by_user': project['is_hosted_by_user'] ?? false,
          'owner': project['owner'], // Assuming the API provides owner details
        }).toList();

        // --- Process Overall Team Members ---
        final Set<int> memberIds = {}; // Use Set for efficient uniqueness check
        final List<Map<String, dynamic>> uniqueMembers = [];

        for (var project in fetchedProjects) {
          // Add owner if exists and not already added
          if (project['owner'] != null && project['owner']['id'] != null && memberIds.add(project['owner']['id'])) {
            uniqueMembers.add(project['owner']);
          }
          // Add members if exist and not already added
          if (project['members'] is List) {
            for (var member in project['members']) {
              if (member != null && member['id'] != null && memberIds.add(member['id'])) {
                uniqueMembers.add(member);
              }
            }
          }
        }

        setState(() {
          _projects = fetchedProjects;
          _overallTeamMembers = uniqueMembers; // Store unique members
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error connecting to server: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildProjectsGrid() {
    // Display only the first 3 projects, or fewer if less than 3 exist
    final recentProjects = _projects.take(3).toList();
    const double cardAspectRatio = 1.6; // Increased aspect ratio for shorter height

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: cardAspectRatio, // Use adjusted aspect ratio
      ),
      itemCount: recentProjects.length, // Use the actual count (max 3)
      itemBuilder: (context, index) {
        final project = recentProjects[index];
        final members = (project['members'] as List<dynamic>?) ?? [];
        final owner = project['owner'] as Map<String, dynamic>?; // Get owner info if available
        final bool isHostedByUser = project['is_hosted_by_user'] == true;
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProjectDetailPage(
                    projectId: project['id'],
                    title: project['name'],
                    description: project['description'],
                    isHostedByUser: project['is_hosted_by_user'] ?? false,
                  ),
                ),
              ).then((_) => _fetchDashboardData()); // Refresh data when returning
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Reduced padding for card content
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section (similar to ProjectCard)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF255DE1).withOpacity(0.1), // Light purple-ish background
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.folder, // Folder Icon
                          size: 16,
                          color: Color(0xFF255DE1), // Blue color
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            project['name'] ?? 'Unnamed Project',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF255DE1), // Blue color
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description Section
                  Text(
                    project['description'] ?? 'No description provided.',
                    style: TextStyle(
                      fontSize: 12,
                      color: (project['description'] == null || project['description'].isEmpty)
                          ? Colors.grey[400]
                          : Colors.black54,
                    ),
                    maxLines: 2, // Limit description lines
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8), // Add some space instead of Spacer
                  // Team Members Section (for this specific project)
                  if (members.isNotEmpty || owner != null)
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        // Add owner chip if exists
                        if (owner != null)
                          _buildMiniMemberChip(owner['full_name'] ?? 'Owner', isOwner: true),
                        // Add member chips
                        ...members.map((member) {
                          // Avoid duplicating owner if they are also in members list
                          if (owner != null && member['id'] == owner['id']) {
                            return const SizedBox.shrink(); // Don't show owner twice
                          }
                          return _buildMiniMemberChip(member['full_name'] ?? 'Member');
                        }).toList(),
                      ],
                    )
                  else
                    const Text(
                      'No members yet',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  const SizedBox(height: 4), // Small spacing at the bottom
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for mini member chips within the project card
  Widget _buildMiniMemberChip(String name, {bool isOwner = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: (isOwner ? Colors.orange[100] : const Color(0xFF255DE1).withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10, // Smaller font size
          color: (isOwner ? Colors.orange[800] : const Color(0xFF255DE1)),
          fontWeight: isOwner ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTeamMembersList() {
    // This list shows OVERALL members across all projects
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _overallTeamMembers.length, // Use the actual count of unique members
      itemBuilder: (context, index) {
        final member = _overallTeamMembers[index];
        final String fullName = member['full_name'] ?? 'Unknown User';
        final String initials = fullName.isNotEmpty
            ? fullName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
            : 'U';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.primaries[math.Random().nextInt(Colors.primaries.length)], // Use Random color
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(fullName),
          subtitle: Text(member['email'] ?? 'No email'), // Display email or other info if available
          trailing: IconButton(
            icon: const Icon(Icons.message),
            onPressed: () { /* TODO: Implement direct message functionality */ }, // Removed extra closing parenthesis and comma
          ),
        );
      },
    );
  }
}