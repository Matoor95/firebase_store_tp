import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_store_tp/firebase_options.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final CollectionReference tasksCollections =
      FirebaseFirestore.instance.collection('tasks');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Liste des taches"),
        ),
        body: StreamBuilder(
          stream: tasksCollections
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text("Erreur de donnes"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final tasks = snapshot.data!.docs;
            if (tasks.isEmpty) {
              return Center(child: Text("Aucune tache disponible"));
            }
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                var data = tasks[index].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: Text(data['description'] ?? ''),
                );
              },
            );
          },
        ));
  }
}
