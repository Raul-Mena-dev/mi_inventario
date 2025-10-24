import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductForm extends StatefulWidget {
  final Product? product;

  const ProductForm({super.key, this.product});

  @override
  ProductFormState createState() => ProductFormState();
}

class ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late TextEditingController _subcategoryController;

  File? _image;
  List<String> _categories = [];
  List<String> _subcategories = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? "");
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? "");
    _priceController =
        TextEditingController(text: widget.product?.price.toString() ?? "");
    _categoryController =
        TextEditingController(text: widget.product?.category ?? "");
    _subcategoryController =
        TextEditingController(text: widget.product?.subcategory ?? "");

    if (widget.product?.imagePath != null) {
      _image = File(widget.product!.imagePath!);
    }

    _loadCategories();
    if (_categoryController.text.isNotEmpty) {
      _loadSubcategories(_categoryController.text);
    }
  }

  Future<void> _loadCategories() async {
    final categories = await ProductRepository.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _loadSubcategories(String category) async {
    final subs = await ProductRepository.getSubcategories(category);
    setState(() {
      _subcategories = subs;
    });
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Tomar foto"),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final pickedFile =
                      await ImagePicker().pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _image = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Elegir de galería"),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final pickedFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _image = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0,
      category: _categoryController.text.trim(),
      subcategory: _subcategoryController.text.trim(),
      imagePath: _image?.path,
    );

    if (widget.product == null) {
      await ProductRepository.insertProduct(product);
    } else {
      await ProductRepository.updateProduct(product);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? "Editar Producto" : "Nuevo Producto"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen principal
                GestureDetector(
                  onTap: _pickImage,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                        image: _image != null
                            ? DecorationImage(
                                image: FileImage(_image!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _image == null
                          ? const Center(
                              child: Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campos
                _buildTextField(_nameController, "Nombre", required: true),
                _buildTextField(_descriptionController, "Descripción",
                    maxLines: 2),
                _buildTextField(_priceController, "Precio",
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    required: true),

                const SizedBox(height: 10),

                // Categoría con Autocomplete
                _buildAutocompleteField(
                  label: "Categoría",
                  controller: _categoryController,
                  options: _categories,
                  onSelected: (selection) async {
                    _categoryController.text = selection;
                    _subcategoryController.clear();
                    await _loadSubcategories(selection);
                  },
                ),

                const SizedBox(height: 10),

                // Subcategoría dependiente
                _buildAutocompleteField(
                  label: "Subcategoría",
                  controller: _subcategoryController,
                  options: _subcategories,
                  onSelected: (selection) {
                    _subcategoryController.text = selection;
                  },
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? "Actualizar" : "Guardar"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required
            ? (val) => val == null || val.trim().isEmpty ? "Requerido" : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildAutocompleteField({
    required String label,
    required TextEditingController controller,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return options.where((o) => o
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: onSelected,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        if (textEditingController.text.isEmpty &&
            controller.text.isNotEmpty) {
          textEditingController.text = controller.text;
        }
        textEditingController.addListener(() {
          controller.text = textEditingController.text;
        });
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        );
      },
    );
  }
}
