import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/search_list.dart';
import 'package:prame_app/mockup/mock_data.dart';
import 'package:prame_app/screens/home_screen.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
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
          Text(Intl.message('lable_my_celeb'),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...myFav.map((item) {
            return FavItem(
              item: item,
              type: 'my',
            );
          }),
          const SizedBox(height: 16),
          Text(Intl.message('label_celeb_recommend'),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (BuildContext context) => const SearchList());
            },
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFE6FBEE),
                border: Border.all(color: const Color(0xFFB7B7B7)),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SvgPicture.asset(
                    'assets/landing/search_icon.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...findYourFav.map((item) {
            return FavItem(
              item: item,
              type: 'find',
            );
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
    required this.item,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, HomeScreen.routeName);
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
            type == 'my'
                ? InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('즐겨찾기에서 삭제'),
                          duration: Duration(milliseconds: 300),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/landing/bookmark_added.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                          Color(type == 'my' ? 0xFF08C97E : 0xFFC4C4C4),
                          BlendMode.srcIn),
                    ),
                  )
                : InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('즐겨찾기에 추가'),
                          duration: Duration(milliseconds: 300),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/landing/bookmark_add.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                          Color(type == 'my' ? 0xFF08C97E : 0xFFC4C4C4),
                          BlendMode.srcIn),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
