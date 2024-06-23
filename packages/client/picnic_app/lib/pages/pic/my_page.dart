import 'package:flutter/material.dart';
import 'package:picnic_app/generated/l10n.dart';

class MyFavItem {
  final String image;

  MyFavItem(this.image);
}

class MomentsItem {
  final String image;
  final String name;

  MomentsItem(this.image, this.name);
}

List<MyFavItem> FabLibrary = [
  MyFavItem('Ellipse 8.png'),
  MyFavItem('Ellipse 9.png'),
  MyFavItem('Ellipse 10.png'),
  MyFavItem('Ellipse 8.png'),
  MyFavItem('Ellipse 9.png'),
  MyFavItem('Ellipse 10.png'),
  MyFavItem('Ellipse 8.png'),
  MyFavItem('Ellipse 9.png'),
  MyFavItem('Ellipse 10.png'),
];

List<MomentsItem> Moments = [
  MomentsItem('Rectangle 14.png', '식사'),
  MomentsItem('Rectangle 14-1.png', '사람들과'),
  MomentsItem('Rectangle 14-2.png', '해변'),
  MomentsItem('Rectangle 14.png', '식사'),
  MomentsItem('Rectangle 14-1.png', '사람들과'),
  MomentsItem('Rectangle 14-2.png', '해변'),
];

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
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
          Text('Fav' 's Library',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...FabLibrary.map((item) {
                  return Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: Image.asset('assets/mockup/my/${item.image}'));
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Special Moments',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...Moments.map((item) {
                  return Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Image.asset('assets/mockup/my/${item.image}'),
                          const SizedBox(height: 4),
                          Text(
                            item.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                          ),
                        ],
                      ));
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ListView(
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              const Divider(height: 20),
              Text(
                S.of(context).mypage_purchases,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20),
              Text(
                S.of(context).mypage_setting,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20),
              Text(
                S.of(context).mypage_subscription,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20),
              Text(
                S.of(context).mypage_comment,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20),
              InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/language');
                  },
                  child: Text(
                    S.of(context).mypage_language,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  )),
              const Divider(height: 20),
            ],
          )
        ],
      )),
    );
  }
}
