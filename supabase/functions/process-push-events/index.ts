// Deno Edge Function: notification_events → FCM (legacy API).
// Secret: FCM_LEGACY_SERVER_KEY (Firebase Console → Project settings → Cloud Messaging).
// Cron: har 1 min chaqiring: supabase functions invoke process-push-events --no-verify-jwt
// yoki Dashboard → Edge Functions → Schedules.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type EventRow = {
  id: string;
  type: string;
  target_user_id: string | null;
  order_id: string | null;
  payload: Record<string, unknown>;
};

function titleBodyForType(type: string, orderId: string | null): { title: string; body: string } {
  const o = orderId ? ` #${orderId.slice(0, 8)}` : "";
  const m: Record<string, { title: string; body: string }> = {
    auction_courier_joined: { title: "Auksion", body: `Kuryer auksionga qo'shildi${o}` },
    auction_outbid: { title: "Auksion", body: `Boshqa kuryer narxni tushirdi${o}` },
    auction_won: { title: "Auksion", body: `Siz yutdingiz${o}` },
    auction_lost: { title: "Auksion", body: `Auksion yakunlandi${o}` },
    winner_selected: { title: "Buyurtma", body: `G'olib aniqlandi${o}` },
    order_picked_up: { title: "Buyurtma", body: `Yuk olib ketildi${o}` },
    order_delivered: { title: "Buyurtma", body: `Yetkazildi${o}` },
    order_completed: { title: "Buyurtma", body: `Buyurtma yakunlandi${o}` },
    feedback_reminder: { title: "Baholash", body: `Buyurtmani baholang${o}` },
    complaint_created: { title: "Admin", body: `Yangi shikoyat${o}` },
    low_rating_alert: { title: "Admin", body: `Past baho${o}` },
    new_matching_order: { title: "Yangi buyurtma", body: `Mos buyurtma${o}` },
  };
  return m[type] ?? { title: "Kuryer", body: `${type}${o}` };
}

async function sendFcmLegacy(
  serverKey: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ ok: boolean; error?: string; messageId?: string }> {
  const res = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      Authorization: `key=${serverKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      to: token,
      notification: { title, body, sound: "default" },
      data,
      priority: "high",
    }),
  });
  const json = (await res.json()) as {
    success?: number;
    failure?: number;
    results?: { message_id?: string; error?: string }[];
  };
  if (!res.ok) {
    return { ok: false, error: JSON.stringify(json) };
  }
  const mid = json.results?.[0]?.message_id;
  const err = json.results?.[0]?.error;
  if (json.success === 1 && mid) return { ok: true, messageId: mid };
  return { ok: false, error: err ?? "unknown" };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const fcmKey = Deno.env.get("FCM_LEGACY_SERVER_KEY") ?? "";

  const supabase = createClient(supabaseUrl, serviceKey);

  if (!fcmKey) {
    console.warn("[push] FCM_LEGACY_SERVER_KEY missing — events will be marked skipped");
  }

  const { data: events, error: qErr } = await supabase
    .from("notification_events")
    .select("id,type,target_user_id,order_id,payload")
    .is("processed_at", null)
    .lte("scheduled_at", new Date().toISOString())
    .order("scheduled_at", { ascending: true })
    .limit(40);

  if (qErr) {
    return new Response(JSON.stringify({ ok: false, error: qErr.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const rows = (events ?? []) as EventRow[];
  const results: unknown[] = [];

  for (const ev of rows) {
    if (!ev.target_user_id) {
      await supabase
        .from("notification_events")
        .update({
          processed_at: new Date().toISOString(),
          last_error: "no_target_user",
        })
        .eq("id", ev.id);
      results.push({ id: ev.id, skipped: "no_target" });
      continue;
    }

    const { data: tokens } = await supabase
      .from("user_device_tokens")
      .select("token")
      .eq("user_id", ev.target_user_id)
      .eq("is_active", true);

    const tokenList = (tokens ?? []).map((t: { token: string }) => t.token).filter(Boolean);
    const { title, body } = titleBodyForType(ev.type, ev.order_id);
    const data: Record<string, string> = {
      type: ev.type,
      order_id: ev.order_id ?? "",
      ...(ev.payload as Record<string, string>),
    };
    for (const k of Object.keys(data)) {
      if (typeof data[k] !== "string") data[k] = String(data[k]);
    }

    if (tokenList.length === 0) {
      await supabase.from("push_notifications_log").insert({
        user_id: ev.target_user_id,
        order_id: ev.order_id,
        type: ev.type,
        title,
        body,
        payload: ev.payload,
        delivery_status: "no_token",
      });
      await supabase
        .from("notification_events")
        .update({ processed_at: new Date().toISOString(), last_error: null })
        .eq("id", ev.id);
      results.push({ id: ev.id, skipped: "no_token" });
      continue;
    }

    if (!fcmKey) {
      await supabase.from("push_notifications_log").insert({
        user_id: ev.target_user_id,
        order_id: ev.order_id,
        type: ev.type,
        title,
        body,
        payload: ev.payload,
        delivery_status: "skipped_no_fcm_key",
      });
      await supabase
        .from("notification_events")
        .update({
          processed_at: new Date().toISOString(),
          last_error: "no_fcm_key",
        })
        .eq("id", ev.id);
      results.push({ id: ev.id, skipped: "no_fcm_key" });
      continue;
    }

    let lastErr: string | null = null;
    let anyOk = false;
    for (const tok of tokenList) {
      const r = await sendFcmLegacy(fcmKey, tok, title, body, data);
      await supabase.from("push_notifications_log").insert({
        user_id: ev.target_user_id,
        order_id: ev.order_id,
        type: ev.type,
        title,
        body,
        payload: { ...ev.payload, fcm_message_id: r.messageId },
        delivery_status: r.ok ? "sent" : "failed",
        error_message: r.ok ? null : r.error,
      });
      if (r.ok) anyOk = true;
      else lastErr = r.error ?? "fail";
    }

    await supabase
      .from("notification_events")
      .update({
        processed_at: new Date().toISOString(),
        last_error: anyOk ? null : lastErr,
      })
      .eq("id", ev.id);

    results.push({ id: ev.id, ok: anyOk, error: lastErr });
  }

  return new Response(JSON.stringify({ ok: true, processed: results.length, results }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
