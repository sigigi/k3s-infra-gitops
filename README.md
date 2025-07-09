# k3s-infra-gitops

k3s 클러스터와 Argo CD를 사용하여 GitOps 환경을 구축하기 위한 초기화 스크립트입니다.

## 주요 기능

- **k3s 설치**: 경량 Kubernetes 배포판인 k3s를 특정 버전에 맞춰 설치합니다.
- **Argo CD 설치**: GitOps를 위한 지속적 배포 도구인 Argo CD를 설치합니다.
- **Ingress 설정**: Traefik Ingress Controller를 사용하여 Argo CD 대시보드에 접근할 수 있도록 자동으로 `IngressRoute`를 생성합니다.

## 사전 요구사항

스크립트를 실행하기 전에 다음 프로그램이 설치되어 있어야 합니다.

- `bash`
- `curl`
- `sudo` 권한

## 사용법

저장소를 클론한 후, 다음 명령어를 실행하여 스크립트에 실행 권한을 부여하고 실행합니다.

```bash
chmod +x init.sh
./init.sh
```

스크립트 실행이 완료되면, Argo CD UI에 접근할 수 있는 주소와 초기 관리자 비밀번호가 터미널에 출력됩니다.

## 설정

`init.sh` 파일 상단에서 다음 변수들을 수정하여 설치 버전을 변경하거나 도메인을 설정할 수 있습니다.

```bash
# ─────────────────────────────────────────────
# CONFIGURABLE VARIABLES
# ─────────────────────────────────────────────
K3S_VERSION="v1.33.1+k3s1"
ARGOCD_VERSION="v3.0.6"
ARGOCD_SERVICE_DOMAIN="argocd.office"
```

- `K3S_VERSION`: 설치할 k3s 버전
- `ARGOCD_VERSION`: 설치할 Argo CD 버전
- `ARGOCD_SERVICE_DOMAIN`: Argo CD UI에 접근하기 위한 도메인 주소

버전은 아래 링크를 참조하세요.
- **k3s releases**: https://github.com/k3s-io/k3s/releases
- **Argo CD releases**: https://github.com/argoproj/argo-cd/releases

## 설치 후

스크립트가 성공적으로 실행되면 다음 단계를 따르세요.

1.  터미널에 출력된 Argo CD URL (예: `https://argocd.office`)로 접속합니다.
2.  사용자 이름은 `admin` 입니다.
3.  비밀번호는 터미널에 출력된 초기 관리자 비밀번호를 사용합니다.
