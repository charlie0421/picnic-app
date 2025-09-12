import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/core/services/device_manager.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/core/utils/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/core/utils/virtual_machine_detector.dart';

class BanScreen extends ConsumerWidget {
  const BanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _LanguageSelector(ref: ref),
              ),
              const Icon(Icons.block, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).ban_title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).ban_message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).ban_contact,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).ban_support_instruction,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              FutureBuilder<Map<String, dynamic>>(
                future: () async {
                  final info = await DeviceManager.getDeviceInfo();
                  final deviceId = await DeviceManager.getDeviceId();

                  final enriched = <String, dynamic>{
                    'device_id': deviceId,
                    'device_info': info,
                    'vm_detection_config': {
                      'enableBuildCheck': VMDetectionConfig.enableBuildCheck,
                      'enableHardwareCheck':
                          VMDetectionConfig.enableHardwareCheck,
                      'enableNetworkCheck':
                          VMDetectionConfig.enableNetworkCheck,
                      'enableSamsungStrictCheck':
                          VMDetectionConfig.enableSamsungStrictCheck,
                      'enableSentryReport':
                          VMDetectionConfig.enableSentryReport,
                      'disableInDebugMode':
                          VMDetectionConfig.disableInDebugMode,
                      'isVMCheckDisabled': VMDetectionConfig.isVMCheckDisabled,
                    },
                  };

                  try {
                    if (UniversalPlatform.isAndroid) {
                      final android = await DeviceInfoPlugin().androidInfo;
                      enriched['vm_referenced_inputs'] = {
                        'manufacturer': android.manufacturer,
                        'model': android.model,
                        'brand': android.brand,
                        'product': android.product,
                        'device': android.device,
                        'hardware': android.hardware,
                        'board': android.board,
                        'bootloader': android.bootloader,
                        'fingerprint': android.fingerprint,
                        'host': android.host,
                        'is_physical_device': android.isPhysicalDevice,
                        'version': {
                          'sdkInt': android.version.sdkInt,
                          'release': android.version.release,
                          'codename': android.version.codename,
                          'incremental': android.version.incremental,
                        },
                        'supported32BitAbis': android.supported32BitAbis,
                        'supported64BitAbis': android.supported64BitAbis,
                        'systemFeatures_sample': android.systemFeatures
                            .take(10)
                            .toList(),
                      };
                    } else if (UniversalPlatform.isIOS) {
                      final ios = await DeviceInfoPlugin().iosInfo;
                      enriched['vm_referenced_inputs'] = {
                        'name': ios.name,
                        'model': ios.model,
                        'system_name': ios.systemName,
                        'system_version': ios.systemVersion,
                        'localized_model': ios.localizedModel,
                        'is_physical_device': ios.isPhysicalDevice,
                        'utsname': {
                          'machine': ios.utsname.machine,
                          'release': ios.utsname.release,
                        },
                      };
                    }
                  } catch (_) {}

                  return enriched;
                }(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  final info = snapshot.data;
                  if (info == null || info.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final pretty = const JsonEncoder.withIndent(
                    '  ',
                  ).convert(info);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => copyToClipboard(context, pretty),
                            icon: const Icon(Icons.copy, size: 16),
                            label: Text(
                              AppLocalizations.of(context).action_copy,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          height: 240,
                          child: SingleChildScrollView(
                            child: SelectableText(
                              pretty,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(appSettingProvider).language;
    final items = const [
      'ko',
      'en',
      'ja',
      'zh_CN',
      'zh_TW',
      'es',
      'th',
      'vi',
      'id',
      'fil',
      'bn_BD',
    ];
    String labelFor(String code) {
      switch (code) {
        case 'ko':
          return '한국어';
        case 'en':
          return 'English';
        case 'ja':
          return '日本語';
        case 'zh_CN':
          return '简体中文';
        case 'zh_TW':
          return '繁體中文';
        case 'es':
          return 'Español';
        case 'th':
          return 'ไทย';
        case 'vi':
          return 'Tiếng Việt';
        case 'id':
          return 'Bahasa Indonesia';
        case 'fil':
          return 'Filipino';
        case 'bn_BD':
          return 'বাংলা (BD)';
        default:
          return code;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: items.contains(current) ? current : 'en',
        underline: const SizedBox.shrink(),
        isDense: true,
        onChanged: (value) async {
          if (value == null) return;
          try {
            ref.read(appSettingProvider.notifier).setLanguage(value);
          } catch (_) {}
        },
        items: items
            .map(
              (code) => DropdownMenuItem<String>(
                value: code,
                child: Text(
                  labelFor(code),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
