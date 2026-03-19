import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'widgets/vintaide_app_bar.dart';

class BuyPage extends StatelessWidget {
  const BuyPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF11114E);

    return Scaffold(
      appBar: const VintaideAppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acheter',
              style: TextStyle(
                color: primary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('vetements').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Erreur de chargement.'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(child: Text('Aucun vêtement disponible.'));
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final title = (data['title'] ?? '').toString();
                      final size = (data['size'] ?? '').toString();
                      final imageUrl = (data['imageUrl'] ?? '').toString().trim();
                      final imageBase64 = (data['imageBase64'] ?? '').toString().trim();
                      final categorie = (data['categorie'] ?? '').toString().trim();

                      final priceRaw = data['price'];
                      final price = (priceRaw is num) ? priceRaw.toDouble() : 0.0;

                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/detail',
                            arguments: doc.id,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: primary.withOpacity(0.25)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _ThumbMixed(imageUrl: imageUrl, imageBase64: imageBase64),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title.isEmpty ? 'Sans titre' : title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      categorie.isEmpty
                                          ? 'Catégorie : -'
                                          : 'Catégorie : $categorie',
                                      style: TextStyle(
                                        color: primary.withOpacity(0.75),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Taille : ${size.isEmpty ? '-' : size}',
                                      style: TextStyle(
                                        color: primary.withOpacity(0.85),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Prix : ${price.toStringAsFixed(2)} €',
                                      style: TextStyle(
                                        color: primary.withOpacity(0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: primary.withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbMixed extends StatelessWidget {
  final String imageUrl;
  final String imageBase64;

  const _ThumbMixed({
    required this.imageUrl,
    required this.imageBase64,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF11114E);

    Widget placeholder() => Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primary.withOpacity(0.18)),
          ),
          child: Center(
            child: Icon(
              Icons.image_outlined,
              color: primary.withOpacity(0.7),
            ),
          ),
        );

    // 1) Priorité: Base64
    if (imageBase64.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(imageBase64);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            bytes,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder(),
          ),
        );
      } catch (_) {
        // Si base64 invalide, on tombe sur URL
      }
    }

    // 2) Fallback: URL
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      ),
    );
  }
}
