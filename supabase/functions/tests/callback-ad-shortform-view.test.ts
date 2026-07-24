import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  createShortformViewHandler,
  signOpaqueClaim,
} from "../callback-ad-shortform-view/index.ts";

Deno.test("shortform view returns the wallet-aware app response contract", async () => {
  const impressionId = "00000000-0000-4000-8000-000000000402";
  const secret = "test-secret";
  const token = await signOpaqueClaim({
    type: "view",
    user_id: "00000000-0000-4000-8000-000000000401",
    imp_id: impressionId,
    jti: "issue-jti",
    exp: Math.floor(Date.now() / 1000) + 300,
  }, secret);
  const reward = {
    reference: { type: "INTERNAL_IMPRESSION", id: impressionId },
    state: "GRANTED",
    grant: {
      id: "1",
      currency: "COTTON_CANDY",
      amount: "1",
      granted_at: "2026-07-24T04:59:06.821Z",
      expires_at: "2026-07-31T04:59:06.821Z",
    },
    wallet: {
      contract_version: "wallet.v1",
      star: "1300",
      bonus: "52",
      cotton: "1",
      cotton_expiring_amount: "1",
      cotton_next_expires_at: "2026-07-31T04:59:06.821Z",
      snapshot_at: "2026-07-24T04:59:06.821Z",
    },
    snapshot_at: "2026-07-24T04:59:06.821Z",
  };
  const handler = createShortformViewHandler({
    secret,
    userId: async () => "00000000-0000-4000-8000-000000000401",
    settle: async () => ({
      data: { amount: 1 },
      error: null,
    }),
    status: async () => ({ data: reward, error: null }),
  });

  const response = await handler(
    new Request("http://local/view", {
      method: "POST",
      body: JSON.stringify({ token }),
    }),
  );
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body.ok, true);
  assertEquals(body.reward_added, 1);
  assertEquals(body.new_bonus, null);
  assertEquals(body.impression_id, impressionId);
  assertExists(body.reward);
  assertEquals(body.reward.wallet.cotton, "1");
});
