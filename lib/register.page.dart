import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatelessWidget {
  var txtName = TextEditingController();
  var txtEmail = TextEditingController();
  var txtPassword = TextEditingController();

  void register(BuildContext context) async
  {
    try 
    {
    var credential = await FirebaseAuth
    .instance
    .createUserWithEmailAndPassword(email: txtEmail.text , password: txtPassword.text); //cria um usuário com email e senha

    await credential.user!.updateDisplayName(txtName.text); //atualiza o nome após a criação do usuário

    Navigator.of(context)
    ..pop()
    ..pushReplacementNamed('/deck');
    }
    on FirebaseAuthException catch(ex) 
    {
      var snackBar = SnackBar(content: Text(ex.message!), backgroundColor: Colors.red,); 
      ScaffoldMessenger.of(context).showSnackBar(snackBar); 
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
              controller: txtName,
              decoration: InputDecoration(
                hintText: "Name",
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(
              height: 6,
            ),
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
            // ignore: prefer_const_constructors
            SizedBox(
              height: 6,
            ),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                child: Text("Register"),
                onPressed: () => register(context),
              ),
            ),
            Container(
              width: double.infinity,
              child: TextButton(
                child: Text("Back to Login"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


//metodos para navegar entre telas são push e pop, empilhar e desempilhar