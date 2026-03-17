import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton/shimmer loading UI for [VoteDetailPage].
///
/// Extracted to keep the main page file focused on interactive logic.
class VoteDetailSkeleton extends StatelessWidget {
  const VoteDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSkeleton(),
                const SizedBox(height: 20),
                _buildTitleSkeleton(),
                const SizedBox(height: 12),
                _buildDateSkeleton(),
                const SizedBox(height: 12),
                _buildButtonSkeleton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _buildVoteListSkeletonStatic()),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  Widget _buildTitleSkeleton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 57.w),
      child: Column(
        children: [
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 24,
            width: 200.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSkeleton() {
    return Center(
      child: Container(
        height: 18,
        width: 250.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }

  Widget _buildButtonSkeleton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: 16.w),
        child: Container(
          width: 120.w,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
          ),
        ),
      ),
    );
  }

  /// Vote list area skeleton, usable standalone (e.g. within an existing CustomScrollView).
  static Widget buildVoteListOnly() => _buildVoteListSkeletonStatic();

  static Widget _buildVoteListSkeletonStatic() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 24, left: 16.w, right: 16.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.r),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70.r),
          topRight: Radius.circular(70.r),
          bottomLeft: Radius.circular(40.r),
          bottomRight: Radius.circular(40.r),
        ),
        color: Colors.white,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 56,
          left: 16.w,
          right: 16.w,
          bottom: 24,
        ).r,
        child: Column(
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(5, (index) => _buildVoteItemSkeletonStatic(index)),
          ],
        ),
      ),
    );
  }

  static Widget _buildVoteItemSkeletonStatic(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Row(
        children: [
          SizedBox(
            width: 39,
            child: Column(
              children: [
                if (index < 3)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }
}
