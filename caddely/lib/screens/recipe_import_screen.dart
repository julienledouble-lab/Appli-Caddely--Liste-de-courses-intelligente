import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/recipe.dart';
import '../services/recipe_ai_extraction_service.dart';
import '../services/recipe_extraction_service.dart';
import '../theme/app_theme.dart';
import 'recipe_ocr_text_review_screen.dart';
import 'recipe_review_screen.dart';

typedef PickRecipeImages = Future<List<XFile>> Function();

class RecipeImportScreen extends StatefulWidget {
  final RecipeExtractionService? extractionService;
  final RecipeAiExtractionService? aiExtractionService;
  final PickRecipeImages? onPickImages;
  final List<XFile>? initialImages;

  const RecipeImportScreen({
    super.key,
    this.extractionService,
    this.aiExtractionService,
    this.onPickImages,
    this.initialImages,
  });

  @override
  State<RecipeImportScreen> createState() => _RecipeImportScreenState();
}

class _RecipeImportScreenState extends State<RecipeImportScreen> {
  late final RecipeExtractionService _extractionService =
      widget.extractionService ?? RecipeExtractionService();
  late final RecipeAiExtractionService _aiExtractionService =
      widget.aiExtractionService ?? RecipeAiExtractionService();
  late final ImagePicker _imagePicker = ImagePicker();

  List<XFile> _selectedImages = const [];
  bool _isExtracting = false;
  String? _selectionMessage;
  String? _analysisError;
  _RecipeImportMode? _lastMode;

  @override
  void initState() {
    super.initState();
    _selectedImages = widget.initialImages ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = _selectedImages.isNotEmpty;
    final selectedCount = _selectedImages.length;
    final photoLabel = selectedCount > 1 ? 'photos' : 'photo';

    return Scaffold(
      appBar: AppBar(title: const Text('Importer une recette')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          const Text(
            'Ajouter des photos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu peux selectionner une ou plusieurs photos pour une seule recette.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'L\'analyse IA donne de meilleurs resultats sur les captures complexes. L\'analyse locale reste gratuite mais peut demander plus de corrections.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.colorBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasImages ? 'Apercu des photos' : 'Aucune photo selectionnee',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _ImagePreviewGallery(
                  images: _selectedImages,
                  onRemove: _isExtracting ? null : _removeImageAt,
                ),
                const SizedBox(height: 12),
                Text(
                  hasImages
                      ? '$selectedCount $photoLabel selectionnee${selectedCount > 1 ? 's' : ''}'
                      : 'Choisis une ou plusieurs photos ou screenshots de recette avant l\'analyse.',
                  key: const Key('selected-images-count'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.colorTextPrimary,
                  ),
                ),
                if (_selectionMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _selectionMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasImages
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  key: const Key('pick-recipe-images'),
                  onPressed: _isExtracting ? null : _replaceImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(hasImages ? 'Remplacer les photos' : 'Ajouter des photos'),
                ),
                if (hasImages) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('append-recipe-images'),
                    onPressed: _isExtracting ? null : _appendImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Ajouter d\'autres photos'),
                  ),
                ],
              ],
            ),
          ),
          if (hasImages) ...[
            const SizedBox(height: 16),
            Container(
              key: const Key('ai-privacy-note'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.colorBorder),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 16,
                    color: AppTheme.colorTextSecondary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Les images seront envoyees a un service IA pour etre analysees.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.colorTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_isExtracting)
            Container(
              key: const Key('recipe-analysis-loading'),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _loadingLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.colorTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_analysisError != null) ...[
            const SizedBox(height: 12),
            _ImportErrorCard(
              message: _analysisError!,
              onRetryAi: _lastMode == _RecipeImportMode.ai && hasImages
                  ? _extractRecipeWithAi
                  : null,
              onUseLocal: hasImages ? _extractRecipeLocally : null,
              onEnterTextManually: _openManualEntry,
              onUseDemo: hasImages
                  ? () => _openReview(
                        _extractionService.buildDemoRecipe(
                          imagePath: _selectedImages.first.path,
                          imagePaths: _selectedImages.map((entry) => entry.path).toList(),
                        ),
                      )
                  : null,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              key: const Key('analyze-recipe-with-ai'),
              onPressed: hasImages && !_isExtracting ? _extractRecipeWithAi : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Analyser avec IA'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('analyze-recipe-locally'),
              onPressed: hasImages && !_isExtracting ? _extractRecipeLocally : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Analyser gratuitement sur l\'appareil'),
            ),
          ],
        ),
      ),
    );
  }

  String get _loadingLabel {
    switch (_lastMode) {
      case _RecipeImportMode.ai:
        return 'Analyse IA en cours...';
      case _RecipeImportMode.local:
      case null:
        return 'Analyse des photos...';
    }
  }

  Future<void> _replaceImages() async {
    await _pickImages(append: false);
  }

  Future<void> _appendImages() async {
    await _pickImages(append: true);
  }

  Future<void> _pickImages({required bool append}) async {
    try {
      final picked = await (widget.onPickImages?.call() ?? _imagePicker.pickMultiImage());
      if (!mounted) {
        return;
      }

      if (picked.isEmpty) {
        setState(() {
          _selectionMessage = 'Selection annulee.';
          _analysisError = null;
        });
        return;
      }

      final merged = append ? [..._selectedImages, ...picked] : picked;
      final unique = <String, XFile>{};
      for (final image in merged) {
        unique[image.path] = image;
      }

      setState(() {
        _selectedImages = unique.values.toList(growable: false);
        _analysisError = null;
        _lastMode = null;
        _selectionMessage =
            '${_selectedImages.length} photo${_selectedImages.length > 1 ? 's' : ''} selectionnee${_selectedImages.length > 1 ? 's' : ''} depuis la galerie.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _analysisError = null;
        _selectionMessage = 'Impossible d\'ouvrir la galerie pour le moment.';
      });
    }
  }

  void _removeImageAt(int index) {
    if (index < 0 || index >= _selectedImages.length) {
      return;
    }

    final updated = [..._selectedImages]..removeAt(index);
    setState(() {
      _selectedImages = updated;
      _analysisError = null;
      _lastMode = null;
      _selectionMessage = updated.isEmpty
          ? 'Aucune photo selectionnee.'
          : '${updated.length} photo${updated.length > 1 ? 's' : ''} restante${updated.length > 1 ? 's' : ''}.';
    });
  }

  Future<void> _extractRecipeWithAi() async {
    if (_selectedImages.isEmpty) {
      return;
    }

    setState(() {
      _isExtracting = true;
      _analysisError = null;
      _lastMode = _RecipeImportMode.ai;
    });

    try {
      final payloads = await Future.wait(
        _selectedImages.map(
          (image) async => RecipeAiImagePayload(
            fileName: image.name.isNotEmpty ? image.name : _fallbackFileName(image.path),
            bytes: await image.readAsBytes(),
            path: image.path,
          ),
        ),
      );

      final recipe = await _aiExtractionService.extractRecipeFromImages(payloads);
      if (!mounted) {
        return;
      }

      setState(() => _isExtracting = false);
      await _openReview(recipe);
    } on RecipeAiExtractionException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isExtracting = false;
        _analysisError = error.userMessage;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isExtracting = false;
        _analysisError =
            'L’analyse IA a échoué. Tu peux réessayer ou utiliser l’analyse locale.';
      });
    }
  }

  Future<void> _extractRecipeLocally() async {
    if (_selectedImages.isEmpty) {
      return;
    }

    setState(() {
      _isExtracting = true;
      _analysisError = null;
      _lastMode = _RecipeImportMode.local;
    });

    try {
      final paths = _selectedImages.map((e) => e.path).toList();
      final rawText = await _extractionService.extractRawTextFromImages(paths);
      if (!mounted) {
        return;
      }

      setState(() => _isExtracting = false);
      await _openOcrTextReview(rawText, paths);
    } on RecipeExtractionException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isExtracting = false;
        _analysisError = error.userMessage;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isExtracting = false;
        _analysisError =
            'Impossible de lire cette image pour l\'instant. Tu peux essayer une autre image.';
      });
    }
  }

  String _fallbackFileName(String path) {
    final segments = path.split(RegExp(r'[\\/]'));
    return segments.isEmpty ? 'recipe-image.jpg' : segments.last;
  }

  Future<void> _openOcrTextReview(String rawText, List<String> imagePaths) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeOcrTextReviewScreen(
          initialText: rawText,
          imagePaths: imagePaths,
          extractionService: _extractionService,
        ),
      ),
    );
  }

  Future<void> _openManualEntry() async {
    final paths = _selectedImages.map((e) => e.path).toList();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeOcrTextReviewScreen(
          imagePaths: paths.isNotEmpty ? paths : null,
          extractionService: _extractionService,
        ),
      ),
    );
  }

  Future<void> _openReview(Recipe recipe) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeReviewScreen(initialRecipe: recipe),
      ),
    );
  }
}

class _ImagePreviewGallery extends StatelessWidget {
  final List<XFile> images;
  final ValueChanged<int>? onRemove;

  const _ImagePreviewGallery({
    required this.images,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const _PreviewFallback(
        key: Key('recipe-image-placeholder'),
        icon: Icons.photo_library_outlined,
        label: 'Aucun apercu pour le moment',
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final entry in images.asMap().entries)
          _PreviewTile(
            image: entry.value,
            index: entry.key,
            onRemove: onRemove,
          ),
      ],
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final XFile image;
  final int index;
  final ValueChanged<int>? onRemove;

  const _PreviewTile({
    required this.image,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final preview = _buildPreview();

    return SizedBox(
      width: 152,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              preview,
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.black.withAlpha(130),
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: Key('remove-recipe-image-$index'),
                    customBorder: const CircleBorder(),
                    onTap: onRemove == null ? null : () => onRemove!(index),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _labelFor(image),
            key: Key('selected-image-label-$index'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.colorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (kIsWeb) {
      return _PreviewFallback(
        key: Key('recipe-image-web-fallback-$index'),
        icon: Icons.image_outlined,
        label: 'Apercu non disponible',
        compact: true,
      );
    }

    final file = File(image.path);
    if (!file.existsSync()) {
      return _PreviewFallback(
        key: Key('recipe-image-error-fallback-$index'),
        icon: Icons.broken_image_outlined,
        label: 'Image introuvable',
        compact: true,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        file,
        key: Key('recipe-image-preview-$index'),
        height: 120,
        width: 152,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) {
          return _PreviewFallback(
            key: Key('recipe-image-error-fallback-$index'),
            icon: Icons.broken_image_outlined,
            label: 'Impossible de charger l\'image',
            compact: true,
          );
        },
      ),
    );
  }

  String _labelFor(XFile file) {
    final name = file.name.trim();
    if (name.isNotEmpty) {
      return name;
    }

    final segments = file.path.split(RegExp(r'[\\/]'));
    return segments.isEmpty ? file.path : segments.last;
  }
}

class _ImportErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetryAi;
  final VoidCallback? onUseLocal;
  final VoidCallback? onEnterTextManually;
  final VoidCallback? onUseDemo;

  const _ImportErrorCard({
    required this.message,
    required this.onRetryAi,
    required this.onUseLocal,
    required this.onEnterTextManually,
    required this.onUseDemo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('recipe-analysis-error'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyse indisponible',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.colorTextSecondary,
            ),
          ),
          if (onRetryAi != null || onUseLocal != null || onEnterTextManually != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onRetryAi != null)
                  TextButton.icon(
                    key: const Key('retry-ai-analysis'),
                    onPressed: onRetryAi,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reessayer'),
                  ),
                if (onUseLocal != null)
                  TextButton.icon(
                    key: const Key('fallback-local-analysis'),
                    onPressed: onUseLocal,
                    icon: const Icon(Icons.offline_bolt_outlined, size: 18),
                    label: const Text('Utiliser l\'analyse locale'),
                  ),
                if (onEnterTextManually != null)
                  TextButton.icon(
                    key: const Key('enter-text-manually'),
                    onPressed: onEnterTextManually,
                    icon: const Icon(Icons.edit_note_outlined, size: 18),
                    label: const Text('Coller le texte manuellement'),
                  ),
              ],
            ),
          ],
          if (onUseDemo != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              key: const Key('use-demo-recipe'),
              onPressed: onUseDemo,
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: const Text('Utiliser une recette de demonstration'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;

  const _PreviewFallback({
    super.key,
    required this.icon,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 152 : double.infinity,
      height: compact ? 120 : 180,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: compact ? 28 : 54,
                color: AppTheme.colorTextSecondary,
              ),
              SizedBox(height: compact ? 6 : 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.colorTextSecondary,
                ),
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RecipeImportMode {
  ai,
  local,
}
