import 'package:flutter/material.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/app_database.dart';

class ListWidget extends StatefulWidget {
  const ListWidget({super.key});

  @override
  State<ListWidget> createState() => _ListState();
}

class _ListState extends State<ListWidget> {
  DatabaseService databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: databaseService.getAllStatements(),
        builder: (context, asyncSnapshot) {
          if (!asyncSnapshot.hasData) {
            // Show a placeholder while loading
            return Center(child: CircularProgressIndicator());
          }
          if (asyncSnapshot.hasError) {
            return Center(
              child: Text("Error: ${asyncSnapshot.error}"),
            );
          }
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: asyncSnapshot.data!.length,
              itemBuilder: (context, index) {
                final Statement statement = asyncSnapshot.data![index];
                return ListTile(
                  title: Text(statement.title),
                  subtitle: Text(statement.paymentDate.toString()),
                  trailing: Text("\$${statement.amount.toStringAsFixed(2)}"),
                );
              },
            ),
          );
        }
      ),
    );
  }
}
