'use server';

import jwt from 'jsonwebtoken';

interface MetabaseUrlOptions {
  dashboardId: number;
  params?: Record<string, string>;
}

export async function generateMetabaseUrl({ dashboardId, params = {} }: MetabaseUrlOptions) {
  const METABASE_SITE_URL = "https://bi.picnic.fan";
  const METABASE_SECRET_KEY = "446c495deeabba5c6d17297c25b812d4f2f69afebce5c633035e36a9b884fedf";
  
  const payload = {
    resource: { dashboard: dashboardId },
    params,
    exp: Math.round(Date.now() / 1000) + (10 * 60) // 10 minute expiration
  };

  const token = jwt.sign(payload, METABASE_SECRET_KEY);
  return METABASE_SITE_URL + "/embed/dashboard/" + token + "#theme=neutral&bordered=true&titled=true";
} 