import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../camera/models/photo_model.dart';
import '../../camera/utils/db_helper.dart';
import '../../utils/app_bar.dart';
import '../cubit/counter_cubit.dart';
import 'fullscreen_image_viewer.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: const AlbumView(),
    );
  }
}

class AlbumView extends StatefulWidget {
  const AlbumView({super.key});

  @override
  State<AlbumView> createState() => _AlbumViewState();
}

class _AlbumViewState extends State<AlbumView> {
  late DatabaseHelper _databaseHelper;
  List<Photo> _photos = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitialLoading = true;

  // Pagination parameters
  static const int _pageSize = 50;
  int _currentPage = 0;

  // Scroll controller for infinite scrolling
  late ScrollController _scrollController;

  // Cache for image widgets to improve performance
  final Map<String, Widget> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper(dbName: 'photo_management.db');
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      // Create indexes for better performance
      await _databaseHelper.createPhotoIndexes();

      // Load initial photos
      await _loadPhotos(isInitial: true);
    } catch (e) {
      print('Error initializing database: $e');
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _imageCache.clear();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadPhotos();
      }
    }
  }

  Future<void> _loadPhotos({bool isInitial = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (isInitial) _isInitialLoading = true;
    });

    try {
      final offset = _currentPage * _pageSize;

      final photoMaps = await _databaseHelper.query(
        'photos',
        orderBy: 'taken_date DESC',
        limit: _pageSize,
        offset: offset,
      );

      if (photoMaps.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
          _isInitialLoading = false;
        });
        return;
      }

      final newPhotos = photoMaps.map((map) => Photo.fromMap(map)).toList();

      if (mounted) {
        setState(() {
          if (isInitial) {
            _photos = newPhotos;
          } else {
            _photos.addAll(newPhotos);
          }
          _currentPage++;
          _isLoading = false;
          _isInitialLoading = false;

          // If we got less than pageSize, we've reached the end
          if (newPhotos.length < _pageSize) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoading = false;
        });
      }
      print('Error loading photos: $e');

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshPhotos() async {
    setState(() {
      _photos.clear();
      _currentPage = 0;
      _hasMore = true;
      _imageCache.clear(); // Clear cache on refresh
    });
    await _loadPhotos(isInitial: true);
  }

  Widget _buildCachedImage(Photo photo, int index) {
    // Use cache to avoid rebuilding image widgets
    final cacheKey = '${photo.path}_$index';

    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }

    final imageWidget = Image.file(
      File(photo.path),
      fit: BoxFit.cover,
      // Add memory caching and size optimization
      cacheWidth: 200,
      // Optimize memory usage
      cacheHeight: 200,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;

        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
    );

    // Cache the widget but limit cache size to prevent memory issues
    if (_imageCache.length < 100) {
      _imageCache[cacheKey] = imageWidget;
    }

    return imageWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        type: AppBarType.timeline,
        selectedCount: 5,
        isAllSelected: false,
        onSelectAll: () => print('Select all tapped'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPhotos,
        child: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : _photos.isEmpty && !_hasMore
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No photos found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2.0,
                            mainAxisSpacing: 2.0,
                            childAspectRatio: 1.0,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index >= _photos.length) return null;

                        final photo = _photos[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    FullscreenImageViewer(photo: photo),
                                transitionDuration: const Duration(milliseconds: 300),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'photo_${photo.id}',
                            child: _buildCachedImage(photo, index),
                          ),
                        );
                      }, childCount: _photos.length),
                    ),
                  ),
                  // Loading indicator at the bottom
                  if (_isLoading && !_isInitialLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  // End of list indicator
                  if (!_hasMore && _photos.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'You\'ve reached the end\n${_photos.length} photos loaded',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
