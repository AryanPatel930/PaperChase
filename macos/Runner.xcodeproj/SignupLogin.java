import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class SignupLogin extends StatefulWidget {
  const SignupLogin({super.key});

  @override
  _SignupLoginState createState() => _SignupLoginState();
}

class _SignupLoginState extends State<SignupLogin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'created_at': Timestamp.now(),
      });

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup Failed: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required.";
    if (value.length < 12) return "Password must be at least 12 characters.";
    if (!RegExp(r'[A-Z]').hasMatch(value)) return "Must contain 1 uppercase letter.";
    if (!RegExp(r'[a-z]').hasMatch(value)) return "Must contain 1 lowercase letter.";
    if (!RegExp(r'\d').hasMatch(value)) return "Must contain 1 number.";
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) return "Must contain 1 special character.";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First Name')),
              TextFormField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last Name')),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: _validatePassword),
              TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true),
              const SizedBox(height: 20),
              _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _signUp, child: const Text('Sign Up')),
            ],
          ),
        ),
      ),
    );
  }
}
