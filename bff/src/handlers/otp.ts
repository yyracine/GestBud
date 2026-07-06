import type { Env } from '../index';
import { json } from '../index';

const E164_REGEX = /^\+[1-9]\d{6,14}$/;
const OTP_TTL_SECONDS = 600; // 10 minutes

export async function handleOtp(
  request: Request,
  env: Env,
  path: string,
): Promise<Response> {
  if (path === '/otp/send') {
    return handleSend(request, env);
  }
  if (path === '/otp/verify') {
    return handleVerify(request, env);
  }
  return json({ error: 'Unknown OTP route' }, 404);
}

async function handleSend(request: Request, env: Env): Promise<Response> {
  const body = await request.json<{ phone: string }>();

  if (!body?.phone) {
    return json({ error: 'phone is required' }, 400);
  }

  if (!E164_REGEX.test(body.phone)) {
    return json({ error: 'Invalid phone format. Expected E.164.' }, 400);
  }

  if (!env.AFRICA_TALKING_API_KEY || !env.AFRICA_TALKING_USERNAME) {
    console.error('[OTP] Africa\'s Talking credentials not configured');
    return json({ error: 'SMS service not configured' }, 503);
  }

  const otp = generateOtp();

  // Store OTP in KV with TTL — key: otp:{phone}
  await env.OTP_STORE.put(
    `otp:${body.phone}`,
    JSON.stringify({ otp, phone: body.phone, createdAt: Date.now() }),
    { expirationTtl: OTP_TTL_SECONDS },
  );

  // Send SMS via Africa's Talking API v1
  const formData = new URLSearchParams({
    username: env.AFRICA_TALKING_USERNAME,
    to: body.phone,
    message: `Ton code GestBud : ${otp}. Valable 10 minutes.`,
  });

  const atBaseUrl =
    env.AFRICA_TALKING_USERNAME === 'sandbox'
      ? 'https://api.sandbox.africastalking.com/version1/messaging'
      : 'https://api.africastalking.com/version1/messaging';

  const atResponse = await fetch(
    atBaseUrl,
    {
      method: 'POST',
      headers: {
        apiKey: env.AFRICA_TALKING_API_KEY,
        'Content-Type': 'application/x-www-form-urlencoded',
        Accept: 'application/json',
      },
      body: formData,
    },
  );

  if (!atResponse.ok) {
    const errorText = await atResponse.text();
    console.error('[OTP] Africa\'s Talking error:', errorText);
    return json({ error: 'SMS delivery failed' }, 502);
  }

  const atData = (await atResponse.json()) as {
    SMSMessageData?: { Recipients?: Array<{ statusCode: number }> };
  };
  const recipient = atData.SMSMessageData?.Recipients?.[0];

  // Africa's Talking statusCode 100 = Processed, 101 = Sent (both indicate acceptance)
  const AT_SUCCESS_CODES = [100, 101];
  if (recipient && !AT_SUCCESS_CODES.includes(recipient.statusCode)) {
    console.error('[OTP] Africa\'s Talking delivery failed, statusCode:', recipient.statusCode);
    return json({ error: 'SMS delivery failed' }, 502);
  }

  return json({ success: true });
}

async function handleVerify(request: Request, env: Env): Promise<Response> {
  const body = await request.json<{ phone: string; code: string }>();
  if (!body?.phone || !body?.code) {
    return json({ error: 'phone and code are required' }, 400);
  }

  if (!E164_REGEX.test(body.phone)) {
    return json({ error: 'Invalid phone format. Expected E.164.' }, 400);
  }

  const stored = await env.OTP_STORE.get(`otp:${body.phone}`);
  if (!stored) {
    return json({ error: 'Ce code a expiré. Demande-en un nouveau.' }, 400);
  }

  const data = JSON.parse(stored) as { otp: string; phone: string; createdAt: number };
  if (data.otp !== body.code) {
    return json({ error: 'Code invalide. Vérifie le SMS reçu.' }, 400);
  }

  // Supprimer le KV après usage pour éviter la réutilisation
  await env.OTP_STORE.delete(`otp:${body.phone}`);

  const token = crypto.randomUUID();
  return json({ token });
}

function generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}
