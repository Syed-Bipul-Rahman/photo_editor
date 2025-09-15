import 'package:flutter/material.dart';

import '../widgets/slide_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int indicatorIndex = 0;
  final List<Map<String, String>> pages = [
    {
      "image": "assets/images/girl1.jpg",
      "title": "Get control over your Happiness",
      "button": "Next",
    },
    {
      "image": "assets/images/girl2.jpg",
      "title": "Optimize your system",
      "button": "Next",
    },
    {
      "image": "assets/images/girl3.jpg",
      "title": "Better Storage, Easy Share ability",
      "button": "Get started",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(),
                  Image.asset('assets/images/logo_onboarding.png'),
                  Text("sign in", style: TextStyle(color: Color(0xFF7CC3ED))),
                ],
              ),

              const SizedBox(height: 48),

              /// Page View Section
              SizedBox(
                height: 300,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      indicatorIndex = index;
                    });
                  },
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 286,
                            height: 222,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.grey.shade200,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                page["image"]!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          /// Title
                          Text(
                            page["title"]!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          /// Page Indicator (Custom implementation)
                        ],
                      ),
                    );
                  },
                ),
              ),

              SlideIndicator(
                indicatorIndex: indicatorIndex,
                length: pages.length,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
