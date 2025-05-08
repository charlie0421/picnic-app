'use client';

import { Descriptions } from 'antd';
import { Version } from '@/lib/types/version';

interface VersionDetailProps {
  record?: Version;
  loading?: boolean;
}

export default function VersionDetail({ record, loading }: VersionDetailProps) {
  return (
    <Descriptions bordered column={1}>
      <Descriptions.Item label='Android'>
        <Descriptions
          bordered
          size='small'
          column={1}
          labelStyle={{ width: '200px' }}
        >
          <Descriptions.Item label='권장 업데이트 버전'>
            {record?.android?.version || '-'}
          </Descriptions.Item>
          <Descriptions.Item label='강제 업데이트 버전'>
            {record?.android?.force_version || '-'}
          </Descriptions.Item>
          <Descriptions.Item label='URL'>
            {record?.android?.url || '-'}
          </Descriptions.Item>
        </Descriptions>
      </Descriptions.Item>

      <Descriptions.Item label='iOS'>
        <Descriptions
          bordered
          size='small'
          column={1}
          labelStyle={{ width: '200px' }}
        >
          <Descriptions.Item label='권장 업데이트 버전'>
            {record?.ios?.version || '-'}
          </Descriptions.Item>
          <Descriptions.Item label='강제 업데이트 버전'>
            {record?.ios?.force_version || '-'}
          </Descriptions.Item>
          <Descriptions.Item label='URL'>
            {record?.ios?.url || '-'}
          </Descriptions.Item>
        </Descriptions>
      </Descriptions.Item>

      <Descriptions.Item label='Linux'>
        <Descriptions
          bordered
          size='small'
          column={1}
          labelStyle={{ width: '200px' }}
        >
          <Descriptions.Item label='권장 업데이트 버전'>
            {record?.linux?.version || '-'}
          </Descriptions.Item>
          <Descriptions.Item label='강제 업데이트 버전'>
            {record?.linux?.force_version || '-'}
          </Descriptions.Item>
          <Descriptions.Item label='URL'>
            {record?.linux?.url || '-'}
          </Descriptions.Item>
        </Descriptions>
      </Descriptions.Item>

      <Descriptions.Item label='macOS'>
        <Descriptions
          bordered
          size='small'
          column={1}
          labelStyle={{ width: '200px' }}
        >
          <Descriptions.Item label='권장 업데이트 버전'>
            {record?.macos?.version || '-'}
          </Descriptions.Item>
          <Descriptions.Item label='강제 업데이트 버전'>
            {record?.macos?.force_version || '-'}
          </Descriptions.Item>
          <Descriptions.Item label='URL'>
            {record?.macos?.url || '-'}
          </Descriptions.Item>
        </Descriptions>
      </Descriptions.Item>

      <Descriptions.Item label='Windows'>
        <Descriptions
          bordered
          size='small'
          column={1}
          labelStyle={{ width: '200px' }}
        >
          <Descriptions.Item label='권장 업데이트 버전'>
            {record?.windows?.version || '-'}
          </Descriptions.Item>
          <Descriptions.Item label='강제 업데이트 버전'>
            {record?.windows?.force_version || '-'}
          </Descriptions.Item>
          <Descriptions.Item label='URL'>
            {record?.windows?.url || '-'}
          </Descriptions.Item>
        </Descriptions>
      </Descriptions.Item>
    </Descriptions>
  );
}
