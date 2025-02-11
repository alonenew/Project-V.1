import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ardear_bakery/src/api/environment.dart';
import 'package:ardear_bakery/src/models/order.dart';
import 'package:ardear_bakery/src/models/response_api.dart';
import 'package:ardear_bakery/src/models/user.dart';
import 'package:ardear_bakery/src/provider/orders_provider.dart';
import 'package:ardear_bakery/src/provider/push_notifications_provider.dart';
import 'package:ardear_bakery/src/utils/my_colors.dart';
import 'package:ardear_bakery/src/utils/my_snackbar.dart';
import 'package:ardear_bakery/src/utils/shared_pref.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;
import 'package:url_launcher/url_launcher.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DeliveryOrdersMapController {
  BuildContext context;
  Function refresh;
  Position _position;
  StreamSubscription _positionStream;

  String addressName;
  LatLng addressLatLng;

  CameraPosition initialPosition = CameraPosition(
      target: LatLng(13.557545978622246, 100.82012777485842), zoom: 14);

  Completer<GoogleMapController> _mapController = Completer();

  BitmapDescriptor deliveryMarker;
  BitmapDescriptor homeMarker;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  Order order;

  Set<Polyline> polylines = {};
  List<LatLng> points = [];

  OrdersProvider _ordersProvider = new OrdersProvider();
  User user;
  SharedPref _sharedPref = new SharedPref();

  double _distanceBetween;

  PushNotificationsProvider pushNotificationsProvider =
      new PushNotificationsProvider();

  bool isClose = false;
  bool isCloseuser = false;

  IO.Socket socket;

  Future init(BuildContext context, Function refresh) async {
    this.context = context;
    this.refresh = refresh;
    order = Order.fromJson(
        ModalRoute.of(context).settings.arguments as Map<String, dynamic>);
    deliveryMarker = await createMarkerFromAsset('assets/img/delivery2.png');
    homeMarker = await createMarkerFromAsset('assets/img/home.png');

    socket = IO.io(
        'http://${Environment.API_DELIVERY}/orders/delivery', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false
    });
    socket.connect();

    user = User.fromJson(await _sharedPref.read('user'));
    _ordersProvider.init(context, user);
    checkGPS();
  }

  void sendNotification200(String tokenDelivery) {
    Map<String, dynamic> data = {'click_action': 'FLUTTER_NOTIFICATION_CLICK'};

    pushNotificationsProvider.sendMessage(tokenDelivery, data,
        'พนักงานส่งกำลังใกล้ถึงปลายทาง', 'กรุณาเตรียมพร้อมรับสินค้า');
  }

  void sendNotificationEnd(String tokenDelivery) {
    Map<String, dynamic> data = {'click_action': 'FLUTTER_NOTIFICATION_CLICK'};

    pushNotificationsProvider.sendMessage(tokenDelivery, data,
        'คำสั่งซื้อสำเร็จ', 'พนักงานจัดส่งออเดอร์เสร็จสิ้น');
  }

  void saveLocation() async {
    order.lat = _position.latitude;
    order.lng = _position.longitude;
    await _ordersProvider.updateLatLng(order);
  }

  void emitPosition() {
    socket.emit('position', {
      'id_order': order.id,
      'lat': _position.latitude,
      'lng': _position.longitude,
    });
  }

  void isCloseToDeliveryPosition() {
    _distanceBetween = Geolocator.distanceBetween(_position.latitude,
        _position.longitude, order.address.lat, order.address.lng);

    print('-------- ระยะทาง ${_distanceBetween} ----------');
    if (_distanceBetween <= 200 && !isClose) {
      sendNotification200(order.client.notificationToken);
      isClose = true;
    } else if (order.status == 'เสร็จสิ้น') {
      sendNotificationEnd(order.client.notificationToken);
    }
  }

  void launchGoogleMaps() async {
    var url =
        'google.navigation:q=${order.address.lat.toString()},${order.address.lng.toString()}';
    var fallbackUrl =
        'https://www.google.com/maps/search/?api=1&query=${order.address.lat.toString()},${order.address.lng.toString()}';
    try {
      bool launched =
          await launch(url, forceSafariVC: false, forceWebView: false);
      if (!launched) {
        await launch(fallbackUrl, forceSafariVC: false, forceWebView: false);
      }
    } catch (e) {
      await launch(fallbackUrl, forceSafariVC: false, forceWebView: false);
    }
  }

  void updateToDelivered() async {
    if (_distanceBetween <= 200) {
      ResponseApi responseApi = await _ordersProvider.updateToDelivered(order);
      if (responseApi.success) {
        Fluttertoast.showToast(
            msg: responseApi.message, toastLength: Toast.LENGTH_LONG);
        Navigator.pushNamedAndRemoveUntil(
            context, 'delivery/orders/list', (route) => false);
      }
    } else {
      MySnackbar.show(context, 'คุณต้องอยู่ใกล้ตำแหน่งจัดส่ง');
    }
  }

  Future<void> setPolylines(LatLng from, LatLng to) async {
    PointLatLng pointFrom = PointLatLng(from.latitude, from.longitude);
    PointLatLng pointTo = PointLatLng(to.latitude, to.longitude);
    PolylineResult result = await PolylinePoints().getRouteBetweenCoordinates(
        Environment.API_KEY_MAPS, pointFrom, pointTo);

    for (PointLatLng point in result.points) {
      points.add(LatLng(point.latitude, point.longitude));
    }

    Polyline polyline = Polyline(
        polylineId: PolylineId('poly'),
        color: MyColors.primaryColor,
        points: points,
        width: 6);

    polylines.add(polyline);

    refresh();
  }

  void addMarker(String markerId, double lat, double lng, String title,
      String content, BitmapDescriptor iconMarker) {
    MarkerId id = MarkerId(markerId);
    Marker marker = Marker(
        markerId: id,
        icon: iconMarker,
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: title, snippet: content));

    markers[id] = marker;

    refresh();
  }

  void selectRefPoint() {
    Map<String, dynamic> data = {
      'address': addressName,
      'lat': addressLatLng.latitude,
      'lng': addressLatLng.longitude,
    };

    Navigator.pop(context, data);
  }

  Future<BitmapDescriptor> createMarkerFromAsset(String path) async {
    ImageConfiguration configuration = ImageConfiguration();
    BitmapDescriptor descriptor =
        await BitmapDescriptor.fromAssetImage(configuration, path);
    return descriptor;
  }

  Future<Null> setLocationDraggableInfo() async {
    if (initialPosition != null) {
      double lat = initialPosition.target.latitude;
      double lng = initialPosition.target.longitude;

      List<Placemark> address = await placemarkFromCoordinates(lat, lng);

      if (address != null) {
        if (address.length > 0) {
          String direction = address[0].thoroughfare;
          String street = address[0].subThoroughfare;
          String city = address[0].locality;
          String department = address[0].administrativeArea;
          addressName = '$direction $street, $city, $department';
          addressLatLng = new LatLng(lat, lng);
          // print('LAT: ${addressLatLng.latitude}');
          // print('LNG: ${addressLatLng.longitude}');

          refresh();
        }
      }
    }
  }

  void onMapCreated(GoogleMapController controller) {
    controller.setMapStyle(
        '[{"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]},{"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#eeeeee"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dadada"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},{"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]},{"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#eeeeee"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9c9c9"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}]');
    _mapController.complete(controller);
  }

  void dispose() {
    _positionStream?.cancel();
    socket?.disconnect();
  }

  void updateLocation() async {
    try {
      await _determinePosition();
      _position = await Geolocator.getLastKnownPosition();
      saveLocation();

      animateCameraToPosition(_position.latitude, _position.longitude);
      addMarker('พนักงานส่ง', _position.latitude, _position.longitude,
          'ตำแหน่งของคุณ', '', deliveryMarker);

      addMarker('ที่อยู่ปลายทาง', order.address.lat, order.address.lng,
          'ที่อยู่ปลายทาง', '', homeMarker);

      LatLng from = new LatLng(_position.latitude, _position.longitude);
      LatLng to = new LatLng(order.address.lat, order.address.lng);

      setPolylines(from, to);

      _positionStream = Geolocator.getPositionStream(
              desiredAccuracy: LocationAccuracy.best, distanceFilter: 1)
          .listen((Position position) {
        _position = position;

        emitPosition();

        addMarker('พนักงานส่ง', _position.latitude, _position.longitude,
            'ตำแหน่งของคุณ', '', deliveryMarker);

        animateCameraToPosition(_position.latitude, _position.longitude);
        isCloseToDeliveryPosition();

        refresh();
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  void call() {
    launch("tel:${order.client.phone}");
  }

  void checkGPS() async {
    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    if (isLocationEnabled) {
      updateLocation();
    } else {
      bool locationGPS = await location.Location().requestService();
      if (locationGPS) {
        updateLocation();
      }
    }
  }

  Future animateCameraToPosition(double lat, double lng) async {
    GoogleMapController controller = await _mapController.future;
    if (controller != null) {
      controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 13, bearing: 0)));
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('ตำแหน่งถูกปิดใช้งาน');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('การขออนุญาตตำแหน่งถูกปฏิเสธ');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'การอนุญาตตำแหน่งถูกปฏิเสธอย่างถาวร เราไม่สามารถขออนุญาตได้');
    }

    return await Geolocator.getCurrentPosition();
  }
}
