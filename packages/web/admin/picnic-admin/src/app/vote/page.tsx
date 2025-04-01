'use client';

import {
  DateField,
  DeleteButton,
  EditButton,
  List,
  MarkdownField,
  ShowButton,
  useTable,
} from '@refinedev/antd';
import { type BaseRecord, useMany } from '@refinedev/core';
import { Space, Table } from 'antd';

export default function VoteList() {
  const { tableProps } = useTable({
    syncWithLocation: true,
    meta: {
      select: '*',
    },
    sorters: {
      initial: [
        {
          field: 'id',
          order: 'desc',
        },
      ],
    },
  });

  const { data: voteData, isLoading: voteIsLoading } = useMany({
    resource: 'vote',
    ids:
      tableProps?.dataSource?.map((item) => item?.vote?.id).filter(Boolean) ??
      [],
    queryOptions: {
      enabled: !!tableProps?.dataSource,
    },
  });

  return (
    <List>
      <Table {...tableProps} rowKey='id'>
        <Table.Column dataIndex='id' title={'ID'} />
        <Table.Column
          dataIndex='title'
          title={'제목 (한국어)'}
          render={(value: any) => {
            if (!value?.ko) return '-';
            return <pre>{value.ko}</pre>;
          }}
        />
        <Table.Column
          dataIndex='title'
          title={'제목 (영어)'}
          render={(value: any) => {
            if (!value?.en) return '-';
            return <pre>{value.en}</pre>;
          }}
        />
        <Table.Column
          dataIndex='title'
          title={'제목 (일본어)'}
          render={(value: any) => {
            if (!value?.ja) return '-';
            return <pre>{value.ja}</pre>;
          }}
        />
        <Table.Column
          dataIndex='title'
          title={'제목 (중국어)'}
          render={(value: any) => {
            if (!value?.zh) return '-';
            return <pre>{value.zh}</pre>;
          }}
        />
        <Table.Column dataIndex='vote_category' title={'투표 카테고리'} />
        <Table.Column
          dataIndex='vote_sub_category'
          title={'투표 서브 카테고리'}
        />
        <Table.Column
          dataIndex='start_at'
          title={'투표시작'}
          render={(value: any) => {
            if (!value) return '-';
            return value
              ? new Date(value)
                  .toLocaleString('ko-KR', {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: false,
                  })
                  .replace(/\. /g, '-')
                  .replace(/:/g, ':')
                  .replace('.', '')
              : '-';
          }}
        />
        <Table.Column
          dataIndex='stop_at'
          title={'투표종료'}
          render={(value: any) => {
            if (!value) return '-';
            return value
              ? new Date(value)
                  .toLocaleString('ko-KR', {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: false,
                  })
                  .replace(/\. /g, '-')
                  .replace(/:/g, ':')
                  .replace('.', '')
              : '-';
          }}
        />
        <Table.Column
          dataIndex='created_at'
          title={'생성일'}
          render={(value: any) => {
            if (!value) return '-';
            return value
              ? new Date(value)
                  .toLocaleString('ko-KR', {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: false,
                  })
                  .replace(/\. /g, '-')
                  .replace(/:/g, ':')
                  .replace('.', '')
              : '-';
          }}
        />
        <Table.Column
          dataIndex='updated_at'
          title={'수정일'}
          render={(value: any) => {
            if (!value) return '-';
            return value
              ? new Date(value)
                  .toLocaleString('ko-KR', {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: false,
                  })
                  .replace(/\. /g, '-')
                  .replace(/:/g, ':')
                  .replace('.', '')
              : '-';
          }}
        />
        <Table.Column
          dataIndex='deleted_at'
          title={'삭제일'}
          render={(value: any) => {
            if (!value) return '-';
            return value
              ? new Date(value)
                  .toLocaleString('ko-KR', {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: false,
                  })
                  .replace(/\. /g, '-')
                  .replace(/:/g, ':')
                  .replace('.', '')
              : '-';
          }}
        />
        <Table.Column
          title={'Actions'}
          dataIndex='actions'
          render={(_, record: BaseRecord) => (
            <Space>
              <EditButton hideText size='small' recordItemId={record.id} />
              <ShowButton hideText size='small' recordItemId={record.id} />
              <DeleteButton hideText size='small' recordItemId={record.id} />
            </Space>
          )}
        />
      </Table>
    </List>
  );
}
