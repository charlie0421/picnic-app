import React from 'react';
import {
  UserOutlined,
  DeleteOutlined,
  UsergroupAddOutlined,
  TrophyOutlined,
} from '@ant-design/icons';
import { theme, Button, Tag } from 'antd';
import dayjs from 'dayjs';
import { Artist } from '@/types/artist';
import { getImageUrl } from '@/utils/image';
import { COLORS } from '@/utils/theme';

interface ArtistCardProps {
  artist: Artist;
  onClick?: () => void;
  onDelete?: () => void;
  showDeleteButton?: boolean;
  voteInfo?: {
    rank?: number;
    voteTotal?: number;
  };
}

const ArtistCard: React.FC<ArtistCardProps> = ({
  artist,
  onClick,
  onDelete,
  showDeleteButton = false,
  voteInfo,
}) => {
  const { token } = theme.useToken();

  return (
    <div
      style={{
        padding: '15px',
        border: `1px solid ${token.colorBorderSecondary}`,
        borderRadius: '8px',
        background: token.colorBgElevated,
        boxShadow: `0 2px 8px rgba(0, 0, 0, ${
          token.colorBgMask === '#000000' ? 0.15 : 0.08
        })`,
        cursor: onClick ? 'pointer' : 'default',
        position: 'relative',
      }}
      onClick={onClick}
    >
      {showDeleteButton && onDelete && (
        <Button
          type='text'
          icon={<DeleteOutlined />}
          danger
          size='small'
          style={{ position: 'absolute', top: '5px', right: '5px' }}
          onClick={(e) => {
            e.stopPropagation();
            onDelete();
          }}
          title='제거'
        />
      )}

      {/* 투표 순위 및 득표수 표시 */}
      {voteInfo?.rank && (
        <div
          style={{
            textAlign: 'center',
            fontSize: '1.5em',
            fontWeight: 'bold',
            color: COLORS.primary,
            marginBottom: '15px',
            padding: '10px',
            backgroundColor: token.colorPrimaryBg,
            borderRadius: '4px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <TrophyOutlined style={{ marginRight: '10px' }} />
          {voteInfo.rank}위
          {voteInfo.voteTotal !== undefined && (
            <Tag
              color='blue'
              style={{
                marginLeft: '10px',
                color: COLORS.secondary,
              }}
            >
              {voteInfo.voteTotal.toLocaleString() || 0} 표
            </Tag>
          )}
        </div>
      )}

      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '10px',
        }}
      >
        <div style={{ textAlign: 'center' }}>
          {artist?.image ? (
            <img
              src={`${getImageUrl(artist.image)}?w=100`}
              alt='아티스트 이미지'
              style={{
                width: '100px',
                height: '100px',
                objectFit: 'cover',
                borderRadius: '50%',
                border: `2px solid ${COLORS.primary}`,
                boxShadow: `0 2px 8px rgba(0, 0, 0, ${
                  token.colorBgMask === '#000000' ? 0.15 : 0.08
                })`,
              }}
              onError={(e) => {
                e.currentTarget.style.display = 'none';
                if (e.currentTarget.nextElementSibling instanceof HTMLElement) {
                  e.currentTarget.nextElementSibling.style.display = 'block';
                }
              }}
            />
          ) : (
            <div
              style={{
                width: '100px',
                height: '100px',
                margin: '0 auto',
                backgroundColor: '#f5f5f5',
                borderRadius: '50%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <UserOutlined style={{ fontSize: '48px', color: '#bfbfbf' }} />
            </div>
          )}
        </div>

        <div style={{ marginTop: '10px' }}>
          <div
            style={{
              fontSize: '16px',
              fontWeight: 'bold',
              textAlign: 'center',
              marginBottom: '12px',
            }}
          >
            {artist?.name?.ko || '-'}
            {artist?.name?.en && (
              <span
                style={{
                  marginLeft: '4px',
                  color: '#8c8c8c',
                  fontWeight: 'normal',
                }}
              >
                ({artist.name.en})
              </span>
            )}
          </div>

          {/* 성별 정보 */}
          {artist?.gender && (
            <div
              style={{
                margin: '8px 0',
                padding: '8px',
                backgroundColor: token.colorFillTertiary,
                borderRadius: '4px',
                border: `1px solid ${token.colorBorderSecondary}`,
              }}
            >
              <div
                style={{
                  fontSize: '13px',
                  color: token.colorTextSecondary,
                }}
              >
                성별:{' '}
                {artist.gender === 'male'
                  ? '남성'
                  : artist.gender === 'female'
                  ? '여성'
                  : artist.gender}
              </div>
            </div>
          )}

          {/* 생일 정보 */}
          {(artist?.birth_date || artist?.yy) && (
            <div
              style={{
                margin: '8px 0',
                padding: '8px',
                backgroundColor: token.colorFillTertiary,
                borderRadius: '4px',
                border: `1px solid ${token.colorBorderSecondary}`,
              }}
            >
              <div
                style={{
                  fontSize: '13px',
                  color: token.colorTextSecondary,
                }}
              >
                생일 🎂:{' '}
                {artist.birth_date
                  ? dayjs(artist.birth_date).format('YYYY-MM-DD')
                  : `${artist.yy}${
                      artist.mm
                        ? `.${artist.mm.toString().padStart(2, '0')}`
                        : ''
                    }${
                      artist.dd
                        ? `.${artist.dd.toString().padStart(2, '0')}`
                        : ''
                    }`}
              </div>
            </div>
          )}

          {/* 그룹 정보 */}
          {artist?.artist_group && (
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                margin: '8px 0 4px 0',
                padding: '8px',
                backgroundColor: token.colorFillTertiary,
                borderRadius: '4px',
                border: `1px solid ${token.colorBorderSecondary}`,
              }}
            >
              {artist.artist_group.image ? (
                <img
                  src={`${getImageUrl(artist.artist_group.image)}?w=30`}
                  alt='그룹 이미지'
                  style={{
                    width: '30px',
                    height: '30px',
                    objectFit: 'cover',
                    borderRadius: '4px',
                  }}
                  onError={(e) => {
                    e.currentTarget.style.display = 'none';
                    if (
                      e.currentTarget.nextElementSibling instanceof HTMLElement
                    ) {
                      e.currentTarget.nextElementSibling.style.display =
                        'block';
                    }
                  }}
                />
              ) : null}
              <div
                style={{
                  width: '30px',
                  height: '30px',
                  backgroundColor: '#f0f0f0',
                  borderRadius: '4px',
                  display: artist.artist_group.image ? 'none' : 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <UsergroupAddOutlined
                  style={{
                    fontSize: '18px',
                    color: token.colorPrimary,
                  }}
                />
              </div>
              <div>
                <div style={{ fontWeight: 'bold' }}>
                  {artist.artist_group.name?.ko || ''}
                  {artist.artist_group.name?.en && (
                    <span
                      style={{
                        marginLeft: '4px',
                        color: '#8c8c8c',
                        fontWeight: 'normal',
                      }}
                    >
                      ({artist.artist_group.name.en})
                    </span>
                  )}
                </div>
                {artist.artist_group.debut_yy && (
                  <div
                    style={{
                      fontSize: '12px',
                      color: token.colorTextSecondary,
                      marginTop: '2px',
                    }}
                  >
                    데뷔: {artist.artist_group.debut_yy}
                    {artist.artist_group.debut_mm &&
                      `.${artist.artist_group.debut_mm
                        .toString()
                        .padStart(2, '0')}`}
                    {artist.artist_group.debut_dd &&
                      `.${artist.artist_group.debut_dd
                        .toString()
                        .padStart(2, '0')}`}
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ArtistCard;
