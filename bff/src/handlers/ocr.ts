import type { Env } from '../index';
import { json } from '../index';

export async function handleOcr(
  request: Request,
  _env: Env,
): Promise<Response> {
  // TODO Story 3.1: réception de l'image, appel Mindee v2 (POST soumission +
  // GET /jobs/<jobId> polling), puis délégation vers handleCategorize
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }
  return json({ lines: [] });
}
