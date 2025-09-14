import 'package:flutter/material.dart';

import 'package:photo_management_app/editor/editor/plugins/emoji_picker_flutter/emoji_picker_flutter.dart';

/// Search Button Widget
class SearchButton extends StatelessWidget {
  /// Constructor
  const SearchButton(this.config, this.showSearchView, this.buttonIconColor,
      {super.key});

  /// Config
  final Config config;

  /// Show search view callback
  final VoidCallback showSearchView;

  /// Button icon color
  final Color buttonIconColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: showSearchView,
      icon: config.customSearchIcon ??
          Icon(
            Icons.search,
            color: buttonIconColor,
          ),
    );
  }
}
