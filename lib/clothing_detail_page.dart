import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'session.dart';

class ClothingDetailPage extends StatefulWidget {
  const ClothingDetailPage({super.key});

  @override
  State<ClothingDetailPage> createState() => _ClothingDetailPageState();
}

class _ClothingDetailPageState extends State<ClothingDetailPage> {
  bool _adding = false;

  Future<void> _addToCart(String vetementId, Map<String, dynamic> vetement) async {
    final login = Session.currentLogin;

    if (login == null || login.isEmpty) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
      return;
    }

    setState(() => _adding = true);

    try {
      final cartItemRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(login)
          .collection('items')
          .doc(vetementId);

      final payload = <String, dynamic>{
        'vetementId': vetementId,
        'title': (vetement['title'] ?? '').toString(),
        'size': (vetement['size'] ?? '').toString(),
        'brand': (vetement['brand'] ?? '').toString(),
        'categorie': (vetement['categorie'] ?? '').toString(),

        'imageUrl': (vetement['imageUrl'] ?? '').toString(),
        'imageBase64': (vetement['imageBase64'] ?? '').toString(),

        'price': (vetement['price'] is num) ? (vetement['price'] as num).toDouble() : 0.0,
        'quantity': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await cartItemRef.set(payload, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajouté au panier ✅')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l’ajout au panier.')),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF11114E);
    final vetementId = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 76,
        iconTheme: const IconThemeData(color: Colors.white),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final logoW = (constraints.maxWidth * 0.40).clamp(120.0, 220.0);
            return Image.asset(
              'assets/logo.png',
              width: logoW,
              fit: BoxFit.contain,
            );
          },
        ),
      ),
      body: vetementId == null
          ? const Center(child: Text('Aucun vêtement sélectionné.'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('vetements').doc(vetementId).get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Erreur de chargement.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final doc = snapshot.data!;
                if (!doc.exists) {
                  return const Center(child: Text('Vêtement introuvable.'));
                }

                final data = doc.data() as Map<String, dynamic>;
                final title = (data['title'] ?? '').toString();
                final size = (data['size'] ?? '').toString();
                final brand = (data['brand'] ?? '').toString();
                final categorie = (data['categorie'] ?? '').toString();

                final imageUrl = (data['imageUrl'] ?? '').toString().trim();
                final imageBase64 = (data['imageBase64'] ?? '').toString().trim();

                final priceRaw = data['price'];
                final price = (priceRaw is num) ? priceRaw.toDouble() : 0.0;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;

                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Détail',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (!isWide) ...[
                                _squareImageMixed(
                                  imageUrl: imageUrl,
                                  imageBase64: imageBase64,
                                  size: 320,
                                ),
                                const SizedBox(height: 16),
                                _infoBlock(
                                  title: title,
                                  brand: brand,
                                  categorie: categorie,
                                  size: size,
                                  price: price,
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _adding ? null : () => _addToCart(vetementId, data),
                                    child: _adding
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Ajouter au panier'),
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _squareImageMixed(
                                      imageUrl: imageUrl,
                                      imageBase64: imageBase64,
                                      size: 320,
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _infoBlock(
                                            title: title,
                                            brand: brand,
                                            categorie: categorie,
                                            size: size,
                                            price: price,
                                          ),
                                          const SizedBox(height: 18),
                                          SizedBox(
                                            width: 420,
                                            child: ElevatedButton(
                                              onPressed: _adding ? null : () => _addToCart(vetementId, data),
                                              child: _adding
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Text('Ajouter au panier'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _squareImageMixed({
    required String imageUrl,
    required String imageBase64,
    required double size,
  }) {
    const primary = Color(0xFF11114E);

    Widget placeholder() => const Center(
          child: Icon(Icons.image_outlined, color: primary, size: 56),
        );

    // ✅ Base64 prioritaire
    if (imageBase64.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(imageBase64);
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: size,
            height: size,
            color: primary.withOpacity(0.06),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder(),
            ),
          ),
        );
      } catch (_) {
        // fallback URL
      }
    }

    // ✅ URL fallback
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        color: primary.withOpacity(0.06),
        child: (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder(),
              )
            : placeholder(),
      ),
    );
  }

  Widget _infoBlock({
    required String title,
    required String brand,
    required String categorie,
    required String size,
    required double price,
  }) {
    const primary = Color(0xFF11114E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.isEmpty ? 'Sans titre' : title,
          style: const TextStyle(
            color: primary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        _infoRow('Marque', brand),
        _infoRow('Catégorie', categorie),
        _infoRow('Taille', size),
        _infoRow('Prix', '${price.toStringAsFixed(2)} €'),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    const primary = Color(0xFF11114E);
    final v = value.isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: TextStyle(
                color: primary.withOpacity(0.80),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(color: primary.withOpacity(0.88)),
            ),
          ),
        ],
      ),
    );
  }
}
