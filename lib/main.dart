import 'dart:convert';
import 'dart:math';

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

/// Fake dataset (Tomato / Potato / Pepper)
final List<PlantDisease> plantDiseases = [
  // TOMATO
  const PlantDisease(
    crop: 'Tomato',
    name: 'Early blight',
    summary:
        '• Dark concentric spots on older leaves.\n• Yellowing around lesions.\n• Can lead to leaf drop in severe cases.',
    suggestedActions:
        '• Remove heavily infected leaves and dispose of them away from the field.\n'
        '• Avoid overhead irrigation; water near the soil surface.\n'
        '• Improve spacing and airflow around plants.\n'
        '• Rotate crops and avoid planting tomatoes in the same soil every year.',
    overview:
        'Early blight is a common fungal disease of tomato leaves caused by Alternaria solani. '
        'It is favored by warm, humid conditions and often starts on older foliage.',
    symptoms:
        '• Dark brown spots with concentric “bullseye” rings on older leaves.\n'
        '• Yellowing around lesions, followed by leaf drop.\n'
        '• In severe infections, stems and fruits may also be affected.',
    management:
        '• Remove infected plant debris at the end of the season.\n'
        '• Use drip irrigation instead of overhead watering.\n'
        '• Ensure good plant spacing for airflow.\n'
        '• Use resistant varieties when available and follow local fungicide recommendations.',
  ),
  const PlantDisease(
    crop: 'Tomato',
    name: 'Late blight',
    summary:
        '• Water-soaked, gray-green lesions.\n• White mold-like growth at lesion edges.\n• Can rapidly destroy foliage.',
    suggestedActions:
        '• Remove and destroy severely infected plants.\n'
        '• Avoid overhead irrigation and reduce leaf wetness duration.\n'
        '• Monitor nearby plants closely for new lesions.\n'
        '• Follow local guidelines for late blight control programs.',
    overview:
        'Late blight is a destructive disease of tomato and potato caused by Phytophthora infestans. '
        'It can spread quickly under cool, wet conditions.',
    symptoms:
        '• Large, irregularly shaped, water-soaked lesions on leaves.\n'
        '• Lesions may turn dark brown; white growth can appear in humidity.\n'
        '• Stems and fruits can also become infected.',
    management:
        '• Remove infected plants and cull piles.\n'
        '• Avoid dense plantings and improve ventilation.\n'
        '• Use disease-free transplants.\n'
        '• Apply recommended fungicides when risk is high in your region.',
  ),
  const PlantDisease(
    crop: 'Tomato',
    name: 'Leaf mold',
    summary:
        '• Pale green spots on upper leaf surface.\n• Olive-green velvety growth underneath.\n• Favored by high humidity.',
    suggestedActions:
        '• Reduce humidity and improve airflow.\n'
        '• Remove affected leaves.\n'
        '• Avoid wetting foliage when watering.\n'
        '• Consider resistant varieties if available.',
    overview:
        'Tomato leaf mold is caused by the fungus Fulvia fulva and is common in humid, poorly ventilated conditions.',
    symptoms:
        '• Yellow/pale spots on top of leaves.\n'
        '• Olive-green to brown “mold” underneath.\n'
        '• Older leaves are affected first.',
    management:
        '• Ventilate growing areas and reduce leaf wetness.\n'
        '• Remove infected leaves.\n'
        '• Use resistant cultivars when possible.\n'
        '• Apply fungicides if needed and permitted.',
  ),

  // POTATO
  const PlantDisease(
    crop: 'Potato',
    name: 'Early blight',
    summary:
        '• Brown spots with concentric rings.\n• Starts on older leaves.\n• Can reduce yield and tuber size.',
    suggestedActions:
        '• Remove crop debris after harvest.\n'
        '• Rotate with non-host crops.\n'
        '• Avoid plant stress (balanced fertilization).\n'
        '• Use certified seed when possible.',
    overview:
        'Potato early blight is caused by Alternaria solani and appears commonly in warm, humid conditions.',
    symptoms:
        '• Brown lesions with target-like rings.\n'
        '• Yellowing and premature leaf drop.\n'
        '• Occasionally stems/tubers can show lesions.',
    management:
        '• Practice crop rotation and remove volunteer plants.\n'
        '• Reduce leaf wetness and improve airflow.\n'
        '• Follow local fungicide guidance when pressure is high.',
  ),
  const PlantDisease(
    crop: 'Potato',
    name: 'Late blight',
    summary:
        '• Dark water-soaked lesions.\n• White growth at lesion edges in humidity.\n• Can rot tubers in storage.',
    suggestedActions:
        '• Remove infected foliage promptly.\n'
        '• Avoid overhead irrigation.\n'
        '• Harvest carefully to avoid tuber injury.\n'
        '• Store tubers cool and dry; remove rotting tubers.',
    overview:
        'Late blight of potato is caused by Phytophthora infestans and can spread quickly under cool, wet conditions.',
    symptoms:
        '• Dark lesions on leaves/stems.\n'
        '• White fungal growth in humid conditions.\n'
        '• Brown, firm tuber lesions that can expand.',
    management:
        '• Use certified seed and destroy cull piles.\n'
        '• Consider resistant cultivars.\n'
        '• Apply protective fungicides when risk is high.\n'
        '• Maintain good storage hygiene.',
  ),
  const PlantDisease(
    crop: 'Potato',
    name: 'Healthy',
    summary:
        '• Uniform green leaves.\n• No visible lesions or halos.\n• Canopy looks vigorous.',
    suggestedActions:
        '• Continue regular scouting.\n'
        '• Maintain balanced irrigation and nutrition.\n'
        '• Keep good field hygiene to reduce disease risk.',
    overview: 'No significant disease symptoms were detected on the scanned potato leaf.',
    symptoms:
        '• Leaf surface clean and evenly colored.\n'
        '• No necrotic spots, mold growth, or distortions.',
    management:
        '• Keep preventive practices.\n'
        '• Avoid overwatering and support airflow.\n'
        '• Inspect lower leaves regularly for early changes.',
  ),

  // PEPPER
  const PlantDisease(
    crop: 'Pepper',
    name: 'Bacterial spot',
    summary:
        '• Small water-soaked spots.\n• Spots may turn brown with halos.\n• Severe cases can defoliate plants.',
    suggestedActions:
        '• Avoid working when foliage is wet.\n'
        '• Use drip irrigation instead of overhead watering.\n'
        '• Remove severely infected plants.\n'
        '• Use disease-free seed/transplants.',
    overview:
        'Bacterial spot of pepper is caused by Xanthomonas species and affects leaves and fruits, especially in wet conditions.',
    symptoms:
        '• Small water-soaked spots that become brown.\n'
        '• Yellow halos around lesions.\n'
        '• Fruit can develop raised, scabby spots.',
    management:
        '• Rotate away from solanaceous crops for 2–3 years.\n'
        '• Control weeds and volunteer plants.\n'
        '• Follow local recommendations (e.g., copper sprays).\n'
        '• Use resistant varieties when available.',
  ),
  const PlantDisease(
    crop: 'Pepper',
    name: 'Healthy',
    summary:
        '• Leaves uniformly green.\n• No visible lesions.\n• Plant vigor appears normal.',
    suggestedActions:
        '• Maintain regular scouting.\n'
        '• Avoid prolonged leaf wetness.\n'
        '• Keep crop hygiene and remove damaged leaves.',
    overview: 'No major disease indicators were observed on the scanned pepper leaf.',
    symptoms:
        '• No visible lesions, spots, or discoloration patterns.\n'
        '• Leaf edges appear intact.',
    management:
        '• Continue good cultural practices.\n'
        '• Maintain airflow and proper irrigation.\n'
        '• Monitor after rain or irrigation events.',
  ),
];

PlantDisease pickRandomDisease() {
  final rnd = Random();
  return plantDiseases[rnd.nextInt(plantDiseases.length)];
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

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final savedUser = await loadUser();
    if (!mounted) return;

    if (savedUser != null) {
      _ensureUserInMemory(savedUser); // ✅ restore user to in-memory list
      currentUserNotifier.value = savedUser;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFD9F5D1);
    const darkGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: Icon(Icons.spa, size: 60, color: darkGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'Plantlly',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: darkGreen,
                letterSpacing: 0.5,
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
              _InfoChip(icon: Icons.insights_outlined, label: 'Demo Confidence: 95%'),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Demo mode: results are randomized until model inference is integrated.', style: TextStyle(fontSize: 11)),
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
  final ImagePicker _picker = ImagePicker();

  bool _permissionDenied = false;
  String _permissionMsg = '';
  String _permissionFor = 'Camera';

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _permissionDenied = false;
      _permissionMsg = '';
      _permissionFor = source == ImageSource.camera ? 'Camera' : 'Gallery';
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final disease = pickRandomDisease();

      if (!mounted) return;

      // "Analyzing..." screen (fake delay)
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AnalyzingScreen()),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            imageBytes: bytes,
            plantDisease: disease,
          ),
        ),
      );
    } on PlatformException {
      setState(() {
        _permissionDenied = true;
        _permissionMsg =
            'Permission is required to access ${source == ImageSource.camera ? "Camera" : "Gallery"}.\n'
            'Please enable it in your device Settings and try again.';
      });
    } catch (_) {
      setState(() {
        _permissionDenied = true;
        _permissionMsg = 'Something went wrong while opening the camera/gallery.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFDF5);

    return Scaffold(
      backgroundColor: bg,
      appBar: appBarBase('Scan Leaf', bg: bg),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Capture or select a photo of a plant leaf for analysis.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),

              // ✅ Permission-friendly message card (UI only)
              if (_permissionDenied) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.redAccent.withValues(alpha:0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Permission needed', style: TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(_permissionMsg, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () => showOpenSettingsHelp(context, forWhat: _permissionFor),
                                  child: const Text('Open Settings'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _permissionDenied = false;
                                    _permissionMsg = '';
                                  }),
                                  child: const Text('Dismiss'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _ScanOptionCard(
                      icon: Icons.camera_alt_outlined,
                      title: 'Take Photo',
                      onTap: () => _pick(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ScanOptionCard(
                      icon: Icons.photo_library_outlined,
                      title: 'Choose from Gallery',
                      onTap: () => _pick(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Tips', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '• Use a single, clear leaf in the frame.\n'
                  '• Avoid strong shadows or very dark images.\n'
                  '• Try to fill most of the image with the leaf.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF1B5E20);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: darkGreen),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkGreen),
            ),
          ],
        ),
      ),
    );
  }
}

/// ======================= SCAN RESULT =======================

class ScanResultScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final PlantDisease plantDisease;

  const ScanResultScreen({
    super.key,
    this.imageBytes,
    required this.plantDisease,
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

    const confidence = 0.95; // demo
    const modelName = 'EfficientNetB3'; // fixed

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
                    const SnackBar(content: Text('Scan saved to history.')),
                  );
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
                    onPressed: () => Navigator.of(context).push(
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
