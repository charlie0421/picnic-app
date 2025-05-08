interface PlatformVersion {
  version: string;
  force_version: string;
  url: string;
}

export interface Version {
  id: number;
  android: PlatformVersion | null;
  ios: PlatformVersion | null;
  linux: PlatformVersion | null;
  macos: PlatformVersion | null;
  windows: PlatformVersion | null;
  deletedAt: string | null;
}
