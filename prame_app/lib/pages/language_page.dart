import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/providers/app_setting_provider.dart';

import '../constants.dart';

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettingState = ref.watch(appSettingProvider);
    final appSettingNotifier = ref.read(appSettingProvider.notifier);

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
                Text(
                  Intl.message('label_current_language'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${countryMap[appSettingState.locale.countryCode] ?? ''}, ${languageMap[appSettingState.locale.languageCode] ?? ''}',
                  style: Theme.of(context).textTheme.titleLarge,
                )
              ],
            )),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: languageMap.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return InkWell(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  height: 50,
                  color: appSettingState.locale.languageCode ==
                          languageMap.keys.elementAt(index)
                      ? Constants.mainColor
                      : null,
                  child: Text(
                    '${countryMap[countryMap.keys.elementAt(index)]!}, ${languageMap[languageMap.keys.elementAt(index)]!}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) {
                      appSettingNotifier.setLocale(Locale(
                        languageMap.keys.elementAt(index),
                        countryMap.keys.elementAt(index),
                      ));
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
