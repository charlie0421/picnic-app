#!/usr/bin/env python3
"""
CodeMagic codemagic.yaml 설정 파일 검증 스크립트
사용법: python validate_codemagic_config.py
"""

import yaml
import os
import sys
from typing import Dict, List, Any

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color

def log_info(message: str):
    print(f"{Colors.BLUE}[INFO]{Colors.NC} {message}")

def log_success(message: str):
    print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} {message}")

def log_warning(message: str):
    print(f"{Colors.YELLOW}[WARNING]{Colors.NC} {message}")

def log_error(message: str):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {message}")

def validate_yaml_syntax(file_path: str) -> bool:
    """YAML 파일 구문 검증"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            yaml.safe_load(file)
        log_success("YAML 구문 검증 통과")
        return True
    except yaml.YAMLError as e:
        log_error(f"YAML 구문 오류: {e}")
        return False
    except FileNotFoundError:
        log_error(f"파일을 찾을 수 없습니다: {file_path}")
        return False

def validate_workflow_structure(config: Dict[str, Any]) -> bool:
    """워크플로우 구조 검증"""
    log_info("워크플로우 구조 검증 중...")
    
    if 'workflows' not in config:
        log_error("'workflows' 섹션이 없습니다")
        return False
    
    workflows = config['workflows']
    if not isinstance(workflows, dict):
        log_error("'workflows'는 딕셔너리여야 합니다")
        return False
    
    expected_workflows = [
        'picnic-app-android',
        'picnic-app-ios', 
        'ttja-app-android',
        'ttja-app-ios'
    ]
    
    missing_workflows = []
    for workflow in expected_workflows:
        if workflow not in workflows:
            missing_workflows.append(workflow)
    
    if missing_workflows:
        log_error(f"누락된 워크플로우: {', '.join(missing_workflows)}")
        return False
    
    log_success(f"총 {len(workflows)}개 워크플로우 확인")
    return True

def validate_workflow_fields(workflow: Dict[str, Any], workflow_name: str) -> bool:
    """개별 워크플로우 필드 검증"""
    required_fields = ['name', 'instance_type', 'max_build_duration', 'environment', 'scripts']
    
    missing_fields = []
    for field in required_fields:
        if field not in workflow:
            missing_fields.append(field)
    
    if missing_fields:
        log_error(f"{workflow_name}: 누락된 필드 - {', '.join(missing_fields)}")
        return False
    
    # 환경 변수 검증
    env = workflow.get('environment', {})
    if 'flutter' not in env:
        log_warning(f"{workflow_name}: Flutter 버전이 명시되지 않았습니다")
    
    # 스크립트 검증
    scripts = workflow.get('scripts', [])
    if not scripts:
        log_error(f"{workflow_name}: 스크립트가 없습니다")
        return False
    
    return True

def validate_environment_groups(config: Dict[str, Any]) -> bool:
    """환경 변수 그룹 검증"""
    log_info("환경 변수 그룹 검증 중...")
    
    workflows = config.get('workflows', {})
    required_groups = {
        'picnic-app-android': ['google_play', 'shorebird-config', 'picnic_env'],
        'picnic-app-ios': ['app_store_connect', 'picnic_env'],
        'ttja-app-android': ['google_play', 'ttja_env'],
        'ttja-app-ios': ['app_store_connect', 'ttja_env']
    }
    
    all_valid = True
    for workflow_name, expected_groups in required_groups.items():
        if workflow_name not in workflows:
            continue
            
        workflow = workflows[workflow_name]
        env = workflow.get('environment', {})
        groups = env.get('groups', [])
        
        missing_groups = []
        for group in expected_groups:
            if group not in groups:
                missing_groups.append(group)
        
        if missing_groups:
            log_warning(f"{workflow_name}: 누락된 환경 변수 그룹 - {', '.join(missing_groups)}")
            all_valid = False
    
    return all_valid

def validate_signing_configuration(config: Dict[str, Any]) -> bool:
    """코드 서명 설정 검증"""
    log_info("코드 서명 설정 검증 중...")
    
    workflows = config.get('workflows', {})
    android_workflows = ['picnic-app-android', 'ttja-app-android']
    ios_workflows = ['picnic-app-ios', 'ttja-app-ios']
    
    all_valid = True
    
    # Android 키스토어 검증
    for workflow_name in android_workflows:
        if workflow_name not in workflows:
            continue
            
        workflow = workflows[workflow_name]
        env = workflow.get('environment', {})
        
        if 'android_signing' not in env:
            log_error(f"{workflow_name}: android_signing 설정이 없습니다")
            all_valid = False
    
    # iOS 코드 서명 검증
    for workflow_name in ios_workflows:
        if workflow_name not in workflows:
            continue
            
        workflow = workflows[workflow_name]
        env = workflow.get('environment', {})
        
        if 'ios_signing' not in env:
            log_error(f"{workflow_name}: ios_signing 설정이 없습니다")
            all_valid = False
        else:
            ios_signing = env['ios_signing']
            if 'bundle_identifier' not in ios_signing:
                log_error(f"{workflow_name}: bundle_identifier가 설정되지 않았습니다")
                all_valid = False
    
    return all_valid

def validate_triggers(config: Dict[str, Any]) -> bool:
    """트리거 설정 검증"""
    log_info("트리거 설정 검증 중...")
    
    workflows = config.get('workflows', {})
    all_valid = True
    
    for workflow_name, workflow in workflows.items():
        if 'triggering' not in workflow:
            log_warning(f"{workflow_name}: 트리거 설정이 없습니다")
            continue
        
        triggering = workflow['triggering']
        
        # 브랜치 패턴 확인
        if 'branch_patterns' in triggering:
            branch_patterns = triggering['branch_patterns']
            expected_branches = ['production', 'develop']
            
            configured_branches = []
            for pattern in branch_patterns:
                if 'pattern' in pattern:
                    configured_branches.append(pattern['pattern'])
            
            for branch in expected_branches:
                if branch not in configured_branches:
                    log_warning(f"{workflow_name}: '{branch}' 브랜치 트리거가 설정되지 않았습니다")
        
        # 태그 패턴 확인
        if 'tag_patterns' in triggering:
            tag_patterns = triggering['tag_patterns']
            if workflow_name.startswith('picnic-'):
                expected_pattern = 'picnic-v*'
            elif workflow_name.startswith('ttja-'):
                expected_pattern = 'ttja-v*'
            else:
                continue
            
            found_pattern = False
            for pattern in tag_patterns:
                if pattern.get('pattern') == expected_pattern:
                    found_pattern = True
                    break
            
            if not found_pattern:
                log_warning(f"{workflow_name}: 예상된 태그 패턴 '{expected_pattern}'이 없습니다")
    
    return all_valid

def validate_publishing(config: Dict[str, Any]) -> bool:
    """배포 설정 검증"""
    log_info("배포 설정 검증 중...")
    
    workflows = config.get('workflows', {})
    android_workflows = ['picnic-app-android', 'ttja-app-android']
    ios_workflows = ['picnic-app-ios', 'ttja-app-ios']
    
    all_valid = True
    
    # Android 배포 검증
    for workflow_name in android_workflows:
        if workflow_name not in workflows:
            continue
            
        workflow = workflows[workflow_name]
        publishing = workflow.get('publishing', {})
        
        if 'google_play' not in publishing:
            log_warning(f"{workflow_name}: Google Play 배포 설정이 없습니다")
        else:
            google_play = publishing['google_play']
            if 'credentials' not in google_play:
                log_error(f"{workflow_name}: Google Play credentials가 설정되지 않았습니다")
                all_valid = False
    
    # iOS 배포 검증
    for workflow_name in ios_workflows:
        if workflow_name not in workflows:
            continue
            
        workflow = workflows[workflow_name]
        publishing = workflow.get('publishing', {})
        
        if 'app_store_connect' not in publishing:
            log_warning(f"{workflow_name}: App Store Connect 배포 설정이 없습니다")
    
    return all_valid

def main():
    """메인 함수"""
    log_info("=== CodeMagic 설정 검증 시작 ===")
    
    config_file = 'codemagic.yaml'
    
    # 1. YAML 구문 검증
    if not validate_yaml_syntax(config_file):
        sys.exit(1)
    
    # 2. 설정 파일 로드
    with open(config_file, 'r', encoding='utf-8') as file:
        config = yaml.safe_load(file)
    
    # 3. 워크플로우 구조 검증
    if not validate_workflow_structure(config):
        sys.exit(1)
    
    # 4. 개별 워크플로우 검증
    workflows = config['workflows']
    for workflow_name, workflow in workflows.items():
        if not validate_workflow_fields(workflow, workflow_name):
            sys.exit(1)
        log_success(f"{workflow_name}: 기본 구조 검증 통과")
    
    # 5. 환경 변수 그룹 검증
    validate_environment_groups(config)
    
    # 6. 코드 서명 설정 검증
    validate_signing_configuration(config)
    
    # 7. 트리거 설정 검증
    validate_triggers(config)
    
    # 8. 배포 설정 검증
    validate_publishing(config)
    
    log_success("=== 모든 검증 완료 ===")
    log_info("\n다음 단계:")
    log_info("1. CodeMagic 대시보드에서 환경 변수 그룹 설정")
    log_info("2. 코드 서명 인증서 업로드")
    log_info("3. ./test_codemagic_local.sh 스크립트로 로컬 빌드 테스트")

if __name__ == "__main__":
    main() 