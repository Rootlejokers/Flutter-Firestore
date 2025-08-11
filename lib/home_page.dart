import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(title: Text("Liste des Produits",style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold
      ),
      ),
        backgroundColor: Colors.blue,foregroundColor: Colors.white,centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FirebaseFirestore.instance.collection('produits').add({
            'nom': 'Cahier',
            'prix': 1000,
          });
        },foregroundColor: Colors.blue,backgroundColor: Colors.blue.shade50,
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('produits').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text("Erreur de chargement");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          final data = snapshot.data!.docs;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final produits = data[index];
              return ListTile(
                title: Text(produits['nom']),
                subtitle: Text("${produits['prix']} XAF"),
              );
            },
          );
        },
      ),

    );
  }
}
