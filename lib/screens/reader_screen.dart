import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../providers/app_provider.dart';
import '../services/user_data_service.dart';
import '../widgets/reader/reader_card.dart';

class ReaderScreen extends StatefulWidget {
  final String bookId;
  const ReaderScreen({super.key, required this.bookId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  List<String> _chunks = [];
  bool _loading = true;
  bool _fetchError = false;
  int _startIndex = 0;
  int _currentIndex = 0;
  late PageController _pageController;
  Timer? _debounceTimer;

  Book? get _book => getBookById(widget.bookId);
  String? get _userId {
    try {
      return supabase.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadReader();
  }

  Future<void> _loadReader() async {
    final book = _book;
    if (book == null || !book.hasChunks) {
      setState(() => _loading = false);
      return;
    }

    // Load cached progress
    int savedIndex = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedIndex = prefs.getInt('progress_${widget.bookId}') ?? 0;
    } catch (_) {}

    // Fetch from Supabase if authenticated
    if (_userId != null) {
      try {
        final res = await supabase
            .from('progress')
            .select('chunk_index')
            .eq('user_id', _userId!)
            .eq('book_id', widget.bookId)
            .maybeSingle();
        if (res != null) savedIndex = res['chunk_index'] as int;
      } catch (_) {}
    }

    // Fetch chunks from Supabase Storage
    try {
      final url = dotenv.env['BOOKS_BUCKET_URL'] ?? '';
      if (url.isEmpty) throw Exception('BOOKS_BUCKET_URL not set');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('fetch failed');
      final data = jsonDecode(response.body) as List;
      final chunks = data.map((e) => e['text'] as String).toList();

      if (mounted) {
        setState(() {
          _chunks = chunks;
          _startIndex = savedIndex.clamp(0, chunks.length - 1);
          _currentIndex = _startIndex;
          _loading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_startIndex);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _fetchError = true; });
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('progress_${widget.bookId}', index);
      } catch (_) {}
      if (_userId != null) {
        try {
          await UserDataService.syncProgress(_userId!, widget.bookId, index);
          await UserDataService.markReadToday(_userId!);
        } catch (_) {}
      }
    });
  }

  void _share(String text) {
    Share.share('$text\n\n— Read on Scroll Books');
  }

  void _goBack(BuildContext context) {
    context.go('/app/library');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;

    if (book == null) {
      return Scaffold(
        backgroundColor: AppTheme.page,
        body: const Center(child: Text('Book not found.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => _goBack(context),
        ),
        title: Text(
          book.title,
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildBody(book),
    );
  }

  Widget _buildBody(Book book) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fetchError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Couldn't load book", style: TextStyle(color: AppTheme.pewter)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() { _loading = true; _fetchError = false; });
                _loadReader();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!book.hasChunks || _chunks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Coming Soon',
              style: TextStyle(
                color: AppTheme.fog,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              book.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Full text arriving soon.',
              style: TextStyle(color: AppTheme.tobacco, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final style = Provider.of<AppProvider>(context).readingStyle;
    final isHorizontal = style == 'horizontal';

    final pageView = PageView.builder(
      controller: _pageController,
      scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
      itemCount: _chunks.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (_, index) => ReaderCard(
        text: _chunks[index],
        chunkIndex: index,
        totalChunks: _chunks.length,
      ),
    );

    return Stack(
      children: [
        pageView,
        if (isHorizontal)
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.share_outlined),
            color: AppTheme.pewter,
            onPressed: () => _share(_chunks[_currentIndex]),
          ),
        ),
      ],
    );
  }
}
