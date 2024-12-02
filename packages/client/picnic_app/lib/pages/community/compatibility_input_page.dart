import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/underlined_text.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_info.dart';
import 'package:picnic_app/components/stroked_text.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/pages/community/compatibility_result_page.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
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
  bool _isLoading = false;

  static List<Map<String, String>> genderOptions = [
    {'value': 'male', 'label': Intl.message('compatibility_gender_male')},
    {'value': 'female', 'label': Intl.message('compatibility_gender_female')},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
    _initTimeSlots();
  }

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            topRightMenu: TopRightType.board,
            showBottomNavigation: false,
            pageTitle: S.of(context).compatibility_page_title,
          );
    });
  }

  void _initTimeSlots() {
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
          if (userProfile != null && mounted) {
            setState(() {
              _birthDate = userProfile.birthDate;
              _gender = userProfile.gender;
              _birthTime = userProfile.birthTime;
            });
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
      firstDate: DateTime(1900),
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

    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    if (_birthDate == null || _gender == null || !_agreedToSaveProfile) {
      _showValidationError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final existingCompatibility = await _checkExistingCompatibility();

      if (existingCompatibility != null) {
        if (!mounted) return;
        final shouldProceed =
            await _showCompatibilityDuplicateDialog(existingCompatibility);

        if (!shouldProceed) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;
      _showLoadingMessage();

      await _saveUserProfile();

      final compatibility = await _createCompatibility();
      if (compatibility == null || !mounted) {
        _showErrorMessage();
        return;
      }

      _navigateToResult(compatibility);
    } catch (e, s) {
      logger.e('Error in submit', error: e, stackTrace: s);
      if (mounted) {
        _showErrorMessage();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<CompatibilityModel?> _checkExistingCompatibility() async {
    var query = supabase
        .from('compatibility_results')
        .select('''
          id,
          user_id,
          artist_id,
          user_birth_date,
          user_birth_time,
          gender,
          status,
          error_message,
          compatibility_score,
          created_at,
          completed_at,
          is_paid
        ''')
        .eq('user_id', supabase.auth.currentUser!.id)
        .eq('artist_id', widget.artist.id)
        .eq('user_birth_date', _birthDate!.toIso8601String())
        .eq('gender', _gender!);
    query = _birthTime == null
        ? query.isFilter('user_birth_time', null)
        : query.eq('user_birth_time', _birthTime!);

    final result = await query.select();

    if (result.isEmpty) return null;

    return CompatibilityModel.fromJson({
      ...result.first,
      'artist': widget.artist.toJson(),
    });
  }

  Future<bool> _showCompatibilityDuplicateDialog(
      CompatibilityModel existing) async {
    if (!mounted) return false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                S.of(context).compatibility_duplicate_data_title,
                style: getTextStyle(AppTypo.title18B, AppColors.grey900),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).compatibility_duplicate_data_message,
                    style: getTextStyle(AppTypo.body14R, AppColors.grey900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${S.of(context).compatibility_birthday}: ${formatDateTimeYYYYMMDD(_birthDate!)}',
                    style: getTextStyle(AppTypo.body14R, AppColors.grey700),
                  ),
                  if (_birthTime != null)
                    Text(
                      '• ${S.of(context).compatibility_birthtime}: ${_timeSlots![int.parse(_birthTime!) - 1].split('|')[0]}',
                      style: getTextStyle(AppTypo.body14R, AppColors.grey700),
                    ),
                  Text(
                    '• ${S.of(context).compatibility_gender}: ${_gender == 'male' ? S.of(context).compatibility_gender_male : S.of(context).compatibility_gender_female}',
                    style: getTextStyle(AppTypo.body14R, AppColors.grey700),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.of(context).compatibility_new_compatibility_ask,
                    style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    S.of(context).button_cancel,
                    style: getTextStyle(AppTypo.body14M, AppColors.grey500),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    S.of(context).compatibility_analyze_start,
                    style: getTextStyle(AppTypo.body14M, AppColors.grey00),
                  ),
                ),
              ],
              actionsPadding: const EdgeInsets.all(16),
            );
          },
        ) ??
        false;
  }

  void _showLoadingMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(S.of(context).compatibility_snackbar_start),
          duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _saveUserProfile() async {
    await ref.read(userInfoProvider.notifier).updateProfile(
          gender: _gender,
          birthDate: _birthDate,
          birthTime: _birthTime,
        );
  }

  Future<CompatibilityModel?> _createCompatibility() async {
    return await ref.read(compatibilityProvider.notifier).createCompatibility(
          artist: widget.artist,
          birthDate: _birthDate!,
          gender: _gender!,
          birthTime: _birthTime,
        );
  }

  void _navigateToResult(CompatibilityModel compatibility) {
    ref.read(navigationInfoProvider.notifier).setCurrentPage(
          CompatibilityResultPage(
            compatibility: compatibility,
          ),
        );
  }

  void _showValidationError() {
    String message;
    if (_birthDate == null) {
      message = S.of(context).compatibility_snackbar_need_birthday;
    } else if (_gender == null) {
      message = S.of(context).compatibility_snackbar_need_gender;
    } else {
      message = S.of(context).compatibility_snackbar_need_profile_save_agree;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).compatibility_snackbar_error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary500.withOpacity(0.8),
              AppColors.mint500.withOpacity(0.8)
            ],
          ),
        ),
        child: Column(
          children: [
            StrokedText(
              text: S.of(context).label_mypage_my_artist,
              textStyle: getTextStyle(AppTypo.title18B, AppColors.grey00),
              strokeWidth: 3,
            ),
            const SizedBox(height: 12),
            CompatibilityInfo(
              artist: widget.artist,
              ref: ref,
              compatibility: null,
            ),
            const SizedBox(height: 8),
            Divider(),
            StrokedText(
              text: S.of(context).my_info,
              textStyle: getTextStyle(AppTypo.title18B, AppColors.grey00),
              strokeWidth: 2,
            ),
            SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      color: AppColors.primary500,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/fortune/heart.svg',
                        width: 36,
                        height: 33,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UnderlinedText(
                          text: S.of(context).compatibility_gender,
                          textStyle:
                              getTextStyle(AppTypo.body14B, AppColors.grey900),
                          underlineColor: AppColors.primary500,
                          underlineHeight: 2,
                          underlineGap: 4,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _gender = genderOptions[1]['value'];
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: _gender == genderOptions[1]['value']
                                      ? AppColors.primary500
                                      : AppColors.grey300,
                                ),
                                width: 60,
                                height: 19,
                                child: Center(
                                  child: Text(
                                    S.of(context).compatibility_gender_female,
                                    style: getTextStyle(
                                        AppTypo.caption10SB, AppColors.grey00),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _gender = genderOptions[0]['value'];
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: _gender == genderOptions[0]['value']
                                      ? AppColors.primary500
                                      : AppColors.grey300,
                                ),
                                width: 60,
                                height: 19,
                                child: Center(
                                  child: Text(
                                    S.of(context).compatibility_gender_male,
                                    style: getTextStyle(
                                        AppTypo.caption10SB, AppColors.grey00),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      color: AppColors.primary500,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/fortune/calendar.svg',
                        width: 36,
                        height: 33,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UnderlinedText(
                            text: S.of(context).compatibility_birthday,
                            textStyle: getTextStyle(
                                AppTypo.body14B, AppColors.grey900),
                            underlineColor: AppColors.primary500,
                            underlineHeight: 2,
                            underlineGap: 4,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 26,
                            constraints: BoxConstraints(
                              maxWidth: 260,
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.grey900,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _birthDate == null
                                  ? S.of(context).compatibility_birthday
                                  : formatDateTimeYYYYMMDD(_birthDate!),
                              style: getTextStyle(
                                AppTypo.caption12M,
                                _birthDate == null
                                    ? AppColors.grey500
                                    : AppColors.grey900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      color: AppColors.primary500,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/fortune/time.svg',
                        width: 36,
                        height: 33,
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            UnderlinedText(
                              textStyle: getTextStyle(
                                  AppTypo.body14B, AppColors.grey900),
                              text: S.of(context).compatibility_birthtime,
                              underlineColor: AppColors.primary500,
                              underlineHeight: 2,
                              underlineGap: 4,
                            ),
                            SizedBox(width: 8),
                            Text(
                              S.of(context).compatibility_birthtime_subtitle,
                              style: getTextStyle(
                                AppTypo.caption10SB,
                                AppColors.point900,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Container(
                            height: 26,
                            constraints: BoxConstraints(
                              maxWidth: 260,
                            ),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.grey900,
                                    width: 0.1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                              ),
                              value: _birthTime,
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    S
                                        .of(context)
                                        .compatibility_time_slot_unknown,
                                    style: getTextStyle(
                                      AppTypo.caption10SB,
                                      AppColors.grey900,
                                    ),
                                  ),
                                ),
                                ...?_timeSlots?.asMap().entries.map(
                                  (entry) {
                                    final index = entry.key;
                                    final time = entry.value;
                                    final parts = time.split('|');
                                    final text = parts[0];
                                    final textTime = parts[1];
                                    final icon =
                                        parts.length > 2 ? parts[2] : '';

                                    return DropdownMenuItem(
                                        value: (index + 1).toString(),
                                        child: Text(
                                          '${icon.isNotEmpty ? '$icon ' : ''}$text $textTime',
                                          style: getTextStyle(
                                            AppTypo.caption10SB,
                                            AppColors.grey900,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ));
                                  },
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _birthTime = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(),

            // Agreement Checkbox
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
                style: getTextStyle(AppTypo.caption12M, AppColors.grey900),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: _isLoading || !_agreedToSaveProfile
                    ? AppColors.grey300
                    : AppColors.primary500,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.grey500,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: SvgPicture.asset(
                            'assets/icons/fortune/heart.svg',
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              AppColors.grey00,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          S.of(context).compatibility_analyze_start,
                          style:
                              getTextStyle(AppTypo.body16B, AppColors.grey00),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class Divider extends StatelessWidget {
  const Divider({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 3,
        width: 48,
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.grey00,
        ),
      ),
    );
  }
}
