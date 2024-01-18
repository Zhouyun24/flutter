import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connect_to_mysql/desktop.dart';

// void main() {
//   runApp(MaterialApp(
//     home: Login(),
//     theme: ThemeData(),
//   ));
// }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Server',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: Login(),
    );
  }
}


class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

enum LoginStatus { notSignIn, signIn }

class _LoginState extends State<Login> {
  LoginStatus _loginStatus = LoginStatus.notSignIn;
  String? email, password;
  final _key = GlobalKey<FormState>();

  bool _secureText = true;

  showHide() {
    setState(() {
      _secureText = !_secureText;
    });
  }

  check() {
    final form = _key.currentState;
    if (form?.validate() ?? false) {
      form?.save();
      _login();
    }
  }

  Future<void> _login() async {
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2/flutterconnect/login.php"),
        body: {"email": email, "password": password},
      );

      print("Raw response: ${response.body}");

      // Check if the response is valid JSON
      if (response.body.isNotEmpty && response.body.startsWith('{')) {
        final data = jsonDecode(response.body);
        dynamic value = data['value']; // Use dynamic type to handle both int and String
        String? pesan = data['message'];
        String? emailAPI = data['email'];
        String? namaAPI = data['nama_pemilik'];
        String? id = data['id_registrasi'];

        if (value == 1 || value == "1") {
          setState(() {
            _loginStatus = LoginStatus.signIn;
            _savePref(value is String ? int.parse(value) : value, emailAPI!, namaAPI!, id!);
          });
          print(pesan);
        } else {
          // Show an alert with the login failure message
          _showLoginFailedDialog(pesan ?? "Login failed");
        }
      } else {
        // Show an alert for invalid JSON format in response
        _showLoginFailedDialog("Invalid JSON format in response");
      }
    } catch (error) {
      print("Error during login: $error");
      // Show an alert for general login error
      _showLoginFailedDialog("Error during login. Please try again.");
    }
  }

  void _showLoginFailedDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Login Failed"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
  // Corrected function name from _savePreff to _savePref
  void _savePref(int value, String email, String nama, String id) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      preferences.setInt("value", value);
      preferences.setString("nama_pemilik", nama);
      preferences.setString("email", email);
      preferences.setString("id_registrasi", id);
    });
  }

  var value;

  getPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      value = preferences.getInt("value");

      _loginStatus = value == 1 ? LoginStatus.signIn : LoginStatus.notSignIn;
    });
  }

  signOut() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      preferences.remove("value");
      _loginStatus = LoginStatus.notSignIn;
    });
  }

  @override
  void initState() {
    super.initState();
    getPref();
  }

  @override
  Widget build(BuildContext context) {
    switch (_loginStatus) {
      case LoginStatus.notSignIn:
        return Scaffold(
          appBar: AppBar(
            title: Text("Login"),
          ),
          body: Form(
            key: _key,
            child: ListView(
              padding: EdgeInsets.all(16.0),
              children: <Widget>[
                TextFormField(
                  validator: (e) {
                    if (e?.isEmpty ?? true) {
                      return "Please insert email";
                    }
                    return null;
                  },
                  onSaved: (e) => email = e,
                  decoration: InputDecoration(
                    labelText: "email",
                  ),
                ),
                TextFormField(
                  obscureText: _secureText,
                  onSaved: (e) => password = e,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      onPressed: showHide,
                      icon: Icon(
                        _secureText ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                MaterialButton(
                  onPressed: () {
                    check();
                  },
                  child: Text("Login"),
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => Register()),
                    );
                  },
                  child: Text(
                    "Create a new account, in here",
                    textAlign: TextAlign.center,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => MyHomePage(title: 'Menu',)),
                    );
                  },
                  child: Text(
                    "Menu",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      case LoginStatus.signIn:
        return MainMenu(signOut);
    }
  }
}

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  String? email, password, nama;
  final _key = new GlobalKey<FormState>();

  bool _secureText = true;

  showHide() {
    setState(() {
      _secureText = !_secureText;
    });
  }

  check() {
    final form = _key.currentState;
    if (form?.validate() ?? false) {
      form?.save();
      save();
    }
  }

  save() async {
    final response = await http.post(
      "http://10.0.0.2/flutterconnect/register.php" as Uri,
      body: {"nama": nama, "email": email, "password": password},
    );
    final data = jsonDecode(response.body);
    int value = data['value'];
    String pesan = data['message'];
    if (value == 1) {
      setState(() {
        Navigator.pop(context);
      });
    } else {
      print(pesan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register"),
      ),
      body: Form(
        key: _key,
        child: ListView(
            padding: EdgeInsets.all(16.0),
            children: <Widget>[
        TextFormField(
        validator: (e) {
      if (e?.isEmpty ?? true) {
      return "Please insert fullname";
      }
      return null;
      },
        onSaved: (e) => nama = e,
        decoration: InputDecoration(labelText: "Nama Lengkap"),
      ),
      TextFormField(
        validator: (e) {
          if (e?.isEmpty ?? true) {
            return "Please insert email";
          }
          return null;
        },
        onSaved: (e) => email = e,
        decoration: InputDecoration(labelText: "email"),
      ),
      TextFormField(
        obscureText: _secureText,
        onSaved: (e) => password = e,
        decoration: InputDecoration(
          labelText: "Password",
          suffixIcon: IconButton(
            onPressed: showHide,
            icon: Icon(
              _secureText ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ),
      ),
      MaterialButton(
          onPressed: () {
            check();
          },
          child: Text("Register"),
    )
    ],
    ),
    ),
    );
  }
}

class MainMenu extends StatefulWidget {
  final VoidCallback signOut;
  MainMenu(this.signOut);
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  signOut() {
    setState(() {
      widget.signOut();
    });
  }

  getPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      // email = preferences.getString("email");
      // nama = preferences.getString("nama");
    });
  }

  @override
  void initState() {
    super.initState();
    getPref();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Halaman Dashboard"),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                signOut();
              },
              icon: Icon(Icons.lock_open),
            )
          ],
        ),
        body: Center(
          child: Text("Dashboard"),
        ),
      ),
    );
  }
}