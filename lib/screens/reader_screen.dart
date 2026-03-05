import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/supabase_client.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../providers/app_provider.dart';
import '../services/user_data_service.dart';
import '../utils/share_passage_image.dart';
import '../widgets/reader/passage_action_overlay.dart';
import '../widgets/reader/passage_share_card.dart';

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
  bool _showShareHint = false;
  bool _overlayActive = false;
  int _startIndex = 0;
  late PageController _pageController;
  Timer? _debounceTimer;
  Timer? _hintTimer;

  // Share card state
  final _passageShareCardKey = GlobalKey();
  String _shareCardText = '';
  String _shareCardTitle = '';
  String _shareCardAuthor = '';
  String _shareCardPageLabel = '';

  Book? get _book => getBookById(widget.bookId);
  String? get _userId {
    try {
      return supabase.auth.currentUser?.id;
    } catch (e, st) {
      debugPrint('_userId error: $e\n$st');
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
    } catch (e, st) {
      debugPrint('Load cached progress error: $e\n$st');
    }

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
      } catch (e, st) {
        debugPrint('Fetch remote progress error: $e\n$st');
      }
    }

    // Fetch chunks from Supabase Storage
    try {
      final baseUrl = dotenv.env['BOOKS_BUCKET_BASE_URL'] ?? '';
      if (baseUrl.isEmpty) throw Exception('BOOKS_BUCKET_BASE_URL not set');
      final url = '$baseUrl/${widget.bookId}.json';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('fetch failed');
      final data = jsonDecode(response.body) as List;
      final chunks = data.map((e) => e['text'] as String).toList();

      if (mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.setBookTotalChunks(widget.bookId, chunks.length);
        provider.setLastReadBook(widget.bookId);
        setState(() {
          _chunks = chunks;
          _startIndex = savedIndex.clamp(0, chunks.length - 1);
          _loading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_startIndex);
          }
          try {
            final prefs = await SharedPreferences.getInstance();
            final shown = prefs.getBool('share_hint_shown') ?? false;
            if (!shown && mounted) {
              setState(() => _showShareHint = true);
              await prefs.setBool('share_hint_shown', true);
              _hintTimer = Timer(const Duration(seconds: 3), () {
                if (mounted) setState(() => _showShareHint = false);
              });
            }
          } catch (e, st) {
            debugPrint('Share hint pref error: $e\n$st');
          }
        });
      }
    } catch (e, st) {
      debugPrint('Fetch chunks error: $e\n$st');
      if (mounted) setState(() { _loading = false; _fetchError = true; });
    }
  }

  void _onPageChanged(int index) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (mounted) {
      Provider.of<AppProvider>(context, listen: false)
          .incrementPassagesRead(today);
      _hintTimer?.cancel();
      setState(() => _showShareHint = false);
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('progress_${widget.bookId}', index);
      } catch (e, st) {
        debugPrint('Save local progress error: $e\n$st');
      }
      if (_userId != null) {
        try {
          await UserDataService.syncProgress(_userId!, widget.bookId, index);
          await UserDataService.markReadToday(_userId!);
        } catch (e, st) {
          debugPrint('Sync remote progress error: $e\n$st');
        }
      }
    });
  }

  Future<void> _shareAsImage(String text, int chunkIndex) async {
    final book = _book;
    if (book == null) return;

    final page = chunkIndex + 1;
    final pct = _chunks.isNotEmpty
        ? ((chunkIndex + 1) / _chunks.length * 100).round()
        : 0;

    setState(() {
      _shareCardText = text;
      _shareCardTitle = book.title;
      _shareCardAuthor = book.author;
      _shareCardPageLabel = 'p. $page · $pct%';
    });

    // Wait for the share card to rebuild with new content
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await sharePassageImage(
          repaintKey: _passageShareCardKey,
          bookTitle: book.title,
          author: book.author,
        );
      } catch (e, st) {
        debugPrint('Share passage error: $e\n$st');
      }
    });
  }

  Future<void> _savePassage(String text, int chunkIndex) async {
    final userId = _userId;
    if (userId == null) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.savePassage(userId, widget.bookId, chunkIndex, text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passage saved', style: GoogleFonts.nunito()),
          backgroundColor: AppTheme.ink,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _goBack(BuildContext context) {
    context.go('/app/library');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _debounceTimer?.cancel();
    _hintTimer?.cancel();
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
          style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildBody(book),
    );
  }

  Widget _wrapWithHint(Widget child) {
    return Stack(
      children: [
        child,
        AnimatedOpacity(
          opacity: _showShareHint ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.ink.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Hold any passage to share or save it',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppTheme.surface,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Hidden share card for PNG generation
        Positioned(
          left: -1000,
          top: -1000,
          child: RepaintBoundary(
            key: _passageShareCardKey,
            child: PassageShareCard(
              passageText: _shareCardText,
              bookTitle: _shareCardTitle,
              author: _shareCardAuthor,
              pageLabel: _shareCardPageLabel,
            ),
          ),
        ),
      ],
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
              style: GoogleFonts.lora(
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

    final provider = Provider.of<AppProvider>(context);
    final style = provider.readingStyle;
    final isHorizontal = style == 'horizontal';

    final pageView = PageView.builder(
      controller: _pageController,
      scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
      physics: _overlayActive ? const NeverScrollableScrollPhysics() : null,
      itemCount: _chunks.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (_, index) => PassageActionOverlay(
        text: _chunks[index],
        chunkIndex: index,
        totalChunks: _chunks.length,
        bookId: widget.bookId,
        isSaved: provider.isPassageSaved(widget.bookId, index),
        onShare: _shareAsImage,
        onSave: _savePassage,
        onActionsVisibleChanged: (visible) {
          if (mounted) setState(() => _overlayActive = visible);
        },
      ),
    );

    if (!isHorizontal) return _wrapWithHint(pageView);

    return _wrapWithHint(Stack(
      children: [
        pageView,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _overlayActive,
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
        ),
      ],
    ));
  }
}
