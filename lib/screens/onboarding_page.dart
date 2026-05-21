import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
    const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  PageController controller = PageController();
  int currentPage = 0;

Future<void> _setOnboarded() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('already_onboarded', true); 
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6DB5FD),
      body: PageView(
        controller: controller,
        onPageChanged: (i) => setState(() => currentPage = i),
        children: [
          buildPage(
            title: "Selamat Datang Di\nFinansisten",
            titleSize: 32,               
            image: ".idea/assets/img/coin.png",
          ),
          buildPage(
            title: "Asisten Finansial\nYang Bantuin Kamu",
            titleSize: 30,               
            image: ".idea/assets/img/phone.png",
          ),
          buildLastPage(),
        ],
      ),
    );
  }

  Widget buildPage({
    required String title,
    required double titleSize,
    required String image,
  }) {
    return Column(
      children: [
        SizedBox(height: 100),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 1, 34, 73),
            ),
          ),
        ),

        SizedBox(height: 60),



Expanded(
  child: Container(
    height: double.infinity,
    width: double.infinity,
    padding: EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
    ),
    child: Column(
      children: [
        SizedBox(height: 60),

        SizedBox(
          width: 320,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD6EAFF),
                ),
              ),
              Image.asset(
                image,
                width: 320,
                height: 320,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),

        SizedBox(height: 60),

        GestureDetector(
          onTap: () {
            controller.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          },
          child: Text(
            "Lanjut",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Color.fromARGB(255, 1, 34, 73),
            ),
          ),
        ),

        SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 5),
              width: currentPage == index ? 14 : 10,
              height: currentPage == index ? 14 : 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentPage == index
                    ? Color(0xFF6DB5FD)
                    : Colors.grey,
              ),
            );
          }),
        ),
      ],
    ),
  ),
),
],
);
}

  Widget buildLastPage() {
    return Scaffold(                  
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              ".idea/assets/img/logo_clear.png",  
              width: 140,
              height: 140,
            ),

            SizedBox(height: 24),

            Text(
              "Finansisten",
              style: TextStyle(
                fontSize: 36,           
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 1, 34, 73),
              ),
            ),

            SizedBox(height: 4),

            Text(
              "Asisten Finansial-Mu\nBantu Kamu Lebih Hemat!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,         
                color: Colors.grey,
              ),
            ),

            SizedBox(height: 40),

            primaryButton("Masuk", () async {
              await _setOnboarded(); 
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            }),

            SizedBox(height: 12),

            secondaryButton("Daftar", () async {
              await _setOnboarded(); 
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RegisterPage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget primaryButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 100),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6DB5FD),
            shape: StadiumBorder(),
            padding: EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              color: Color.fromARGB(255, 1, 34, 73),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget secondaryButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 100),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFE3F2FD),
            elevation: 0,
            shape: StadiumBorder(),
            padding: EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              color: Color.fromARGB(255, 1, 34, 73),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}