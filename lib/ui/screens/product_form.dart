import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductForm extends StatefulWidget {
  final Product? product; // 👈 opcional para edición

  const ProductForm({Key? key, this.product}) : super(key: key);

  @override
  ProductFormState createState() => ProductFormState();
}

class ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;

  File? _image;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con valores si es edición
    _nameController = TextEditingController(text: widget.product?.name ?? "");
    _descriptionController = TextEditingController(text: widget.product?.description ?? "");
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? "");
    _categoryController = TextEditingController(text: widget.product?.category ?? "");

    if (widget.product?.imagePath != null) {
      _image = File(widget.product!.imagePath!);
    }
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
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
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
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
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
      id: widget.product?.id, // 👈 importante para update
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      category: _categoryController.text,
      imagePath: _image?.path,
    );

    if (widget.product == null) {
      // Crear
      await ProductRepository.insertProduct(product);
    } else {
      // Editar
      await ProductRepository.updateProduct(product);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Editar Producto" : "Nuevo Producto")),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen del producto
                Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: _image != null
                      ? Image.file(_image!, fit: BoxFit.cover)
                      : const Center(child: Text("No hay imagen")),
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(isEditing ? "Cambiar Foto" : "Seleccionar Imagen"),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Nombre"),
                  validator: (val) => val == null || val.isEmpty ? "Requerido" : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Descripción"),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: "Precio"),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.isEmpty ? "Requerido" : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: "Categoría"),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  child: Text(isEditing ? "Actualizar" : "Guardar"),
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
