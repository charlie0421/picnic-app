import 'package:flutter/material.dart';
import 'package:picnic_app/components/my_page/vote_artist_search.dart';

class VoteArtistPage extends StatelessWidget {
  final String pageName = 'label_tab_my_artist';

  const VoteArtistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const VoteMyArtistList();
  }
}
