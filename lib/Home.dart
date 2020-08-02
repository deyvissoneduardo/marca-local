import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marca_location/Maps.dart';
import 'package:marca_location/constantes/Firebase.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  /** lista  **/
  final _controller = StreamController<QuerySnapshot>.broadcast();

  /**instacia do firestore **/
  Firestore _banco = Firestore.instance;

  /** metodo para abri mapa **/
  _abriMapa(String idViagem) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Maps(idViagem: idViagem,),
        ));
  }

  /** metodo de excluir **/
  _excluirViagem(String idViagem) {
    _banco.collection(Firebase.COLECAO_VIAGENS).document(idViagem).delete();
  }

  /** metodo que adc local **/
  _adicionaLocal() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Maps(),
        ));
  }

  _adicionarListenerViagens() async {
    final stream = _banco.collection(Firebase.COLECAO_VIAGENS)
    .snapshots();
    stream.listen((dados) {
      _controller.add(dados);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _adicionarListenerViagens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Salva Local'),
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          backgroundColor: Color(0xff0022cc),
          onPressed: () {
            _adicionaLocal();
          }),
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        // ignore: missing_return
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
            case ConnectionState.done:
              QuerySnapshot querySnapshot = snapshot.data;
              List<DocumentSnapshot> viagens = querySnapshot.documents.toList();

              return Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                        itemCount: viagens.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot item = viagens[index];
                          String title = item['titulo'];
                          String idViagem = item.documentID;
                          return GestureDetector(
                            onTap: () {
                              _abriMapa( idViagem);
                            },
                            child: Card(
                              /** icon excluir **/
                              child: ListTile(
                                title: Text(title),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () {
                                        _excluirViagem(idViagem);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                  ),
                ],
              );
              break;
          }
        },
      ),
    );
  }
}
