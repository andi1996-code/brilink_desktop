import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/auth_provider.dart';

/// LoginScreen with two-column layout for desktop
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  VoidCallback? _authListener;

  @override
  void initState() {
    super.initState();
    // Set default server URL dari yang terakhir digunakan, atau kosongkan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _serverUrlController.text = auth.lastUsedBaseUrl ?? '';
      // Update the field if session loads later
      _authListener = () {
        final a = Provider.of<AuthProvider>(context, listen: false);
        final savedUrl = a.lastUsedBaseUrl ?? '';
        if (_serverUrlController.text != savedUrl) {
          setState(() {
            _serverUrlController.text = savedUrl;
          });
        }
      };
      auth.addListener(_authListener!);
    });
  }

  @override
  void dispose() {
    if (_authListener != null) {
      try {
        Provider.of<AuthProvider>(
          context,
          listen: false,
        ).removeListener(_authListener!);
      } catch (_) {}
    }
    _usernameController.dispose();
    _passwordController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      bool success = await auth.loginWithCustomUrl(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        _serverUrlController.text.trim(),
      );
      if (success) {
        Navigator.pushReplacementNamed(context, '/transactions');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Login failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.briBlue.withOpacity(0.8),
                  AppColors.briBlue,
                  AppColors.briBlue.withOpacity(0.9),
                ],
              ),
            ),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: size.width > 800 ? 1000 : 800,
                ),
                margin: const EdgeInsets.all(20),
                child: Card(
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Left side: image and title
                      if (size.width > 700)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.briBlue,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(40),
                                topRight: Radius.circular(40),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.briBlue,
                                  AppColors.briBlue.withOpacity(0.8),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 320,
                                    color: AppColors.briBlue,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  'System Management\nTransaksi BRILink',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Selamat datang di sistem manajemen transaksi BRILink. Silakan masuk untuk melanjutkan.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Right side: login form
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(size.width > 700 ? 40 : 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (size.width <= 700) ...[
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.briBlue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  child: Icon(
                                    Icons.account_balance,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'System Management\nTransaksi BRILink',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: AppColors.briBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 30),
                              ],
                              Text(
                                'Login',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.briBlue,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Masukkan kredensial Anda untuk melanjutkan',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 30),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _serverUrlController,
                                      onFieldSubmitted: (value) async {
                                        final url = value.trim();
                                        final uri = Uri.tryParse(url);
                                        if (uri != null && uri.hasScheme) {
                                          await Provider.of<AuthProvider>(
                                            context,
                                            listen: false,
                                          ).setLastUsedBaseUrl(url);
                                        }
                                      },
                                      onEditingComplete: () async {
                                        final url = _serverUrlController.text
                                            .trim();
                                        final uri = Uri.tryParse(url);
                                        if (uri != null && uri.hasScheme) {
                                          await Provider.of<AuthProvider>(
                                            context,
                                            listen: false,
                                          ).setLastUsedBaseUrl(url);
                                        }
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Server URL',
                                        prefixIcon: const Icon(Icons.dns),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColors.briBlue,
                                            width: 2,
                                          ),
                                        ),
                                        hintText:
                                            'Masukkan URL server (contoh: https://api.example.com)',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Server URL tidak boleh kosong';
                                        }
                                        final uri = Uri.tryParse(value);
                                        if (uri == null || !uri.hasScheme) {
                                          return 'Format URL tidak valid';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _usernameController,
                                      decoration: InputDecoration(
                                        labelText: 'Username',
                                        prefixIcon: const Icon(Icons.person),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColors.briBlue,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Username tidak boleh kosong';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(Icons.lock),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColors.briBlue,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      obscureText: _obscurePassword,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password tidak boleh kosong';
                                        }
                                        if (value.length < 6) {
                                          return 'Password minimal 6 karakter';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _onLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.briBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 5,
                                    shadowColor: AppColors.briBlue.withOpacity(
                                      0.4,
                                    ),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Close button positioned at top right
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: () => exit(0),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              tooltip: 'Tutup Aplikasi',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
