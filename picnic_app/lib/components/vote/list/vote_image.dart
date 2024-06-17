import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

class VoteImage extends StatelessWidget {
  final VoteModel vote;

  const VoteImage({super.key, required this.vote});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 30.w),
      margin: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.w, bottom: 0.w),
      decoration: BoxDecoration(
        color: AppColors.Grey600,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: CachedNetworkImage(
          imageUrl:
              'https://cdn-dev.picnic.fan/vote/${vote.id}/${vote.main_image}?w=800',
          fit: BoxFit.cover,
          placeholder: (context, url) => buildPlaceholderImage(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}
