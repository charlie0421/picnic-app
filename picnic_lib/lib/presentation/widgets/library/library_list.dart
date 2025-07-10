import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/library_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/loading_view.dart';
import 'package:picnic_lib/ui/style.dart';

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
              height: 300,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        AppLocalizations.of(context).label_library_save,
                        style: getTextStyle(AppTypo.body16B),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _showAddAlbum();
                        },
                        child: Text(
                          AppLocalizations.of(context).label_album_add,
                          style: getTextStyle(AppTypo.body14R),
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
                          height: 50,
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
                    margin: const EdgeInsets.only(bottom: 30),
                    child: ElevatedButton(
                      onPressed: () {
                        logger.w('selectedRadioTile: $_selectedRadioTile');
                        final asyncLibraryNotifier =
                            ref.read(asyncLibraryListProvider.notifier);
                        asyncLibraryNotifier.addImageToLibrary(
                            _selectedRadioTile, widget.imageId);
                      },
                      child: Text(AppLocalizations.of(context).button_complete),
                    ),
                  ),
                ],
              ),
            ),
        error: (error, stackTrace) => buildErrorView(context,
            error: error, stackTrace: stackTrace, retryFunction: () {}),
        loading: () => const LoadingView());
  }

  Future<void> _showAddAlbum() {
    return showDialog(
      context: context,
      builder: (context) {
        TextEditingController albumController = TextEditingController();
        return AlertDialog(
          title: Text(AppLocalizations.of(context).title_dialog_library_add),
          content: TextFormField(
            controller: albumController,
            decoration: InputDecoration(
                hintText: AppLocalizations.of(context).hint_library_add),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context).button_cancel),
              onPressed: () {
                albumController.dispose();
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context).button_ok),
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
