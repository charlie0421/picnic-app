import {Column, Entity} from "typeorm";
import {BaseEntity} from "./base_entity";

@Entity('version')
export class VersionEntity extends BaseEntity {
    @Column({name: 'ios_version'})
    iosVersion: string;

    @Column({name: 'ios_force_version'})
    iosForceVersion: string;

    @Column({name: 'ios_url'})
    iosUrl: string;

    @Column({name: 'android_version'})
    androidVersion: string;

    @Column({name: 'android_force_version'})
    androidForceVersion: string;

    @Column({name: 'android_url'})
    androidUrl: string;

    @Column({name: 'macos_url'})
    macosUrl: string;

    @Column({name: 'macos_force_version'})
    macosForceVersion: string;

    @Column({name: 'macos_version'})
    macosVersion: string;

    @Column({name: 'windows_version'})
    windowsVersion: string;

    @Column({name: 'windows_force_version'})
    windowsForceVersion: string;

    @Column({name: 'windows_url'})
    windowsUrl: string;

    @Column({name: 'linux_version'})
    linuxVersion: string;

    @Column({name: 'linux_force_version'})
    linuxForceVersion: string;

    @Column({name: 'linux_url'})
    linuxUrl: string;
}
