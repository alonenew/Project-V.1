import 'package:ardear_bakery/src/utils/relative_time_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ardear_bakery/src/models/order.dart';
import 'package:ardear_bakery/src/pages/delivery/orders/list/delivery_orders_list_controller.dart';
import 'package:ardear_bakery/src/utils/my_colors.dart';
import 'package:ardear_bakery/src/widgets/no_data_widget.dart';

class DeliveryOrdersListPage extends StatefulWidget {
  const DeliveryOrdersListPage({Key key}) : super(key: key);

  @override
  _DeliveryOrdersListPageState createState() => _DeliveryOrdersListPageState();
}

class _DeliveryOrdersListPageState extends State<DeliveryOrdersListPage> {
  DeliveryOrdersListController _con = new DeliveryOrdersListController();

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
      length: _con.status?.length,
      child: Scaffold(
        key: _con.key,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            flexibleSpace: Column(
              children: [
                SizedBox(height: 40),
                _menuDrawer(),
              ],
            ),
            bottom: TabBar(
              indicatorColor: MyColors.primaryColor,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[400],
              isScrollable: true,
              tabs: List<Widget>.generate(_con.status.length, (index) {
                return Tab(
                  child: Text(_con.status[index] ?? ''),
                );
              }),
            ),
          ),
        ),
        drawer: _drawer(),
        body: TabBarView(
          children: _con.status.map((String status) {
            return FutureBuilder(
                future: _con.getOrders(status) ?? '',
                builder: (context, AsyncSnapshot<List<Order>> snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data.length > 0) {
                      return RefreshIndicator(
                        child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 20),
                            itemCount: snapshot.data?.length ?? 0,
                            itemBuilder: (_, index) {
                              return _cardOrder(snapshot.data[index]);
                            }),
                        onRefresh: _getData,
                      );
                    } else {
                      return NoDataWidget(text: 'ไม่มีสินค้า');
                    }
                  } else {
                    return NoDataWidget(text: 'ไม่มีสินค้า');
                  }
                });
          }).toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: refresh,
          tooltip: 'refresh',
          child: Icon(Icons.refresh),
        ),
      ),
    );
  }

  Future<void> _getData() async {
    setState(() {
      _cardOrder;
    });
  }

  Widget _cardOrder(Order order) {
    return GestureDetector(
      onTap: () {
        _con.openBottomSheet(order);
      },
      child: Container(
        height: 155,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Card(
          elevation: 3.0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Stack(
            children: [
              Positioned(
                  child: Container(
                height: 30,
                width: MediaQuery.of(context).size.width * 1,
                decoration: BoxDecoration(
                    color: MyColors.primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    )),
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Text(
                    'Order #${order.id}',
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontFamily: 'NimbusSans'),
                  ),
                ),
              )),
              Container(
                margin: EdgeInsets.only(top: 40, left: 20, right: 20),
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: EdgeInsets.symmetric(vertical: 5),
                      width: double.infinity,
                      child: Text(
                        'วันที่สั่ง : ${RelativeTimeUtil.getRelativeTime(order.timestamp ?? 0)}',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        'ลูกค้า : ${order.client?.name ?? ''} ${order.client?.lastname ?? ''}',
                        style: TextStyle(fontSize: 13),
                        maxLines: 1,
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        'ที่อยู่ปลายทาง : ${order.address?.address ?? ''}',
                        style: TextStyle(fontSize: 13),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuDrawer() {
    return GestureDetector(
      onTap: _con.openDrawer,
      child: Container(
        margin: EdgeInsets.only(left: 20),
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
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic),
                    maxLines: 1,
                  ),
                  Text(
                    _con.user?.phone ?? '',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic),
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
            onTap: _con.logout,
            title: Text('ออกจากระบบ'),
            trailing: Icon(Icons.power_settings_new),
          ),
        ],
      ),
    );
  }

  void refresh() {
    setState(() {}); // CTRL + S
  }
}
