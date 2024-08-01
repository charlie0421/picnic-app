import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/vote/store/purchase/purchase_star_candy_state.dart';

class PurchaseStarCandy extends ConsumerStatefulWidget {
  const PurchaseStarCandy({Key? key}) : super(key: key);

  @override
  ConsumerState<PurchaseStarCandy> createState() => PurchaseStarCandyState();
}
