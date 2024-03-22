import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:prame_app/screens/home_screen.dart';

class LandingItem {
  final String image;
  final String name;

  LandingItem(this.image, this.name);
}

List<LandingItem> MyFav = [
  LandingItem('Ellipse 2-5.png', '고윤정'),
  LandingItem('Ellipse 2.png', '이장우'),
  LandingItem('Ellipse 2-1.png', '배두나'),
];

List<LandingItem> FindYourFav = [
  LandingItem('Ellipse 2-2.png', '안보현'),
  LandingItem('Ellipse 2-3.png', '박서준'),
  LandingItem('Ellipse 2-4.png', '정해인'),
  LandingItem('Ellipse 2-6.png', '유선'),
];

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36.0),
      child: SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Fav',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ...MyFav.map((item) {
            return FavItem(item: item, type: 'my',);
          }),
          SizedBox(height: 16),
          Text('Find your Fav',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          ...FindYourFav.map((item) {
            return FavItem(item: item, type: 'find',);
          }),
        ],
      )),
    );
  }
}

class FavItem extends StatelessWidget {
  final LandingItem item;
  final String type;

  const FavItem({
    super.key,
    required this.item, required this.type,

  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context,HomeScreen.routeName);
      },

      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset('assets/mockup/landing/${item.image}',
                    width: 60, height: 60),
                const SizedBox(width: 16),
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            SvgPicture.asset(
              'assets/mockup/landing/landing_plus.svg',
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(Color(
                  type == 'my' ? 0xFF08C97E : 0xFFC4C4C4), BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}
