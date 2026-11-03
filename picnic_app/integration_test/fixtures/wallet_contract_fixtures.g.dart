// GENERATED; DO NOT EDIT. Integration-test only.
const walletSummaryV1Json = r'''{
  "contract_version": "wallet.v1",
  "star": "9007199254740993",
  "bonus": "250",
  "cotton": "40",
  "cotton_expiring_amount": "10",
  "cotton_next_expires_at": "2026-07-22T00:00:00.000Z",
  "snapshot_at": "2026-07-21T00:00:00.000Z"
}''';
const walletSummaryV1Sha256 =
    '8051c5d3145da910c2654433ac4685172fccca2e8e19bb88dc8e25b22daf2fac';
const currencyHistoryEmptyV1Json = r'''{
  "items": [],
  "total_count": "0",
  "next_cursor": null,
  "snapshot_at": "2026-07-21T00:00:00.000Z"
}''';
const currencyHistoryEmptyV1Sha256 =
    '1d63d16c9d506450d79d2f795daae2fa667d8307b6ea8328123373f106b426fa';
const currencyHistoryMixedV1Json = r'''{
  "items": [
    {
      "id": "101",
      "currency": "STAR_CANDY",
      "event_type": "PURCHASE",
      "origin": "mobile_purchase",
      "delta": "100",
      "balance_effect": "90",
      "expires_at": "2027-07-21T00:00:00.000Z",
      "purchase_id": "00000000-0000-4000-8000-000000000101",
      "refund_id": null,
      "grant_id": null,
      "operation_id": "00000000-0000-4000-8000-000000000201",
      "created_at": "2026-07-21T00:00:00.000Z"
    },
    {
      "id": "202",
      "currency": "COTTON_CANDY",
      "event_type": "VOTE",
      "origin": "wallet",
      "delta": "-5",
      "balance_effect": "-5",
      "expires_at": null,
      "purchase_id": null,
      "refund_id": null,
      "grant_id": "302",
      "operation_id": "00000000-0000-4000-8000-000000000202",
      "created_at": "2026-07-20T23:59:00.000Z"
    }
  ],
  "total_count": "2",
  "next_cursor": null,
  "snapshot_at": "2026-07-21T00:00:00.000Z"
}''';
const currencyHistoryMixedV1Sha256 =
    'a2554658e13e21b3d8e581cb94e93e596dac07541ef7466fa7119e9006066f93';
const voteResultV3Json = r'''{
  "votePickId": 301,
  "updatedVoteTotal": 1017,
  "addedVoteTotal": 17,
  "updatedAt": "2026-07-21T00:00:00.000Z",
  "operation_id": "00000000-0000-4000-8000-000000000301",
  "replayed": false,
  "usage": {
    "cotton_candy_usage": "5",
    "star_candy_bonus_usage": "7",
    "star_candy_usage": "5"
  },
  "wallet": {
    "contract_version": "wallet.v1",
    "star": "95",
    "bonus": "23",
    "cotton": "0",
    "cotton_expiring_amount": "0",
    "cotton_next_expires_at": null,
    "snapshot_at": "2026-07-21T00:00:00.000Z"
  }
}''';
const voteResultV3Sha256 =
    '3bdc10b26b6dbf894d683ffb848e94d794e14cd553d7c5ada4875a1146658c4e';
const adRewardPendingV1Json = r'''{
  "reference": {
    "type": "PANGLE_CLAIM",
    "id": "00000000-0000-4000-8000-000000000401"
  },
  "state": "PENDING",
  "grant": null,
  "wallet": {
    "contract_version": "wallet.v1",
    "star": "100",
    "bonus": "20",
    "cotton": "5",
    "cotton_expiring_amount": "5",
    "cotton_next_expires_at": "2026-07-28T00:00:00.000Z",
    "snapshot_at": "2026-07-21T00:00:00.000Z"
  },
  "snapshot_at": "2026-07-21T00:00:00.000Z"
}''';
const adRewardPendingV1Sha256 =
    '4851a60f643890ccb2647cdf13dd8d22880d306934dbf8cfd27078e51bab5aef';
const adRewardGrantedV1Json = r'''{
  "reference": {
    "type": "INTERNAL_IMPRESSION",
    "id": "00000000-0000-4000-8000-000000000402"
  },
  "state": "GRANTED",
  "grant": {
    "id": "502",
    "currency": "COTTON_CANDY",
    "amount": "3",
    "granted_at": "2026-07-21T00:00:00.000Z",
    "expires_at": "2026-07-28T00:00:00.000Z"
  },
  "wallet": {
    "contract_version": "wallet.v1",
    "star": "100",
    "bonus": "20",
    "cotton": "8",
    "cotton_expiring_amount": "8",
    "cotton_next_expires_at": "2026-07-28T00:00:00.000Z",
    "snapshot_at": "2026-07-21T00:00:00.000Z"
  },
  "snapshot_at": "2026-07-21T00:00:00.000Z"
}''';
const adRewardGrantedV1Sha256 =
    'a8d7b6f566596c00ffeb095e6a95a05915fd7f4b7e7f6a4d87babd20e58376be';
const promotionSurfacesEmptyV1Json = r'''{
  "items": [],
  "total_count": "0",
  "next_cursor": null,
  "snapshot_at": "2026-07-21T00:00:00.000Z",
  "campaign_owned_home_banner_ids": []
}''';
const promotionSurfacesEmptyV1Sha256 =
    'ef3c8b2d29ee77e31ca3b28bfa7ab4070592e3f22c6ead6cb99bff74e68dde8c';
const promotionSurfacesActiveV1Json = r'''{
  "items": [
    {
      "campaign_id": "00000000-0000-4000-8000-000000000901",
      "campaign_version_id": "00000000-0000-4000-8000-000000000902",
      "code": "CANDY_BOOST_DAY",
      "display_name": {
        "ko": "캔디 부스트 데이",
        "en": "Candy Boost Day"
      },
      "extra_bonus_bps": 10000,
      "window_starts_at": "2026-07-19T15:00:00.000Z",
      "window_ends_at": "2026-07-21T15:00:00.000Z",
      "show_in_store": true,
      "show_home_banner": true,
      "home_creative": {
        "banner_id": 101,
        "title": {
          "ko": "캔디 부스트 데이",
          "en": "Candy Boost Day"
        },
        "image": {
          "ko": "https://cdn.example.test/candy-boost-ko.png",
          "en": "https://cdn.example.test/candy-boost-en.png"
        },
        "thumbnail": "https://cdn.example.test/candy-boost-thumb.png",
        "link": "picnic://store",
        "duration": 4500
      }
    }
  ],
  "total_count": "1",
  "next_cursor": null,
  "snapshot_at": "2026-07-21T00:00:00.000Z",
  "campaign_owned_home_banner_ids": [
    101
  ]
}''';
const promotionSurfacesActiveV1Sha256 =
    '54a4f19ba64e7f683de8b2fcd8ab4c0b25b18ae62ad0a947c2da7c15f1f8a028';
const promotionSurfacesEmptyV2Json = r'''{
  "items": [],
  "total_count": "0",
  "next_cursor": null,
  "snapshot_at": "2026-07-21T00:00:00.000Z",
  "campaign_owned_home_banner_ids": []
}''';
const promotionSurfacesEmptyV2Sha256 =
    'ef3c8b2d29ee77e31ca3b28bfa7ab4070592e3f22c6ead6cb99bff74e68dde8c';
const promotionSurfacesActiveV2Json = r'''{
  "items": [
    {
      "campaign_id": "00000000-0000-4000-8000-000000000911",
      "campaign_version_id": "00000000-0000-4000-8000-000000000912",
      "code": "CANDY_BOOST_DAY_V2",
      "display_name": {
        "ko": "캔디 부스트 데이",
        "en": "Candy Boost Day"
      },
      "multiplier_tenths": 15,
      "event_starts_at": "2026-07-19T15:00:00.000Z",
      "event_ends_at": "2026-07-21T15:00:00.000Z",
      "repeat_iso_dows": [
        1,
        2,
        3,
        4,
        5
      ],
      "home_creative": {
        "banner_id": 101,
        "title": {
          "ko": "캔디 부스트 데이",
          "en": "Candy Boost Day"
        },
        "image": {
          "ko": "https://cdn.example.test/candy-boost-ko.png",
          "en": "https://cdn.example.test/candy-boost-en.png"
        },
        "thumbnail": "https://cdn.example.test/candy-boost-thumb.png",
        "link": "picnic://store",
        "duration": 4500
      }
    }
  ],
  "total_count": "1",
  "next_cursor": null,
  "snapshot_at": "2026-07-21T00:00:00.000Z",
  "campaign_owned_home_banner_ids": [
    101
  ]
}''';
const promotionSurfacesActiveV2Sha256 =
    '26c0f18ebfaef3d8219af09857845955ca247d79fac0de28e644bde65871adf0';
const promotionSurfacesPaymentBadgeV2Json = r'''{
  "items": [
    {
      "campaign_id": "00000000-0000-4000-8000-000000000921",
      "campaign_version_id": "00000000-0000-4000-8000-000000000922",
      "code": "CANDY_BOOST_PAYMENT_V2",
      "display_name": {
        "ko": "결제 화면 부스트",
        "en": "Payment Badge Boost"
      },
      "multiplier_tenths": 20,
      "event_starts_at": "2026-07-19T15:00:00.000Z",
      "event_ends_at": "2026-07-21T15:00:00.000Z",
      "repeat_iso_dows": [
        1,
        2,
        3,
        4,
        5,
        6,
        7
      ],
      "home_creative": null
    }
  ],
  "total_count": "1",
  "next_cursor": null,
  "snapshot_at": "2026-07-21T00:00:00.000Z",
  "campaign_owned_home_banner_ids": []
}''';
const promotionSurfacesPaymentBadgeV2Sha256 =
    'fbb2dbccbd4cfe960f88278ca2780260391c5b1abdbd4edc5dfefb4a8c4404dc';
const purchaseResultsV1Json = r'''{
  "cases": [
    {
      "contract_version": "wallet.v1",
      "operation_id": "00000000-0000-4000-8000-000000000601",
      "replayed": false,
      "base_star_amount": "100",
      "base_bonus_amount": "20",
      "promotion": {
        "resolution_id": "00000000-0000-4000-8000-000000000611",
        "state": "PENDING_TIME",
        "campaign_version_id": "00000000-0000-4000-8000-000000000621",
        "promo_bonus_amount": "0",
        "domain_code": "PROMO_REVIEW_REQUIRED"
      },
      "wallet": {
        "contract_version": "wallet.v1",
        "star": "100",
        "bonus": "20",
        "cotton": "5",
        "cotton_expiring_amount": "5",
        "cotton_next_expires_at": "2026-07-28T00:00:00.000Z",
        "snapshot_at": "2026-07-21T00:00:00.000Z"
      }
    },
    {
      "contract_version": "wallet.v1",
      "operation_id": "00000000-0000-4000-8000-000000000602",
      "replayed": false,
      "base_star_amount": "100",
      "base_bonus_amount": "20",
      "promotion": {
        "resolution_id": "00000000-0000-4000-8000-000000000612",
        "state": "INELIGIBLE",
        "campaign_version_id": null,
        "promo_bonus_amount": "0",
        "domain_code": null
      },
      "wallet": {
        "contract_version": "wallet.v1",
        "star": "200",
        "bonus": "40",
        "cotton": "5",
        "cotton_expiring_amount": "5",
        "cotton_next_expires_at": "2026-07-28T00:00:00.000Z",
        "snapshot_at": "2026-07-21T00:00:00.000Z"
      }
    },
    {
      "contract_version": "wallet.v1",
      "operation_id": "00000000-0000-4000-8000-000000000603",
      "replayed": true,
      "base_star_amount": "100",
      "base_bonus_amount": "20",
      "promotion": {
        "resolution_id": "00000000-0000-4000-8000-000000000613",
        "state": "GRANTED",
        "campaign_version_id": "00000000-0000-4000-8000-000000000623",
        "promo_bonus_amount": "20",
        "domain_code": null
      },
      "wallet": {
        "contract_version": "wallet.v1",
        "star": "300",
        "bonus": "80",
        "cotton": "5",
        "cotton_expiring_amount": "5",
        "cotton_next_expires_at": "2026-07-28T00:00:00.000Z",
        "snapshot_at": "2026-07-21T00:00:00.000Z"
      }
    }
  ]
}''';
const purchaseResultsV1Sha256 =
    '7523a45148d014cbb04f828ed8649d522018ea866bfe97e670b56f8355d8e776';
const adminCsSummaryV1Json = r'''{
  "user_id": "00000000-0000-4000-8000-000000000701",
  "balances": {
    "STAR_CANDY": "100",
    "BONUS_STAR_CANDY": "20",
    "COTTON_CANDY": "5"
  },
  "open_debt": {
    "STAR_CANDY": "0",
    "BONUS_STAR_CANDY": "3"
  },
  "cotton_expiring_amount": "5",
  "cotton_next_expires_at": "2026-07-28T00:00:00.000Z",
  "invariant_status": "OK",
  "authoritative_totals": {
    "STAR_CANDY": "100",
    "BONUS_STAR_CANDY": "20",
    "COTTON_CANDY": "5"
  },
  "recent_operation": null,
  "snapshot_at": "2026-07-21T00:00:00.000Z"
}''';
const adminCsSummaryV1Sha256 =
    'b5f2681542c2f25e0daeaf943f30a540e2b0eef6a33ae460413bfb3df5dc3825';
const adminMoneyTimelineV1Json = r'''{
  "items": [
    {
      "id": "00000000-0000-4000-8000-000000000801",
      "kind": "mobile_purchase",
      "allocations": [
        {
          "component": "BASE_STAR",
          "currency": "STAR_CANDY",
          "gross_delta": "100",
          "wallet_delta": "90",
          "debt_delta": "10"
        }
      ],
      "provider_occurred_at": "2026-07-20T23:59:00.000Z",
      "campaign_version_id": "00000000-0000-4000-8000-000000000802",
      "audit_id": "00000000-0000-4000-8000-000000000803",
      "operation_id": "00000000-0000-4000-8000-000000000801",
      "created_at": "2026-07-21T00:00:00.000Z"
    }
  ],
  "total_count": "1",
  "next_cursor": null,
  "snapshot_at": "2026-07-21T00:00:00.000Z"
}''';
const adminMoneyTimelineV1Sha256 =
    '26635a3b5ad3ed88b072d83e90d3820eb867d7fed0c40f7ac2573c0c8fb0eacd';
const stableErrorV1Json = r'''{
  "ok": false,
  "domain_code": "WALLET_RELEASE_GATE_BLOCKED",
  "retryable": false,
  "operation_id": null,
  "audit_id": null,
  "payload": null,
  "support_ref": null
}''';
const stableErrorV1Sha256 =
    'fee43ed1220e9ef5a3c38030882fa2c5a88b6c2592d78345a860a15acae56953';
const walletContractFixtureJson = <String, String>{
  'wallet_summary_v1.json': walletSummaryV1Json,
  'currency_history_empty_v1.json': currencyHistoryEmptyV1Json,
  'currency_history_mixed_v1.json': currencyHistoryMixedV1Json,
  'vote_result_v3.json': voteResultV3Json,
  'ad_reward_pending_v1.json': adRewardPendingV1Json,
  'ad_reward_granted_v1.json': adRewardGrantedV1Json,
  'promotion_surfaces_empty_v1.json': promotionSurfacesEmptyV1Json,
  'promotion_surfaces_active_v1.json': promotionSurfacesActiveV1Json,
  'promotion_surfaces_empty_v2.json': promotionSurfacesEmptyV2Json,
  'promotion_surfaces_active_v2.json': promotionSurfacesActiveV2Json,
  'promotion_surfaces_payment_badge_v2.json':
      promotionSurfacesPaymentBadgeV2Json,
  'purchase_results_v1.json': purchaseResultsV1Json,
  'admin_cs_summary_v1.json': adminCsSummaryV1Json,
  'admin_money_timeline_v1.json': adminMoneyTimelineV1Json,
  'stable_error_v1.json': stableErrorV1Json,
};
const walletContractFixtureSha256 = <String, String>{
  'wallet_summary_v1.json': walletSummaryV1Sha256,
  'currency_history_empty_v1.json': currencyHistoryEmptyV1Sha256,
  'currency_history_mixed_v1.json': currencyHistoryMixedV1Sha256,
  'vote_result_v3.json': voteResultV3Sha256,
  'ad_reward_pending_v1.json': adRewardPendingV1Sha256,
  'ad_reward_granted_v1.json': adRewardGrantedV1Sha256,
  'promotion_surfaces_empty_v1.json': promotionSurfacesEmptyV1Sha256,
  'promotion_surfaces_active_v1.json': promotionSurfacesActiveV1Sha256,
  'promotion_surfaces_empty_v2.json': promotionSurfacesEmptyV2Sha256,
  'promotion_surfaces_active_v2.json': promotionSurfacesActiveV2Sha256,
  'promotion_surfaces_payment_badge_v2.json':
      promotionSurfacesPaymentBadgeV2Sha256,
  'purchase_results_v1.json': purchaseResultsV1Sha256,
  'admin_cs_summary_v1.json': adminCsSummaryV1Sha256,
  'admin_money_timeline_v1.json': adminMoneyTimelineV1Sha256,
  'stable_error_v1.json': stableErrorV1Sha256,
};
const walletContractFixtureSetSha256 =
    'f165de0a6277d7033d547ae71b8b7f58099e97a747fed4c68f0ef97181967831';
