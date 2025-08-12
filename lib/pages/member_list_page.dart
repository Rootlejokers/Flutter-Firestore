import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'member_form_page.dart';

class MemberListPage extends StatelessWidget {
  const MemberListPage({super.key});

  Future<void> _confirmDelete(BuildContext context, String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer $name ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('membres').doc(id).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membre supprimé')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance.collection('membres');

    return Scaffold(
        appBar: AppBar(
            title: Text('Membres',style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25
            ),),centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: col.orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return const Center(child: Text('Erreur de chargement'));
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('Aucun membre pour le moment'));

              return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data() as Map<String, dynamic>? ?? {};
                    final first = (data['firstName'] ?? '').toString();
                    final last  = (data['lastName'] ?? '').toString();
                    final age   = (data['age'] ?? '').toString();
                    final role  = (data['role'] ?? 'membre').toString();
                    final note  = (data['note'] ?? '').toString();

                    return ListTile(
                        leading: CircleAvatar(child: Text(first.isNotEmpty ? first[0].toUpperCase() : '?')),
                        title: Text('$first $last'),
                        subtitle: Text('Âge: $age — Rôle: $role${note.isNotEmpty ? " — $note" : ""}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MemberFormPage(
                                docId: d.id,
                                existing: data, // Map simple
                              ),
                            ),
                          );
                        },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Supprimer',
                        onPressed: () => _confirmDelete(context, d.id, '$first $last'),
                      ),
                    );
                  },
              );
            },
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemberFormPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}