import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_images.dart';
import '../../core/constants/app_strings.dart';
import '../../utils/primary_button.dart';
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
      "image": AppImages.girl1,
      "title": "Get control over your Happiness",
      "button": "Next",
    },
    {
      "image": AppImages.girl2,
      "title": "Optimize your system",
      "button": "Next",
    },
    {
      "image": AppImages.girl3,
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
                  Image.asset(AppImages.logoOnboarding),
                  Text(AppStrings.signIn, style: TextStyle(color: AppColors.primaryLight)),
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
                              color: AppColors.galleryItemBackground[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                page["image"]!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.galleryItemError[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.image,
                                      size: 50,
                                      color: AppColors.galleryBackground,
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
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
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
              SizedBox(height: 64),
              Container(
                width: double.infinity,
                height: 48,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: AppColors.buttonPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 83,
                      top: 13,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 12,
                        children: [
                          Image.asset(AppImages.googleLogo),
                          Text(
                            AppStrings.signUpWithGoogle,
                            style: GoogleFonts.publicSans(
                              color: AppColors.textLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(AppStrings.or),
              SizedBox(height: 16),
              PrimaryButton(
                text: 'Sign up With Email',
                onPressed: () {
                  // TODO: Implement sign up with email functionality
                },
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
