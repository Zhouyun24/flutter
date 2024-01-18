import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:intl/intl.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<List<Map<String, dynamic>>> getMethod() async {
    try {
      String theUrl = 'http://10.0.2.2/flutterconnect/getData.php';
      var res = await http.get(Uri.parse(theUrl), headers: {"Accept": "application/json"});
      print(res.body);

      if (res.statusCode == 200) {
        var responseBody = json.decode(res.body);

        if (responseBody is List) {
          return responseBody.cast<Map<String, dynamic>>();
        } else {
          throw Exception("Invalid response format");
        }
      } else {
        throw Exception("Failed to load data. Status code: ${res.statusCode}");
      }
    } catch (error) {
      print("Error in MySQL query: $error");
      throw error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getMethod(),
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Error fetching data", style: TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Retry fetching data on button press
                      });
                    },
                    child: Text("Retry"),
                  ),
                ],
              ),
            );
          }
          List<Map<String, dynamic>> snap = snapshot.data!;

          return ListView.separated(
            separatorBuilder: (BuildContext context, int index) => SizedBox(height: 16.0), // Add spacing between items
            itemCount: snap.length,
            itemBuilder: (context, index) {
              final String? fotoProduk = snap[index]['foto_produk'];
              final imageBytes = fotoProduk != null ? base64Decode(fotoProduk) : Uint8List(0);

              // Format the price as Indonesian Rupiah (IDR)
              final formattedPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(snap[index]['harga_jual']);

              return ListTile(
                contentPadding: EdgeInsets.all(10.0),
                leading: imageBytes.isNotEmpty
                    ? Container(
                  width: 100,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: MemoryImage(imageBytes),
                    ),
                  ),
                )
                    : Placeholder(),
                title: Text("${snap[index]['nama_produk']}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$formattedPrice"),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}