import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/widgets/wallet/wallet_summary_panel.dart';

class StarCandyInfoText extends ConsumerStatefulWidget {
  final MainAxisAlignment alignment;

  const StarCandyInfoText({
    super.key,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  ConsumerState<StarCandyInfoText> createState() => _StarCandyInfoTextState();
}

class _StarCandyInfoTextState extends ConsumerState<StarCandyInfoText> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WalletSummaryPanel(compact: true, alignment: widget.alignment);
  }
}
