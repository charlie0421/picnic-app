import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:prame_app/components/loading_view.dart';
import 'package:prame_app/models/vote/vote.dart';
import 'package:prame_app/ui/style.dart';

class VoteImage extends StatelessWidget {
  final VoteModel vote;

  const VoteImage({super.key, required this.vote});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 30.h),
      margin: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 0.h),
      decoration: BoxDecoration(
        color: AppColors.Gray600,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: CachedNetworkImage(
          imageUrl: '${vote.mainImage}?w=800',
          fit: BoxFit.cover,
          placeholder: (context, url) => const LoadingView(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}
