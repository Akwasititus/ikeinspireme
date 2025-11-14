import 'dart:async';
import 'dart:io';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_it/share_it.dart';
import 'package:wiceq/sharedPrefFavList.dart';
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

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    Future.microtask(
        () => Provider.of<QuoteProvider>(context, listen: false).fetchQuotes());
  }

  Future<void> _shareCardAsImage() async {
    try {
      EasyLoading.show(status: 'Preparing image...');

      // Add a small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 100));

      final image = await _screenshotController.capture(
        pixelRatio: 2.0, // Higher quality
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

      // Share the image
      await ShareIt.file(
        path: imagePath,
        type: ShareItFileType.image,
        androidSheetTitle: 'Share Quote Card',
      );

      // Clean up after sharing
      await Future.delayed(const Duration(seconds: 2));
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Failed to share: $e');
      print('Share error: $e');
    }
  }

  static const appLink =
      '\n\n\n  Please download the app for more quotes like this \n'
      'https://play.google.com/store/apps/details?id=com.titus.wiceq.wiceq';

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _copyQuote(String quoteText) {
    Clipboard.setData(ClipboardData(text: quoteText));
    EasyLoading.showSuccess('Quote copied to clipboard');
  }

  void shareAppLink() {
    ShareIt.link(
        androidSheetTitle:
            'Looking for an inspirational quote that will inspire your life? Download this app now',
        url: appLink);
  }

  Widget _buildCleanDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: onTap,
        ),
      ),
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
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.white70],
          ).createShader(bounds),
          child: const Text(
            "ikeinspireme",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white, // Clean solid background
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header
              SizedBox(
                height: 220,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade700, // Single solid color
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('asset/ps-card-image.jpeg'),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "ikeinspireme",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        "Daily Inspiration",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Drawer items
              _buildCleanDrawerItem(
                icon: Icons.favorite_rounded,
                title: 'My Favorites',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const LikedQuotesPage()),
                  );
                },
              ),
              _buildCleanDrawerItem(
                icon: Icons.share_rounded,
                title: 'Share App',
                color: Colors.blueAccent,
                onTap: () {
                  Navigator.pop(context);
                  shareAppLink();
                },
              ),

              const SizedBox(height: 30),

              // Footer note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Swipe up or down to explore quotes",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Animated Background
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("asset/bg-wallpepper.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Content
          Consumer<QuoteProvider>(
            builder: (context, quoteProvider, child) {
              if (quoteProvider.quotes.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:  0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              }

              return SafeArea(
                child: PageView.builder(
                  itemCount: quoteProvider.quotes.length,
                  scrollDirection: Axis.vertical,
                  controller: PageController(viewportFraction: 0.8),
                  itemBuilder: (context, index) {
                    final quote = quoteProvider.quotes[index];
                    final quoteText = quote.text;
                    final author = quote.author;

                    void share() {
                      final shareText = '"$quoteText" - $author $appLink';
                      ShareIt.text(
                        content: shareText,
                        androidSheetTitle: 'Share Quote',
                      );
                    }

                    return Center(
                      child: Container(
                        width: screenWidth * 0.9,
                        height: screenHeight * 0.7,
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Stack(
                            children: [
                              // Your existing card content...
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepPurple.withOpacity(0.5),
                                        Colors.transparent,
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(100),
                                    ),
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(30),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircleAvatar(
                                      radius: 35,
                                      backgroundImage: AssetImage('asset/ps-card-image.jpeg'),
                                    ),
                                    const SizedBox(height: 20),

                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          quoteText,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w300,
                                            color: Colors.white,
                                            height: 1.6,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 25),

                                    Container(
                                      width: 60,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.deepPurple.shade400,
                                            Colors.purple.shade300,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 25,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.deepPurple.shade50,
                                            Colors.purple.shade50,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: Colors.deepPurple.shade100,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        '— $author',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.deepPurple.shade700,
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 30),

                                    // Action buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildModernButton(
                                          icon: Icons.share_rounded,
                                          label: 'Share',
                                          gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                                          onPressed: share,
                                        ),
                                        _buildModernButton(
                                          icon: Icons.content_copy_rounded,
                                          label: 'Copy',
                                          gradient: const LinearGradient(colors: [Colors.green, Colors.lightGreen]),
                                          onPressed: () => _copyQuote(quoteText),
                                        ),
                                        _buildModernButton(
                                          icon: quoteProvider.isFavorite(quote) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          label: quoteProvider.isFavorite(quote) ? 'Saved' : 'Favorite',
                                          gradient: LinearGradient(
                                            colors: quoteProvider.isFavorite(quote)
                                                ? [Colors.red, Colors.pink]
                                                : [Colors.grey.shade400, Colors.grey.shade300],
                                          ),
                                          onPressed: () {
                                            if (quoteProvider.isFavorite(quote)) {
                                              quoteProvider.removeFavorite(quote);
                                            } else {
                                              quoteProvider.addFavorite(quote);
                                            }
                                          },
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
                    );
                  },
                ),
              );

              // return SafeArea(
              //   child: Swiper(
              //     itemCount: quoteProvider.quotes.length,
              //     itemBuilder: (context, index) {
              //       final quote = quoteProvider.quotes[index];
              //       final quoteText = quote.text;
              //       final author = quote.author;
              //
              //       void share() {
              //         final shareText = '"$quoteText" - $author $appLink';
              //         ShareIt.text(
              //           content: shareText,
              //           androidSheetTitle: 'Share Quote',
              //         );
              //       }
              //
              //       return Center(
              //         child: Screenshot(
              //           controller: _screenshotController,
              //           child: Container(
              //             width: screenWidth * 0.9,
              //             height: screenHeight * 0.7,
              //             margin: const EdgeInsets.symmetric(vertical: 20),
              //             decoration: BoxDecoration(
              //               color: Colors.white.withValues(alpha: 0.45),
              //               borderRadius: BorderRadius.circular(30),
              //               boxShadow: [
              //                 BoxShadow(
              //                   color: Colors.black.withOpacity(0.3),
              //                   blurRadius: 30,
              //                   offset: const Offset(0, 15),
              //                   spreadRadius: 5,
              //                 ),
              //               ],
              //             ),
              //             child: ClipRRect(
              //               borderRadius: BorderRadius.circular(30),
              //               child: Stack(
              //                 children: [
              //                   // Decorative top corner
              //                   Positioned(
              //                     top: 0,
              //                     right: 0,
              //                     child: Container(
              //                       width: 100,
              //                       height: 100,
              //                       decoration: BoxDecoration(
              //                         gradient: LinearGradient(
              //                           colors: [
              //                             Colors.deepPurple.withOpacity(0.5),
              //                             Colors.transparent,
              //                           ],
              //                         ),
              //                         borderRadius: const BorderRadius.only(
              //                           bottomLeft: Radius.circular(100),
              //                         ),
              //                       ),
              //                     ),
              //                   ),
              //                   // Main content
              //                   Padding(
              //                     padding: const EdgeInsets.all(30),
              //                     child: Column(
              //                       mainAxisAlignment: MainAxisAlignment.center,
              //                       children: [
              //                         // Quote icon
              //
              //                         const CircleAvatar(
              //                           radius: 35, // adjust the size as needed
              //                           backgroundImage: AssetImage(
              //                               'asset/ps-card-image.jpeg'),
              //                         ),
              //                         // Quote text
              //                         const SizedBox(height: 20),
              //                         Expanded(
              //                           child: SingleChildScrollView(
              //                             child: Text(
              //                               quoteText,
              //                               textAlign: TextAlign.center,
              //                               style: const TextStyle(
              //                                 fontSize: 16,
              //                                 fontWeight: FontWeight.w300,
              //                                 color: Colors.white,
              //                                 height: 1.6,
              //                                 letterSpacing: 0.1,
              //                               ),
              //                             ),
              //                           ),
              //                         ),
              //                         const SizedBox(height: 25),
              //                         // Divider
              //                         Container(
              //                           width: 60,
              //                           height: 3,
              //                           decoration: BoxDecoration(
              //                             gradient: LinearGradient(
              //                               colors: [
              //                                 Colors.deepPurple.shade400,
              //                                 Colors.purple.shade300,
              //                               ],
              //                             ),
              //                             borderRadius:
              //                                 BorderRadius.circular(2),
              //                           ),
              //                         ),
              //                         const SizedBox(height: 20),
              //                         // Author
              //                         Container(
              //                           padding: const EdgeInsets.symmetric(
              //                             horizontal: 25,
              //                             vertical: 12,
              //                           ),
              //                           decoration: BoxDecoration(
              //                             gradient: LinearGradient(
              //                               colors: [
              //                                 Colors.deepPurple.shade50,
              //                                 Colors.purple.shade50,
              //                               ],
              //                             ),
              //                             borderRadius:
              //                                 BorderRadius.circular(25),
              //                             border: Border.all(
              //                               color: Colors.deepPurple.shade100,
              //                               width: 1.5,
              //                             ),
              //                           ),
              //                           child: Text(
              //                             '— $author',
              //                             style: TextStyle(
              //                               fontSize: 12,
              //                               fontWeight: FontWeight.w700,
              //                               color: Colors.deepPurple.shade700,
              //                               fontStyle: FontStyle.italic,
              //                               letterSpacing: 0.5,
              //                             ),
              //                           ),
              //                         ),
              //                         const SizedBox(height: 30),
              //                         // Action buttons
              //                         Row(
              //                           mainAxisAlignment:
              //                               MainAxisAlignment.spaceEvenly,
              //                           children: [
              //                             _buildModernButton(
              //                               icon: Icons.share_rounded,
              //                               label: 'Share',
              //                               gradient: const LinearGradient(
              //                                 colors: [
              //                                   Colors.blue,
              //                                   Colors.blueAccent
              //                                 ],
              //                               ),
              //                               onPressed: share,
              //                             ),
              //                             _buildModernButton(
              //                               icon: Icons.image_rounded,
              //                               label: 'Share Card',
              //                               gradient: const LinearGradient(
              //                                 colors: [
              //                                   Colors.purple,
              //                                   Colors.deepPurple
              //                                 ],
              //                               ),
              //                               onPressed: _shareCardAsImage,
              //                             ),
              //                             _buildModernButton(
              //                               icon: Icons.content_copy_rounded,
              //                               label: 'Copy',
              //                               gradient: const LinearGradient(
              //                                 colors: [
              //                                   Colors.green,
              //                                   Colors.lightGreen
              //                                 ],
              //                               ),
              //                               onPressed: () =>
              //                                   _copyQuote(quoteText),
              //                             ),
              //                             _buildModernButton(
              //                               icon: quoteProvider
              //                                       .isFavorite(quote)
              //                                   ? Icons.favorite_rounded
              //                                   : Icons.favorite_border_rounded,
              //                               label:
              //                                   quoteProvider.isFavorite(quote)
              //                                       ? 'Saved'
              //                                       : 'Favorite',
              //                               gradient: LinearGradient(
              //                                 colors: quoteProvider
              //                                         .isFavorite(quote)
              //                                     ? [Colors.red, Colors.pink]
              //                                     : [
              //                                         Colors.grey.shade400,
              //                                         Colors.grey.shade300
              //                                       ],
              //                               ),
              //                               onPressed: () {
              //                                 if (quoteProvider
              //                                     .isFavorite(quote)) {
              //                                   quoteProvider
              //                                       .removeFavorite(quote);
              //                                 } else {
              //                                   quoteProvider
              //                                       .addFavorite(quote);
              //                                 }
              //                               },
              //                             ),
              //                           ],
              //                         ),
              //                       ],
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           ),
              //         ),
              //       );
              //     },
              //     scrollDirection: Axis.vertical,
              //     loop: true,
              //     autoplay: true,
              //     autoplayDelay: 60000,
              //     duration: 800,
              //     curve: Curves.easeInOut,
              //     scale: 0.9,
              //   ),
              // );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
