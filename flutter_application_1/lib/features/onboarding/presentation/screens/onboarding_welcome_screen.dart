import 'package:flutter/material.dart';
import '../../models/feature_model.dart';
import '../components/hero_illustration.dart';
import '../components/onboarding_header.dart';
import '../components/feature_list_item.dart';
import '../components/onboarding_footer.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  final List<FeatureModel> features = const [
    FeatureModel(
      icon: Icons.record_voice_over,
      title: 'AI Shadowing',
      description: 'Perfect your pitch accent with real-time feedback',
    ),
    FeatureModel(
      icon: Icons.forum,
      title: 'Real-time Roleplay',
      description: 'Interactive scenarios with dynamic AI tutors',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: const HeroIllustration(
                                imageUrl:
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDb8AysMFUg1EMwbOJ94ln2ur18Nj5zePT4vL8nKyOJyUEzDWG56xFVyJ8Q0H_CikjJbNgRfPaYYxDPosiBU1ASan9-ZMJ4l199rejj9Detp3dnuWA4Vm_D0nOsaEJYfN2g-Ixf8z0OPZ0s1K32V3seuqLF0ZH75S9i5G_0p3zp-vlCUegYUVMHgGev28UGlyReuKjIVWiKQ9kX3uxn9-bBv97FsyAcXun7AxUsh3a_TbTNYFgUBO092cMiH50ixHD1bv3Co_sCIdQn',
                                icon: Icons.translate,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const OnboardingHeader(
                            titleStart: 'Welcome to the future of ',
                            highlightWord: 'Japanese',
                            titleEnd: ' learning',
                            subtitle:
                                'Master the language of the rising sun with our advanced AI-driven methodology.',
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              children: features.map((feature) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: FeatureListItem(feature: feature),
                                );
                              }).toList(),
                            ),
                          ),
                          const Spacer(),
                          OnboardingFooter(
                            currentStep: 1,
                            totalSteps: 3,
                            onNext: () {
                              // TODO: handle next step
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
