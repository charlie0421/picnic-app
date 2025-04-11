'use client';

import React from 'react';
import { ResourceDetail } from '../components/ResourceDetail';

export default function ShowPage({ params }: { params: { id: string } }) {
  const tableName = '${dirname}';
  
  return <ResourceDetail resource={tableName} id={params.id} />;
}
