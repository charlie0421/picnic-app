import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/ui/style.dart';

class VoteArtists extends StatelessWidget {
  final VoteModel vote;

  const VoteArtists({super.key, required this.vote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1 / 1.45,
        ),
        children: vote.vote_item!
            .asMap()
            .entries
            .map((artist) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey.withOpacity(1),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 7,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Image.network(
                            '${artist.value.artist?.image}?w=100',
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              width: 18.w,
                              height: 18.w,
                              decoration: BoxDecoration(
                                color: picMainColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  (artist.key + 1).toString(),
                                  style: getTextStyle(
                                      AppTypo.BODY14R, Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 2.w,
                      ),
                      Text(
                        artist.value.artist
                                ?.name[Intl.getCurrentLocale().split('_')[0]] ??
                            '',
                        style: getTextStyle(AppTypo.CAPTION12B),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
