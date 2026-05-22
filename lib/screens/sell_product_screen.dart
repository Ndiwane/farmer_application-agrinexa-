import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class SellProductScreen extends StatefulWidget {
  const SellProductScreen({super.key});

  @override
  State<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _customUnitController = TextEditingController();

  final String _cloudName = 'drhscazuw';
  final String _uploadPreset = 'agrinexa_upload';

  File? _selectedImage;
  bool _isLoading = false;

  // Unit options
  final List<String> _unitOptions = [
    'kg', 'bucket', 'basket', 'bag', 'crate', 'Other'
  ];
  String _selectedUnit = 'kg';
  bool _isCustomUnit = false;

  // ── Categories ─────────────────────────────────────────────────────────
  // Each category has a name and emoji for display
  static const List<Map<String, String>> _categories = [
    {'name': 'Vegetables', 'emoji': '🥬'},
    {'name': 'Fruits',     'emoji': '🍎'},
    {'name': 'Grains',     'emoji': '🌽'},
    {'name': 'Legumes',    'emoji': '🫘'},
    {'name': 'Tubers',     'emoji': '🍠'},
    {'name': 'Nuts',       'emoji': '🌰'},
    {'name': 'Spices',     'emoji': '🌶️'},
    {'name': 'Other',      'emoji': '🌾'},
  ];

  // Currently selected category (required before submitting)
  String? _selectedCategory;

  @override
  void dispose() {
    _cropNameController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Image Source',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(
            await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      if (response.statusCode == 200) return jsonData['secure_url'];
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitProduct() async {
    // Validate image
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a product image'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Validate category selection
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product category'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Get final unit
    final unit = _isCustomUnit
        ? _customUnitController.text.trim()
        : _selectedUnit;

    if (_isCustomUnit && unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your custom unit'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image to Cloudinary
      final imageUrl = await _uploadImage(_selectedImage!);
      if (imageUrl == null) throw Exception('Image upload failed');

      final user = FirebaseAuth.instance.currentUser;
      final price = _priceController.text.trim();
      final quantity = _quantityController.text.trim();

      // Save product to Firestore with category
      await FirebaseFirestore.instance.collection('products').add({
        'name': _cropNameController.text.trim(),
        'category': _selectedCategory, // ← Category saved here
        'quantity': quantity,
        'unit': unit,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': '$price FCFA/$unit',
        'priceValue': double.tryParse(price) ?? 0,
        'imageUrl': imageUrl,
        'sellerId': user?.uid,
        'sellerName': user?.displayName ?? 'Unknown',
        'createdAt': FieldValue.serverTimestamp(),
        'avgRating': 0.0,
        'reviewCount': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product listed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Sell Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image picker ───────────────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_selectedImage!,
                              fit: BoxFit.cover, width: double.infinity),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: 44, color: AppColors.textLight),
                            const SizedBox(height: 8),
                            Text('Tap to add product image',
                                style: TextStyle(
                                    color: AppColors.textLight, fontSize: 13)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Crop name ──────────────────────────────────────────────
              const _FieldLabel('Crop Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cropNameController,
                decoration: const InputDecoration(
                    hintText: 'e.g. Tomatoes, Maize, Cassava'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Crop name is required'
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Category selector ──────────────────────────────────────
              const _FieldLabel('Category'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 categories per row
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected =
                      _selectedCategory == category['name'];

                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = category['name']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            category['emoji']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category['name']!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Show error if no category selected and form submitted
              if (_selectedCategory == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Please select a category',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.danger),
                  ),
                ),
              const SizedBox(height: 14),

              // ── Quantity + Unit ────────────────────────────────────────
              const _FieldLabel('Available Quantity'),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 10'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) {
                          return 'Enter a valid number';
                        }
                        if (double.parse(v.trim()) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      items: _unitOptions.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value!;
                          _isCustomUnit = value == 'Other';
                        });
                      },
                    ),
                  ),
                ],
              ),

              // Custom unit input
              if (_isCustomUnit) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customUnitController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your unit (e.g. bunch, tray, sack)',
                    prefixIcon: Icon(Icons.edit_outlined,
                        color: AppColors.primary, size: 18),
                  ),
                  validator: (v) {
                    if (_isCustomUnit && (v == null || v.trim().isEmpty)) {
                      return 'Please enter your custom unit';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 14),

              // ── Location ───────────────────────────────────────────────
              const _FieldLabel('Location'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    hintText: 'e.g. Buea, Bamenda, Yaounde'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Location is required'
                    : null,
              ),
              const SizedBox(height: 14),

              // ── Description ────────────────────────────────────────────
              const _FieldLabel('Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText:
                        'Describe your product quality, freshness, etc.'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (v.trim().length < 10) return 'Description too short';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Price ──────────────────────────────────────────────────
              const _FieldLabel('Price per Unit'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 500',
                  prefixText: 'FCFA  ',
                  suffixText:
                      '/ ${_isCustomUnit && _customUnitController.text.isNotEmpty ? _customUnitController.text.trim() : _selectedUnit == 'Other' ? 'unit' : _selectedUnit}',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid price';
                  }
                  if (double.parse(v.trim()) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // ── Submit button ──────────────────────────────────────────
              ElevatedButton(
                onPressed: _isLoading ? null : _submitProduct,
                child: _isLoading
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('List Product'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark));
  }
}
