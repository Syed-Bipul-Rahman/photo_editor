import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';

enum AppBarType { selection, trash, timeline, detail }

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppBarType type;
  final String? title;
  final int selectedCount;
  final bool isAllSelected;
  final VoidCallback? onSelectAll;
  final VoidCallback? onBack;
  final VoidCallback? onCamera;
  final VoidCallback? onSearch;
  final VoidCallback? onMenu;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onMore;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomAppBar({
    Key? key,
    required this.type,
    this.title,
    this.selectedCount = 0,
    this.isAllSelected = false,
    this.onSelectAll,
    this.onBack,
    this.onCamera,
    this.onSearch,
    this.onMenu,
    this.onShare,
    this.onDelete,
    this.onMore,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AppBarType.selection:
        return _buildSelectionAppBar(context);
      case AppBarType.trash:
        return _buildTrashAppBar(context);
      case AppBarType.timeline:
        return _buildTimelineAppBar(context);
      case AppBarType.detail:
        return _buildDetailAppBar(context);
    }
  }

  AppBar _buildSelectionAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? Colors.black,
      elevation: 1,
      leading: Row(
        children: [
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onSelectAll,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade600, width: 2),
                borderRadius: BorderRadius.circular(2),
                color: isAllSelected ? Colors.blue : Colors.transparent,
              ),
              child: isAllSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
      leadingWidth: 60,
      title: Text(
        'Select all',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: foregroundColor ?? Colors.black,
        ),
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$selectedCount Selected',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  AppBar _buildTrashAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.grey.shade600,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: onMenu,
        icon: const Icon(Icons.menu, color: Colors.white),
      ),
      title: Text(
        'Trash',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: foregroundColor ?? Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined, color: Colors.white),
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        IconButton(
          onPressed: onMore,
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ],
    );
  }

  AppBar _buildTimelineAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.grey.shade600,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: onMenu,
        icon: const Icon(Icons.menu, color: Colors.white),
      ),
      title: Text(
        'Timeline',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: foregroundColor ?? Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: onCamera,
          icon: Container(
            padding: const EdgeInsets.all(2),
            // decoration: BoxDecoration(
            //   border: Border.all(color: Colors.white, width: 2),
            //   borderRadius: BorderRadius.circular(4),
            // ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        IconButton(
          onPressed: onSearch,
          icon: const Icon(Icons.search, color: Colors.white),
        ),
        IconButton(
          onPressed: onMore,
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ],
    );
  }

  AppBar _buildDetailAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.grey.shade600,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: onBack ?? () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Text(
        title ?? 'Luna',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: foregroundColor ?? Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: onCamera,
          icon: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        IconButton(
          onPressed: onSearch,
          icon: const Icon(Icons.search, color: Colors.white),
        ),
        IconButton(
          onPressed: onMore,
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Example usage class
class AppBarExample extends StatefulWidget {
  const AppBarExample({Key? key}) : super(key: key);

  @override
  State<AppBarExample> createState() => _AppBarExampleState();
}

class _AppBarExampleState extends State<AppBarExample> {
  AppBarType currentAppBarType = AppBarType.selection;
  int selectedCount = 0;
  bool isAllSelected = false;

  void _switchAppBarType(AppBarType type) {
    setState(() {
      currentAppBarType = type;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      isAllSelected = !isAllSelected;
      selectedCount = isAllSelected ? 10 : 0;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        type: currentAppBarType,
        title: currentAppBarType == AppBarType.detail ? 'Luna' : null,
        selectedCount: selectedCount,
        isAllSelected: isAllSelected,
        onSelectAll: _toggleSelectAll,
        onBack: () => _showSnackBar(AppStrings.backPressed),
        onCamera: () => _showSnackBar(AppStrings.cameraPressed),
        onSearch: () => _showSnackBar(AppStrings.searchPressed),
        onMenu: () => _showSnackBar(AppStrings.menuPressed),
        onShare: () => _showSnackBar(AppStrings.sharePressed),
        onDelete: () => _showSnackBar(AppStrings.deletePressed),
        onMore: () => _showSnackBar(AppStrings.morePressed),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'AppBar Type Switcher',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildAppBarButton('Selection AppBar', AppBarType.selection),
            _buildAppBarButton('Trash AppBar', AppBarType.trash),
            _buildAppBarButton('Timeline AppBar', AppBarType.timeline),
            _buildAppBarButton('Detail AppBar', AppBarType.detail),
            const SizedBox(height: 32),
            if (currentAppBarType == AppBarType.selection) ...[
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedCount = (selectedCount + 1) % 11;
                    isAllSelected = selectedCount == 10;
                  });
                },
                child: Text('Selected: $selectedCount'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarButton(String title, AppBarType type) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 200,
      child: ElevatedButton(
        onPressed: () => _switchAppBarType(type),
        style: ElevatedButton.styleFrom(
          backgroundColor: currentAppBarType == type
              ? Colors.blue
              : Colors.grey,
          foregroundColor: Colors.white,
        ),
        child: Text(title),
      ),
    );
  }
}
