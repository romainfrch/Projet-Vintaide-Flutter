// @dart=3.3
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:web/web.dart' as web;

import 'session.dart';
import 'widgets/vintaide_app_bar.dart';

// ─── Interop JS pour TensorFlow.js / MobileNet ────────────────────────────────

@JS('mobilenet.load')
external JSPromise _mobilenetLoad();

extension type _MobileNet(JSObject _) implements JSObject {
  @JS('classify')
  external JSPromise classify(JSObject imageElement);
}

extension type _Prediction(JSObject _) implements JSObject {
  @JS('className')
  external String get className;

  @JS('probability')
  external double get probability;
}

// ─── Mapping ImageNet → catégories Vintaide ───────────────────────────────────

const Map<String, List<String>> _imageNetToCategory = {
  'Pantalon': [
    'jean', 'jeans', 'denim', 'trousers', 'pants', 'chino', 'cargo',
    'leggings', 'sweatpants', 'breeches', 'jodhpurs',
  ],
  'Short': [
    'shorts', 'bermuda', 'swim brief', 'swimming trunks',
  ],
  'Haut': [
    'jersey', 't-shirt', 'tee', 'shirt', 'sweatshirt', 'pullover',
    'hoody', 'hoodie', 'cardigan', 'sweater', 'jumper', 'blouse',
    'jacket', 'coat', 'overcoat', 'trench coat', 'windbreaker',
    'anorak', 'parka', 'raincoat', 'dress', 'robe', 'kimono',
    'polo', 'vest', 'tank top', 'stole', 'cloak', 'cape',
    'blazer', 'suit',
  ],
  'Chaussures': [
    'shoe', 'sneaker', 'boot', 'sandal', 'loafer', 'clog',
    'running shoe', 'gym shoe', 'athletic shoe', 'tennis shoe',
    'moccasin', 'flip-flop', 'thong', 'slipper', 'pump',
    'high heel', 'stiletto', 'oxford', 'platform shoe',
  ],
  'Accessoires': [
    'cap', 'hat', 'bonnet', 'beret', 'sombrero', 'mortarboard',
    'cowboy hat', 'beanie', 'scarf', 'muffler', 'belt',
    'handbag', 'purse', 'backpack', 'wallet', 'watch',
    'sunglasses', 'necklace', 'bracelet', 'ring', 'earring',
    'bow tie', 'necktie', 'tie',
  ],
};

// ─── Page ─────────────────────────────────────────────────────────────────────

class AddClothingPage extends StatefulWidget {
  const AddClothingPage({super.key});

  @override
  State<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends State<AddClothingPage> {
  static const List<String> _categories = [
    'Haut', 'Pantalon', 'Short', 'Chaussures', 'Accessoires', 'Autre',
  ];

  final _titleCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  Uint8List? _finalBytes;
  String? _finalBase64;
  String _fileName = '';

  String _categorie = 'Autre';
  bool _saving = false;
  bool _analyzingImage = false;

  // Modèle MobileNet mis en cache pour ne le charger qu'une seule fois
  _MobileNet? _mobilenet;

  String get _login => Session.currentLogin ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_login.isEmpty) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
    });
    // Préchargement silencieux du modèle dès l'ouverture de la page
    _preloadModel();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _sizeCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ─── 1. Préchargement MobileNet ─────────────────────────────────────────────
  Future<void> _preloadModel() async {
    try {
      final model = await _mobilenetLoad().toDart;
      _mobilenet = model as _MobileNet;
      debugPrint('[MobileNet] Modèle chargé ✅');
    } catch (e) {
      debugPrint('[MobileNet] Échec du préchargement : $e');
    }
  }

  // ─── 2. Analyse visuelle avec MobileNet ─────────────────────────────────────
  Future<String> _analyzeWithMobileNet(String base64Jpeg) async {
    try {
      _mobilenet ??= await _mobilenetLoad().toDart as _MobileNet;

      // Création d'un élément <img> temporaire dans le DOM
      final imgEl = web.HTMLImageElement();
      imgEl.src = 'data:image/jpeg;base64,$base64Jpeg';
      imgEl.width = 224;
      imgEl.height = 224;
      imgEl.style.display = 'none';
      web.document.body!.append(imgEl);

      // Attente que l'image soit chargée
      await imgEl.onLoad.first;

      // Inférence
      final rawPredictions = await _mobilenet!.classify(imgEl).toDart;
      imgEl.remove();

      // Conversion JSArray → liste Dart
      final preds = <_Prediction>[];
      final jsArray = rawPredictions as JSArray;
      for (var i = 0; i < jsArray.length; i++) {
        preds.add(jsArray[i] as _Prediction);
      }

      // Mapping vers une catégorie Vintaide
      for (final pred in preds) {
        final labelLower = pred.className.toLowerCase();
        debugPrint(
          '[MobileNet] ${pred.className} — ${(pred.probability * 100).toStringAsFixed(1)}%',
        );

        for (final entry in _imageNetToCategory.entries) {
          if (entry.value.any((kw) => labelLower.contains(kw))) {
            debugPrint('[MobileNet] → Catégorie : ${entry.key}');
            return entry.key;
          }
        }
      }

      debugPrint('[MobileNet] Aucun mapping → fallback règles textuelles.');
      return _suggestByRules();
    } catch (e) {
      debugPrint('[MobileNet] Erreur : $e');
      return _suggestByRules();
    }
  }

  // ─── 3. Fallback règles textuelles ──────────────────────────────────────────
  String _suggestByRules() {
    final text =
        ('${_titleCtrl.text} ${_brandCtrl.text} $_fileName').toLowerCase();
    bool has(List<String> kws) => kws.any((k) => text.contains(k));

    if (has(['shoe', 'sneaker', 'boot', 'chauss', 'basket', 'dunk', 'air max'])) {
      return 'Chaussures';
    }
    if (has(['pantalon', 'jean', 'denim', 'pants', 'trouser', 'cargo', 'chino'])) {
      return 'Pantalon';
    }
    if (has(['short', 'bermuda'])) return 'Short';
    if (has([
      'tshirt', 't-shirt', 'tee', 'shirt', 'chemise',
      'pull', 'sweat', 'hoodie', 'veste', 'jacket',
    ])) return 'Haut';
    if (has(['cap', 'casquette', 'hat', 'belt', 'ceinture', 'bag', 'sac', 'watch', 'montre'])) {
      return 'Accessoires';
    }
    return 'Autre';
  }

  // ─── 4. Sélection + compression + analyse ───────────────────────────────────
  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;

    final file = res.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      _snack('Impossible de lire le fichier.');
      return;
    }

    setState(() {
      _fileName = file.name;
      _finalBytes = null;
      _finalBase64 = null;
      _categorie = 'Autre';
    });

    final compressed = _compressToJpeg(bytes, maxSide: 512, quality: 75);
    if (compressed == null) {
      _snack('Image invalide ou non supportée.');
      return;
    }

    final approxBase64Size = (compressed.length * 4 / 3).round();
    if (approxBase64Size > 900000) {
      _snack('Image trop lourde. Prends une image plus petite.');
      return;
    }

    final b64 = base64Encode(compressed);

    setState(() {
      _finalBytes = compressed;
      _finalBase64 = b64;
      _analyzingImage = true;
    });

    _snack('Image importée ✅ — Analyse en cours…');

    final suggested = await _analyzeWithMobileNet(b64);

    if (mounted) {
      setState(() {
        _categorie = suggested;
        _analyzingImage = false;
      });
      _snack('Catégorie détectée : $suggested ✅');
    }
  }

  Uint8List? _compressToJpeg(
    Uint8List input, {
    required int maxSide,
    required int quality,
  }) {
    try {
      final decoded = img.decodeImage(input);
      if (decoded == null) return null;
      final resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxSide : null,
        height: decoded.height > decoded.width ? maxSide : null,
        interpolation: img.Interpolation.average,
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (_) {
      return null;
    }
  }

  // ─── 5. Sauvegarde Firestore ─────────────────────────────────────────────────
  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final size = _sizeCtrl.text.trim();
    final brand = _brandCtrl.text.trim();
    final priceStr = _priceCtrl.text.trim();

    if (_finalBase64 == null) {
      _snack("Ajoute une image avant de valider.");
      return;
    }
    if (title.isEmpty || size.isEmpty || brand.isEmpty || priceStr.isEmpty) {
      _snack('Tous les champs doivent être remplis.');
      return;
    }

    final price = double.tryParse(priceStr.replaceAll(',', '.'));
    if (price == null) {
      _snack('Le prix doit être un nombre valide.');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('vetements').add({
        'imageBase64': _finalBase64,
        'title': title,
        'categorie': _categorie,
        'size': size,
        'brand': brand,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _login,
      });
      if (!mounted) return;
      _snack('Vêtement ajouté ✅');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _snack("Erreur lors de l'enregistrement.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── 6. UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF11114E);

    return Scaffold(
      appBar: const VintaideAppBar(showBack: true, iconColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter un vêtement',
              style: TextStyle(
                color: primary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _analyzingImage ? null : _pickImage,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _finalBytes == null
                              ? 'Uploader une image'
                              : "Changer l'image",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_finalBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _finalBytes!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Titre'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _brandCtrl,
                      decoration: const InputDecoration(labelText: 'Marque'),
                    ),
                    const SizedBox(height: 16),

                    // Catégorie — loader pendant l'analyse
                    _analyzingImage
                        ? const TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Catégorie (analyse IA…)',
                              suffixIcon: SizedBox(
                                width: 18,
                                height: 18,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                          )
                        : TextFormField(
                            readOnly: true,
                            initialValue: _categorie,
                            key: ValueKey(_categorie),
                            decoration: InputDecoration(
                              labelText: 'Catégorie détectée',
                              suffixIcon: _finalBase64 != null
                                  ? const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.amber,
                                    )
                                  : null,
                            ),
                          ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _sizeCtrl,
                      decoration: const InputDecoration(labelText: 'Taille'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+([.,]\d{0,2})?$'),
                        ),
                      ],
                      decoration: const InputDecoration(labelText: 'Prix (€)'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_saving || _analyzingImage) ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Valider'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}