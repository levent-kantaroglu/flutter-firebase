import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase/book.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

enum ProgressStatus { active, passive }

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference booksCollectionReference;
  List<Book> books = [];
  ProgressStatus progressStatus = ProgressStatus.passive;

  @override
  void initState() {
    super.initState();
    getBooks();
  }

  Future<void> getBooks() async {
    setState(() {
      progressStatus = ProgressStatus.active;
    });
    books = [];
    booksCollectionReference = firestore.collection("books");
    booksCollectionReference.get().then((QuerySnapshot querySnapshot) {
      print("Books length " + querySnapshot.docs.length.toString());
      querySnapshot.docs.forEach((QueryDocumentSnapshot queryDocumentSnapshot) {
        Book currentBook = Book(
          id: queryDocumentSnapshot.id,
          title: queryDocumentSnapshot.data()["title"],
          author: queryDocumentSnapshot.data()["title"],
          page: queryDocumentSnapshot.data()["page"],
          category: queryDocumentSnapshot.data()["category"],
        );
        books.add(currentBook);
      });
      setState(() {
        progressStatus = ProgressStatus.passive;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return (progressStatus == ProgressStatus.active)
        ? progressWidget
        : Scaffold(
            appBar: appBar,
            body: body,
            floatingActionButton: fab,
          );
  }

  Widget get body {
    return Center(
      child: (books.length == 0)
          ? Text(
              "Liste boş",
              textAlign: TextAlign.center,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                for (Book book in books) bookItemWidget(book),
              ],
            ),
    );
  }

  Widget get progressWidget {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget get appBar => AppBar(
        leading: Center(
          child: FlutterLogo(),
        ),
        title: Text('Flutter & Firebase'),
        actions: appBarActionButtons,
      );

  List<Widget> get appBarActionButtons => [
        IconButton(
          icon: Icon(Icons.delete_outline),
          onPressed: deleteBooks,
        ),
      ];

  Widget bookItemWidget(Book book) {
    return ExpansionTile(
      leading: Icon(Icons.book),
      title: Text(book.title),
      subtitle: Text(book.author),
      childrenPadding: EdgeInsets.all(10),
      children: [
        Text("Sayfa sayısı ${book.page}"),
        Text("Kategori ${book.category}"),
      ],
    );
  }

  Widget get fab {
    return FloatingActionButton(
      child: Icon(Icons.add_circle_outline),
      onPressed: addBook,
    );
  }

  void addBook() async {
    setState(() {
      progressStatus = ProgressStatus.active;
    });
    await booksCollectionReference.add({
      "title": "Yeni Kitap",
      "author": "Ben Deniz",
      "page": 45,
      "category": [],
    });
    setState(() {
      progressStatus = ProgressStatus.passive;
    });
    getBooks();
  }

  void deleteBooks() {
    setState(() {
      progressStatus = ProgressStatus.active;
    });
    books.forEach((Book book) async {
      await booksCollectionReference.doc(book.id).delete();
    });
    setState(() {
      progressStatus = ProgressStatus.passive;
    });
    getBooks();
  }
}
