import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ardear_bakery/src/models/category.dart';
import 'package:ardear_bakery/src/models/product.dart';
import 'package:ardear_bakery/src/pages/client/products/list/client_products_list_controller.dart';
import 'package:ardear_bakery/src/utils/my_colors.dart';
import 'package:ardear_bakery/src/widgets/no_data_widget.dart';

class ClientProductsListPage extends StatefulWidget {
  const ClientProductsListPage({Key key}) : super(key: key);

  @override
  _ClientProductsListPageState createState() => _ClientProductsListPageState();
}

class _ClientProductsListPageState extends State<ClientProductsListPage> {
  ClientProductsListController _con = new ClientProductsListController();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _con.init(context, refresh);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _con.categories?.length,
      child: Scaffold(
        key: _con.key,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(150),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            actions: [_shoppingBag()],
            flexibleSpace: Column(
              children: [
                SizedBox(height: 15),
                _menuDrawer(),
                SizedBox(height: 20),
                _textFieldSearch()
              ],
            ),
            bottom: TabBar(
              indicatorColor: MyColors.primaryColor,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[400],
              isScrollable: true,
              tabs: List<Widget>.generate(_con.categories.length, (index) {
                return Tab(
                  child: Text(
                    ' ' + _con.categories[index].name + ' ',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }),
            ),
          ),
        ),
        drawer: _drawer(),
        body: TabBarView(
          children: _con.categories.map((Category category) {
            return FutureBuilder(
                future: _con.getProducts(category.id, _con.productName),
                builder: (context, AsyncSnapshot<List<Product>> snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data.length > 0) {
                      return GridView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 20),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, childAspectRatio: 0.7),
                          itemCount: snapshot.data?.length ?? 0,
                          itemBuilder: (_, index) {
                            return _cardProduct(snapshot.data[index]);
                          });
                    } else {
                      return NoDataWidget(text: 'ไม่มีสินค้า');
                    }
                  } else {
                    return NoDataWidget(text: 'ไม่มีสินค้า');
                  }
                });
          }).toList(),
        ),
      ),
    );
  }

  Widget _cardProduct(Product product) {
    return GestureDetector(
      onTap: () {
        _con.openBottomSheet(product);
      },
      child: Container(
        height: 200,
        child: Card(
          elevation: 3.0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Stack(
            children: [
              Positioned(
                  top: -1.0,
                  right: -1.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: MyColors.primaryColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          topRight: Radius.circular(20),
                        )),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  )),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 150,
                    margin: EdgeInsets.only(top: 20),
                    width: MediaQuery.of(context).size.width * 0.45,
                    padding: EdgeInsets.all(20),
                    child: FadeInImage(
                      image: product.image1 != null
                          ? NetworkImage(product.image1)
                          : AssetImage('assets/img/pizza2.png'),
                      fit: BoxFit.contain,
                      fadeInDuration: Duration(milliseconds: 50),
                      placeholder: AssetImage('assets/img/no-image.png'),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    height: 25,
                    child: Text(
                      product.name ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontFamily: 'NimbusSans'),
                    ),
                  ),
                  Spacer(),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      '${product.price ?? 0} บาท',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NimbusSans'),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _shoppingBag() {
    return GestureDetector(
      onTap: _con.goToOrderCreatePage,
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.only(right: 15, top: 13),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: Colors.black,
            ),
          ),
          Positioned(
              right: 16,
              top: 15,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.all(Radius.circular(30))),
              ))
        ],
      ),
    );
  }

  Widget _textFieldSearch() {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      child: TextField(
        onChanged: _con.onChangeText,
        decoration: InputDecoration(
            hintText: 'ค้นหา',
            suffixIcon: Icon(Icons.search, color: Colors.grey[400]),
            hintStyle: TextStyle(fontSize: 17, color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: Colors.grey[300])),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: Colors.grey[300])),
            contentPadding: EdgeInsets.all(15)),
      ),
    );
  }

  Widget _menuDrawer() {
    return GestureDetector(
      onTap: _con.openDrawer,
      child: Container(
        margin: EdgeInsets.only(left: 20, top: 30),
        alignment: Alignment.centerLeft,
        child: Image.asset('assets/img/menu.png', width: 20, height: 20),
      ),
    );
  }

  Widget _drawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
              decoration: BoxDecoration(color: MyColors.primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_con.user?.name ?? ''} ${_con.user?.lastname ?? ''}',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                  Text(
                    _con.user?.email ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    maxLines: 1,
                  ),
                  Text(
                    _con.user?.phone ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    maxLines: 1,
                  ),
                  Container(
                    height: 60,
                    margin: EdgeInsets.only(top: 10),
                    child: FadeInImage(
                      image: _con.user?.image != null
                          ? NetworkImage(_con.user?.image)
                          : AssetImage('assets/img/no-image.png'),
                      fit: BoxFit.contain,
                      fadeInDuration: Duration(milliseconds: 50),
                      placeholder: AssetImage('assets/img/no-image.png'),
                    ),
                  )
                ],
              )),
          ListTile(
            onTap: _con.goToUpdatePage,
            title: Text('แก้ไขข้อมูลส่วนตัว'),
            trailing: Icon(Icons.edit_outlined),
          ),
          ListTile(
            onTap: _con.goToOrdersList,
            title: Text('ประวัติคำสั่งซื้อ'),
            trailing: Icon(Icons.shopping_cart_outlined),
          ),
          _con.user != null
              ? _con.user.roles.length == 2
                  ? ListTile(
                      onTap: _con.goToRoles,
                      title: Text('เลือก Role'),
                      trailing: Icon(Icons.person_outline),
                    )
                  : Container()
              : Container(),
          ListTile(
            onTap: _con.logout,
            title: Text('ออกจากระบบ'),
            trailing: Icon(Icons.power_settings_new),
          ),
        ],
      ),
    );
  }

  void refresh() {
    setState(() {});
  }
}
