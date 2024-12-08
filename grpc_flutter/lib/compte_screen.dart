import 'package:flutter/material.dart';
import 'services/grpc_client.dart';
import 'config/grpc_config.dart';
import 'package:grpc/grpc.dart';
import 'generated/compte_service.pbgrpc.dart';

class CompteScreen extends StatefulWidget {
  const CompteScreen({super.key});

  @override
  _CompteScreenState createState() => _CompteScreenState();
}

class _CompteScreenState extends State<CompteScreen> {
  final grpcClient = GrpcClient();
  List<Compte> comptes = [];
  bool isLoading = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadComptes();
  }

  Future<void> loadComptes() async {
    setState(() => isLoading = true);
    try {
      final response = await grpcClient.client.allComptes(GetAllComptesRequest());
      setState(() => comptes = response.comptes);
    } catch (e) {
      _showErrorSnackBar('Failed to load accounts: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> deleteCompte(String id) async {
    try {
      final request = DeleteByIdRequest()..id = id;
      final response = await grpcClient.client.deleteById(request);
      if (response.success) {
        setState(() {
          comptes.removeWhere((compte) => compte.id == id);
        });
        _showSuccessSnackBar('Account deleted successfully');
      } else {
        _showErrorSnackBar('Failed to delete account');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete account: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comptes Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isLoading ? null : loadComptes,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : comptes.isEmpty
              ? Center(
                  child: Text('No accounts found'),
                )
              : RefreshIndicator(
                  onRefresh: loadComptes,
                  child: ListView.builder(
                    itemCount: comptes.length,
                    itemBuilder: (context, index) {
                      final compte = comptes[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(
                            'Solde: ${compte.solde.toStringAsFixed(2)}€',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Type: ${compte.type}'),
                              Text('Created: ${compte.dateCreation}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteCompte(compte.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: isSaving ? null : () => _showAddCompteDialog(context),
        child: isSaving ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.add),
      ),
    );
  }

  void _showAddCompteDialog(BuildContext context) {
    double? solde;
    var type = TypeCompte.COURANT;  // Set initial value of type

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) => AlertDialog(
        title: Text('Add New Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Solde',
                prefixText: '€',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => solde = double.tryParse(value),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<TypeCompte>(
              value: type,
              decoration: InputDecoration(
                labelText: 'Account Type',
                border: OutlineInputBorder(),
              ),
              items: TypeCompte.values.map((t) =>
                DropdownMenuItem(value: t, child: Text(t.name))
              ).toList(),
              onChanged: (newType) {
                if (newType != null) {
                  setState(() {
                    type = newType;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: isSaving ? null : () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
                    if (solde == null) {
                      _showErrorSnackBar('Please enter a valid amount');
                      return;
                    }

                    setState(() => isSaving = true);
                    try {
                      final request = SaveCompteRequest()
                        ..compte = (CompteRequest()
                          ..solde = solde!
                          ..dateCreation = DateTime.now().toIso8601String()
                          ..type = type);  // Assign the enum directly
                      
                      // Save account to backend
                      await grpcClient.client.saveCompte(request);

                      // Add the new account to the local list
                      final newCompte = Compte()
                        ..solde = solde!
                        ..dateCreation = DateTime.now().toIso8601String()
                        ..type = type;  // Store the type as enum directly
                       
                      setState(() {
                        comptes.add(newCompte);
                      });

                      Navigator.pop(context);
                      _showSuccessSnackBar('Account created successfully');
                    } catch (e) {
                      _showErrorSnackBar('Failed to create account: ${e.toString()}');
                    } finally {
                      setState(() => isSaving = false);
                    }
                  },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
