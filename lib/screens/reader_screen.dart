import 'package:flutter/material.dart';
class ReaderScreen extends StatelessWidget {
  final String bookId;
  const ReaderScreen({super.key, required this.bookId});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Reader')));
}
