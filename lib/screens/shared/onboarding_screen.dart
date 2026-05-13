import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:microlab/theme/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardData> _pages = const [
    _OnboardData(
      step: '01 / 03',
      title: 'Book a blood test\nfrom home',
      subtitle:
          'Schedule your test in minutes. Choose your preferred time slot and a certified technician visits you.',
      bgColor: Color(0xFFE8F5F1),
      illustrationId: 0,
    ),
    _OnboardData(
      step: '02 / 03',
      title: 'Verified technicians\nat your door',
      subtitle:
          'All technicians are certified, background-checked, and rated by other customers for your safety.',
      bgColor: Color(0xFFEEF4FB),
      illustrationId: 1,
    ),
    _OnboardData(
      step: '03 / 03',
      title: 'How will you use\nMicroLab?',
      subtitle: 'Choose your role to get the experience built for you.',
      bgColor: Color(0xFFFEF6EE),
      illustrationId: 2,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _skipToRoleSelect() {
    _pageController.animateToPage(_pages.length - 1,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _onRoleSelected(String role) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginScreen(userRole: role),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content column
            Column(
              children: [
                // PageView — takes full remaining space
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => _OnboardPage(data: _pages[i]),
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _pages.length,
                        effect: const ExpandingDotsEffect(
                          dotHeight: 6,
                          dotWidth: 6,
                          expansionFactor: 3,
                          spacing: 6,
                          activeDotColor: AppColors.brandGreen,
                          dotColor: AppColors.divider,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _currentPage < 2
                            ? _PrimaryButton(
                                key: ValueKey('next-$_currentPage'),
                                label: _currentPage == 0
                                    ? 'Get Started'
                                    : 'Continue',
                                onTap: _nextPage,
                              )
                            : Column(
                                key: const ValueKey('role-select'),
                                children: [
                                  _PrimaryButton(
                                    label: "I'm a Customer",
                                    onTap: () => _onRoleSelected('customer'),
                                  ),
                                  const SizedBox(height: 10),
                                  _OutlineButton(
                                    label: "I'm a Technician",
                                    onTap: () => _onRoleSelected('technician'),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Skip button — Positioned must be direct child of Stack
            Positioned(
              top: 14,
              right: 16,
              child: AnimatedOpacity(
                opacity: isLastPage ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: isLastPage,
                  child: GestureDetector(
                    onTap: _skipToRoleSelect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandGreen,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 13, color: AppColors.brandGreen),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardData {
  final String step;
  final String title;
  final String subtitle;
  final Color bgColor;
  final int illustrationId;
  const _OnboardData({
    required this.step, required this.title, required this.subtitle,
    required this.bgColor, required this.illustrationId,
  });
}

class _OnboardPage extends StatelessWidget {
  final _OnboardData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.38,
          color: data.bgColor,
          child: Center(
            child: CustomPaint(
              size: const Size(200, 200),
              painter: _IllustrationPainter(id: data.illustrationId),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.step,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                Text(data.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary, height: 1.25, letterSpacing: -0.2)),
                const SizedBox(height: 12),
                Text(data.subtitle,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final int id;
  const _IllustrationPainter({required this.id});

  @override
  void paint(Canvas canvas, Size size) {
    switch (id) {
      case 0: _drawBooking(canvas, size); break;
      case 1: _drawTechnician(canvas, size); break;
      case 2: _drawRoleSelect(canvas, size); break;
    }
  }

  void _drawBooking(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx-50,cy-55,95,105),const Radius.circular(14)),Paint()..color=AppColors.brandGreen.withOpacity(0.08)..style=PaintingStyle.fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx-50,cy-55,95,105),const Radius.circular(14)),Paint()..color=AppColors.brandGreen.withOpacity(0.3)..style=PaintingStyle.stroke..strokeWidth=1.5);
    final lp = Paint()..color=AppColors.brandGreen.withOpacity(0.25)..strokeWidth=3..strokeCap=StrokeCap.round;
    for(int i=0;i<3;i++) canvas.drawLine(Offset(cx-30,cy-10+i*16.0),Offset(cx+20,cy-10+i*16.0),lp);
    canvas.drawLine(Offset(cx-30,cy-30),Offset(cx-10,cy-30),Paint()..color=AppColors.brandGreen.withOpacity(0.5)..strokeWidth=4..strokeCap=StrokeCap.round);
    canvas.drawCircle(Offset(cx+42,cy-42),20,Paint()..color=AppColors.brandGreen..style=PaintingStyle.fill);
    final pp=Paint()..color=Colors.white..strokeWidth=2.5..strokeCap=StrokeCap.round;
    canvas.drawLine(Offset(cx+42,cy-52),Offset(cx+42,cy-32),pp);
    canvas.drawLine(Offset(cx+32,cy-42),Offset(cx+52,cy-42),pp);
    canvas.drawCircle(Offset(cx-42,cy+55),16,Paint()..color=AppColors.brandGreenLight..style=PaintingStyle.fill);
    canvas.drawCircle(Offset(cx-42,cy+55),16,Paint()..color=AppColors.brandGreen..style=PaintingStyle.stroke..strokeWidth=1.5);
    canvas.drawPath(Path()..moveTo(cx-50,cy+55)..lineTo(cx-44,cy+62)..lineTo(cx-34,cy+48),Paint()..color=AppColors.brandGreen..strokeWidth=2..strokeCap=StrokeCap.round..style=PaintingStyle.stroke);
  }

  void _drawTechnician(Canvas canvas, Size size) {
    final cx = size.width/2; final cy = size.height/2;
    canvas.drawCircle(Offset(cx,cy),65,Paint()..color=const Color(0xFF1565C0).withOpacity(0.08)..style=PaintingStyle.fill);
    canvas.drawCircle(Offset(cx,cy),65,Paint()..color=const Color(0xFF1565C0).withOpacity(0.15)..style=PaintingStyle.stroke..strokeWidth=1);
    canvas.drawCircle(Offset(cx,cy),42,Paint()..color=const Color(0xFF1565C0).withOpacity(0.1)..style=PaintingStyle.fill);
    final hp=Paint()..color=const Color(0xFF1565C0).withOpacity(0.5)..style=PaintingStyle.fill;
    canvas.drawCircle(Offset(cx,cy-10),18,hp);
    canvas.drawPath(Path()..moveTo(cx-28,cy+42)..quadraticBezierTo(cx,cy+10,cx+28,cy+42)..close(),hp);
    canvas.drawCircle(Offset(cx+48,cy-38),16,Paint()..color=AppColors.brandGreenLight..style=PaintingStyle.fill);
    canvas.drawCircle(Offset(cx+48,cy-38),16,Paint()..color=AppColors.brandGreen..style=PaintingStyle.stroke..strokeWidth=1.5);
    canvas.drawPath(Path()..moveTo(cx+40,cy-38)..lineTo(cx+46,cy-32)..lineTo(cx+56,cy-46),Paint()..color=AppColors.brandGreen..strokeWidth=2..strokeCap=StrokeCap.round..style=PaintingStyle.stroke);
  }

  void _drawRoleSelect(Canvas canvas, Size size) {
    final cx=size.width/2; final cy=size.height/2;
    void card(double x,double y,Color bg,Color border){
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,80,95),const Radius.circular(14)),Paint()..color=bg..style=PaintingStyle.fill);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,80,95),const Radius.circular(14)),Paint()..color=border..style=PaintingStyle.stroke..strokeWidth=1.5);
      canvas.drawCircle(Offset(x+55,y+18),14,Paint()..color=border.withOpacity(0.15)..style=PaintingStyle.fill);
      canvas.drawLine(Offset(x+12,y+45),Offset(x+35,y+45),Paint()..color=border.withOpacity(0.4)..strokeWidth=3..strokeCap=StrokeCap.round);
      canvas.drawLine(Offset(x+12,y+58),Offset(x+50,y+58),Paint()..color=border.withOpacity(0.2)..strokeWidth=3..strokeCap=StrokeCap.round);
      canvas.drawLine(Offset(x+12,y+70),Offset(x+43,y+70),Paint()..color=border.withOpacity(0.2)..strokeWidth=3..strokeCap=StrokeCap.round);
    }
    card(cx-92,cy-50,const Color(0xFFFFE0B2),const Color(0xFFE65100));
    card(cx+12,cy-50,AppColors.brandGreenLight,AppColors.brandGreen);
    final cp=Paint()..color=AppColors.brandGreen..strokeWidth=2.5..strokeCap=StrokeCap.round;
    canvas.drawLine(Offset(cx+55,cy-40),Offset(cx+55,cy-25),cp);
    canvas.drawLine(Offset(cx+47,cy-32),Offset(cx+63,cy-32),cp);
    final personP=Paint()..color=const Color(0xFFE65100)..style=PaintingStyle.fill;
    canvas.drawCircle(Offset(cx-37,cy-36),6,personP);
    canvas.drawPath(Path()..moveTo(cx-48,cy-15)..quadraticBezierTo(cx-37,cy-24,cx-26,cy-15)..close(),personP);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PrimaryButton extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _PrimaryButton({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandGreen, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    ),
  );
}

class _OutlineButton extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 50,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.brandGreen, side: const BorderSide(color: AppColors.brandGreen, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    ),
  );
}
