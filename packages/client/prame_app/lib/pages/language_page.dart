import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/providers/app_setting_provider.dart';

Map<String, String> countryMap = {
  'KR': 'South Korea',
  'US': 'United States',
  'JP': 'Japan',
  'DE': 'Germany',
  'FR': 'France',
  'ES': 'Spain',
  'IT': 'Italy',
  'RU': 'Russia',
  'CN': 'China',
  'BR': 'Brazil',
};

Map<String, String> languageMap = {
  'ko': '한국어',
  'en': 'English',
  'ja': '日本語',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
  'it': 'Italiano',
  'ru': 'Русский',
  'zh': '中文',
  'pt': 'Português',
};

class LanguagePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Column(
      children: [
        Container(
            width: double.infinity,
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Intl.message('label_current_language'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),),
                Text('${countryMap[locale.countryCode] ?? ''}, ${languageMap[locale.languageCode] ?? ''}', style: Theme.of(context).textTheme.titleLarge,)
              ],
            )),
        Divider(),
        Expanded(
          child: ListView.separated(
            itemCount: languageMap.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return InkWell(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  height: 40,
                  child: Text(
                    '${countryMap[countryMap.keys.elementAt(index)]!}, ${languageMap[languageMap.keys.elementAt(index)]!}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                onTap: () {
                  ref.read(localeProvider.notifier).state  = Locale(
                    languageMap.keys.elementAt(index),
                    countryMap.keys.elementAt(index),
                  );
                Intl.defaultLocale = locale.languageCode;
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
