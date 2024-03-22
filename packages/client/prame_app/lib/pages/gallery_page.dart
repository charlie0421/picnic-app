import 'package:flutter/material.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final PageController _pageController = PageController(
    viewportFraction: 0.9,
  );

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.fromLTRB(10,16,10,0),
          child: Column(
            children: [
              Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Day ${index + 1}',
                    style: Theme.of(context).textTheme.titleLarge,
                  )),
              Image.asset('assets/mockup/gallery/Group 4.png'),
              Container(
                  margin: const EdgeInsets.only(top: 16.0),
                  child: Text(
                      '오늘 백화점에 갔는데, 김치볶음밥 패키지가 넘 웃긴거 있지? 그리고 매뉴팩트 커피에 들리기! 나서긴 좀 부끄러워서 매니저가 대신 사와줬어! 플랫 화이트가 역시 죽인다니깐~~!~!')),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('철썩이', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text('나도 그런데 우린 사실 운명이 아니었을까??', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('고운정고윤정', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text('연희동이었는데 나도 방금!', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
