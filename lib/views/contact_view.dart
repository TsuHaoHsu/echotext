import 'package:echotext/components/contact_popup.dart';
import 'package:flutter/material.dart';

class ContactView extends StatefulWidget {
  const ContactView({super.key});

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
final List<String> contacts = [
  "Jason",
  "Hank",
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index){
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(contacts[index]),
            onTap: () => {
              // open each contact
              showModalBottomSheet(
                context: context, 
                builder: (BuildContext context){
                  return ContactPopup(contactName: contacts[index]);
                },
              )
            },
          );
        }
      )
    );
  }
}