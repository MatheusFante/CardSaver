import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class LoginPage extends StatelessWidget {
  var txtEmail = TextEditingController();
  var txtPassword = TextEditingController();

    void login(BuildContext context) async
  {
    try 
    {
       await FirebaseAuth // 'await' - aguarde isso responder. Se retornar com sucesso, ele navega. Se der falha, mostra snackbar
        .instance
        .signInWithEmailAndPassword(email: txtEmail.text, password: txtPassword.text);

      Navigator.pushReplacementNamed(context, '/deck');
    }
    on FirebaseAuthException catch(ex) 
    {
      var snackBar = SnackBar(content: Text(ex.message!), backgroundColor: Colors.red,); //monta uma tarja com uma mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(snackBar); //exibe a tarja
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 195, 201, 206),
      body: Container(
        padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: txtEmail,
              decoration: InputDecoration(
                hintText: "E-mail(required)",
                labelText: "E-mail",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(
              height: 6,
            ),
            TextField(
              controller: txtPassword,
              decoration: InputDecoration(
                hintText: "Password",
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(
              height: 6,
            ),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                child: Text("Login"),
                onPressed: () => login(context),
              ),
            ),
            Container(
              width: double.infinity,
              child: TextButton(
                child: Text("New User"),
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
