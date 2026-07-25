import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface DatabaseError {
  code?: string;
  message?: string;
}

interface RpcResult {
  data: unknown;
  error: DatabaseError | null;
}

interface Deps {
  secret: string;
  userId(req: Request): Promise<string | null>;
  settle(args: Record<string, unknown>): Promise<RpcResult>;
  status(impressionId: string): Promise<RpcResult>;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function domainError(domain_code: string, status: number): Response {
  return json({ domain_code }, status);
}

function domainStatus(error: DatabaseError): number {
  const message = error.message ?? "";
  if (/IDEMPOTENCY_CONFLICT/.test(message)) return 409;
  if (/NOT_FOUND|UNKNOWN_CLAIM/.test(message)) return 404;
  if (/EXPIRED|DENIED|MISMATCH|INVALID/.test(message)) return 400;
  if (error.code?.startsWith("08") || error.code === "57014") return 503;
  return 500;
}

/**
 * Stable, client-facing domain codes a database error may legitimately carry.
 * Ordered most specific first so `SHORTFORM_EXPIRED` wins over `EXPIRED` and
 * `SHORTFORM_USER_MISMATCH` over `MISMATCH`.
 */
const DATABASE_DOMAIN_CODES = [
  "IDEMPOTENCY_CONFLICT",
  "SHORTFORM_ACTION_MISMATCH",
  "SHORTFORM_USER_MISMATCH",
  "SHORTFORM_EXPIRED",
  "UNKNOWN_CLAIM",
  "INVALID_TOKEN",
  "NOT_FOUND",
  "EXPIRED",
  "DENIED",
  "MISMATCH",
  "INVALID",
] as const;

/**
 * Resolves a database error to a fixed token from `DATABASE_DOMAIN_CODES`, or
 * to `fallback` when the message carries no recognised domain signal.
 *
 * The raw message is never returned: unexpected Postgres/PostgREST failures
 * would otherwise hand any authenticated caller internal detail (function and
 * schema names, constraint text) and break `domain_code`, which the app treats
 * as a fixed token.
 */
function domainCodeFrom(error: DatabaseError, fallback: string): string {
  const message = error.message ?? "";
  return DATABASE_DOMAIN_CODES.find((code) => message.includes(code)) ??
    fallback;
}

/** Records the detail that must stay server-side. */
function logFailure(scope: string, error: DatabaseError): void {
  console.error(
    `[callback-ad-shortform-view] ${scope} failed`,
    `code=${error.code ?? "unknown"}`,
    `message=${error.message ?? ""}`,
  );
}

function logThrown(scope: string, cause: unknown): void {
  console.error(
    `[callback-ad-shortform-view] ${scope} threw`,
    cause instanceof Error ? `${cause.name}: ${cause.message}` : String(cause),
  );
}

function b64url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(
    /=+$/g,
    "",
  );
}

function decode(value: string): Uint8Array {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/").padEnd(
    Math.ceil(value.length / 4) * 4,
    "=",
  );
  return Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
}

async function sha256Hex(value: string): Promise<string> {
  return Array.from(
    new Uint8Array(
      await crypto.subtle.digest(
        "SHA-256",
        new TextEncoder().encode(value),
      ),
    ),
  ).map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

export async function signOpaqueClaim(
  payload: Record<string, unknown>,
  secret: string,
): Promise<string> {
  const encoded = b64url(new TextEncoder().encode(JSON.stringify(payload)));
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "HMAC",
      key,
      new TextEncoder().encode(encoded),
    ),
  );
  return `${encoded}.${b64url(signature)}`;
}

async function verifyOpaqueClaim(
  token: string,
  secret: string,
): Promise<Record<string, unknown> | null> {
  const [payload, signature, extra] = token.split(".");
  if (!payload || !signature || extra || !secret) return null;
  try {
    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["verify"],
    );
    if (
      !await crypto.subtle.verify(
        "HMAC",
        key,
        decode(signature).buffer as ArrayBuffer,
        new TextEncoder().encode(payload),
      )
    ) return null;
    const parsed = JSON.parse(new TextDecoder().decode(decode(payload)));
    return parsed && typeof parsed === "object" && !Array.isArray(parsed)
      ? parsed
      : null;
  } catch {
    return null;
  }
}

function first<T>(value: T | T[]): T {
  return Array.isArray(value) ? value[0] : value;
}

export function createShortformViewHandler(deps: Deps) {
  const handle = async (req: Request): Promise<Response> => {
    if (req.method !== "POST") return domainError("METHOD_NOT_ALLOWED", 405);

    // A transport failure inside auth.getUser() is an upstream outage, not a
    // rejected caller: without this guard it escapes the handler and Deno.serve
    // answers with a plain-text 500 the client's {domain_code} parser cannot read.
    let userId: string | null;
    try {
      userId = await deps.userId(req);
    } catch (cause) {
      logThrown("auth", cause);
      return domainError("AUTH_UNAVAILABLE", 503);
    }
    if (!userId) return domainError("UNAUTHORIZED", 401);

    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return domainError("INVALID_TOKEN", 400);
    }
    const token = typeof body.token === "string" ? body.token : "";
    const claim = await verifyOpaqueClaim(token, deps.secret);
    if (!claim) return domainError("INVALID_TOKEN", 400);
    if (claim.type !== "view") {
      return domainError("SHORTFORM_ACTION_MISMATCH", 400);
    }
    if (claim.user_id !== userId) {
      return domainError("SHORTFORM_USER_MISMATCH", 403);
    }
    if (
      typeof claim.imp_id !== "string" ||
      typeof claim.jti !== "string" ||
      typeof claim.exp !== "number"
    ) return domainError("INVALID_TOKEN", 400);
    if (claim.exp < Math.floor(Date.now() / 1000)) {
      return domainError("SHORTFORM_EXPIRED", 400);
    }

    const settlement = await deps.settle({
      p_impression_id: claim.imp_id,
      p_user_id: userId,
      p_issue_jti: claim.jti,
      p_token_expires_at: new Date(claim.exp * 1000).toISOString(),
      p_payload_hash: await sha256Hex(token),
    });
    if (settlement.error) {
      logFailure("settle", settlement.error);
      return domainError(
        domainCodeFrom(settlement.error, "SHORTFORM_SETTLEMENT_FAILED"),
        domainStatus(settlement.error),
      );
    }

    // Past this point the wallet is already credited by the service-role settle.
    // The status read is a receipt look-up through the user-scoped client, so a
    // failure here must degrade to a receipt-less success: answering 4xx/5xx
    // would report an already-granted reward as a failed one.
    let reward: unknown = null;
    try {
      const status = await deps.status(claim.imp_id);
      if (status.error) {
        logFailure("status", status.error);
      } else {
        reward = first(
          status.data as
            | Record<string, unknown>
            | Record<string, unknown>[],
        );
      }
    } catch (cause) {
      logThrown("status", cause);
    }

    const settled = first(
      settlement.data as
        | Record<string, unknown>
        | Record<string, unknown>[],
    );
    return json({
      ok: true,
      reward_added: Number(settled?.amount ?? 0),
      impression_id: claim.imp_id,
      new_bonus: null,
      reward: reward ?? null,
    });
  };

  // Nothing may escape as a plain-text 500: the client only parses
  // {domain_code} JSON.
  return async (req: Request): Promise<Response> => {
    try {
      return await handle(req);
    } catch (cause) {
      logThrown("handler", cause);
      return domainError("SHORTFORM_INTERNAL_ERROR", 500);
    }
  };
}

if (import.meta.main) {
  Deno.serve((req) => {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const authHeader = req.headers.get("Authorization") ?? "";
    const anonClient = createClient(
      url,
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    const admin = createClient(
      url,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );
    return createShortformViewHandler({
      secret: Deno.env.get("AD_SHORTFORM_SECRET") ?? "",
      userId: async () =>
        (await anonClient.auth.getUser()).data.user?.id ?? null,
      settle: async (args) =>
        await admin.rpc("settle_shortform_view_reward", args),
      status: async (impressionId) =>
        await anonClient.rpc("get_ad_reward_status", {
          p_reference_type: "INTERNAL_IMPRESSION",
          p_reference_id: impressionId,
        }),
    })(req);
  });
}
