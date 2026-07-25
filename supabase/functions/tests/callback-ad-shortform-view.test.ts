import {
  assert,
  assertEquals,
  assertExists,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  createShortformViewHandler,
  signOpaqueClaim,
} from "../callback-ad-shortform-view/index.ts";

const USER_ID = "00000000-0000-4000-8000-000000000401";
const IMPRESSION_ID = "00000000-0000-4000-8000-000000000402";
const SECRET = "test-secret";

const REWARD = {
  reference: { type: "INTERNAL_IMPRESSION", id: IMPRESSION_ID },
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

interface DatabaseError {
  code?: string;
  message?: string;
}

interface RpcResult {
  data: unknown;
  error: DatabaseError | null;
}

interface HandlerOverrides {
  secret?: string;
  userId?: (req: Request) => Promise<string | null>;
  settle?: (args: Record<string, unknown>) => Promise<RpcResult>;
  status?: (impressionId: string) => Promise<RpcResult>;
}

/** An RPC stub that resolves with rows. */
function rows(data: unknown): Promise<RpcResult> {
  return Promise.resolve({ data, error: null });
}

/** An RPC stub that resolves with a database error. */
function rpcError(error: DatabaseError): Promise<RpcResult> {
  return Promise.resolve({ data: null, error });
}

function handlerWith(overrides: HandlerOverrides = {}) {
  return createShortformViewHandler({
    secret: overrides.secret ?? SECRET,
    userId: overrides.userId ?? (() => Promise.resolve(USER_ID)),
    settle: overrides.settle ?? (() => rows({ amount: 1 })),
    status: overrides.status ?? (() => rows(REWARD)),
  });
}

/**
 * A settle stub that records how often it was called, so tests can prove a
 * rejected request never reached the money-granting RPC.
 */
function countingSettle() {
  const calls: Array<Record<string, unknown>> = [];
  return {
    calls,
    settle: (args: Record<string, unknown>) => {
      calls.push(args);
      return rows({ amount: 1 });
    },
  };
}

function viewClaim(overrides: Record<string, unknown> = {}) {
  return {
    type: "view",
    user_id: USER_ID,
    imp_id: IMPRESSION_ID,
    jti: "issue-jti",
    exp: Math.floor(Date.now() / 1000) + 300,
    ...overrides,
  };
}

function post(token: unknown): Request {
  return new Request("http://local/view", {
    method: "POST",
    body: JSON.stringify({ token }),
  });
}

/** Captures console.error output so server-side logging can be asserted. */
async function withCapturedErrorLog<T>(
  run: () => Promise<T>,
): Promise<{ result: T; logs: string[] }> {
  const original = console.error;
  const logs: string[] = [];
  console.error = (...args: unknown[]) => {
    logs.push(
      args.map((a) => typeof a === "string" ? a : JSON.stringify(a)).join(" "),
    );
  };
  try {
    return { result: await run(), logs };
  } finally {
    console.error = original;
  }
}

function assertJsonEnvelope(response: Response) {
  assertEquals(
    response.headers.get("Content-Type"),
    "application/json",
    "every rejection must use the JSON {domain_code} envelope the client parses",
  );
}

// ---------------------------------------------------------------------------
// Happy path
// ---------------------------------------------------------------------------

Deno.test("shortform view returns the wallet-aware app response contract", async () => {
  const token = await signOpaqueClaim(viewClaim(), SECRET);
  const response = await handlerWith()(post(token));
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body.ok, true);
  assertEquals(body.reward_added, 1);
  assertEquals(body.new_bonus, null);
  assertEquals(body.impression_id, IMPRESSION_ID);
  assertExists(body.reward);
  assertEquals(body.reward.wallet.cotton, "1");
});

Deno.test("settlement rows returned as an array still yield the granted amount", async () => {
  const token = await signOpaqueClaim(viewClaim(), SECRET);
  const response = await handlerWith({
    settle: () => rows([{ amount: 3 }]),
    status: () => rows([REWARD]),
  })(post(token));
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body.reward_added, 3);
  assertEquals(body.reward.state, "GRANTED");
});

// ---------------------------------------------------------------------------
// Transport / envelope rejections
// ---------------------------------------------------------------------------

Deno.test("non-POST method is rejected with METHOD_NOT_ALLOWED", async () => {
  for (const method of ["GET", "PUT", "DELETE", "PATCH"]) {
    const response = await handlerWith()(
      new Request("http://local/view", { method }),
    );
    assertJsonEnvelope(response);
    assertEquals(response.status, 405, `${method} must not be accepted`);
    assertEquals((await response.json()).domain_code, "METHOD_NOT_ALLOWED");
  }
});

Deno.test("unauthenticated caller is rejected with UNAUTHORIZED", async () => {
  const token = await signOpaqueClaim(viewClaim(), SECRET);
  const response = await handlerWith({
    userId: () => Promise.resolve(null),
  })(post(token));

  assertJsonEnvelope(response);
  assertEquals(response.status, 401);
  assertEquals((await response.json()).domain_code, "UNAUTHORIZED");
});

Deno.test("malformed request body is rejected with INVALID_TOKEN", async () => {
  const response = await handlerWith()(
    new Request("http://local/view", { method: "POST", body: "{not json" }),
  );

  assertJsonEnvelope(response);
  assertEquals(response.status, 400);
  assertEquals((await response.json()).domain_code, "INVALID_TOKEN");
});

Deno.test("missing or non-string token is rejected with INVALID_TOKEN", async () => {
  for (const token of [undefined, null, 42, { nested: true }, ""]) {
    const response = await handlerWith()(post(token));
    assertEquals(response.status, 400);
    assertEquals((await response.json()).domain_code, "INVALID_TOKEN");
  }
});

// ---------------------------------------------------------------------------
// Signature forgery
// ---------------------------------------------------------------------------

Deno.test("forged signature is rejected and never reaches settlement", async () => {
  const token = await signOpaqueClaim(viewClaim(), SECRET);
  const [payload, signature] = token.split(".");
  // Mutate the first character: it carries six significant bits, so the
  // decoded signature always changes. The trailing character of a 43-char
  // base64url signature carries only two, so flipping it can decode to the
  // same 32 bytes.
  const forgedSignature = (signature[0] === "A" ? "B" : "A") +
    signature.slice(1);
  const settle = countingSettle();

  const response = await handlerWith({ settle: settle.settle })(
    post(`${payload}.${forgedSignature}`),
  );

  assertEquals(response.status, 400);
  assertEquals((await response.json()).domain_code, "INVALID_TOKEN");
  assertEquals(settle.calls.length, 0, "a forged token must never settle");
});

Deno.test("tampered payload with a stale signature is rejected", async () => {
  const token = await signOpaqueClaim(viewClaim(), SECRET);
  const [, signature] = token.split(".");
  const forged = await signOpaqueClaim(
    viewClaim({ imp_id: "00000000-0000-4000-8000-0000000004ff" }),
    "attacker-secret",
  );
  const settle = countingSettle();

  const response = await handlerWith({ settle: settle.settle })(
    post(`${forged.split(".")[0]}.${signature}`),
  );

  assertEquals(response.status, 400);
  assertEquals((await response.json()).domain_code, "INVALID_TOKEN");
  assertEquals(settle.calls.length, 0);
});

Deno.test("token signed with the wrong secret is rejected", async () => {
  const token = await signOpaqueClaim(viewClaim(), "attacker-secret");
  const settle = countingSettle();

  const response = await handlerWith({ settle: settle.settle })(post(token));

  assertEquals(response.status, 400);
  assertEquals((await response.json()).domain_code, "INVALID_TOKEN");
  assertEquals(settle.calls.length, 0);
});

Deno.test("structurally invalid tokens are rejected", async () => {
  const valid = await signOpaqueClaim(viewClaim(), SECRET);
  const [payload, signature] = valid.split(".");
  const candidates = [
    payload,
    `${payload}.`,
    `.${signature}`,
    `${payload}.${signature}.extra`,
    "....",
    "not-a-token",
  ];

  for (const token of candidates) {
    const response = await handlerWith()(post(token));
    assertEquals(response.status, 400, `token "${token}" must be rejected`);
    assertEquals((await response.json()).domain_code, "INVALID_TOKEN");
  }
});

Deno.test("a missing signing secret rejects every token", async () => {
  // A misconfigured deployment (AD_SHORTFORM_SECRET unset) must reject every
  // token rather than accept them.
  const token = await signOpaqueClaim(viewClaim(), SECRET);
  const settle = countingSettle();

  const response = await handlerWith({ secret: "", settle: settle.settle })(
    post(token),
  );

  assertEquals(response.status, 400);
  assertEquals((await response.json()).domain_code, "INVALID_TOKEN");
  assertEquals(settle.calls.length, 0);
});

// ---------------------------------------------------------------------------
// Claim content rejections
// ---------------------------------------------------------------------------

Deno.test("claim type other than view is rejected with SHORTFORM_ACTION_MISMATCH", async () => {
  for (const type of ["more", "click", "", null]) {
    const token = await signOpaqueClaim(viewClaim({ type }), SECRET);
    const settle = countingSettle();
    const response = await handlerWith({ settle: settle.settle })(post(token));

    assertEquals(response.status, 400);
    assertEquals(
      (await response.json()).domain_code,
      "SHORTFORM_ACTION_MISMATCH",
    );
    assertEquals(settle.calls.length, 0);
  }
});

Deno.test("claim issued to another user is rejected with 403", async () => {
  const token = await signOpaqueClaim(
    viewClaim({ user_id: "00000000-0000-4000-8000-0000000004aa" }),
    SECRET,
  );
  const settle = countingSettle();

  const response = await handlerWith({ settle: settle.settle })(post(token));

  assertEquals(response.status, 403);
  assertEquals((await response.json()).domain_code, "SHORTFORM_USER_MISMATCH");
  assertEquals(settle.calls.length, 0, "another user's claim must not settle");
});

Deno.test("expired claim is rejected with SHORTFORM_EXPIRED", async () => {
  const token = await signOpaqueClaim(
    viewClaim({ exp: Math.floor(Date.now() / 1000) - 1 }),
    SECRET,
  );
  const settle = countingSettle();

  const response = await handlerWith({ settle: settle.settle })(post(token));

  assertEquals(response.status, 400);
  assertEquals((await response.json()).domain_code, "SHORTFORM_EXPIRED");
  assertEquals(settle.calls.length, 0, "an expired claim must never settle");
});

Deno.test("claim missing required fields is rejected with INVALID_TOKEN", async () => {
  const malformed = [
    viewClaim({ imp_id: undefined }),
    viewClaim({ imp_id: 12 }),
    viewClaim({ jti: undefined }),
    viewClaim({ jti: { nested: true } }),
    viewClaim({ exp: undefined }),
    viewClaim({ exp: "2026-07-25T00:00:00Z" }),
  ];

  for (const claim of malformed) {
    const token = await signOpaqueClaim(claim, SECRET);
    const response = await handlerWith()(post(token));
    assertEquals(response.status, 400);
    assertEquals((await response.json()).domain_code, "INVALID_TOKEN");
  }
});

// ---------------------------------------------------------------------------
// Database error mapping (domainStatus)
// ---------------------------------------------------------------------------

Deno.test("settlement domain errors map to stable codes and statuses", async () => {
  const cases: Array<
    { error: DatabaseError; status: number; domain_code: string }
  > = [
    {
      error: { code: "P0001", message: "IDEMPOTENCY_CONFLICT" },
      status: 409,
      domain_code: "IDEMPOTENCY_CONFLICT",
    },
    {
      error: {
        code: "P0001",
        message: "IDEMPOTENCY_CONFLICT: jti already settled",
      },
      status: 409,
      domain_code: "IDEMPOTENCY_CONFLICT",
    },
    {
      error: { code: "P0002", message: "UNKNOWN_CLAIM" },
      status: 404,
      domain_code: "UNKNOWN_CLAIM",
    },
    {
      error: { code: "P0002", message: "NOT_FOUND" },
      status: 404,
      domain_code: "NOT_FOUND",
    },
    {
      error: { code: "P0001", message: "SHORTFORM_EXPIRED" },
      status: 400,
      domain_code: "SHORTFORM_EXPIRED",
    },
    {
      error: { code: "P0001", message: "EXPIRED" },
      status: 400,
      domain_code: "EXPIRED",
    },
    {
      error: { code: "P0001", message: "DENIED" },
      status: 400,
      domain_code: "DENIED",
    },
    {
      error: { code: "P0001", message: "MISMATCH" },
      status: 400,
      domain_code: "MISMATCH",
    },
    {
      error: { code: "P0001", message: "INVALID" },
      status: 400,
      domain_code: "INVALID",
    },
  ];

  for (const testCase of cases) {
    const token = await signOpaqueClaim(viewClaim(), SECRET);
    const { result: response } = await withCapturedErrorLog(() =>
      handlerWith({ settle: () => rpcError(testCase.error) })(post(token))
    );
    const body = await response.json();

    assertJsonEnvelope(response);
    assertEquals(
      response.status,
      testCase.status,
      `${testCase.error.message} must map to ${testCase.status}`,
    );
    assertEquals(body.domain_code, testCase.domain_code);
    assertFalse("ok" in body, "a rejection must not look like a grant");
  }
});

Deno.test("connection and timeout SQLSTATEs map to 503 without leaking detail", async () => {
  const cases: DatabaseError[] = [
    {
      code: "08006",
      message: "connection failure to db-primary.internal:5432",
    },
    { code: "08003", message: "connection does not exist" },
    { code: "57014", message: "canceling statement due to statement timeout" },
  ];

  for (const error of cases) {
    const token = await signOpaqueClaim(viewClaim(), SECRET);
    const { result: response } = await withCapturedErrorLog(() =>
      handlerWith({ settle: () => rpcError(error) })(post(token))
    );
    const raw = await response.text();

    assertEquals(response.status, 503, `${error.code} must map to 503`);
    assertEquals(JSON.parse(raw).domain_code, "SHORTFORM_SETTLEMENT_FAILED");
    assertFalse(
      raw.includes(error.message ?? ""),
      "internal detail must not reach the caller",
    );
  }
});

// ---------------------------------------------------------------------------
// Defect 1 - internal detail must never reach the caller
// ---------------------------------------------------------------------------

Deno.test("unexpected settlement failures return a generic code and leak nothing", async () => {
  const leaky: DatabaseError[] = [
    {
      code: "42501",
      message: "permission denied for function settle_shortform_view_reward",
    },
    {
      code: "23502",
      message:
        'null value in column "impression_id" of relation "ad_reward_grants" violates not-null constraint',
    },
    {
      code: "42883",
      message:
        "function private_wallet.settle_shortform_view_reward(uuid, uuid) does not exist",
    },
    {
      code: "23505",
      message:
        'duplicate key value violates unique constraint "ad_reward_grants_pkey"',
    },
    { code: "PGRST202", message: "Could not find the function in the schema" },
  ];

  for (const error of leaky) {
    const token = await signOpaqueClaim(viewClaim(), SECRET);
    const { result: response, logs } = await withCapturedErrorLog(() =>
      handlerWith({ settle: () => rpcError(error) })(post(token))
    );
    const raw = await response.text();
    const body = JSON.parse(raw);

    assertEquals(response.status, 500);
    assertEquals(body.domain_code, "SHORTFORM_SETTLEMENT_FAILED");
    assertEquals(
      Object.keys(body),
      ["domain_code"],
      "the error envelope must carry nothing but domain_code",
    );
    assertFalse(
      raw.includes(error.message ?? ""),
      `raw database message leaked: ${raw}`,
    );
    for (
      const fragment of [
        "permission denied",
        "settle_shortform_view_reward",
        "not-null constraint",
        "relation",
        "unique constraint",
        "private_wallet",
        "schema",
      ]
    ) {
      assertFalse(
        raw.toLowerCase().includes(fragment.toLowerCase()),
        `response leaked "${fragment}": ${raw}`,
      );
    }
    assert(
      logs.some((line) => line.includes(error.message ?? "")),
      "the detail must still be logged server-side",
    );
  }
});

Deno.test("unexpected status-read failures leak nothing to the caller", async () => {
  const error: DatabaseError = {
    code: "42501",
    message: "permission denied for function get_ad_reward_status",
  };
  const token = await signOpaqueClaim(viewClaim(), SECRET);
  const { result: response, logs } = await withCapturedErrorLog(() =>
    handlerWith({ status: () => rpcError(error) })(post(token))
  );
  const raw = await response.text();

  assertFalse(
    raw.includes(error.message ?? ""),
    `raw database message leaked: ${raw}`,
  );
  assertFalse(raw.toLowerCase().includes("permission denied"));
  assertFalse(raw.includes("get_ad_reward_status"));
  assert(
    logs.some((line) => line.includes(error.message ?? "")),
    "the detail must still be logged server-side",
  );
});

// ---------------------------------------------------------------------------
// Replay
// ---------------------------------------------------------------------------

Deno.test("replaying the same token maps the settle conflict to 409, not a fresh grant", async () => {
  // This function holds no replay guard of its own: duplicate settlement is
  // delegated entirely to settle_shortform_view_reward. What is asserted here
  // is the contract the function *is* responsible for - the same token is
  // forwarded with identical idempotency inputs, and a conflicting settle
  // result surfaces as 409 with a stable domain code instead of a second grant.
  const token = await signOpaqueClaim(viewClaim(), SECRET);
  const settleArgs: Array<Record<string, unknown>> = [];
  const handler = handlerWith({
    settle: (args) => {
      settleArgs.push(args);
      return settleArgs.length === 1 ? rows({ amount: 1 }) : rpcError({
        code: "P0001",
        message: "IDEMPOTENCY_CONFLICT: issue_jti already settled",
      });
    },
  });

  const first = await handler(post(token));
  const firstBody = await first.json();
  const { result: second } = await withCapturedErrorLog(() =>
    handler(post(token))
  );
  const secondBody = await second.json();

  assertEquals(first.status, 200);
  assertEquals(firstBody.ok, true);
  assertEquals(firstBody.reward_added, 1);

  assertEquals(second.status, 409);
  assertEquals(secondBody.domain_code, "IDEMPOTENCY_CONFLICT");
  assertFalse("ok" in secondBody, "a replay must not present as a grant");
  assertFalse("reward_added" in secondBody);
  assertFalse("reward" in secondBody);

  // Both attempts must reach the database with identical idempotency inputs,
  // otherwise the database-side guard cannot recognise the replay.
  assertEquals(settleArgs.length, 2);
  assertEquals(settleArgs[0], settleArgs[1]);
  assertEquals(settleArgs[0].p_issue_jti, "issue-jti");
  assertEquals(settleArgs[0].p_impression_id, IMPRESSION_ID);
  assertEquals(settleArgs[0].p_user_id, USER_ID);
  assertExists(settleArgs[0].p_payload_hash);
});

// ---------------------------------------------------------------------------
// Defect 3 - auth transport failure
// ---------------------------------------------------------------------------

Deno.test("auth transport failure returns a JSON domain envelope, not a bare 500", async () => {
  const failures = [
    new TypeError(
      "error sending request for url (https://project.supabase.co/auth/v1/user)",
    ),
    new Error("connection closed before message completed"),
    new DOMException("The signal has been aborted", "AbortError"),
  ];

  for (const failure of failures) {
    const token = await signOpaqueClaim(viewClaim(), SECRET);
    const settle = countingSettle();
    const { result: response, logs } = await withCapturedErrorLog(() =>
      handlerWith({
        userId: () => Promise.reject(failure),
        settle: settle.settle,
      })(post(token))
    );
    const raw = await response.text();
    const body = JSON.parse(raw);

    assertJsonEnvelope(response);
    assertEquals(response.status, 503);
    assertEquals(body.domain_code, "AUTH_UNAVAILABLE");
    assertEquals(Object.keys(body), ["domain_code"]);
    assertFalse(raw.includes("supabase.co"), `transport detail leaked: ${raw}`);
    assertEquals(settle.calls.length, 0, "a failed auth check must not settle");
    assert(logs.length > 0, "the transport failure must be logged");
  }
});

Deno.test("an unexpected throw anywhere in the handler still returns a JSON envelope", async () => {
  const token = await signOpaqueClaim(viewClaim(), SECRET);
  const { result: response } = await withCapturedErrorLog(() =>
    handlerWith({
      settle: () =>
        Promise.reject(new TypeError("error sending request for url (rpc)")),
    })(post(token))
  );
  const raw = await response.text();

  assertJsonEnvelope(response);
  assertEquals(response.status, 500);
  assertEquals(JSON.parse(raw).domain_code, "SHORTFORM_INTERNAL_ERROR");
  assertFalse(raw.includes("error sending request"));
});

// ---------------------------------------------------------------------------
// Post-settlement status read
// ---------------------------------------------------------------------------

Deno.test("a status-read failure after a successful settle still reports the grant", async () => {
  const token = await signOpaqueClaim(viewClaim(), SECRET);
  const { result: response } = await withCapturedErrorLog(() =>
    handlerWith({
      status: () => rpcError({ code: "42501", message: "permission denied" }),
    })(post(token))
  );
  const body = await response.json();

  assertEquals(
    response.status,
    200,
    "the wallet was already credited; a read-back failure must not report failure",
  );
  assertEquals(body.ok, true);
  assertEquals(body.reward_added, 1);
  assertEquals(body.impression_id, IMPRESSION_ID);
  assertEquals(body.new_bonus, null);
  assertEquals(body.reward, null);
  assertEquals(
    Object.keys(body).sort(),
    ["impression_id", "new_bonus", "ok", "reward", "reward_added"],
    "the response must keep the exact key set the client parser accepts",
  );
});

Deno.test("a status read that throws after a successful settle still reports the grant", async () => {
  const token = await signOpaqueClaim(viewClaim(), SECRET);
  const { result: response } = await withCapturedErrorLog(() =>
    handlerWith({
      status: () => Promise.reject(new TypeError("error sending request")),
    })(post(token))
  );
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body.ok, true);
  assertEquals(body.reward_added, 1);
  assertEquals(body.reward, null);
});
