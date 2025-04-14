import { useCreate, useList, useUpdate } from '@refinedev/core';
import { Empty, Space, Transfer, message, theme } from 'antd';
import { useEffect, useState } from 'react';
import Image from 'next/image';
import { getCdnImageUrl } from '@/lib/image';
import { RewardItem } from '@/lib/vote';

interface VoteRewardSelectorProps {
  initialRewardIds: number[];
  selectedRewardIds: number[];
  onRewardChange: (rewardIds: number[]) => void;
}

export default function VoteRewardSelector({
  initialRewardIds,
  selectedRewardIds,
  onRewardChange,
}: VoteRewardSelectorProps) {
  const { token } = theme.useToken();
  const [rewardItems, setRewardItems] = useState<RewardItem[]>([]);
  const [transferTargetKeys, setTransferTargetKeys] = useState<string[]>([]);

  // 리워드 목록 조회
  const { data: rewardsData, isLoading: isRewardsLoading } = useList({
    resource: 'reward',
    pagination: {
      pageSize: 100,
    },
    meta: {
      select: 'id,title,order,thumbnail',
      sort: {
        field: 'order',
        order: 'asc',
      },
    },
  });

  // Transfer targetKeys 초기화
  useEffect(() => {
    console.log(
      'VoteRewardSelector - selectedRewardIds 변경:',
      selectedRewardIds,
    );
    const stringIds = selectedRewardIds.map((id) => id.toString());
    setTransferTargetKeys(stringIds);
    console.log('Transfer targetKeys 설정됨:', stringIds);
  }, [selectedRewardIds]);

  // 리워드 목록 설정
  useEffect(() => {
    console.log('VoteRewardSelector - rewardsData 변경:', rewardsData);
    if (rewardsData?.data) {
      const items = rewardsData.data.map((item: any) => ({
        id: item.id,
        title: item.title || {},
        order: item.order,
        thumbnail: item.thumbnail,
      }));
      console.log('리워드 아이템 설정:', items);
      setRewardItems(items);
    }
  }, [rewardsData]);

  // 리워드 선택 변경 핸들러
  const handleRewardSelectChange = (nextTargetKeys: string[] | React.Key[]) => {
    console.log('Transfer 선택 변경 이벤트:', nextTargetKeys);

    // 문자열 키로 변환
    const stringKeys = nextTargetKeys.map((key) => key.toString());
    console.log('문자열 키로 변환:', stringKeys);

    // Transfer 컴포넌트 상태 업데이트
    setTransferTargetKeys(stringKeys);

    // 숫자 ID로 변환하여 부모에게 전달
    const numericIds = stringKeys
      .map((key) => Number(key))
      .filter((id) => !isNaN(id) && id > 0);

    console.log('숫자 ID로 변환된 결과:', numericIds);
    onRewardChange(numericIds);
  };

  return (
    <div
      style={{
        backgroundColor: token.colorBgContainer,
        border: `1px solid ${token.colorBorderSecondary}`,
        borderRadius: token.borderRadiusLG,
        padding: token.padding,
        marginBottom: token.marginLG,
        boxShadow: token.boxShadowTertiary,
      }}
    >
      <h3 style={{ marginTop: 0, color: token.colorTextHeading }}>
        리워드 연결
      </h3>
      <p style={{ color: token.colorTextSecondary }}>
        이 투표와 연결할 리워드를 선택하세요. 투표 결과에 따라 제공될
        리워드입니다.
      </p>

      {isRewardsLoading ? (
        <div style={{ textAlign: 'center', padding: '20px' }}>
          리워드 목록을 불러오는 중...
        </div>
      ) : rewardItems.length === 0 ? (
        <Empty description='연결할 수 있는 리워드가 없습니다.' />
      ) : (
        <>
          <div
            style={{ marginBottom: '10px', color: token.colorTextSecondary }}
          >
            현재 선택된 리워드:{' '}
            {selectedRewardIds.length > 0
              ? selectedRewardIds.map((id) => `#${id}`).join(', ')
              : '없음'}
          </div>

          <Transfer
            targetKeys={transferTargetKeys}
            onChange={handleRewardSelectChange}
            dataSource={rewardItems.map((item) => ({
              key: item.id.toString(),
              title: item.title?.ko || item.title?.en || '제목 없음',
              description: `ID: ${item.id}`,
              disabled: false,
              order: item.order,
              thumbnail: item.thumbnail,
            }))}
            titles={['사용 가능한 리워드', '선택된 리워드']}
            render={(item) => (
              <Space>
                {item.thumbnail && (
                  <Image
                    src={getCdnImageUrl(item.thumbnail, 40)}
                    alt='리워드 썸네일'
                    width={30}
                    height={30}
                    style={{ objectFit: 'cover', borderRadius: '4px' }}
                  />
                )}
                <span>{item.title}</span>
              </Space>
            )}
            listStyle={{ width: 350, height: 300 }}
            style={{ marginBottom: '20px' }}
            showSearch
            filterOption={(inputValue, option) =>
              option.title.toLowerCase().indexOf(inputValue.toLowerCase()) > -1
            }
          />
        </>
      )}
    </div>
  );
}
