import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';

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
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).label_current_language,
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
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  alignment: Alignment.centerLeft,
                  height: 50,
                  color: appSettingState.locale.languageCode ==
                          languageMap.keys.elementAt(index)
                      ? picMainColor
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
