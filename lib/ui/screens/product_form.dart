import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductForm extends StatefulWidget {
  @override
  _ProductFormState createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  String name = "", description = "", category = "";
  double price = 0;

  File? _image;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera); 
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nuevo Producto")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child:
           Column(
            children: [
              _image != null
                  ? Image.file(_image!, height: 120)
                  : Text("No hay imagen"),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.camera_alt),
                label: Text("Tomar Foto"),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Nombre"),
                onSaved: (val) => name = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Descripción"),
                onSaved: (val) => description = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Precio"),
                keyboardType: TextInputType.number,
                onSaved: (val) => price = double.parse(val!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Categoría"),
                onSaved: (val) => category = val!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Guardar"),
                onPressed: () async {
                  _formKey.currentState!.save();
                  await ProductRepository.insertProduct(
                    Product(
                      name: name,
                      description: description,
                      price: price,
                      category: category,
                      imagePath: _image?.path,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
