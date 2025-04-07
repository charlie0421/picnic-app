import React from 'react';
import {
  SettingOutlined,
  TeamOutlined,
  KeyOutlined,
  UserSwitchOutlined,
  LinkOutlined,
  VideoCameraOutlined,
  UserOutlined,
  GroupOutlined,
  CheckCircleOutlined,
} from '@ant-design/icons';
import type { ResourceProps } from '@refinedev/core';

export const resources: ResourceProps[] = [
  // 관리 메뉴 (권한 관리 상위 메뉴) - 상위 메뉴를 먼저 정의해야 함
  {
    name: 'admin',
    meta: {
      label: '관리자 설정',
      icon: 'SettingOutlined',
    },
  },
  // 권한 관리 리소스들 (경로 수정)
  {
    name: 'admin_roles',
    list: '/admin_roles', // 경로 수정
    create: '/admin_roles/create', // 경로 수정
    edit: '/admin_roles/edit/:id', // 경로 수정
    meta: {
      canDelete: true,
      parent: 'admin',
      label: '역할 관리',
      icon: 'TeamOutlined',
      list: {
        label: '역할 목록',
      },
      create: {
        label: '역할 추가',
      },
      edit: {
        label: '역할 수정',
      },
    },
  },
  {
    name: 'admin_permissions',
    list: '/admin_permissions', // 경로 수정
    create: '/admin_permissions/create', // 경로 수정
    edit: '/admin_permissions/edit/:id', // 경로 수정
    meta: {
      canDelete: true,
      parent: 'admin',
      label: '권한 관리',
      icon: 'KeyOutlined',
      list: {
        label: '권한 목록',
      },
      create: {
        label: '권한 추가',
      },
      edit: {
        label: '권한 수정',
      },
    },
  },
  {
    name: 'admin_role_permissions',
    list: '/admin_role_permissions', // 경로 수정
    create: '/admin_role_permissions/create', // 경로 수정
    edit: '/admin_role_permissions/edit/:id', // 경로 수정
    meta: {
      canDelete: true,
      parent: 'admin',
      label: '역할-권한 매핑',
      icon: 'LinkOutlined',
      list: {
        label: '역할-권한 목록',
      },
      create: {
        label: '역할-권한 연결',
      },
      edit: {
        label: '역할-권한 수정',
      },
    },
  },
  {
    name: 'admin_user_roles',
    list: '/admin_user_roles', // 경로 수정
    create: '/admin_user_roles/create', // 경로 수정
    edit: '/admin_user_roles/edit/:id', // 경로 수정
    meta: {
      canDelete: true,
      parent: 'admin',
      label: '사용자 역할 관리',
      icon: 'UserSwitchOutlined',
      list: {
        label: '사용자 역할 목록',
      },
      create: {
        label: '사용자 역할 추가',
      },
      edit: {
        label: '사용자 역할 수정',
      },
    },
  },
  // 권한 없는 사용자를 위한 리소스 (메뉴 숨김)
  {
    name: 'admin_no_access',
    list: '/admin/no-access',
    meta: {
      hide: true, // 메뉴에서 숨김
    },
  },
  // 기존 메뉴들
  {
    name: 'vote',
    list: '/vote',
    create: '/vote/create',
    edit: '/vote/edit/:id',
    show: '/vote/show/:id',
    meta: {
      canDelete: true,
      label: '투표관리',
      icon: 'CheckCircleOutlined',
      list: {
        label: '투표관리',
      },
      create: {
        label: '투표생성',
      },
      edit: {
        label: '투표수정',
      },
      show: {
        label: '투표조회',
      },
    },
  },
  {
    name: 'media',
    list: '/media',
    create: '/media/create',
    edit: '/media/edit/:id',
    show: '/media/show/:id',
    meta: {
      canDelete: true,
      label: '미디어 관리',
      icon: 'VideoCameraOutlined',
      list: {
        label: '미디어 목록',
      },
      create: {
        label: '미디어 추가',
      },
      edit: {
        label: '미디어 수정',
      },
      show: {
        label: '미디어 상세',
      },
    },
  },
  {
    name: 'artist_group',
    list: '/artist-group',
    create: '/artist-group/create',
    edit: '/artist-group/edit/:id',
    show: '/artist-group/show/:id',
    meta: {
      canDelete: true,
      label: '아티스트 그룹 관리',
      icon: 'GroupOutlined',
      list: {
        label: '아티스트 그룹 목록',
      },
      create: {
        label: '아티스트 그룹 추가',
      },
      edit: {
        label: '아티스트 그룹 수정',
      },
      show: {
        label: '아티스트 그룹 상세',
      },
    },
  },
  {
    name: 'artist',
    list: '/artist',
    create: '/artist/create',
    edit: '/artist/edit/:id',
    show: '/artist/show/:id',
    meta: {
      canDelete: true,
      label: '아티스트 관리',
      icon: 'UserOutlined',
      list: {
        label: '아티스트 목록',
      },
      create: {
        label: '아티스트 추가',
      },
      edit: {
        label: '아티스트 수정',
      },
      show: {
        label: '아티스트 상세',
      },
    },
  },
];
