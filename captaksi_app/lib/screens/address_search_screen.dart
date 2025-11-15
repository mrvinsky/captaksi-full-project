import 'package:captaksi_app/models/place_model.dart';
import 'package:captaksi_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final _controller = TextEditingController();
  final _apiService = ApiService();
  List<PlaceSuggestion> _suggestions = [];
  String? _sessionToken;

  @override
  void initState() {
    super.initState();
    // Her arama ekranı açıldığında yeni bir session token oluştur
    _sessionToken = const Uuid().v4();
  }

  void _onInputChanged(String input) async {
    if (input.isNotEmpty && _sessionToken != null) {
      try {
        final suggestions = await _apiService.fetchSuggestions(input, _sessionToken!);
        setState(() {
          _suggestions = suggestions;
        });
      } catch (e) {
        print(e);
      }
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onInputChanged,
          decoration: const InputDecoration(
            hintText: 'Bir adres arayın...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(suggestion.description),
            onTap: () async {
              try {
                final placeDetails = await _apiService.getPlaceDetails(suggestion.placeId, _sessionToken!);
                // Seçilen adresi bir önceki ekrana geri gönder
                if (mounted) {
                  Navigator.of(context).pop(placeDetails);
                }
              } catch (e) {
                print(e);
              }
            },
          );
        },
      ),
    );
  }
}
