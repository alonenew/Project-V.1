import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ardear_bakery/src/models/category.dart';
import 'package:ardear_bakery/src/models/product.dart';
import 'package:ardear_bakery/src/models/response_api.dart';
import 'package:ardear_bakery/src/models/user.dart';
import 'package:ardear_bakery/src/provider/categories_provider.dart';
import 'package:ardear_bakery/src/provider/products_provider.dart';
import 'package:ardear_bakery/src/utils/my_snackbar.dart';
import 'package:ardear_bakery/src/utils/shared_pref.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

class RestaurantProductsCreateController {
  BuildContext context;
  Function refresh;

  TextEditingController nameController = new TextEditingController();
  TextEditingController descriptionController = new TextEditingController();
  MoneyMaskedTextController priceController = new MoneyMaskedTextController(
      decimalSeparator: '.', thousandSeparator: ',');
  CategoriesProvider _categoriesProvider = new CategoriesProvider();
  ProductsProvider _productsProvider = new ProductsProvider();

  User user;
  SharedPref sharedPref = new SharedPref();

  List<Category> categories = [];
  String idCategory;

  PickedFile pickedFile;
  File imageFile1;
  File imageFile2;
  File imageFile3;

  ProgressDialog _progressDialog;

  Future init(BuildContext context, Function refresh) async {
    this.context = context;
    this.refresh = refresh;
    _progressDialog = new ProgressDialog(context: context);
    user = User.fromJson(await sharedPref.read('user'));
    _categoriesProvider.init(context, user);
    _productsProvider.init(context, user);
    getCategories();
  }

  void getCategories() async {
    categories = await _categoriesProvider.getAll();
    refresh();
  }

  void createProduct() async {
    String name = nameController.text;
    String description = descriptionController.text;
    double price = priceController.numberValue;

    if (name.isEmpty || description.isEmpty || price == 0) {
      MySnackbar.show(context, 'กรุณากรอกให้ครบ');
      return;
    }

    if (imageFile1 == null) {
      MySnackbar.show(context, 'เลือกภาพ');
      return;
    }

    if (idCategory == null) {
      MySnackbar.show(context, 'เลือกหมวดสินค้า');
      return;
    }

    Product product = new Product(
        name: name,
        description: description,
        price: price,
        idCategory: int.parse(idCategory));

    List<File> images = [];
    images.add(imageFile1);

    _progressDialog.show(max: 100, msg: 'รอสักครู่...');
    Stream stream = await _productsProvider.create(product, images);
    stream.listen((res) {
      _progressDialog.close();

      ResponseApi responseApi = ResponseApi.fromJson(json.decode(res));
      MySnackbar.show(context, responseApi.message);

      if (responseApi.success) {
        resetValues();
      }
    });
  }

  void resetValues() {
    nameController.text = '';
    descriptionController.text = '';
    priceController.text = '0.0';
    imageFile1 = null;
    imageFile2 = null;
    imageFile3 = null;
    idCategory = null;
    refresh();
  }

  Future selectImage(ImageSource imageSource, int numberFile) async {
    pickedFile = await ImagePicker().getImage(source: imageSource);
    if (pickedFile != null) {
      if (numberFile == 1) {
        imageFile1 = File(pickedFile.path);
      } else if (numberFile == 2) {
        imageFile2 = File(pickedFile.path);
      } else if (numberFile == 3) {
        imageFile3 = File(pickedFile.path);
      }
    }
    Navigator.pop(context);
    refresh();
  }

  void showAlertDialog(int numberFile) {
    Widget galleryButton = ElevatedButton(
        onPressed: () {
          selectImage(ImageSource.gallery, numberFile);
        },
        child: Text('คลังภาพ'));

    Widget cameraButton = ElevatedButton(
        onPressed: () {
          selectImage(ImageSource.camera, numberFile);
        },
        child: Text('กล้อง'));

    AlertDialog alertDialog = AlertDialog(
      title: Text('เลือกรูปภาพ'),
      actions: [galleryButton, cameraButton],
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        });
  }
}
