import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // Assurez-vous que ce fichier est généré et importé

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD Tâches',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

// Page d'accueil : affichage de la liste des tâches
class HomePage extends StatelessWidget {
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance.collection('tasks');


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des tâches'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            tasksCollection.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!.docs;
          if (tasks.isEmpty) {
            return Center(child: Text("Aucune tâche pour le moment."));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              var data = tasks[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? ''),
                subtitle: Text(data['description'] ?? ''),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await tasks[index].reference.delete();
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTaskPage(
                        taskId: tasks[index].id,
                        data: data,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskPage()),
          );
        },
      ),
    );
  }
}

// Page pour ajouter une tâche
class AddTaskPage extends StatefulWidget {
  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter une tâche")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Titre"),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Veuillez entrer un titre";
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Description"),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Veuillez entrer une description";
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Ajouter"),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await FirebaseFirestore.instance.collection('tasks').add({
                      'title': _title,
                      'description': _description,
                      'isDone': false,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Page pour modifier une tâche existante
class EditTaskPage extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> data;

  EditTaskPage({required this.taskId, required this.data});

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late bool _isDone;

  @override
  void initState() {
    super.initState();
    _title = widget.data['title'];
    _description = widget.data['description'];
    _isDone = widget.data['isDone'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modifier la tâche")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: "Titre"),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Veuillez entrer un titre";
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
              ),
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: "Description"),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Veuillez entrer une description";
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              CheckboxListTile(
                title: Text("Tâche terminée"),
                value: _isDone,
                onChanged: (value) {
                  setState(() {
                    _isDone = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Mettre à jour"),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await FirebaseFirestore.instance
                        .collection('tasks')
                        .doc(widget.taskId)
                        .update({
                      'title': _title,
                      'description': _description,
                      'isDone': _isDone,
                    });
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
