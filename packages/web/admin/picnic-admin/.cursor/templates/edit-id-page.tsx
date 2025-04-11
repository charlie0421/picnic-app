'use client';

import React from 'react';
import { ResourceEdit } from '../components/ResourceEdit';

export default function EditPage({ params }: { params: { id: string } }) {
  const tableName = '${dirname}';
  
  return <ResourceEdit resource={tableName} id={params.id} />;
}
