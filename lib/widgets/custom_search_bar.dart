import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final bool isCollapsed;
  final Function(String) onSearch;

  const CustomSearchBar({
    super.key,
    required this.isCollapsed,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCollapsed ? Colors.white.withValues(alpha: 230) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onSubmitted: onSearch,
        decoration: InputDecoration(
          hintText: 'Search events, organizations...',
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
