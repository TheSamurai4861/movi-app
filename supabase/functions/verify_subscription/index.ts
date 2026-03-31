// Supabase Edge Function: verify_subscription
// Purpose: verify iOS/Android subscriptions server-side and upsert entitlements.
//
// NOTE: This is a scaffold. Store validation must be implemented before
// enabling production usage.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Platform = "ios" | "android";

type VerifySubscriptionRequest = {
  platform: Platform;
  productId: string;
  // Android: purchaseToken
  purchaseToken?: string;
  // iOS: receipt or transaction id depending on your chosen validation strategy
  receipt?: string;
  transactionId?: string;
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function base64Url(data: Uint8Array) {
  const b64 = btoa(String.fromCharCode(...data));
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

async function signRs256(pemPkcs8: string, message: string): Promise<string> {
  const pem = pemPkcs8
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const keyBytes = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(message),
  );

  return base64Url(new Uint8Array(sig));
}

async function googleAccessTokenFromServiceAccount(
  serviceAccountJson: string,
): Promise<string> {
  const sa = JSON.parse(serviceAccountJson);
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: "RS256", typ: "JWT", kid: sa.private_key_id };
  const claimSet = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 60 * 60,
  };

  const encodedHeader = base64Url(
    new TextEncoder().encode(JSON.stringify(header)),
  );
  const encodedClaims = base64Url(
    new TextEncoder().encode(JSON.stringify(claimSet)),
  );
  const signingInput = `${encodedHeader}.${encodedClaims}`;
  const signature = await signRs256(sa.private_key, signingInput);
  const assertion = `${signingInput}.${signature}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`google_oauth_failed:${res.status}:${text}`);
  }
  const json = await res.json();
  if (!json.access_token) throw new Error("google_oauth_missing_access_token");
  return json.access_token as string;
}

async function verifyAndroidSubscription(params: {
  packageName: string;
  subscriptionId: string;
  purchaseToken: string;
  serviceAccountJson: string;
}): Promise<{ isActive: boolean; expiresAtUtc: string | null }> {
  const accessToken = await googleAccessTokenFromServiceAccount(
    params.serviceAccountJson,
  );

  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(params.packageName)}` +
    `/purchases/subscriptions/${encodeURIComponent(params.subscriptionId)}` +
    `/tokens/${encodeURIComponent(params.purchaseToken)}`;

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`google_verify_failed:${res.status}:${text}`);
  }

  const json: any = await res.json();
  const expiryTimeMillis = json?.expiryTimeMillis
    ? Number(json.expiryTimeMillis)
    : null;
  const expiresAtUtc = expiryTimeMillis
    ? new Date(expiryTimeMillis).toISOString()
    : null;

  const now = Date.now();
  const isActive =
    expiryTimeMillis != null && Number.isFinite(expiryTimeMillis) &&
    expiryTimeMillis > now;

  return { isActive, expiresAtUtc };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    return jsonResponse({ error: "missing_auth" }, 401);
  }

  // Client for user authentication (extract user from JWT)
  const supabaseAuth = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });

  const { data: userData, error: userError } = await supabaseAuth.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse({ error: "invalid_auth" }, 401);
  }

  let payload: any;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse({ error: "invalid_json" }, 400);
  }

  const typed = payload as Partial<VerifySubscriptionRequest>;
  const platform = typed?.platform as Platform | undefined;
  const productId = (typed?.productId ?? "").toString();

  if (platform !== "ios" && platform !== "android") {
    return jsonResponse({ error: "invalid_platform" }, 400);
  }
  if (!productId) {
    return jsonResponse({ error: "missing_product_id" }, 400);
  }

  // Admin client for database upserts (never expose service role key to clients).
  const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: { persistSession: false },
  });

  try {
    let verifiedActive = false;
    let expiresAtUtc: string | null = null;

    if (platform === "android") {
      const purchaseToken = (typed?.purchaseToken ?? "").toString();
      if (!purchaseToken) {
        return jsonResponse({ error: "missing_purchase_token" }, 400);
      }

      const packageName = Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME") ?? "";
      const serviceAccountJson =
        Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON") ?? "";
      if (!packageName || !serviceAccountJson) {
        return jsonResponse(
          { error: "android_validation_not_configured" },
          500,
        );
      }

      const verified = await verifyAndroidSubscription({
        packageName,
        subscriptionId: productId,
        purchaseToken,
        serviceAccountJson,
      });

      verifiedActive = verified.isActive;
      expiresAtUtc = verified.expiresAtUtc;
    } else {
      // iOS validation requires App Store Server API integration.
      // We keep a clear error until configured.
      return jsonResponse({ error: "ios_validation_not_implemented" }, 501);
    }

    const status = verifiedActive ? "active" : "inactive";
    const entitlements = verifiedActive ? { all: true } : {};

    const upsertPayload = {
      user_id: userData.user.id,
      platform,
      product_id: productId,
      status,
      entitlements,
      active_plan_id: verifiedActive ? productId : null,
      expires_at: expiresAtUtc,
      last_verified_at: new Date().toISOString(),
    };

    const { error: upsertError } = await supabaseAdmin
      .from("subscription_entitlements")
      .upsert(upsertPayload, { onConflict: "user_id,platform" });

    if (upsertError) {
      return jsonResponse({ error: "db_upsert_failed" }, 500);
    }

    return jsonResponse({
      status,
      active_plan_id: upsertPayload.active_plan_id,
      expires_at: expiresAtUtc,
      entitlements,
    });
  } catch (e) {
    // Avoid leaking tokens/keys: return only coarse error.
    return jsonResponse({ error: "verification_failed" }, 500);
  }
});

