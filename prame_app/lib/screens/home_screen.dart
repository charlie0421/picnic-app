import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/celeb_list_item.dart';
import 'package:prame_app/components/error.dart';
import 'package:prame_app/components/no_bookmark_celeb.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/celeb.dart';
import 'package:prame_app/pages/gallery_page.dart';
import 'package:prame_app/pages/home_page.dart';
import 'package:prame_app/providers/bottom_navigation_provider.dart';
import 'package:prame_app/providers/celeb_banner_list_provider.dart';
import 'package:prame_app/providers/celeb_list_provider.dart';
import 'package:prame_app/providers/my_celeb_list_provider.dart';
import 'package:prame_app/providers/selected_celeb_provider.dart';
import 'package:prame_app/screens/bottom_navigation_bar.dart';
import 'package:prame_app/screens/landing_screen.dart';
import 'package:prame_app/ui/style.dart';
import 'package:prame_app/util.dart';

class HomeScreen extends ConsumerWidget {
  static const String routeName = '/home';

  CelebModel celebModel;
  HomeScreen({super.key, required this.celebModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context, ref),
      bottomNavigationBar: buildBottomNavigationBar(ref),
      body: _buildPage(ref),
    );
  }

  AppBar _buildAppBar(context, WidgetRef ref) {
    final bottomNavigationBarIndexState =
        ref.watch(bottomNavigationBarIndexStateProvider);
    final asyncMyCelebListState = ref.watch(asyncMyCelebListProvider);
    final asyncCelebListState = ref.watch(asyncCelebListProvider);
    final asyncSelectedCelebState = ref.watch(selectedCelebProvider);
    celebModel = asyncSelectedCelebState ?? celebModel;

    switch (bottomNavigationBarIndexState) {
      case 0:
        return AppBar(
          title: asyncCelebListState.when(
              data: (data) {
                if (data.items.isEmpty) {
                  asyncMyCelebListState.when(
                    data: (celebListModel) {
                      SizedBox(
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              CachedNetworkImage(
                                  imageUrl:
                                      celebListModel.items.first.thumbnail,
                                  width: 38,
                                  height: 38),
                              const SizedBox(width: 8),
                              Text(
                                celebListModel.items.first.nameKo,
                                style: getTextStyle(
                                    AppTypo.UI16B, AppColors.Gray00),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    _buildSelectCelebBottomSheet(context, ref),
                                child: SvgPicture.asset(
                                  'assets/icons/dropdown.svg',
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ],
                          ));
                    },
                    error: (error, stackTrace) => ErrorView(
                      context,
                      retryFunction: () {
                        ref.refresh(asyncMyCelebListProvider);
                      },
                      error: error,
                      stackTrace: stackTrace,
                    ),
                    loading: () => buildLoadingOverlay(),
                  );
                } else {
                  // celebModel = selectedCelebState ?? data.items.first;
                  // logger.w('selectedCelebState.nameKo: ${celebModel.nameKo}');
                  // final selectedCelebNotifier =
                  //     ref.read(selectedCelebProvider.notifier);
                  // WidgetsBinding.instance.addPostFrameCallback((_) {
                  //   selectedCelebNotifier.setSelectedCeleb(celebModel);
                  // });

                  return SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CachedNetworkImage(
                              imageUrl: celebModel.thumbnail,
                              width: 38,
                              height: 38),
                          const SizedBox(width: 8),
                          Text(
                            celebModel.nameKo,
                            style:
                                getTextStyle(AppTypo.UI16B, AppColors.Gray00),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                _buildSelectCelebBottomSheet(context, ref),
                            child: SvgPicture.asset(
                              'assets/icons/dropdown.svg',
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ],
                      ));
                }
              },
              loading: () => buildLoadingOverlay(),
              error: (error, stackTrace) => ErrorView(
                    context,
                    retryFunction: () {
                      ref.refresh(asyncMyCelebListProvider);
                    },
                    error: error,
                    stackTrace: stackTrace,
                  )),
        );
      case 1:
        return AppBar(
          title: const Text('Gallery'),
        );
      default:
        return AppBar();
    }
  }

  Widget _buildPage(ref) {
    final counterState = ref.watch(bottomNavigationBarIndexStateProvider);

    switch (counterState) {
      case 0:
        return HomePage(
          celebModel: celebModel,
        );
      case 1:
        return const GalleryPage();
      default:
        return Container();
    }
  }

  void _buildSelectCelebBottomSheet(BuildContext context, WidgetRef ref) {
    final asyncMyCelebListState = ref.watch(asyncMyCelebListProvider);
    final asyncSelectedCelebState = ref.watch(selectedCelebProvider);
    CelebModel? selectedCeleb = asyncSelectedCelebState;
    showModalBottomSheet(
        context: context,
        useSafeArea: false,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        builder: (BuildContext context) {
          return SingleChildScrollView(
              child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                Intl.message('label_moveto_celeb_gallery'),
                style: getTextStyle(AppTypo.UI20B, AppColors.Gray900),
              ),
              Text(
                Intl.message('text_moveto_celeb_gallery'),
                style: getTextStyle(AppTypo.UI16, AppColors.Gray900),
              ),
              const SizedBox(height: 16),
              ...asyncMyCelebListState.when(
                  data: (data) {
                    logger.w('data.items.length: ${data.items.length}');
                    return data.items.isNotEmpty
                        ? _buildSearchList(context, ref, data, selectedCeleb)
                        : [const NoBookmarkCeleb()];
                  },
                  loading: () => [buildLoadingOverlay()],
                  error: (error, stackTrace) => [
                        ErrorView(
                          context,
                          retryFunction: () {
                            ref.refresh(asyncMyCelebListProvider);
                          },
                          error: error,
                          stackTrace: stackTrace,
                        )
                      ]),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, LandingScreen.routeName, (route) => false);
                  },
                  child: Text(Intl.message('label_find_celeb'))),
              const SizedBox(
                height: 40,
              ),
            ],
          ));
        });
  }

  List<Widget> _buildSearchList(BuildContext context, WidgetRef ref,
      CelebListModel data, CelebModel? selectedCeleb) {
    logger.w('selectedCeleb: ${selectedCeleb}');
    logger.w('selectedCeleb: ${selectedCeleb?.nameKo}');
    logger.w('CelebListModel: ${data.items.length}');

    if (selectedCeleb != null) {
      data.items.removeWhere((item) => item.id == selectedCeleb.id);
      data.items.insert(0, selectedCeleb);
    }
    return selectedCeleb != null
        ? data.items
            .map((e) => Container(
                height: 70,
                margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: e.id == selectedCeleb?.id
                      ? const Color(0xFF47E89B)
                      : AppColors.Gray00,
                  border: Border.all(
                    color: AppColors.Gray100,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    ref
                        .read(selectedCelebProvider.notifier)
                        .setSelectedCeleb(e);
                    ref.read(asyncCelebBannerListProvider(celebId: e.id));
                    Navigator.pop(context);
                  },
                  child: CelebListItem(
                      item: e,
                      type: 'my',
                      showBookmark: e.id != selectedCeleb?.id,
                      enableBookmark: false),
                )))
            .toList()
        : [const NoBookmarkCeleb()];
  }
}

class HomeScreenArguments {
  final CelebModel celebModel;

  HomeScreenArguments(this.celebModel);
}
