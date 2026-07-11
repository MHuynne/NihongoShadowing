import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFFC8102E);
    const bgWhite = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Center(
                child: Text(
                  'Khám phá',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ),


            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1522383225653-ed111181a951?q=80&w=800&auto=format&fit=crop'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),


            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: bgWhite,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 26,
                            height: 1.3,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            fontFamily: 'Roboto',
                          ),
                          children: [
                            TextSpan(text: 'Chinh phục tiếng Nhật\n'),
                            TextSpan(
                              text: 'thật dễ dàng',
                              style: TextStyle(color: primaryRed),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Bắt đầu hành trình ngôn ngữ của bạn với phương pháp học hiện đại và lộ trình rõ ràng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),


                      _buildFeatureCard(
                        iconColor: primaryRed,
                        title: 'Phương pháp SRS',
                        subtitle: 'Ghi nhớ từ vựng hiệu quả qua lặp lại ngắt quãng',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        iconColor: primaryRed,
                        title: 'Lộ trình JLPT',
                        subtitle: 'Hệ thống bài học từ N5 đến N1 chuẩn quốc tế',
                      ),

                      const SizedBox(height: 32),


                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDot(isActive: true, color: primaryRed),
                          const SizedBox(width: 6),
                          _buildDot(isActive: false, color: primaryRed.withValues(alpha: 0.2)),
                          const SizedBox(width: 6),
                          _buildDot(isActive: false, color: primaryRed.withValues(alpha: 0.2)),
                        ],
                      ),
                      const SizedBox(height: 24),


                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Bắt đầu ngay',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),


                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13, color: Colors.black45),
                          children: [
                            TextSpan(text: 'Bạn đã có tài khoản? '),
                            TextSpan(
                              text: 'Đăng nhập',
                              style: TextStyle(
                                color: primaryRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                )
              ]
            ),
            child: Icon(Icons.check_circle, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required bool isActive, required Color color}) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}