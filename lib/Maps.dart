import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:marca_location/constantes/Firebase.dart';

class Maps extends StatefulWidget {
  String idViagem;

  Maps({this.idViagem});

  @override
  _MapsState createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  /** controller do map **/
  Completer<GoogleMapController> _controller = Completer();

  /**instacia do firestore **/
  Firestore _banco = Firestore.instance;

  /** inicia camera maps **/
  CameraPosition _positionCamera = CameraPosition(
    target: LatLng(-15.9047264, -47.7741343),
    zoom: 14.4746,
  );

  /** cria o mapa **/
  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  /** inicia lista de marcadores **/
  Set<Marker> _marcadores = {};

  /** metodo que cria o marcado de acordo com o clique **/
  _exibirMarcador(LatLng latLng) async {
    // print('lat long do clique: ' + latLng.toString());

    List<Placemark> listaEndereco = await Geolocator()
        .placemarkFromCoordinates(latLng.latitude, latLng.longitude);

    /** verifica se existe endereco **/
    if (listaEndereco != null && listaEndereco.length > 0) {
      Placemark endereco = listaEndereco[0];
      /** recupera dados do endereco caso exista **/
      String rua = endereco.thoroughfare;
      String cep = endereco.postalCode;
      String local = endereco.locality;

      /** cria marcado de acordo com dados do endereco **/
      Marker markerValue = Marker(
          markerId:
              MarkerId('marcardor-${latLng.latitude}-${latLng.longitude}'),
          position: (latLng),
          infoWindow: InfoWindow(title: rua + cep + local),
          icon: BitmapDescriptor.defaultMarker);
      setState(() {
        _marcadores.add(markerValue);
        /** salva no firebase **/
        Map<String, dynamic> viagem = Map();
        viagem['titulo'] = rua;
        viagem['cep'] = cep;
        viagem['latitude'] = latLng.latitude;
        viagem['longitude'] = latLng.longitude;
        _banco.collection(Firebase.COLECAO_VIAGENS).add(viagem);
      });
    }
  }

  /** metodo que movimenta camera de acordo com usuario **/
  _movimentaCamera() async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(_positionCamera));
  }

  /** metodo que recupera locazacao do usuario **/
  _adicionarListenerLocalizacao() {
    var geolocator = Geolocator();
    var locationOptions = LocationOptions(accuracy: LocationAccuracy.high);

    geolocator.getPositionStream(locationOptions).listen((Position position) {
      setState(() {
        /** atualizacao posicao da camera **/
        _positionCamera = CameraPosition(
            target: LatLng(position.latitude, position.longitude), zoom: 18);
        /** movimenta a camera **/
        _movimentaCamera();
      });
    });
  }

  _recuperaViagemPorId(String idViagem) async {
    if (idViagem != null) {
      /** exibe marcador para id viagem **/
      DocumentSnapshot documentSnapshot = await _banco
          .collection(Firebase.COLECAO_VIAGENS)
          .document(idViagem)
          .get();
      var dados = documentSnapshot.data;
      String cep = dados['cep'];
      String titulo = dados['titulo'];
      LatLng latLng = LatLng(dados['latitude'], dados['longitude']);
      setState(() {
        Marker markerValue = Marker(
            markerId:
                MarkerId('marcardor-${latLng.latitude}-${latLng.longitude}'),
            position: (latLng),
            infoWindow: InfoWindow(title: titulo + cep),
            icon: BitmapDescriptor.defaultMarker);
        _marcadores.add(markerValue);
        _positionCamera = CameraPosition(target: latLng, zoom: 18);
        _movimentaCamera();
      });
    } else {
      _adicionarListenerLocalizacao();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _recuperaViagemPorId(widget.idViagem);
    // _adicionarListenerLocalizacao();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mapa"),
      ),
      body: Container(
        child: GoogleMap(
          markers: _marcadores,
          mapType: MapType.normal,
          initialCameraPosition: _positionCamera,
          onMapCreated: _onMapCreated,
          onLongPress: _exibirMarcador,
          myLocationEnabled: true,
        ),
      ),
    );
  }
}
