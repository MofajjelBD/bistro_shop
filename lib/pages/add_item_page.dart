import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/food_item.dart';

class AddItemPage extends StatefulWidget {
  final FoodItem? item;

  const AddItemPage({super.key, this.item});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _detailsController = TextEditingController();
  String? _selectedCategory;
  File? _image;
  String? _uploadedImageUrl;

  final Map<String, Color> categoryColors = {
    'Salad': Colors.green.shade400,
    'Pizza': Colors.redAccent,
    'Soup': Colors.orange.shade600,
    'Dessert': Colors.pink.shade300,
    'Drinks': Colors.blueAccent,
  };

  final List<String> categories = [
    'Salad',
    'Pizza',
    'Soup',
    'Dessert',
    'Drinks',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toString();
      _detailsController.text = widget.item!.recipe;
      _selectedCategory = widget.item!.category[0].toUpperCase() +
          widget.item!.category.substring(1);
      _uploadedImageUrl = widget.item!.image;
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.deepPurple.shade50,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.deepPurple.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.deepPurple.shade700,
        fontSize: 16,
        letterSpacing: 0.6,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _uploadImageToImgbb() async {
    if (_image == null) return;
    final apiKey = dotenv.env['VITE_IMG_BB_API_KEY'];

    final bytes = await _image!.readAsBytes();
    final base64Image = base64Encode(bytes);
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final response = await http.post(url, body: {'image': base64Image});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _uploadedImageUrl = data['data']['url'];
      });
    } else {
      throw Exception('Image upload failed');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image != null) {
      await _uploadImageToImgbb();
    }

    if (_uploadedImageUrl == null) {
      Fluttertoast.showToast(
        msg: "Please upload an image",
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
      return;
    }

    final newItem = FoodItem(
      id: widget.item?.id ?? '',
      name: _nameController.text.trim(),
      category: _selectedCategory!.toLowerCase(),
      price: double.parse(_priceController.text),
      recipe: _detailsController.text.trim(),
      image: _uploadedImageUrl!,
    );

    final isEditing = widget.item != null;
    final url = isEditing
        ? Uri.parse(
            'https://bistro-boss-server-pink-tau.vercel.app/menu/${newItem.id}')
        : Uri.parse('https://bistro-boss-server-pink-tau.vercel.app/menu');

    final response = await (isEditing
        ? http.patch(url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(newItem.toJson()))
        : http.post(url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(newItem.toJson())));

    if (response.statusCode == 200 || response.statusCode == 201) {
      Fluttertoast.showToast(
        msg:
            isEditing ? "Item updated successfully" : "Item added successfully",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: "Something went wrong",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return ChoiceChip(
          label: Text(cat),
          selected: isSelected,
          selectedColor: categoryColors[cat],
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (selected) {
            setState(() {
              _selectedCategory = selected ? cat : null;
            });
          },
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '🍽️ Add New Item',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 3),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Recipe Name'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildCategoryChips(),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration('Price'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return 'Enter price';
                      final price = double.tryParse(val);
                      if (price == null || price <= 0)
                        return 'Enter valid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _detailsController,
                    maxLines: 4,
                    decoration: _inputDecoration('Details'),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Enter details'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _image != null || _uploadedImageUrl != null
                                ? Colors.transparent
                                : Colors.deepPurple,
                            width: 2),
                        color: Colors.deepPurple.shade50,
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_image!,
                                  width: double.infinity, fit: BoxFit.cover))
                          : _uploadedImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(_uploadedImageUrl!,
                                      width: double.infinity,
                                      fit: BoxFit.cover))
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      FaIcon(FontAwesomeIcons.image,
                                          size: 36, color: Colors.deepPurple),
                                      SizedBox(height: 8),
                                      Text('No Image Selected',
                                          style: TextStyle(
                                              color: Colors.deepPurple,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: FaIcon(widget.item == null
                          ? FontAwesomeIcons.plus
                          : FontAwesomeIcons.save),
                      label: Text(
                          widget.item == null ? "Add Item" : "Save Changes"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
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
