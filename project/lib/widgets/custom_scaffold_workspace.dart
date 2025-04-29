import 'package:flutter/material.dart';
import 'package:project/dashboard.dart';

class CustomScaffoldWorkspace extends StatefulWidget {
  final String selectedPage;
  final Function(String) onItemSelected;
  final Widget body;

  const CustomScaffoldWorkspace({
    super.key,
    required this.selectedPage,
    required this.onItemSelected,
    required this.body,
  });

  @override
  CustomScaffoldWorkspaceState createState() => CustomScaffoldWorkspaceState();
}

class CustomScaffoldWorkspaceState extends State<CustomScaffoldWorkspace> {
  List<String> workspacePages = ['Work', 'Goals', 'Task List'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFFEFEFF4),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Title
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'NeoNote',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF255DE1),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    // Main Navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _HoverSidebarItem(
                        icon: Icons.home,
                        label: 'Home',
                        isSelected: widget.selectedPage == 'Home',
                        onTap: () => widget.onItemSelected('Home'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _HoverSidebarItem(
                        icon: Icons.inbox,
                        label: 'Inbox',
                        isSelected: widget.selectedPage == 'Inbox',
                        onTap: () => widget.onItemSelected('Inbox'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _HoverSidebarItem(
                        icon: Icons.person,
                        label: 'Switch to Personal',
                        isSelected: false,
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const DashboardScreen()),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _HoverSidebarItem(
                        icon: Icons.chat,
                        label: 'Chat',
                        isSelected: widget.selectedPage == 'Chat',
                        onTap: () => widget.onItemSelected('Chat'),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // WorkSpace Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Workspace',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF255DE1),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Color(0xFF255DE1)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                            onPressed: () => _showAddWorkspaceDialog(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Display workspace pages
                    for (var page in workspacePages)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _HoverSidebarItem(
                          icon: page == 'Work' ? Icons.work :
                                page == 'Goals' ? Icons.flag :
                                Icons.task_alt,
                          label: page,
                          isSelected: widget.selectedPage == page,
                          onTap: () => widget.onItemSelected(page),
                        ),
                      ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Utilities
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _HoverSidebarItem(
                        icon: Icons.calendar_today,
                        label: 'Calendar',
                        isSelected: widget.selectedPage == 'Calendar',
                        onTap: () => widget.onItemSelected('Calendar'),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _HoverSidebarItem(
                        icon: Icons.delete,
                        label: 'Bin',
                        isSelected: widget.selectedPage == 'Bin',
                        onTap: () => widget.onItemSelected('Bin'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Invite Members Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invitation feature coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.group),
                        label: const Text('Invite Members'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF255DE1),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          // Main Content
          Expanded(
            flex: 4,
            child: widget.body,
          ),
        ],
      ),
    );
  }

  // Show dialog to add a new workspace item
  void _showAddWorkspaceDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Workspace Item'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter item name',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF255DE1)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  addWorkspaceItem(controller.text);
                  Navigator.of(dialogContext).pop(); // Close the dialog
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF255DE1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void addWorkspaceItem(String itemName) {
    if (itemName.isNotEmpty && !workspacePages.contains(itemName)) {
      setState(() {
        workspacePages.add(itemName);
      });
    }
  }
}

class _HoverSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _HoverSidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  _HoverSidebarItemState createState() => _HoverSidebarItemState();
}

class _HoverSidebarItemState extends State<_HoverSidebarItem> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _translateAnimation = Tween<double>(begin: 0, end: -3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isHovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(10),
              boxShadow: _getShadow(),
              border: _getBorder(),
            ),
            transform: Matrix4.translationValues(0, _translateAnimation.value, 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(10),
                hoverColor: Colors.transparent,
                splashColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                highlightColor: const Color(0xFFE3F2FD).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Icon(
                          widget.icon,
                          color: _getIconColor(),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: _getTextColor(),
                              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 16,
                              letterSpacing: widget.isSelected ? 0.3 : 0,
                              shadows: _isHovering || widget.isSelected ? [
                                Shadow(
                                  color: const Color(0xFF255DE1).withOpacity(0.3),
                                  blurRadius: 2.0,
                                  offset: const Offset(0, 1),
                                ),
                              ] : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.isSelected) {
      return const Color(0xFFE3F2FD);
    } else if (_isHovering) {
      return const Color(0xFFF5F5F5);
    } else {
      return Colors.transparent;
    }
  }

  Color _getIconColor() {
    if (widget.isSelected) {
      return const Color(0xFF255DE1);
    } else if (_isHovering) {
      return const Color(0xFF255DE1).withOpacity(0.8);
    } else {
      return Colors.black54;
    }
  }

  Color _getTextColor() {
    if (widget.isSelected) {
      return const Color(0xFF255DE1);
    } else if (_isHovering) {
      return const Color(0xFF255DE1).withOpacity(0.8);
    } else {
      return Colors.black87;
    }
  }

  List<BoxShadow>? _getShadow() {
    if (widget.isSelected || _isHovering) {
      return [
        BoxShadow(
          color: const Color(0xFF255DE1).withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return null;
  }

  Border? _getBorder() {
    if (widget.isSelected) {
      return Border(
        left: BorderSide(
          color: const Color(0xFF255DE1),
          width: 3,
        ),
      );
    }
    return null;
  }
}
