import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../camera/models/photo_model.dart';
import '../../camera/utils/db_helper.dart';
import '../../utils/app_bar.dart';
import '../cubit/counter_cubit.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper(dbName: 'photo_management.db');
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final photoMaps = await _databaseHelper.query(
        'photos',
        orderBy: 'taken_date DESC',
      );

      final photos = photoMaps.map((map) => Photo.fromMap(map)).toList();

      if (mounted) {
        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading photos: $e');
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
          ? const Center(
              child: Text(
                'No photos found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2.0,
                mainAxisSpacing: 2.0,
                childAspectRatio: 1.0,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return Image.file(
                  File(photo.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
