import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_it/share_it.dart';

import 'QuoteProvider.dart';

class LikedQuotesPage extends StatelessWidget {
  const LikedQuotesPage({super.key});

  static const appLink =
      '\n\n\n  Please download the app for more quotes like this \n' 'https://play.google.com/store/apps/details?id=com.titus.wiceq.wiceq';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Favorite Quotes'),
      ),
      body: Stack(children: [
        AnimatedContainer(
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          decoration:const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("asset/bg-wallpepper.jpeg"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Consumer<QuoteProvider>(
          builder: (context, quoteProvider, child) {
            if (quoteProvider.favorites.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 10,
                      color: Colors.green,
                    ),
                    Text("No Like quote", style: TextStyle(color: Colors.white),)
                  ],
                ),
              );
            } else {
              return ListView.builder(
                itemCount: quoteProvider.favorites.length,
                itemBuilder: (context, index) {
                  final quote = quoteProvider.favorites[index];

                  final quoteText = quote.text;
                  final author = quote.author;

                  void share() {
                    final shareText =
                        '"$quoteText" - $author $appLink';
                    ShareIt.text(
                      content: shareText,
                      androidSheetTitle: 'Share Quote',
                    );
                  }

                  return Card(
                    color: Colors.white.withValues(alpha: 0.45),
                    child: ListTile(
                      title: Text(quote.text,  textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1.6,
                          letterSpacing: 0.1,
                        )),
                      subtitle: Column(
                        children: [
                          const SizedBox(height: 10),
                          const Divider(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text('Author: ${quote.author}'
                              ,style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                          const Divider(),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red,),
                                onPressed: () {
                                  quoteProvider.removeFavorite(quote);
                                },
                              ),

                              IconButton(
                                onPressed: share,
                                icon: const Icon(Icons.share),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ]),
    );
  }
}
