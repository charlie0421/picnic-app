import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_info.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/pages/community/compatibility_result_page.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';

class CompatibilityInputPage extends ConsumerStatefulWidget {
  const CompatibilityInputPage({
    super.key,
    required this.artist,
  });

  final ArtistModel artist;

  @override
  ConsumerState<CompatibilityInputPage> createState() =>
      _CompatibilityInputScreenState();
}

class _CompatibilityInputScreenState
    extends ConsumerState<CompatibilityInputPage> {
  DateTime? _birthDate;
  String? _birthTime;
  String? _gender;
  bool _agreedToSaveProfile = false;
  List<String>? _timeSlots;

  static const genderOptions = [
    {'value': 'male', 'label': '남성'},
    {'value': 'female', 'label': '여성'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.board,
          showBottomNavigation: false,
          pageTitle: S.of(context).compatibility_page_title);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move the time slots initialization here
    _timeSlots = [
      S.of(context).compatibility_time_slot1,
      S.of(context).compatibility_time_slot2,
      S.of(context).compatibility_time_slot3,
      S.of(context).compatibility_time_slot4,
      S.of(context).compatibility_time_slot5,
      S.of(context).compatibility_time_slot6,
      S.of(context).compatibility_time_slot7,
      S.of(context).compatibility_time_slot8,
      S.of(context).compatibility_time_slot9,
      S.of(context).compatibility_time_slot10,
      S.of(context).compatibility_time_slot11,
      S.of(context).compatibility_time_slot12,
    ];
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProfileAsync = ref.read(userInfoProvider);
      userProfileAsync.when(
        data: (userProfile) {
          if (userProfile != null) {
            setState(() {
              _birthDate = userProfile.birthDate;
              _gender = userProfile.gender;
              _birthTime =
                  userProfile.birthTime; // Load birth time from profile
            });
            logger.i(
                'Loaded user profile - birthDate: $_birthDate, gender: $_gender, birthTime: $_birthTime');
          }
        },
        loading: () => null,
        error: (error, stack) {
          logger.e('Error loading user profile',
              error: error, stackTrace: stack);
        },
      );
    } catch (e, s) {
      logger.e('Error loading user profile', error: e, stackTrace: s);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary500,
              onPrimary: AppColors.grey00,
              surface: AppColors.grey00,
              onSurface: AppColors.grey900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일을 선택해주세요')),
      );
      return;
    }

    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성별을 선택해주세요')),
      );
      return;
    }

    if (!_agreedToSaveProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 정보 저장에 동의해주세요')),
      );
      return;
    }

    try {
      // 중복 데이터 확인을 위한 쿼리 빌더
      var query = supabase
          .from('compatibility_results')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('artist_id', widget.artist.id)
          .eq('user_birth_date', _birthDate!.toIso8601String())
          .eq('gender', _gender!);

      // birth_time이 null인 경우와 아닌 경우를 구분하여 처리
      if (_birthTime == null) {
        query = query.isFilter('user_birth_time', null);
      } else {
        query = query.eq('user_birth_time', _birthTime!);
      }

      final existingResult = await query.select();

      if (existingResult.isNotEmpty) {
        // 중복된 데이터가 있는 경우 확인 다이얼로그 표시
        if (!mounted) return;

        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                '이미 존재하는 궁합 데이터',
                style: getTextStyle(AppTypo.title18B, AppColors.grey900),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '동일한 조건의 궁합 데이터가 이미 존재합니다:',
                    style: getTextStyle(AppTypo.body14R, AppColors.grey900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 생년월일: ${DateFormat('yyyy년 MM월 dd일').format(_birthDate!)}',
                    style: getTextStyle(AppTypo.body14R, AppColors.grey700),
                  ),
                  if (_birthTime != null)
                    Text(
                      '• 태어난 시간: ${_timeSlots![int.parse(_birthTime!) - 1].split('|')[0]}',
                      style: getTextStyle(AppTypo.body14R, AppColors.grey700),
                    ),
                  Text(
                    '• 성별: ${_gender == 'male' ? '남성' : '여성'}',
                    style: getTextStyle(AppTypo.body14R, AppColors.grey700),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '새로운 궁합을 보시겠습니까?',
                    style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    '취소',
                    style: getTextStyle(AppTypo.body14M, AppColors.grey500),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '새로 보기',
                    style: getTextStyle(AppTypo.body14M, AppColors.grey00),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
              actionsPadding: const EdgeInsets.all(16),
            );
          },
        );

        if (shouldProceed != true) {
          return;
        }
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('궁합을 분석하고 있습니다...')),
        );
      }

      // 프로필 정보 저장
      await ref.read(userInfoProvider.notifier).updateProfile(
            gender: _gender,
            birthDate: _birthDate,
            birthTime: _birthTime,
          );

      logger.i('Starting compatibility analysis');

      // 궁합 분석 시작
      final compatibility =
          await ref.read(compatibilityProvider.notifier).createCompatibility(
                userId: supabase.auth.currentUser!.id,
                artist: widget.artist,
                birthDate: _birthDate!,
                birthTime: _birthTime,
                gender: _gender!,
              );

      if (mounted) {
        // 결과 페이지로 이동
        ref.read(navigationInfoProvider.notifier).setCurrentPage(
              CompatibilityResultPage(
                compatibility: compatibility,
              ),
            );
      }
    } catch (e) {
      logger.e('Error in submit', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 프로필 이미지와 이름
            CompatibilityInfo(
              artist: widget.artist,
              ref: ref,
              birthDate: _birthDate,
              birthTime: _birthTime,
            ),
            const SizedBox(height: 8),

            // 성별 선택
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            color: AppColors.primary500),
                        const SizedBox(width: 8),
                        Text(
                          '성별',
                          style:
                              getTextStyle(AppTypo.body14B, AppColors.grey900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: genderOptions
                          .map((option) => Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: FilledButton(
                                    onPressed: () => setState(
                                        () => _gender = option['value']),
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          _gender == option['value']
                                              ? AppColors.primary500
                                              : AppColors.grey300,
                                    ),
                                    child: Text(
                                      option['label']!,
                                      style: getTextStyle(
                                        AppTypo.body14B,
                                        _gender == option['value']
                                            ? AppColors.grey00
                                            : AppColors.grey900,
                                      ),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 생년월일 선택
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: AppColors.primary500),
                          const SizedBox(width: 8),
                          Text(
                            '생년월일',
                            style: getTextStyle(
                                AppTypo.body14B, AppColors.grey900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _birthDate == null
                            ? '날짜를 선택해주세요'
                            : '${_birthDate!.year}년 ${_birthDate!.month}월 ${_birthDate!.day}일',
                        style: getTextStyle(
                          AppTypo.body14B,
                          _birthDate == null
                              ? AppColors.grey500
                              : AppColors.grey900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 시간 선택
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: AppColors.primary500),
                        const SizedBox(width: 8),
                        Text(
                          '태어난 시간 (선택사항)',
                          style:
                              getTextStyle(AppTypo.body14R, AppColors.grey900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.grey300,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      value: _birthTime,
                      // This will now use the loaded birth time
                      hint: Text(
                        '시간을 선택해주세요',
                        style: getTextStyle(AppTypo.body14M, AppColors.grey500),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            '모름',
                            style: getTextStyle(
                                AppTypo.body14M, AppColors.grey900),
                          ),
                        ),
                        ...?_timeSlots?.asMap().entries.map(
                          (entry) {
                            final index = entry.key;
                            final time = entry.value;
                            final text = time.split('|')[0];
                            final textTime = time.split('|')[1];
                            final icon = time.split('|').last;

                            return DropdownMenuItem(
                              value: (index + 1).toString(),
                              child: Row(
                                children: [
                                  Text(icon),
                                  Text(' '),
                                  Text(
                                    text,
                                    style: getTextStyle(
                                        AppTypo.body14M, AppColors.grey900),
                                  ),
                                  Text(' '),
                                  Text(textTime),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _birthTime = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 동의 체크박스
            CheckboxListTile(
              value: _agreedToSaveProfile,
              activeColor: AppColors.primary500,
              onChanged: (value) {
                setState(() {
                  _agreedToSaveProfile = value ?? false;
                });
              },
              title: Text(
                S.of(context).compatibility_agree_checkbox,
                style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // Submit Button
            FilledButton(
              onPressed: _agreedToSaveProfile ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: _agreedToSaveProfile
                    ? AppColors.primary500
                    : AppColors.grey300,
              ),
              child: Text(
                '궁합 보기',
                style: getTextStyle(AppTypo.body16B, AppColors.grey00),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
