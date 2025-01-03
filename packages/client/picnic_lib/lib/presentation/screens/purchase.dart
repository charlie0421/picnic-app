import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy_web.dart';

class PurchaseScreen extends StatelessWidget {
  static const String routeName = '/purchase';

  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: PurchaseStarCandyWeb());
  }
}
