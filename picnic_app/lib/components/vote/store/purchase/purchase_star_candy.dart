import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/vote/store/purchase/purchase_star_candy_state.dart';

class PurchaseStarCandy extends ConsumerStatefulWidget {
  const PurchaseStarCandy({super.key});

  @override
  ConsumerState<PurchaseStarCandy> createState() => PurchaseStarCandyState();
}
