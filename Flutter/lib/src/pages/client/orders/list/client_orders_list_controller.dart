import 'package:flutter/material.dart';
import 'package:ardear_bakery/src/models/user.dart';
import 'package:ardear_bakery/src/pages/client/orders/detail/client_orders_detail_page.dart';
import 'package:ardear_bakery/src/provider/orders_provider.dart';
import 'package:ardear_bakery/src/utils/shared_pref.dart';
import 'package:ardear_bakery/src/models/order.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ClientOrdersListController {
  BuildContext context;
  SharedPref _sharedPref = new SharedPref();
  GlobalKey<ScaffoldState> key = new GlobalKey<ScaffoldState>();
  Function refresh;
  User user;

  List<String> status = [
    'รายการสั่งซื้อ',
    'กำลังดำเนินการ',
    'ระหว่างนำส่ง',
    'เสร็จสิ้น'
  ];
  OrdersProvider _ordersProvider = new OrdersProvider();

  bool isUpdated;

  Future init(BuildContext context, Function refresh) async {
    this.context = context;
    this.refresh = refresh;
    user = User.fromJson(await _sharedPref.read('user'));

    _ordersProvider.init(context, user);
    refresh();
  }

  Future<List<Order>> getOrders(String status) async {
    return await _ordersProvider.getByClientAndStatus(
        user.id ?? '', status ?? '');
  }

  void openBottomSheet(Order order) async {
    isUpdated = await showMaterialModalBottomSheet(
        context: context,
        builder: (context) => ClientOrdersDetailPage(order: order));

    if (isUpdated) {
      refresh();
    }
  }

  void logout() {
    _sharedPref.logout(context, user.id);
  }

  void goToCategoryCreate() {
    Navigator.pushNamed(context, 'restaurant/categories/create');
  }

  void goToProductCreate() {
    Navigator.pushNamed(context, 'restaurant/products/create');
  }

  void openDrawer() {
    key.currentState.openDrawer();
  }

  void goToRoles() {
    Navigator.pushNamedAndRemoveUntil(context, 'roles', (route) => false);
  }
}
