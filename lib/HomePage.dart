import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_it/share_it.dart';
import 'package:wiceq/quotesModel.dart';
import 'package:wiceq/sharedPrefFavList.dart';
import 'CommentsScreen.dart';
import 'CountFormatHelper.dart';
import 'QuoteProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  final ScreenshotController _screenshotController = ScreenshotController();

  // Warm gold palette — feels devotional, premium, editorial
  static const Color _gold = Color(0xFFD4A853);
  static const Color _deepGold = Color(0xFFA87A2E);
  static const Color _cream = Color(0xFFFDF6EC);
  static const Color _darkBrown = Color(0xFF1C1208);

  static const appLink =
      '\n\n\n  Please download the app for more quotes like this \n'
      'https://play.google.com/store/apps/details?id=com.titus.wiceq.wiceq';

  @override
  void initState() {
    super.initState();
    Provider.of<QuoteProvider>(context, listen: false).fetchQuotes();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // ── Format posted date from Firestore Timestamp ──────────────────────────
  String _formatPostedDate(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      // Firestore Timestamp has a .toDate() method
      final DateTime dt = createdAt.toDate();
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  Future<void> _shareCardAsImage() async {
    try {
      EasyLoading.show(status: 'Preparing image...');
      await Future.delayed(const Duration(milliseconds: 100));
      final image = await _screenshotController.capture(
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 200),
      );
      if (image == null) {
        EasyLoading.showError('Failed to capture image');
        return;
      }
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);
      EasyLoading.dismiss();
      await ShareIt.file(
        path: imagePath,
        type: ShareItFileType.image,
        androidSheetTitle: 'Share Quote Card',
      );
      await Future.delayed(const Duration(seconds: 2));
      if (await imageFile.exists()) await imageFile.delete();
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Failed to share: $e');
    }
  }

  void shareAppLink() {
    const String playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.titus.wiceq.wiceq';
    ShareIt.text(
      content:
      '✨ Looking for daily inspiration? Download ikeinspireme now!\n\n$playStoreUrl',
      androidSheetTitle: 'Share ikeinspireme',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _gold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "ikeinspireme",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _gold,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25), width: 1),
              ),
              child: const Icon(Icons.menu_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
      ),

      // ── Drawer ─────────────────────────────────────────────────────────
      drawer: _buildDrawer(),

      // ── Body ───────────────────────────────────────────────────────────
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("asset/bg-wallpepper.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Layered dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.65),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Quotes Feed ──────────────────────────────────────────────
          Consumer<QuoteProvider>(
            builder: (context, quoteProvider, child) {
              if (quoteProvider.quotes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          const AlwaysStoppedAnimation<Color>(_gold),
                          backgroundColor:
                          Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Loading inspiration...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SafeArea(
                child: PageView.builder(
                  itemCount: quoteProvider.quotes.length,
                  scrollDirection: Axis.vertical,
                  controller: PageController(viewportFraction: 0.88),
                  itemBuilder: (context, index) {
                    final quote = quoteProvider.quotes[index];
                    return _QuoteCard(
                      quote: quote,
                      quoteProvider: quoteProvider,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      formattedDate: _formatPostedDate(quote.createdAt),
                      onShare: () {
                        final shareText =
                            '"${quote.text}" — ${quote.author} $appLink';
                        ShareIt.text(
                          content: shareText,
                          androidSheetTitle: 'Share Quote',
                        );
                      },
                      onComment: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentsScreen(
                              quoteId: quote.id,
                              quoteText: quote.text,
                              author: quote.author,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),

          // Swipe hint at bottom
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.keyboard_arrow_up_rounded,
                      color: Colors.white.withValues(alpha: 0.4), size: 20),
                  Text(
                    'swipe for more',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. About Us bottom sheet ─────────────────────────────────────────
  void _showAboutUs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1208),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD4A853).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A853).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4A853), width: 2),
                image: const DecorationImage(
                  image: AssetImage('asset/ps-card-image.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'ikeinspireme',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'by Pastor Isaac Amankwaah Junior',
              style: TextStyle(
                color: Color(0xFFD4A853),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 20),

            Divider(
              color: const Color(0xFFD4A853).withValues(alpha: 0.2),
              thickness: 1,
            ),

            const SizedBox(height: 16),

            Text(
              '"ikeinspireme is a daily devotional quote app curated by '
                  'Pastor Isaac Amankwaah Junior to encourage, uplift and inspire people '
                  'in their everyday walk with God."',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13.5,
                height: 1.8,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD4A853).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4A853).withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Color(0xFFD4A853),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ── 3. The full rebuilt drawer ────────────────────────────────────────
  Widget _buildDrawer() {
    const Color gold = Color(0xFFD4A853);
    const Color darkBrown = Color(0xFF1C1208);

    return Drawer(
      backgroundColor: darkBrown,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Stack(
            children: [
              // Wallpaper bg
              Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("asset/bg-wallpepper.jpeg"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Dark scrim
              Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [gold, Color(0xFFFAD07A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 28,
                        backgroundImage:
                        AssetImage('asset/ps-card-image.jpeg'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ikeinspireme',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Daily Inspiration',
                              style: TextStyle(
                                color: gold.withValues(alpha: 0.9),
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Menu items ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                const SizedBox(height: 8),

                // Section label
                _drawerSectionLabel('LIBRARY'),

                _buildDrawerItem(
                  icon: Icons.favorite_rounded,
                  label: 'My Favorites',
                  subtitle: 'Quotes you\'ve liked',
                  accent: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const LikedQuotesPage()));
                  },
                ),

                const SizedBox(height: 8),
                _drawerSectionLabel('CONNECT'),

                _buildDrawerItem(
                  icon: Icons.share_rounded,
                  label: 'Share App',
                  subtitle: 'Spread the inspiration',
                  accent: gold,
                  // ✅ Fixed: calls the corrected shareAppLink()
                  onTap: () {
                    Navigator.pop(context);
                    shareAppLink();
                  },
                ),

                // _buildDrawerItem(
                //   icon: Icons.rate_review_rounded,
                //   label: 'Rate Us',
                //   subtitle: 'Love the app? Let us know',
                //   accent: const Color(0xFF4A9EFF),
                //   onTap: () {
                //     Navigator.pop(context);
                //     // Opens Play Store listing
                //     ShareIt.link(
                //       url:
                //       'https://play.google.com/store/apps/details?id=com.titus.wiceq.wiceq',
                //       androidSheetTitle: 'Rate ikeinspireme',
                //     );
                //   },
                // ),

                const SizedBox(height: 8),
                _drawerSectionLabel('INFO'),

                _buildDrawerItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About Us',
                  subtitle: 'The story behind the app',
                  accent: const Color(0xFFB388FF),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutUs(context);
                  },
                ),

                const SizedBox(height: 24),

                // Gold divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(
                    color: gold.withValues(alpha: 0.15),
                    thickness: 1,
                  ),
                ),

                const SizedBox(height: 16),

                // Footer quote
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '"Swipe up to receive\nyour daily inspiration"',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ── Section label helper ─────────────────────────────────────────────
  Widget _drawerSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFFD4A853).withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

// ── Drawer item ──────────────────────────────────────────────────────
  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: accent.withValues(alpha: 0.1),
          highlightColor: accent.withValues(alpha: 0.05),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 14),
                // Label + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Quote Card ────────────────────────────────────────────────────────────────
class _QuoteCard extends StatefulWidget {
  final Quote quote;
  final QuoteProvider quoteProvider;
  final double screenWidth;
  final double screenHeight;
  final String formattedDate;
  final VoidCallback onShare;
  final VoidCallback onComment;

  const _QuoteCard({
    required this.quote,
    required this.quoteProvider,
    required this.screenWidth,
    required this.screenHeight,
    required this.formattedDate,
    required this.onShare,
    required this.onComment,
  });

  @override
  State<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<_QuoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color _gold = Color(0xFFD4A853);
  static const Color _cream = Color(0xFFFDF6EC);

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;
    final qp = widget.quoteProvider;
    final isLiked = qp.isFavorite(quote);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Center(
          child: Container(
            width: widget.screenWidth * 0.9,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              // Warm cream-tinted glass
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _gold.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: _gold.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Top-right warm accent blob
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _gold.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom-left accent
                  Positioned(
                    bottom: -30,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _gold.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Profile + Posted date ──────────────────────
                        Row(
                          children: [
                            // Avatar with gold ring
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [_gold, Color(0xFFFAD07A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const CircleAvatar(
                                radius: 22,
                                backgroundImage:
                                AssetImage('asset/ps-card-image.jpeg'),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ikeinspireme',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (widget.formattedDate.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    // ✅ Posted date shown here
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 10,
                                          color: _gold.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Posted ${widget.formattedDate}',
                                          style: TextStyle(
                                            color: _gold
                                                .withValues(alpha: 0.85),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Decorative quotation mark
                            Text(
                              '\u201C',
                              style: TextStyle(
                                fontSize: 48,
                                color: _gold.withValues(alpha: 0.35),
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Quote text ─────────────────────────────────
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: widget.screenHeight * 0.28,
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              quote.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                height: 1.75,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Gold rule
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                  color: _gold.withValues(alpha: 0.2),
                                  thickness: 1),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: _gold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                  color: _gold.withValues(alpha: 0.2),
                                  thickness: 1),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Author pill ────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 9),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '— ${quote.author}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _gold,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Action buttons ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ActionButton(
                              icon: Icons.share_rounded,
                              label: 'Share',
                              count: null,
                              color: const Color(0xFF4A9EFF),
                              onTap: widget.onShare,
                            ),
                            _LikeButton(
                              isLiked: isLiked,
                              count: FormatHelper.formatLikeCount(
                                  quote.likeCount),
                              onTap: () => qp.toggleLike(quote),
                            ),
                            _ActionButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'Comment',
                              count: FormatHelper.formatLikeCount(
                                  quote.commentCount),
                              color: const Color(0xFFFF9F4A),
                              onTap: widget.onComment,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Action Button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? count;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          if (count != null && count!.isNotEmpty)
            Text(
              count!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Like Button (animated) ────────────────────────────────────────────────────
class _LikeButton extends StatefulWidget {
  final bool isLiked;
  final String count;
  final VoidCallback onTap;

  const _LikeButton({
    required this.isLiked,
    required this.count,
    required this.onTap,
  });

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pulse.forward().then((_) => _pulse.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color =
    widget.isLiked ? Colors.redAccent : Colors.white.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isLiked
                    ? Colors.red.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isLiked
                      ? Colors.red.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                widget.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: color,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.count,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.isLiked ? 'Liked' : 'Like',
            style: TextStyle(
              color: widget.isLiked
                  ? Colors.redAccent.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
