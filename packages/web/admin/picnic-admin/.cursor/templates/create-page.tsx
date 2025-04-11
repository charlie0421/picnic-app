'use client';

import React from 'react';
import { ResourceCreate } from '../components/ResourceCreate';

export default function CreatePage() {
  const tableName = '${dirname}';
  
  return <ResourceCreate resource={tableName} />;
}
