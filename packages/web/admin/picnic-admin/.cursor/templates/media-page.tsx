import React from 'react';
import { Metadata } from 'next';
import { DataTable } from '@/components/ui/data-table';
import { columns } from './columns';

export const metadata: Metadata = {
  title: '미디어 관리',
  description: '미디어 관리 페이지',
};

interface Column {
  accessorKey: string;
  header: string;
  cell?: (props: any) => React.ReactNode;
}

interface DataTableProps {
  columns: Column[];
  data: any[];
  pageCount: number;
  page: number;
  limit: number;
  sort?: string;
  order?: string;
  search?: string;
}

interface MediaPageProps {
  searchParams: {
    page?: string;
    limit?: string;
    sort?: string;
    order?: string;
    search?: string;
  };
}

export default async function MediaPage({ searchParams }: MediaPageProps) {
  const page = Number(searchParams.page) || 1;
  const limit = Number(searchParams.limit) || 10;
  const sort = searchParams.sort;
  const order = searchParams.order;
  const search = searchParams.search;

  // TODO: API 호출로 데이터 가져오기
  const data = [];
  const total = 0;

  return (
    <div className='container mx-auto py-10'>
      <div className='flex items-center justify-between'>
        <h1 className='text-3xl font-bold'>미디어 관리</h1>
      </div>
      <div className='mt-8'>
        <DataTable
          columns={columns}
          data={data}
          pageCount={Math.ceil(total / limit)}
          page={page}
          limit={limit}
          sort={sort}
          order={order}
          search={search}
        />
      </div>
    </div>
  );
}
