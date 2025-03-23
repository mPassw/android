import 'package:flutter/material.dart';
import 'package:mpass/dashboard/navigation/passwords/components/passwords_header.dart';
import 'package:mpass/dashboard/navigation/passwords/components/passwords_list_widget.dart';
import 'package:mpass/dashboard/navigation/passwords/components/passwords_searchbar.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PasswordsSearchBar(isTrash: true),
            PasswordsHeader(title: "Trash", icon: Icons.delete_outline),
            PasswordListWidget(isTrash: true),
          ],
        ),
      ),
    );
  }
}
