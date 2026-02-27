import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sobes/core/theme/app_theme.dart';
import 'package:sobes/features/home/widgets/history_drawer.dart';
import 'package:sobes/features/interview/presentation/pages/setup_page.dart';
import 'package:sobes/features/profile/presentation/pages/profile_page.dart';
import 'package:sobes/features/profile/presentation/providers/profile_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 Берем данные профиля для аватарки 👇
    final profileData = context.watch<ProfileProvider>();
    final String currentName = profileData.userName;
    final String initials = currentName.trim().isNotEmpty 
        ? currentName.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join()
        : "?";

    return Scaffold(
      backgroundColor: Colors.black, 
      drawer: const HistoryDrawer(),
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.grey),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24), 
            child: GestureDetector( 
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF2C2C2E), 
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials, // 👈 ТЕПЕРЬ ТУТ РЕАЛЬНЫЕ ИНИЦИАЛЫ
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          )
        ],
      ),

      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              const Spacer(flex: 2), 

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
              ),
              
              const Gap(32),

              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(fontFamily: 'Inter', height: 1.1),
                  children: [
                    TextSpan(text: "Master Your\n", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                    TextSpan(text: "Interview", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              
              const Gap(16),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0), 
                child: Text(
                  "AI-powered coaching tailored to\nyour specific role and goals.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
                ),
              ),

              const Gap(48),

              SizedBox(
                width: 220, height: 56,
                child: ElevatedButton(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: Colors.black,
                    shape: const StadiumBorder(), elevation: 10,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Start Interview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Gap(8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3), 

              Container(
                margin: const EdgeInsets.only(bottom: 24), 
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515), 
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                    const Gap(10),
                    Text(
                      "2 FREE SESSIONS REMAINING",
                      style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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