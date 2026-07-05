import type { Env } from '../index';
import { json } from '../index';
import { categorizeLines, type OcrLine } from './categorize';

interface MindeeLineItem {
  description?: string;
  total_amount?: number;
  quantity?: number;
  unit_price?: number;
}

interface MindeeJobResponse {
  job?: { id?: string; status?: string; error?: unknown };
  document?: {
    inference?: {
      prediction?: {
        line_items?: MindeeLineItem[];
      };
    };
  };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function extractLinesFromMindee(file: File, apiKey: string): Promise<OcrLine[]> {
  // Submit async job
  const submitForm = new FormData();
  submitForm.append('document', file);

  const submitRes = await fetch(
    'https://api.mindee.net/v1/products/mindee/expense_receipts/v5/predict_async',
    {
      method: 'POST',
      headers: { Authorization: `Token ${apiKey}` },
      body: submitForm,
    },
  );

  if (!submitRes.ok) return [];

  const submitData = await submitRes.json() as MindeeJobResponse;
  const jobId = submitData.job?.id;
  if (!jobId) return [];

  // Poll up to 5 × 2 s = 10 s
  for (let i = 0; i < 5; i++) {
    await sleep(2000);

    const pollRes = await fetch(
      `https://api.mindee.net/v1/products/mindee/expense_receipts/v5/documents/queue/${jobId}`,
      { headers: { Authorization: `Token ${apiKey}` } },
    );

    if (!pollRes.ok) continue;

    const pollData = await pollRes.json() as MindeeJobResponse;

    if (pollData.job?.status !== 'completed') continue;

    const lineItems = pollData.document?.inference?.prediction?.line_items ?? [];

    return lineItems
      .filter((item): item is MindeeLineItem & { description: string } =>
        typeof item.description === 'string' && item.description.trim().length > 0,
      )
      .map((item) => ({
        label: item.description.trim(),
        amount_cents: Math.round((item.total_amount ?? 0) * 100),
      }));
  }

  return [];
}

export async function handleScan(request: Request, env: Env): Promise<Response> {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  if (!env.MINDEE_API_KEY) {
    return json({ lines: [] });
  }

  let file: File | null = null;
  try {
    const formData = await request.formData();
    const entry = formData.get('file');
    if (entry instanceof File) file = entry;
  } catch {
    return json({ error: 'Invalid multipart body' }, 400);
  }

  if (!file) {
    return json({ error: 'No file provided' }, 400);
  }

  const ocrLines = await extractLinesFromMindee(file, env.MINDEE_API_KEY);
  const categorized = await categorizeLines(ocrLines, env);

  return json({ lines: categorized });
}
