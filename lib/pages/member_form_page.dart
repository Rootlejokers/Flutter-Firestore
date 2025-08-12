import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MemberFormPage extends StatefulWidget {
  final String? docId;                     // null = création, non-null = édition
  final Map<String, dynamic>? existing;    // valeurs initiales si édition
  const MemberFormPage({super.key, this.docId, this.existing});

  @override
  State<MemberFormPage> createState() => _MemberFormPageState();
}

class _MemberFormPageState extends State<MemberFormPage> {
  final _formKey = GlobalKey<FormState>();

  // ✅ Sans contrôleurs : on garde des variables simples
  String firstName = '';
  String lastName  = '';
  String role      = 'membre';
  String note      = '';
  String ageText   = '';  // on garde le texte saisi pour pouvoir valider

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      firstName = (e['firstName'] ?? '').toString();
      lastName  = (e['lastName'] ?? '').toString();
      role      = (e['role'] ?? 'membre').toString();
      note      = (e['note'] ?? '').toString();
      final a   = e['age'];
      ageText   = a == null ? '' : a.toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final col = FirebaseFirestore.instance.collection('membres');
    try {
      final age = int.tryParse(ageText.trim()) ?? 0;

      if (widget.docId == null) {
        // CREATE
        await col.add({
          'firstName': firstName.trim(),
          'lastName' : lastName.trim(),
          'age'      : age,
          'role'     : role.trim().isEmpty ? 'membre' : role.trim(),
          'note'     : note.trim().isEmpty ? null : note.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membre ajouté')));
      } else {
        // UPDATE
        await col.doc(widget.docId!).update({
          'firstName': firstName.trim(),
          'lastName' : lastName.trim(),
          'age'      : age,
          'role'     : role.trim().isEmpty ? 'membre' : role.trim(),
          'note'     : note.trim().isEmpty ? null : note.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membre modifié')));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Modifier un membre' : 'Nouveau membre')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AbsorbPointer(
            absorbing: _saving, // désactive les champs pendant l'enregistrement
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: firstName,
                          decoration: const InputDecoration(
                            labelText: 'Prénom',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Prénom requis' : null,
                          onChanged: (v) => setState(() => firstName = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: lastName,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                          onChanged: (v) => setState(() => lastName = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: ageText,
                          decoration: const InputDecoration(
                            labelText: 'Âge',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null; // vide accepté = 0
                            final n = int.tryParse(v.trim());
                            if (n == null) return 'Entrez un nombre';
                            if (n < 0) return 'Âge ≥ 0';
                            return null;
                          },
                          onChanged: (v) => setState(() => ageText = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: role,
                          decoration: const InputDecoration(
                            labelText: 'Rôle (admin/staff/membre)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => setState(() => role = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: note,
                    decoration: const InputDecoration(
                      labelText: 'Note (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (v) => setState(() => note = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}