export interface USER {
  id: number;
  email: string;
  name: string;
  isSuperAdmin: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ROLE {
  id: number;
  name: string;
  description: string;
  createdAt: string;
  updatedAt: string;
}

export interface PERMISSION {
  id: number;
  resource: string;
  action: string;
  description: string;
  createdAt: string;
  updatedAt: string;
}

export interface ROLE_PERMISSION_RELATIONSHIP {
  id: number;
  roleId: number;
  permissionId: number;
  createdAt: string;
  updatedAt: string;
}

export interface ROLE_USER_RELATIONSHIP {
  id: number;
  roleId: number;
  userId: number;
  createdAt: string;
  updatedAt: string;
}

export interface UserIdentity {
  id: number;
  email: string;
  name: string;
  isSuperAdmin: boolean;
}
