let permissions: Record<string, string[]> | null = null;

/**
 * 메모리에 저장된 권한 맵을 설정합니다.
 * @param newPermissions 새로운 권한 맵 또는 null
 */
export const setPermissions = (
  newPermissions: Record<string, string[]> | null,
) => {
  permissions = newPermissions;
};

/**
 * 메모리에 저장된 권한 맵을 반환합니다.
 * @returns 현재 저장된 권한 맵 또는 null
 */
export const getPermissions = (): Record<string, string[]> | null => {
  return permissions;
};
