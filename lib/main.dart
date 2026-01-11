import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

/// ======================= UI HELPERS =======================

AppBar appBarBase(
  String title, {
  Color bg = const Color(0xFFFFFDF5),
  bool centerTitle = false,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
}) {
  return AppBar(
    title: Text(title),
    backgroundColor: bg,
    elevation: 0,
    centerTitle: centerTitle,
    actions: actions,
    automaticallyImplyLeading: automaticallyImplyLeading,
  );
}

Future<void> showOpenSettingsHelp(BuildContext context, {required String forWhat}) async {
  
  // UI-only (no extra deps). You can add url_launcher or permission_handler later.
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Enable Permission'),
      content: Text(
        'To use $forWhat, please enable permission in:\n\n'
        'Settings → Apps → Plantlly → Permissions → Allow\n\n'
        'Then come back and try again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// ======================= APP ROOT =======================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plantlly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: const Color(0xFFDFF5D8),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// ======================= SIMPLE AUTH STATE =======================

class AppUser {
  final String username;
  final String email;
  final String phone;
  final String password;

  const AppUser({
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
  });
}

// In-memory user storage (demo only)
final List<AppUser> _registeredUsers = [];
final ValueNotifier<AppUser?> currentUserNotifier = ValueNotifier<AppUser?>(null);

void _ensureUserInMemory(AppUser user) {
  final exists = _registeredUsers.any((u) => u.email.toLowerCase() == user.email.toLowerCase());
  if (!exists) _registeredUsers.add(user);
}


/// ======================= DISEASE DATA MODEL =======================

class PlantDisease {
  final String crop;
  final String name;
  final String summary;
  final String suggestedActions;
  final String overview;
  final String symptoms;
  final String management;

  const PlantDisease({
    required this.crop,
    required this.name,
    required this.summary,
    required this.suggestedActions,
    required this.overview,
    required this.symptoms,
    required this.management,
  });
}


final List<PlantDisease> plantDiseases = [
  // ================= TOMATO =================
  const PlantDisease(
    crop: 'Tomato',
    name: 'Healthy',
    summary: '• Leaf appears healthy.\n• No strong disease patterns detected.',
    suggestedActions:
        '• Keep regular watering and balanced nutrition.\n'
        '• Avoid wetting leaves for long periods.\n'
        '• Keep monitoring (new symptoms can appear later).',
    overview: 'The model predicted a healthy tomato leaf.',
    symptoms: '• No major spots, halos, or mold-like growth detected.',
    management:
        '• Maintain field hygiene.\n'
        '• Ensure good airflow between plants.\n'
        '• Monitor weekly for early symptoms.',
  ),
  const PlantDisease(
    crop: 'Tomato',
    name: 'Early blight',
    summary: '• Dark concentric spots.\n• Often starts on older leaves.',
    suggestedActions:
        '• Remove heavily affected leaves.\n'
        '• Improve airflow (spacing/pruning).\n'
        '• Avoid overhead irrigation.',
    overview: 'Fungal leaf disease commonly triggered by warm + humid conditions.',
    symptoms: '• “Target-like” rings on spots.\n• Yellowing around lesions.',
    management:
        '• Remove plant debris.\n'
        '• Rotate crops.\n'
        '• Use recommended fungicide only if required by your local guidance.',
  ),
  const PlantDisease(
    crop: 'Tomato',
    name: 'Late blight',
    summary: '• Water-soaked lesions.\n• Can spread fast in cool/wet weather.',
    suggestedActions:
        '• Remove infected tissue.\n'
        '• Reduce leaf wetness.\n'
        '• Separate sick plants if possible.',
    overview: 'Aggressive disease that can rapidly damage tomato foliage.',
    symptoms: '• Dark irregular lesions.\n• Possible white growth underneath leaves in humidity.',
    management:
        '• Improve airflow.\n'
        '• Monitor daily during high-risk weather.\n'
        '• Follow local control recommendations if outbreaks occur.',
  ),
  const PlantDisease(
    crop: 'Tomato',
    name: 'Leaf mold',
    summary: '• Yellow patches on top.\n• Olive/velvety mold under leaf.',
    suggestedActions:
        '• Reduce humidity.\n'
        '• Increase ventilation.\n'
        '• Remove affected leaves.',
    overview: 'Common in humid, poorly ventilated environments.',
    symptoms: '• Pale spots above.\n• Mold growth underneath.',
    management:
        '• Avoid wet foliage.\n'
        '• Space plants.\n'
        '• Use resistant varieties if available.',
  ),
  const PlantDisease(
    crop: 'Tomato',
    name: 'Septoria leaf spot',
    summary: '• Small round spots.\n• Often many spots per leaf.',
    suggestedActions:
        '• Remove affected leaves.\n'
        '• Avoid splashing water from soil.\n'
        '• Improve airflow.',
    overview: 'Leaf-spot disease that typically starts on lower leaves.',
    symptoms: '• Tiny spots with darker border.\n• Yellowing as infection spreads.',
    management:
        '• Sanitation + crop rotation.\n'
        '• Mulch to reduce soil splash.\n'
        '• Local fungicide guidance if needed.',
  ),
  const PlantDisease(
    crop: 'Tomato',
    name: 'Spider mites',
    summary: '• Speckled leaves.\n• Fine webbing may appear.',
    suggestedActions:
        '• Spray water under leaves (lightly).\n'
        '• Remove heavily infested leaves.\n'
        '• Isolate affected plant if possible.',
    overview: 'Pest damage (not fungus). Often worse in hot/dry conditions.',
    symptoms: '• Tiny yellow/white specks.\n• Webbing on underside.',
    management:
        '• Increase humidity slightly.\n'
        '• Use safe pest control options based on local recommendations.',
  ),
  const PlantDisease(
    crop: 'Tomato',
    name: 'Target spot',
    summary: '• Circular lesions with rings.\n• May enlarge over time.',
    suggestedActions:
        '• Remove infected leaves.\n'
        '• Improve airflow.\n'
        '• Avoid overhead watering.',
    overview: 'Fungal-like spotting pattern that can reduce leaf area.',
    symptoms: '• Target-like rings.\n• Yellowing around spots.',
    management: '• Field hygiene + ventilation.\n• Rotate crops.',
  ),
  const PlantDisease(
    crop: 'Tomato',
    name: 'Yellow leaf curl virus',
    summary: '• Leaf curling.\n• Yellowing and reduced growth.',
    suggestedActions:
        '• Remove severely affected plants.\n'
        '• Control whiteflies (main spreader).\n'
        '• Use healthy seedlings.',
    overview: 'Virus disease commonly spread by whiteflies.',
    symptoms: '• Curling + yellow margins.\n• Stunted growth.',
    management:
        '• Vector control (whiteflies).\n'
        '• Use resistant varieties when available.',
  ),
  const PlantDisease(
    crop: 'Tomato',
    name: 'Mosaic virus',
    summary: '• Mosaic pattern.\n• Distorted leaves possible.',
    suggestedActions:
        '• Remove infected plants.\n'
        '• Disinfect tools.\n'
        '• Avoid handling plants when wet.',
    overview: 'Virus causing mottled leaf patterns and deformation.',
    symptoms: '• Light/dark mosaic patches.\n• Leaf distortion.',
    management:
        '• Sanitation.\n'
        '• Use clean seed/seedlings.\n'
        '• Control mechanical spread.',
  ),
  const PlantDisease(
    crop: 'Tomato',
    name: 'General issue',
    summary: '• Tomato-related class detected.\n• Not mapped to a specific card yet.',
    suggestedActions: '• Check the leaf visually.\n• Compare with known symptoms.\n• Re-scan with clearer image.',
    overview: 'This is a fallback card when the predicted class is not mapped.',
    symptoms: '• Varies by condition.',
    management: '• Use best practices: airflow, hygiene, avoid wet foliage.',
  ),  

  // ================= POTATO =================
  const PlantDisease(
    crop: 'Potato',
    name: 'Healthy',
    summary: '• Leaf appears healthy.\n• No strong disease pattern detected.',
    suggestedActions: '• Maintain irrigation.\n• Keep scouting regularly.',
    overview: 'The model predicted a healthy potato leaf.',
    symptoms: '• No obvious lesions or mold growth.',
    management: '• Keep preventive care.\n• Monitor lower leaves first.',
  ),
  const PlantDisease(
    crop: 'Potato',
    name: 'Early blight',
    summary: '• Brown spots with rings.\n• Often on older leaves.',
    suggestedActions: '• Remove debris.\n• Improve airflow.\n• Reduce leaf wetness.',
    overview: 'Common potato leaf fungal disease.',
    symptoms: '• Target-like rings.\n• Yellowing.',
    management: '• Crop rotation.\n• Local protection guidance.',
  ),
  const PlantDisease(
    crop: 'Potato',
    name: 'Late blight',
    summary: '• Dark wet lesions.\n• Can spread rapidly.',
    suggestedActions: '• Remove infected foliage.\n• Avoid overhead watering.\n• Monitor closely.',
    overview: 'High-risk disease in cool/wet conditions.',
    symptoms: '• Dark patches.\n• Possible white growth in humidity.',
    management: '• Hygiene.\n• Follow local recommendations.',
  ),
  const PlantDisease(
    crop: 'Potato',
    name: 'General issue',
    summary: '• Potato-related class detected.\n• Not mapped to a specific card yet.',
    suggestedActions: '• Re-scan.\n• Check lighting + focus.',
    overview: 'Fallback potato card.',
    symptoms: '• Varies.',
    management: '• Field hygiene + monitoring.',
  ),
];


PlantDisease mapClassNameToDisease(String className) {
  final c = className.toLowerCase().trim();

  bool has(String s) => c.contains(s);

  // --- TOMATO ---
  if (has('tomato')) {
    if (has('healthy')) return plantDiseases.firstWhere((d) => d.crop == 'Tomato' && d.name == 'Healthy');
    if (has('early_blight')) return plantDiseases.firstWhere((d) => d.crop == 'Tomato' && d.name == 'Early blight');
    if (has('late_blight')) return plantDiseases.firstWhere((d) => d.crop == 'Tomato' && d.name == 'Late blight');
    if (has('leaf_mold') || has('mold_leaf') || has('tomato_mold')) {
      return plantDiseases.firstWhere((d) => d.crop == 'Tomato' && d.name == 'Leaf mold');
    }
    if (has('septoria')) return plantDiseases.firstWhere((d) => d.crop == 'Tomato' && d.name == 'Septoria leaf spot');
    if (has('spider_mites')) return plantDiseases.firstWhere((d) => d.crop == 'Tomato' && d.name == 'Spider mites');
    if (has('target_spot')) return plantDiseases.firstWhere((d) => d.crop == 'Tomato' && d.name == 'Target spot');
    if (has('yellowleaf') || has('curl_virus') || has('yellow_virus')) {
      return plantDiseases.firstWhere((d) => d.crop == 'Tomato' && d.name == 'Yellow leaf curl virus');
    }
    if (has('mosaic_virus')) return plantDiseases.firstWhere((d) => d.crop == 'Tomato' && d.name == 'Mosaic virus');

    return plantDiseases.firstWhere((d) => d.crop == 'Tomato' && d.name == 'General issue');
  }

  // --- POTATO ---
  if (has('potato')) {
    if (has('healthy')) return plantDiseases.firstWhere((d) => d.crop == 'Potato' && d.name == 'Healthy');
    if (has('early_blight')) return plantDiseases.firstWhere((d) => d.crop == 'Potato' && d.name == 'Early blight');
    if (has('late_blight')) return plantDiseases.firstWhere((d) => d.crop == 'Potato' && d.name == 'Late blight');
    return plantDiseases.firstWhere((d) => d.crop == 'Potato' && d.name == 'General issue');
  }

  // --- PEPPER ---
  if (has('pepper') || has('bell_pepper')) {
    if (has('healthy')) return plantDiseases.firstWhere((d) => d.crop == 'Pepper' && d.name == 'Healthy');
    if (has('bacterial_spot')) return plantDiseases.firstWhere((d) => d.crop == 'Pepper' && d.name == 'Bacterial spot');
    return plantDiseases.firstWhere((d) => d.crop == 'Pepper' && d.name == 'General issue');
  }

  // --- APPLE / GRAPE (if your bundle contains them) ---

  // fallback
  return plantDiseases.first;
}

/// ======================= PERSISTENCE HELPERS =======================

Future<void> saveUser(AppUser user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('username', user.username);
  await prefs.setString('email', user.email);
  await prefs.setString('phone', user.phone);
  await prefs.setString('password', user.password);
}

Future<AppUser?> loadUser() async {
  final prefs = await SharedPreferences.getInstance();

  final username = prefs.getString('username');
  final email = prefs.getString('email');
  final phone = prefs.getString('phone');
  final password = prefs.getString('password');

  if (username == null || email == null || password == null) return null;

  return AppUser(
    username: username,
    email: email,
    phone: phone ?? '',
    password: password,
  );
}

Future<void> clearUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('username');
  await prefs.remove('email');
  await prefs.remove('phone');
  await prefs.remove('password');
}

/// ======================= SPLASH =======================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  // Bootstrapping the app: Check for saved user and navigate accordingly
  Future<void> _bootstrap() async {
  await Future.delayed(const Duration(seconds: 2));  // Simulate splash screen delay

  if (!mounted) return;  // Ensure widget is still mounted

  final savedUser = await loadUser();  // Load user from shared preferences

  if (savedUser != null) {
    _ensureUserInMemory(savedUser);  // Restore user to in-memory list
    currentUserNotifier.value = savedUser;  // Update the current user
    if (!mounted) return; // Add mounted check before navigation
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),  // Navigate to HomeShell if user is found
    );
  } else {
    if (!mounted) return; // Add mounted check before navigation
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),  // Navigate to LoginScreen if no user is found
    );
  }
}

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFD9F5D1);  // Light green background
    const darkGreen = Color(0xFF2E7D32);  // Dark green color for text and icon

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: Icon(Icons.spa, size: 60, color: darkGreen),  // The spa icon
            ),
            const SizedBox(height: 24),  // Space between icon and text
            const Text(
              'Plantlly',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,  // Bold font
                color: darkGreen,  // Dark green text color
                letterSpacing: 0.5,  // Small letter spacing
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ======================= LOGIN =======================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // username or email
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final id = _identifierController.text.trim();
    final pw = _passwordController.text;

    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final idLower = id.toLowerCase();
    final match = _registeredUsers.where((u) {
      return (u.username.toLowerCase() == idLower || u.email.toLowerCase() == idLower) && u.password == pw;
    }).toList();

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No matching account found or wrong password.\n'
            'Please sign up first if you don\'t have an account.',
          ),
        ),
      );
      return;
    }

    final user = match.first;
    _ensureUserInMemory(user);
    currentUserNotifier.value = user;
    await saveUser(user);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);
    const darkGreen = Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Icon(Icons.spa, size: 64, color: darkGreen),
                const SizedBox(height: 12),
                const Text(
                  'Welcome to Plantlly',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: darkGreen),
                ),
                const SizedBox(height: 4),
                const Text('Log in to continue', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _identifierController,
                        decoration: const InputDecoration(
                          labelText: 'Username or Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your username or email.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'Please enter your password.' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Forgot password flow will be added later.')),
                            );
                          },
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _tryLogin,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Log In'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?'),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ======================= SIGNUP =======================

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _trySignup() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final exists = _registeredUsers.any((u) =>
        u.username.toLowerCase() == username.toLowerCase() || u.email.toLowerCase() == email.toLowerCase());

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An account with that username or email already exists.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _registeredUsers.add(
      AppUser(username: username, email: email, phone: phone, password: password),
    );

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created. You can now log in.')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase('Sign up', bg: bg),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 4),
              const Text(
                'Create your Plantlly account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a username.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter an email.';
                        if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a phone number.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a password.';
                        if (v.length < 6) return 'Password must be at least 6 characters.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _trySignup,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




/// ======================= HISTORY MODEL + PERSISTENCE =======================

class ScanPreview {
  final String date;
  final String time;
  final String plantName;

  const ScanPreview({
    required this.date,
    required this.time,
    required this.plantName,
  });

  Map<String, dynamic> toJson() => {'date': date, 'time': time, 'plantName': plantName};

  static ScanPreview fromJson(Map<String, dynamic> json) {
    return ScanPreview(
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      plantName: (json['plantName'] ?? '').toString(),
    );
  }
}

final ValueNotifier<List<ScanPreview>> historyNotifier = ValueNotifier<List<ScanPreview>>([]);

Future<void> saveHistory(List<ScanPreview> scans) async {
  final prefs = await SharedPreferences.getInstance();
  final list = scans.map((e) => e.toJson()).toList();
  await prefs.setString('scan_history', jsonEncode(list));
}

Future<List<ScanPreview>> loadHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('scan_history');
  if (raw == null) return [];

  final decoded = jsonDecode(raw);
  if (decoded is! List) return [];

  return decoded.map((e) => ScanPreview.fromJson(Map<String, dynamic>.from(e as Map))).toList();
}

/// ======================= NOTIFICATIONS MODEL + PERSISTENCE =======================

class AppNotification {
  final String title;
  final String message;
  final String time; // simple display string

  const AppNotification({
    required this.title,
    required this.message,
    required this.time,
  });

  Map<String, dynamic> toJson() => {'title': title, 'message': message, 'time': time};

  static AppNotification fromJson(Map<String, dynamic> json) {
    return AppNotification(
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
    );
  }
}

final ValueNotifier<List<AppNotification>> notificationsNotifier = ValueNotifier<List<AppNotification>>([]);

Future<void> saveNotifications(List<AppNotification> items) async {
  final prefs = await SharedPreferences.getInstance();
  final list = items.map((e) => e.toJson()).toList();
  await prefs.setString('app_notifications', jsonEncode(list));
}

Future<List<AppNotification>> loadNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('app_notifications');
  if (raw == null) return [];

  final decoded = jsonDecode(raw);
  if (decoded is! List) return [];

  return decoded.map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map))).toList();
}

Future<void> addNotification(AppNotification n) async {
  final current = List<AppNotification>.from(notificationsNotifier.value);
  current.add(n);
  notificationsNotifier.value = current;
  await saveNotifications(current);
}

Future<void> clearNotifications() async {
  notificationsNotifier.value = [];
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('app_notifications');
}

/// ======================= API INFERENCE =======================

class InferenceItem {
  final int classIndex;
  final String className;
  final double confidence;

  InferenceItem({
    required this.classIndex,
    required this.className,
    required this.confidence,
  });

  factory InferenceItem.fromJson(Map<String, dynamic> j) {
    return InferenceItem(
      classIndex: j['class_index'] as int,
      className: j['class_name'].toString(),
      confidence: (j['confidence'] as num).toDouble(),
    );
  }
}

class InferenceResponse {
  final String modelUsed;
  final List<InferenceItem> topk;

  InferenceResponse({required this.modelUsed, required this.topk});

  factory InferenceResponse.fromJson(Map<String, dynamic> j) {
    return InferenceResponse(
      modelUsed: j['model_used'].toString(),
      topk: (j['topk'] as List)
          .map((e) => InferenceItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DualInferenceResult {
  final InferenceResponse eff;
  final InferenceResponse mob;
  final InferenceItem bestItem;
  final String bestModel;

  DualInferenceResult({
    required this.eff,
    required this.mob,
    required this.bestItem,
    required this.bestModel,
  });
}

String apiBaseUrl() {
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}

Future<InferenceResponse> predictFromApi({
  required Uint8List imageBytes,
  String model = 'efficientnet_b3',
  int topk = 3,
}) async {
  final uri = Uri.parse('${apiBaseUrl()}/predict?model=$model&topk=$topk');

  final req = http.MultipartRequest('POST', uri);
  req.files.add(
    http.MultipartFile.fromBytes('file', imageBytes, filename: 'leaf.jpg'),
  );

  final res = await req.send();
  final body = await res.stream.bytesToString();

  if (res.statusCode != 200) {
    throw Exception('API error ${res.statusCode}: $body');
  }

  return InferenceResponse.fromJson(jsonDecode(body));
}

class BestPrediction {
  final String modelUsed;
  final InferenceItem item;

  BestPrediction({required this.modelUsed, required this.item});
}

BestPrediction pickBestOfTwo(InferenceResponse a, InferenceResponse b) {
  final aBest = a.topk.first;
  final bBest = b.topk.first;

  if (aBest.confidence >= bBest.confidence) {
    return BestPrediction(modelUsed: a.modelUsed, item: aBest);
  } else {
    return BestPrediction(modelUsed: b.modelUsed, item: bBest);
  }
}

/// ======================= HOME SHELL (BOTTOM NAV) =======================

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final loaded = await loadNotifications();
    notificationsNotifier.value = loaded;
  }

  Future<void> _loadHistory() async {
    final loaded = await loadHistory();
    historyNotifier.value = loaded;
  }

  void _goTo(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardTab(onOpenHistoryTab: () => _goTo(2)),
      const LibraryTab(),
      const HistoryTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class PredictPlantDiseaseScreen extends StatefulWidget {
  const PredictPlantDiseaseScreen({super.key}); // Added key to super constructor

  @override
  PredictPlantDiseaseScreenState createState() => PredictPlantDiseaseScreenState(); // Changed to public name
}

class PredictPlantDiseaseScreenState extends State<PredictPlantDiseaseScreen> { // Removed underscore for public class
  final _picker = ImagePicker();
  String _predictionResult = 'No prediction yet';

  // Image picking method
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      await uploadImage(pickedFile); // Send the image for prediction
    }
  }

  // Upload the image to the FastAPI server
  // Example: Upload image function with mounted check
Future<void> uploadImage(XFile imageFile) async {
  final bytes = await imageFile.readAsBytes();

  var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:8000/predict'));
  request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'leaf.jpg'));

  var response = await request.send();

  if (!mounted) return;  // Ensure widget is still mounted

  if (response.statusCode == 200) {
    final responseString = await response.stream.bytesToString();
    if (!mounted) return;  // Ensure widget is still mounted before calling setState
    setState(() {
      _predictionResult = responseString;
    });
  } else {
    if (!mounted) return;  // Ensure widget is still mounted before calling setState

    setState(() {
      _predictionResult = 'Failed to get predictions.';
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Plant Disease Prediction')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Button to capture image
            ElevatedButton(
              onPressed: _pickImage, // Call the _pickImage method when the button is pressed
              child: Text('Capture Image'),
            ),
            SizedBox(height: 20),
            // Display the prediction result
            Text(_predictionResult), // Show the result from the prediction API
          ],
        ),
      ),
    );
  }
}


/// ======================= DASHBOARD TAB =======================

class DashboardTab extends StatelessWidget {
  final VoidCallback onOpenHistoryTab;

  const DashboardTab({super.key, required this.onOpenHistoryTab});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFDFF5D8);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        shape: const StadiumBorder(),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ScanLeafScreen()),
        ),
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Scan Leaf'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Plantlly',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('AI-powered plant disease detection', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              _QuickScanCard(
                onScan: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScanLeafScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _RecentScansSection(onSeeAll: onOpenHistoryTab),
              const SizedBox(height: 16),
              const Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ModelOverviewCard()),
                    SizedBox(width: 12),
                    Expanded(child: _TipsCard()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickScanCard extends StatelessWidget {
  final VoidCallback onScan;

  const _QuickScanCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF1B5E20);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5F7E0),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE5F7E0),
                  child: Icon(Icons.spa, color: darkGreen, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Scan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkGreen),
                      ),
                      const SizedBox(height: 4),
                      const Text('Scan a leaf to detect possible diseases.', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: darkGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: onScan,
                          child: const Text('Scan Leaf Now', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(color: darkGreen, shape: BoxShape.circle),
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _RecentScansSection extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _RecentScansSection({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ScanPreview>>(
      valueListenable: historyNotifier,
      builder: (context, scans, _) {
        final hasScans = scans.isNotEmpty;
        final reversed = scans.reversed.toList();
        final count = reversed.length < 3 ? reversed.length : 3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Recent Scans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (hasScans)
                  TextButton(
                    onPressed: onSeeAll,
                    child: const Text('See All'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!hasScans)
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'No scans yet. Your recent scans will appear here after you scan a leaf.',
                  style: TextStyle(fontSize: 12),
                ),
              )
            else
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: count,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _RecentScanCard(item: reversed[index]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  final ScanPreview item;

  const _RecentScanCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFE5F7E0),
            child: Icon(Icons.spa, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(item.time, style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 2),
                Text(item.plantName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ======================= LOWER CARDS =======================
class _ModelOverviewCard extends StatelessWidget {
  const _ModelOverviewCard();

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF1B5E20);

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Model Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkGreen)),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InfoChip(icon: Icons.memory_outlined, label: 'Model: EfficientNetB3'),
              _InfoChip(icon: Icons.insights_outlined, label: 'Confidence: 95%'),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Live mode: predictions are generated by the Deep Learning Models (EfficientNetB3 + MobileNetV2).', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.all(12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tips', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20))),
          SizedBox(height: 8),
          Text(
            '• Use a single, clear leaf in the frame.\n'
            '• Avoid strong shadows or very dark images.\n'
            '• Try to fill most of the image with the leaf.\n'
            '• Scan multiple leaves for more reliable results.',
            style: TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFE5F7E0), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}



/// ======================= SCAN LEAF =======================
class ScanLeafScreen extends StatefulWidget {
  const ScanLeafScreen({super.key});

  @override
  State<ScanLeafScreen> createState() => _ScanLeafScreenState();
}

class _ScanLeafScreenState extends State<ScanLeafScreen> {
  String _predictionResult = 'No prediction yet';
  bool _isAnalyzing = false;  // To manage the analyzing state

  final ImagePicker _picker = ImagePicker();

  // Image picking method
  Future<void> _pickImageAndUpload(ImageSource source) async {
    if (!mounted) return;

    // Start the analyzing state
    setState(() {
      _isAnalyzing = true;
    });

    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      await uploadImage(pickedFile); // Upload the image if captured
    } else {
      // Stop analyzing if no image is picked
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  // Upload the image to the server for prediction and safely update _predictionResult
  Future<void> uploadImage(XFile imageFile) async {
    if (!mounted) return;  // Ensure the widget is still mounted

    try {
      final bytes = await imageFile.readAsBytes();

      var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:8000/predict'))
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'leaf.jpg'));

      var response = await request.send();

      if (!mounted) return;  // Ensure the widget is still mounted

      if (response.statusCode == 200) {
        final responseString = await response.stream.bytesToString();

        if (!mounted) return;  // Guard against using context after async gap

        setState(() {
          _predictionResult = responseString;  // Safely update the result
          _isAnalyzing = false; // Stop analyzing when prediction is done
        });

        // Show result in a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseString)));
      } else {
        if (!mounted) return;

        setState(() {
          _predictionResult = 'Failed to get predictions';  // Safely update state if failed
          _isAnalyzing = false; // Stop analyzing
        });

        // Show error in a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get predictions')));
      }
    } catch (e) {
      if (!mounted) return;  // Ensure the widget is still mounted

      setState(() {
        _predictionResult = 'Error occurred: $e';  // Safely update state on error
        _isAnalyzing = false;  // Stop analyzing
      });

      // Show error in a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error occurred: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Leaf')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // If analyzing, show the "Analyzing" screen
            if (_isAnalyzing)
              const CircularProgressIndicator(),
            // If not analyzing, show buttons to capture or choose an image
            if (!_isAnalyzing) ...[
              ElevatedButton(
                onPressed: () => _pickImageAndUpload(ImageSource.camera),
                child: Text('Capture Image'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _pickImageAndUpload(ImageSource.gallery),
                child: Text('Choose from Gallery'),
              ),
            ],
            const SizedBox(height: 20),
            Text(_predictionResult),  // Display the prediction result or error
          ],
        ),
      ),
    );
  }
}

/// ======================= ANALYZING SCREEN =======================
class AnalyzingScreen extends StatelessWidget {
  const AnalyzingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);
    const darkGreen = Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase('Analyzing...', bg: bg),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Analyzing your leaf...\nPlease wait a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: darkGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



/// ======================= SCAN RESULT =======================
class ScanResultScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final PlantDisease plantDisease;
  final String? modelUsed;
  final double? confidence;
  final String? rawClassName;

  const ScanResultScreen({
    super.key,
    this.imageBytes,
    required this.plantDisease,
    this.modelUsed,
    this.confidence,
    this.rawClassName,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final crop = widget.plantDisease.crop;
    final diseaseName = widget.plantDisease.name;
    final confidence = widget.confidence ?? 0.0;
    final modelName = widget.modelUsed ?? 'Unknown';

    const bg = Color(0xFFFFFDF5);
    const darkGreen = Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase('Scan Result', bg: bg),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Image.memory(widget.imageBytes!, fit: BoxFit.cover),
                    ),
                  )
                else
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F7E0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.eco_outlined, size: 48, color: darkGreen),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Scan Result', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _kvRow('Crop:', crop),
                      const SizedBox(height: 4),
                      _kvRow('Disease:', diseaseName),
                      const SizedBox(height: 4),
                      _kvRow('Model:', modelName),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: darkGreen, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFFFFF7CC), borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(widget.plantDisease.summary, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Suggested Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(widget.plantDisease.suggestedActions, style: const TextStyle(fontSize: 13)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                    ? null
                    : () async {
                      final messenger = ScaffoldMessenger.of(context); // ✅ capture BEFORE await
                      setState(() => _saving = true);
                      await Future.delayed(const Duration(milliseconds: 300));

                      final now = DateTime.now();
                      final date =
                      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                      final time =
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                      
                      final crop = widget.plantDisease.crop;
                      final diseaseName = widget.plantDisease.name;
                      
                      final newScan = ScanPreview(
                        date: date,
                        time: time,
                        plantName: '$crop – $diseaseName',
                      );
                      
                      final current = List<ScanPreview>.from(historyNotifier.value)..add(newScan);
                      historyNotifier.value = current;
                      await saveHistory(current);
                      final now2 = DateTime.now();
                      final t = '${now2.hour.toString().padLeft(2, '0')}:${now2.minute.toString().padLeft(2, '0')}';
                      await addNotification(
                        AppNotification(
                          title: 'Scan saved',
                          message: 'Your scan was saved to history successfully.',
                          time: t,
                        ),
                      );
                      
                      if (!mounted) return;
                      setState(() => _saving = false);
                      messenger.showSnackBar( // ✅ no context here anymore
                      const SnackBar(content: Text('Scan saved to history.')));

                    },
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bookmark_border),
                    label: Text(_saving ? 'Saving...' : 'Save to History'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>  Navigator.of(context).push(
                      
                      MaterialPageRoute(builder: (_) => DiseaseInfoScreen(disease: widget.plantDisease)),
                    ),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('View Disease Info'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Pass the predicted disease data to the DiseaseInfoScreen
                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DiseaseInfoScreen(disease: widget.plantDisease),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('View Disease Info'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  static Widget _kvRow(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Expanded(child: Text(v)),
      ],
    );
  }
}

/// ======================= PROFILE TAB =======================
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);
    const darkGreen = Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase('Profile', bg: bg, centerTitle: true),
      body: ValueListenableBuilder<AppUser?>(
        valueListenable: currentUserNotifier,
        builder: (context, user, _) {
          if (user == null) {
            return const Center(child: Text('No user logged in.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFE5F7E0),
                      child: Icon(Icons.person, color: darkGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(user.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(user.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ProfileTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              _ProfileTile(
                icon: Icons.info_outline,
                title: 'About Plantlly',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  await clearUser();
                  currentUserNotifier.value = null;

                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Log Out', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF1B5E20);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5F7E0),
                child: Icon(icon, size: 18, color: darkGreen),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// ======================= HISTORY TAB =======================

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);
    

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase('Scan History', bg: bg, centerTitle: true),
      body: ValueListenableBuilder<List<ScanPreview>>(
        valueListenable: historyNotifier,
        builder: (context, scans, _) {
          if (scans.isEmpty) {
            return const Center(
              child: Text(
                'No scans saved yet.\nScan a leaf and tap "Save to History".',
                textAlign: TextAlign.center,
              ),
            );
          }

          final reversed = scans.reversed.toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reversed.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = reversed[index];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFF9FD89B),
                      child: Icon(Icons.spa, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.plantName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${item.date}  ·  ${item.time}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}


/// ======================= LIBRARY TAB =======================

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);
    const darkGreen = Color(0xFF1B5E20);

    const crops = [
      _CropCardData('Tomato', Icons.local_florist),
      _CropCardData('Potato', Icons.spa),
      _CropCardData('Pepper', Icons.emoji_nature),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase('Disease Library', bg: bg, centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Browse crops and their common diseases', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: crops.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final c = crops[i];
                  final count = plantDiseases.where((d) => d.crop == c.name).length;
                  return _CropCard(
                    title: c.name,
                    icon: c.icon,
                    diseaseCount: count,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DiseaseListScreen(cropName: c.name)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFFE5F7E0), borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.all(14),
              child: const Text(
                'Tip: Tap a crop to explore diseases, symptoms, and management guidance.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Popular Diseases', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: darkGreen)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: min(5, plantDiseases.length),
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final d = plantDiseases[index];
                  return _DiseaseMiniCard(
                    disease: d,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DiseaseInfoScreen(disease: d)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropCardData {
  final String name;
  final IconData icon;
  const _CropCardData(this.name, this.icon);
}

class _CropCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int diseaseCount;
  final VoidCallback onTap;

  const _CropCard({
    required this.title,
    required this.icon,
    required this.diseaseCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF1B5E20);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE5F7E0),
              child: Icon(icon, color: darkGreen, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('$diseaseCount items', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: darkGreen, borderRadius: BorderRadius.circular(16)),
                    child: const Text(
                      'View Diseases →',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiseaseMiniCard extends StatelessWidget {
  final PlantDisease disease;
  final VoidCallback onTap;

  const _DiseaseMiniCard({required this.disease, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE5F7E0),
              child: Icon(Icons.spa, color: Color(0xFF1B5E20), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${disease.crop} — ${disease.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  const Text('Tap to view details', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// ======================= DISEASE LIST SCREEN =======================

class DiseaseListScreen extends StatelessWidget {
  final String cropName;

  const DiseaseListScreen({super.key, required this.cropName});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);

    final list = plantDiseases.where((d) => d.crop == cropName).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase('$cropName Diseases', bg: bg),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select a disease to view details',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.7), fontSize: 13)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final d = list[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DiseaseInfoScreen(disease: d)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFE5F7E0),
                            child: Icon(Icons.menu_book_outlined, color: Color(0xFF1B5E20), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text(
                                  d.summary.split('\n').first.replaceAll('• ', ''),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// ======================= DISEASE INFO =======================
class DiseaseInfoScreen extends StatelessWidget {
  final PlantDisease disease;

  const DiseaseInfoScreen({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase('${disease.crop} – ${disease.name}', bg: bg),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Overview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(disease.overview, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            const Text('Typical Symptoms', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(disease.symptoms, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            const Text('Management Tips', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(disease.management, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// ======================= NOTIFICATIONS SCREEN =======================
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);
    const darkGreen = Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase(
        'Notifications',
        bg: bg,
        actions: [
          TextButton(
            onPressed: () async {
              await clearNotifications();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications cleared.')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: darkGreen)),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<AppNotification>>(
        valueListenable: notificationsNotifier,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.\nSave a scan to history to generate one.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final reversed = items.reversed.toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reversed.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = reversed[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFE5F7E0),
                      child: Icon(Icons.notifications, size: 18, color: darkGreen),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                              ),
                              Text(n.time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(n.message, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// ======================= SETTINGS SCREEN =======================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase('Settings', bg: bg),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SettingRow(title: 'Theme', value: 'Light (fixed)'),
          _SettingRow(title: 'Language', value: 'English (fixed)'),
          _SettingSwitch(title: 'Notifications', value: true),
          SizedBox(height: 10),
          _SettingRow(title: 'App Version', value: '1.0.0'),
          _SettingRow(title: 'Privacy Policy', value: 'Placeholder'),
          _SettingRow(title: 'Terms & Conditions', value: 'Placeholder'),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String value;

  const _SettingRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String title;
  final bool value;

  const _SettingSwitch({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          Switch(value: value, onChanged: null),
        ],
      ),
    );
  }
}

/// ======================= ABOUT SCREEN =======================
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase('About Plantlly', bg: bg),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plantlly', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text(
                'Plantlly is a plant disease detection demo app.\n'
                'It provides educational guidance based on sample disease cards.\n\n'
                'Disclaimer: Results are for educational purposes and should not replace professional advice.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text('Version: 1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
