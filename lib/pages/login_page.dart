import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_page.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class SavedAccount {
  final String email;
  final String fullName;
  final DateTime lastLogin;

  SavedAccount({
    required this.email,
    required this.fullName,
    required this.lastLogin,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'fullName': fullName,
        'lastLogin': lastLogin.toIso8601String(),
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
        email: json['email'],
        fullName: json['fullName'],
        lastLogin: DateTime.parse(json['lastLogin']),
      );
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showSavedAccounts = false;
  List<SavedAccount> _savedAccounts = [];
  SavedAccount? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('saved_accounts');
    
    if (accountsJson != null) {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      setState(() {
        _savedAccounts = decoded.map((json) => SavedAccount.fromJson(json)).toList();
        _savedAccounts.sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
        
        if (_savedAccounts.isNotEmpty) {
          _selectedAccount = _savedAccounts.first;
          _showSavedAccounts = true;
        }
      });
    }
  }

  Future<void> _saveAccount(String email, String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove existing account with same email
    _savedAccounts.removeWhere((acc) => acc.email == email);
    
    // Add new/updated account
    _savedAccounts.insert(0, SavedAccount(
      email: email,
      fullName: fullName,
      lastLogin: DateTime.now(),
    ));
    
    // Keep only last 5 accounts
    if (_savedAccounts.length > 5) {
      _savedAccounts = _savedAccounts.sublist(0, 5);
    }
    
    final accountsJson = jsonEncode(_savedAccounts.map((acc) => acc.toJson()).toList());
    await prefs.setString('saved_accounts', accountsJson);
  }

  Future<void> _removeAccount(SavedAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _savedAccounts.removeWhere((acc) => acc.email == account.email);
      if (_selectedAccount?.email == account.email) {
        _selectedAccount = _savedAccounts.isNotEmpty ? _savedAccounts.first : null;
      }
      if (_savedAccounts.isEmpty) {
        _showSavedAccounts = false;
      }
    });
    
    final accountsJson = jsonEncode(_savedAccounts.map((acc) => acc.toJson()).toList());
    await prefs.setString('saved_accounts', accountsJson);
    
    HapticFeedback.mediumImpact();
  }

  Future<void> _quickLogin(SavedAccount account) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('users')
          .select()
          .eq('email', account.email)
          .maybeSingle();

      if (response != null) {
        await _saveAccount(account.email, response['full_name']);
        HapticFeedback.mediumImpact();
        print('Quick login successful: ${response['full_name']}');

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = 'Account not found. Please log in manually.';
        });
      }
    } catch (e) {
      print('Quick login error: $e');
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _attemptLogin() async {
    FocusScope.of(context).unfocus();
    final email = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty && password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email and password';
      });
      HapticFeedback.mediumImpact();
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
      });
      HapticFeedback.mediumImpact();
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'No password was given';
      });
      HapticFeedback.mediumImpact();
      return;
    }

    if (!email.contains('@student.hau.edu.ph') && !email.contains('@hau.edu.ph')) {
      setState(() {
        _errorMessage = 'Please use your HAU university email';
      });
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        await _saveAccount(email, response['full_name']);
        HapticFeedback.mediumImpact();
        print('Login successful: ${response['full_name']}');

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = 'Invalid credentials. Please verify your email and password.';
        });
      }
    } catch (e) {
      print('Login error: $e');
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'An error occurred during login. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/background.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF610B0B), Color(0xFF8B1818), Color(0xFF610B0B)],
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.25),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenW * 0.08, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Image.asset(
                        'assets/icons/HAU_LOGO2.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF610B0B),
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Login Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 380),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.03),
                              Colors.white.withOpacity(0.06),
                              Colors.white.withOpacity(0.02),
                            ],
                            stops: [0.0, 0.3, 0.7, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            width: 0.5,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 60,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: LiquidGlassPainter(),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [Colors.white, Colors.white.withOpacity(0.95)],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'HAUTRACK',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Lost and Found',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.80),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Saved Accounts Section
                                if (_showSavedAccounts && _savedAccounts.isNotEmpty) ...[
                                  _buildSavedAccountsSection(),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      setState(() => _showSavedAccounts = false);
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Text(
                                      'Use different account',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // Manual Login Form
                                  _buildGlassTextField(
                                    controller: _loginController,
                                    focusNode: _emailFocusNode,
                                    hint: 'University Email',
                                    icon: Icons.mail_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildGlassTextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    hint: 'Password',
                                    icon: Icons.lock_rounded,
                                    obscureText: _obscurePassword,
                                    onSubmitted: (_) => _attemptLogin(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                        color: Colors.white.withOpacity(0.6),
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                        HapticFeedback.lightImpact();
                                      },
                                    ),
                                  ),
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_rounded, color: Colors.white.withOpacity(0.9), size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.95),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  _buildGlassButton(
                                    onPressed: _isLoading ? null : _attemptLogin,
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.9)),
                                            ),
                                          )
                                        : const Text(
                                            'Log In',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_savedAccounts.isNotEmpty)
                                        TextButton(
                                          onPressed: () {
                                            setState(() => _showSavedAccounts = true);
                                            HapticFeedback.lightImpact();
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          child: Text(
                                            'Saved accounts',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      TextButton(
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                  'Please contact the administrator to reset your password.'),
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: Colors.white.withOpacity(0.15),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        ),
                                        child: Text(
                                          'Forgot password?',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'HAU Lost & Found System v1.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/admin');
        },
        backgroundColor: const Color(0xFF550000),
        child: const Icon(Icons.admin_panel_settings, color: Colors.white),
      ),
    );
  }

  Widget _buildSavedAccountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select an account',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _savedAccounts.length,
          itemBuilder: (context, index) {
            final account = _savedAccounts[index];
            return _buildAccountCard(account);
          },
        ),
      ],
    );
  }

  Widget _buildAccountCard(SavedAccount account) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : () => _quickLogin(account),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            account.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              account.email,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.6),
                          size: 18,
                        ),
                        onPressed: () => _removeAccount(account),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Function(String)? onSubmitted,
    Widget? suffixIcon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
                Colors.white.withOpacity(0.08),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 25,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
              ),
              suffixIcon: suffixIcon != null
                  ? Padding(padding: const EdgeInsets.only(right: 10), child: suffixIcon)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: onPressed == null
                  ? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.06)]
                  : [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0.08)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: onPressed == null
                    ? Colors.black.withOpacity(0.03)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed != null
                  ? () {
                      HapticFeedback.mediumImpact();
                      onPressed();
                    }
                  : null,
              borderRadius: BorderRadius.circular(18),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paints = [
      Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..style = PaintingStyle.fill,
      Paint()
        ..color = Colors.white.withOpacity(0.04)
        ..style = PaintingStyle.fill,
      Paint()
        ..color = Colors.white.withOpacity(0.03)
        ..style = PaintingStyle.fill,
    ];

    final path1 = Path();
    path1.moveTo(size.width * 0.05, size.height * 0.15);
    path1.quadraticBezierTo(
      size.width * 0.25, size.height * 0.05,
      size.width * 0.45, size.height * 0.25,
    );
    path1.quadraticBezierTo(
      size.width * 0.65, size.height * 0.45,
      size.width * 0.85, size.height * 0.35,
    );
    path1.quadraticBezierTo(
      size.width * 0.95, size.height * 0.55,
      size.width * 0.75, size.height * 0.75,
    );
    path1.quadraticBezierTo(
      size.width * 0.55, size.height * 0.85,
      size.width * 0.35, size.height * 0.65,
    );
    path1.quadraticBezierTo(
      size.width * 0.15, size.height * 0.45,
      size.width * 0.05, size.height * 0.25,
    );
    path1.close();
    
    canvas.drawPath(path1, paints[0]);

    final path2 = Path();
    path2.moveTo(size.width * 0.8, size.height * 0.1);
    path2.quadraticBezierTo(
      size.width * 0.6, size.height * 0.2,
      size.width * 0.4, size.height * 0.1,
    );
    path2.quadraticBezierTo(
      size.width * 0.2, size.height * 0.3,
      size.width * 0.3, size.height * 0.5,
    );
    path2.quadraticBezierTo(
      size.width * 0.5, size.height * 0.7,
      size.width * 0.7, size.height * 0.6,
    );
    path2.quadraticBezierTo(
      size.width * 0.9, size.height * 0.4,
      size.width * 0.8, size.height * 0.2,
    );
    path2.close();
    
    canvas.drawPath(path2, paints[1]);

    final path3 = Path();
    path3.moveTo(size.width * 0.7, size.height * 0.3);
    path3.quadraticBezierTo(
      size.width * 0.85, size.height * 0.2,
      size.width * 0.9, size.height * 0.4,
    );
    path3.quadraticBezierTo(
      size.width * 0.8, size.height * 0.6,
      size.width * 0.6, size.height * 0.5,
    );
    path3.quadraticBezierTo(
      size.width * 0.5, size.height * 0.7,
      size.width * 0.7, size.height * 0.8,
    );
    path3.close();
    
    canvas.drawPath(path3, paints[2]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}