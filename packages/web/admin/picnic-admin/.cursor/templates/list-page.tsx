'use client';

import React from 'react';
import { ResourceList } from './components/ResourceList';

export default function ListPage() {
  const tableName = '${dirname}';
  
  return <ResourceList resource={tableName} />;
}
