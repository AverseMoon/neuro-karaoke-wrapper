import { join } from 'path';
import { app } from 'electron';

/**
 * Get asset path (works in both dev and production)
 * Uses packaged assets from inside the .asar
 */
export function getAssetPath(filename: string) {
  return join(app.getAppPath(), 'assets', filename);
}