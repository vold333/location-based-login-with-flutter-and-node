import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _token;
  int? _userId;
  String? _name;
  String? _email;
  String? _phone;
  String? _loginLatitude;
  String? _loginLongitude;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      _userId = prefs.getInt('userId');
      _name = prefs.getString('name');
      _email = prefs.getString('email');
      _phone = prefs.getString('phone');
      _loginLatitude = prefs.getString('login_latitude');
      _loginLongitude = prefs.getString('login_longitude');
      _loading = false;
    });
  }

  Future<bool> _checkLocationEnabledAndPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services to logout.')),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied. Cannot logout.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied forever. Enable it in settings.')),
      );
      return false;
    }

    return true;
  }

  Future<void> _logout() async {
    bool canLogout = await _checkLocationEnabledAndPermission();
    if (!canLogout) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    final response = await http.post(
      Uri.parse('http://192.168.180.30:5000/users/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
      }),
    );

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    } else {
      final error = jsonDecode(response.body)['message'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, User ID: $_userId', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Name: ${_name ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Email: ${_email ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Phone: ${_phone ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Login Latitude: ${_loginLatitude ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Login Longitude: ${_loginLongitude ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
