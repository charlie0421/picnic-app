import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { PincruxService } from "../callback-pincrux/shared/services/ad/platforms/pincrux-service.ts";
import { getPincruxRewardExpiry } from "../callback-pincrux/shared/services/ad/utils/date.ts";

Deno.test("Pincrux reward expiry is stable across retries on opposite sides of the monthly cutoff", () => {
  const beforeCutoffRetry = getPincruxRewardExpiry(
    "20260814transaction",
    new Date("2026-08-14T00:00:00Z"),
  );
  const afterCutoffRetry = getPincruxRewardExpiry(
    "20260814transaction",
    new Date("2026-08-21T00:00:00Z"),
  );

  assertEquals(beforeCutoffRetry, "2026-09-15 00:00:00");
  assertEquals(afterCutoffRetry, beforeCutoffRetry);
});

Deno.test("Pincrux credits bonus through the wallet bridge before recording the provider transaction", async () => {
  const calls: Array<
    { kind: string; name?: string; args?: unknown; row?: unknown }
  > = [];
  const supabase = {
    from(table: string) {
      if (table === "user_profiles") {
        return {
          select() {
            return {
              eq() {
                return {
                  single: () =>
                    Promise.resolve({
                      data: { star_candy_bonus: 10 },
                      error: null,
                    }),
                };
              },
            };
          },
        };
      }

      assertEquals(table, "transaction_pincrux");
      return {
        insert(row: unknown) {
          calls.push({ kind: "insert", row });
          return Promise.resolve({ error: null });
        },
      };
    },
    rpc(name: string, args: unknown) {
      calls.push({ kind: "rpc", name, args });
      return Promise.resolve({ data: null, error: null });
    },
  };

  const service = Object.create(PincruxService.prototype) as PincruxService & {
    supabase: typeof supabase;
  };
  service.supabase = supabase;

  await service.processTransaction({
    usrKey: "00000000-0000-4000-8000-000000000123",
    coin: "440",
    transid: "pincrux-transaction-123",
    appkey: "351764",
    pubkey: 911885,
    app_title: "offer",
    menu_category1: "4",
  });

  assertEquals(calls[0], {
    kind: "rpc",
    name: "wallet_credit_bonus",
    args: {
      p_user_id: "00000000-0000-4000-8000-000000000123",
      p_source_key: "pincrux_reward",
      p_operation_key: "pincrux:pincrux-transaction-123",
      p_bonus_amount: 440,
      p_bonus_expires_at: calls[0].args &&
        (calls[0].args as Record<string, unknown>).p_bonus_expires_at,
      p_reason: "AD",
      p_reference_type: "PINCRUX_TRANSACTION",
      p_reference_id: "pincrux-transaction-123",
      p_metadata: { writer: "callback-pincrux" },
    },
  });
  assertEquals(calls[1], {
    kind: "insert",
    row: {
      transaction_id: "pincrux-transaction-123",
      app_key: "351764",
      pub_key: 911885,
      app_title: "offer",
      menu_category1: "4",
      usr_key: "00000000-0000-4000-8000-000000000123",
    },
  });
});

Deno.test("all nine reported spreadsheet callbacks are processed without a real credit", async () => {
  const reportedRows = [
    ["20260821gotxtrhcmixieusbcasp090140659167", "351764", "440", "4"],
    ["20260820mrcumhcgggbcsrabtasp004519147100", "351404", "1440", "4"],
    ["20260816wzadyxhnuacshllflasp225433236255", "351426", "2", "3"],
    ["20260816xyvmdsyuhofxqsuauasp201943988974", "351426", "2", "3"],
    ["20260816gvuolrbosssgbiadxasp195307992027", "348961", "2", "3"],
    ["20260816egchjsfudrehyzhcbasp194637452410", "351426", "2", "3"],
    ["20260816oxrlotjrjulwmjmvyasp105604018477", "351426", "2", "3"],
    ["20260814uaxucalgasumsetnjasp125127258875", "351426", "2", "3"],
    ["20260814whewfehdvmctiwqhqasp073012791138", "351426", "2", "3"],
  ] as const;
  const calls: Array<
    { kind: "rpc" | "insert"; args: Record<string, unknown> }
  > = [];
  const fakeSupabase = {
    from(table: string) {
      if (table === "user_profiles") {
        return {
          select: () => ({
            eq: () => ({
              single: () =>
                Promise.resolve({
                  data: { star_candy_bonus: 0 },
                  error: null,
                }),
            }),
          }),
        };
      }
      assertEquals(table, "transaction_pincrux");
      return {
        insert: (args: Record<string, unknown>) => {
          calls.push({ kind: "insert", args });
          return Promise.resolve({ error: null });
        },
      };
    },
    rpc(name: string, args: Record<string, unknown>) {
      assertEquals(name, "wallet_credit_bonus");
      calls.push({ kind: "rpc", args });
      return Promise.resolve({ data: { replayed: false }, error: null });
    },
  };
  const service = Object.create(PincruxService.prototype) as PincruxService & {
    supabase: typeof fakeSupabase;
  };
  service.supabase = fakeSupabase;

  for (
    const [index, [transid, appkey, coin, menuCategory]] of reportedRows
      .entries()
  ) {
    await service.processTransaction({
      usrKey: `00000000-0000-4000-8000-${String(index + 1).padStart(12, "0")}`,
      coin,
      transid,
      appkey,
      pubkey: 911885,
      app_title: `anonymized-xlsx-row-${index + 2}`,
      menu_category1: menuCategory,
    });
  }

  assertEquals(calls.length, 18);
  for (
    const [index, [transid, appkey, coin, menuCategory]] of reportedRows
      .entries()
  ) {
    const credit = calls[index * 2];
    const providerRecord = calls[index * 2 + 1];
    assertEquals(credit.kind, "rpc");
    assertEquals(credit.args.p_operation_key, `pincrux:${transid}`);
    assertEquals(credit.args.p_bonus_amount, Number(coin));
    assertEquals(credit.args.p_source_key, "pincrux_reward");
    assertEquals(providerRecord.kind, "insert");
    assertEquals(providerRecord.args.transaction_id, transid);
    assertEquals(providerRecord.args.app_key, appkey);
    assertEquals(providerRecord.args.menu_category1, menuCategory);
  }
});
