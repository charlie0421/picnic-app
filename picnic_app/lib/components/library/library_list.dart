import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/loading_view.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/library_list_provider.dart';
import 'package:picnic_app/ui/style.dart';

class AlbumList extends ConsumerStatefulWidget {
  final int imageId;

  const AlbumList({super.key, required this.imageId});

  @override
  ConsumerState<AlbumList> createState() => _LibraryListState();
}

class _LibraryListState extends ConsumerState<AlbumList> {
  int _selectedRadioTile = 0;

  @override
  Widget build(BuildContext context) {
    final asyncLibraryState = ref.watch(asyncLibraryListProvider);

    return asyncLibraryState.when(
        data: (data) => SizedBox(
              height: 300.h,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        Intl.message('label_library_save'),
                        style: getTextStyle(AppTypo.BODY16B),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showAddAlbum();
                        },
                        child: Text(
                          Intl.message('label_album_add'),
                          style: getTextStyle(AppTypo.BODY14R),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data?.length ?? 0,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          height: 50.h,
                          width: double.infinity,
                          child: RadioListTile<int>(
                            title: Text(
                              data?[index].title ?? '',
                            ),
                            value: data?[index].id ?? 0,
                            groupValue: _selectedRadioTile,
                            onChanged: (int? value) {
                              setState(() {
                                _selectedRadioTile = value!;
                              });
                            },
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 30.h),
                    child: ElevatedButton(
                      onPressed: () {
                        logger.w('selectedRadioTile: $_selectedRadioTile');
                        final asyncLibraryNotifier =
                            ref.read(asyncLibraryListProvider.notifier);
                        asyncLibraryNotifier.addImageToLibrary(
                            _selectedRadioTile, widget.imageId);
                      },
                      child: Text(Intl.message('button_complete')),
                    ),
                  ),
                ],
              ),
            ),
        error: (error, stackTrace) => ErrorView(context,
            error: error, stackTrace: stackTrace, retryFunction: () {}),
        loading: () => const LoadingView());
  }

  _showAddAlbum() {
    return showDialog(
      context: context,
      builder: (context) {
        TextEditingController albumController = TextEditingController();
        return AlertDialog(
          title: Text(Intl.message('title_dialog_library_add')),
          content: TextFormField(
              controller: albumController,
              decoration:
                  InputDecoration(hintText: Intl.message('hint_library_add'))),
          actions: <Widget>[
            TextButton(
              child: Text(Intl.message('button_cancel')),
              onPressed: () {
                albumController.dispose();
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(Intl.message('button_ok')),
              onPressed: () {
                if (albumController.text.isNotEmpty) {
                  albumController.dispose();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
