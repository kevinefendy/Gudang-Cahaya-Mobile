import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  XFile? _pickedImage;
  bool _loading = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();

    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _categoryController.text = product.category;
      _priceController.text = formatPriceForInput(product.price);
      _stockController.text = product.stock.toString();
      _descriptionController.text = product.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );

      if (picked != null && mounted) {
        setState(() => _pickedImage = picked);
      }
    } catch (_) {
      _showMessage('Gagal membuka galeri', isError: true);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final product = ProductModel(
      id: widget.product?.id ?? 0,
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      price: parsePriceInput(_priceController.text) ?? 0,
      stock: parseIntInput(_stockController.text) ?? 0,
      description: _descriptionController.text.trim(),
      imageUrl: widget.product?.imageUrl ?? '',
    );

    try {
      if (_isEdit) {
        await ApiService.instance.updateProduct(
          product,
          imagePath: _pickedImage?.path,
        );
      } else {
        await ApiService.instance.createProduct(
          product,
          imagePath: _pickedImage?.path,
        );
      }

      if (!mounted) return;
      _showMessage(
        _isEdit ? 'Produk berhasil diperbarui' : 'Produk berhasil ditambahkan',
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Produk gagal disimpan, silakan coba lagi', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildImagePicker(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) => validateRequired(value, 'Nama produk'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (value) => validateRequired(value, 'Kategori'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  hintText: 'Contoh: 25000',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: validatePrice,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  hintText: 'Contoh: 10',
                  prefixIcon: Icon(Icons.inventory_outlined),
                ),
                validator: validateStock,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (value) => validateRequired(value, 'Deskripsi'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_loading ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gambar Produk (opsional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _loading ? null : _pickImage,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 180,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1.5,
              ),
              color: colorScheme.surfaceContainerHighest,
            ),
            child: _buildImageContent(colorScheme),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Kosongkan jika tidak ingin menambahkan gambar',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _loading ? null : _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _pickedImage == null && (widget.product?.imageUrl ?? '').isEmpty
                    ? 'Pilih Gambar'
                    : 'Ganti Gambar',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageContent(ColorScheme colorScheme) {
    final picked = _pickedImage;
    if (picked != null) {
      return Image.file(
        File(picked.path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imagePlaceholder(colorScheme),
      );
    }

    final imageUrl = widget.product?.imageUrl ?? '';
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imagePlaceholder(colorScheme),
      );
    }

    return _imagePlaceholder(colorScheme);
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 44,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          'Ketuk untuk memilih gambar',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
