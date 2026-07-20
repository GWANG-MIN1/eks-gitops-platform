# 로드맵

단계별로 만들어 나갑니다. 각 단계는 독립적으로 `apply` 가능하고, 저장소를 항상
동작하는 상태로 남깁니다. 체크박스는 작업이 실제로 반영될 때 갱신해서 상태를 항상
정직하게 유지합니다.

## Phase 1 — Terraform 기반 구성 ✅ (라이브 apply 검증 완료)

목표: `environments/dev`에서 `terraform apply` 하면 접근 가능한 EKS 클러스터가 뜬다.

- [x] Remote state 백엔드 (S3 + DynamoDB 잠금) — `terraform/bootstrap/`
- [x] VPC 모듈 (public/private 서브넷, NAT, 2개 이상 AZ)
- [x] EKS 모듈 (컨트롤 플레인 + managed node group)
- [x] 서비스 계정용 IAM(IRSA) 기본 구성 — EKS OIDC provider
- [x] CI에서 `terraform fmt` / `validate` 통과(green)

> **2026-07-20 실계정 검증 완료**: bootstrap → `init -backend-config` → `apply` 전체
> 플로우 성공. 노드 2개 Ready(v1.30.14-eks), coredns/aws-node/kube-proxy/
> pod-identity-agent 전부 Running, 서브넷 4개가 2a/2c 두 AZ에 분산, remote state가
> S3에 기록, IRSA용 OIDC provider 생성 확인. 매일 destroy 원칙은 계속 유지.

## Phase 2 — ArgoCD 기반 GitOps ✅ (코드 완료 · 클러스터 sync 검증 전)

목표: 클러스터 상태를 Git에 선언하고 자동으로 반영한다.

- [x] ArgoCD 설치 (bootstrap manifest) — `gitops/bootstrap/argocd/` (kustomize, v2.13.4 고정)
- [x] app-of-apps root Application — `gitops/bootstrap/root-app.yaml`
- [x] GitOps로 샘플 워크로드 배포 — `gitops/apps/sample-app`
- [x] push → sync 흐름 문서화 — `gitops/README.md`

> 매니페스트는 검증 완료(`kubectl kustomize`로 ArgoCD install 빌드 성공, 전 YAML 파싱
> OK). 실제 클러스터에 apply해서 ArgoCD가 Synced/Healthy로 수렴하는지는 Phase 1과
> 함께 계정에서 한 번에 검증한다. (체크박스 = "매니페스트/구조 검증 완료", not
> live-synced.)

## Phase 3 — Observability ✅ (코드 완료 · 클러스터 검증 전)

목표: 메트릭, 대시보드, 로그를 수동 설정 없이 바로 볼 수 있게 한다.

- [x] kube-prometheus-stack (Prometheus + Grafana + Alertmanager) — `observability/kube-prometheus-stack/` (차트 87.16.1 고정)
- [x] 로그 집계용 Loki — `observability/loki/` (SingleBinary) + `observability/promtail/`, Grafana 데이터소스로 연결
- [x] 기본 대시보드와 의미 있는 알림 몇 개 — 기본 대시보드는 차트 제공, 알림은 `observability/kube-prometheus-stack/alerts.yaml` (ArgoCD 드리프트/헬스, sample-app down)

> 전부 GitOps로 배포된다 (`gitops/apps/`의 multi-source Application = 업스트림 차트 +
> 이 레포의 values). 차트 values 스키마는 실제 차트를 받아 키 존재를 검증했고, YAML은
> 전부 파싱 OK. 실제 클러스터에서 sync/scrape 되는지는 Phase 1·2와 함께 검증한다.
>
> 의도적으로 정한 것: **EKS 컨트롤플레인(etcd/scheduler/controller-manager)은 스크레이프
> 불가라 비활성화**(안 그러면 영구 red + 무의미한 알림), **PVC 없음**(EBS CSI 드라이버
> 미설치 → PVC는 Pending에서 멈춤, 게다가 매일 destroy). 영속화는 별도 작업.

## Phase 4 — DevSecOps ✅ (코드 완료 · 클러스터 검증 전)

목표: 보안 가드레일이 나중에 덧붙이는 게 아니라 자동으로 돌아가게 한다.

- [x] CI에서 Trivy 이미지 스캔 — `.github/workflows/security-ci.yml` (fixable CRITICAL 게이트, HIGH·IaC report-only)
- [x] Kyverno admission 정책 — `security/kyverno/policies/` (`:latest` 금지, resource 필수, non-root, privilege 제한). **Audit 모드**로 시작(→ 검증 후 Enforce)
- [x] kube-bench CIS 벤치마크 실행 — `security/kube-bench/job-eks.yaml` (`make kube-bench`)
- [x] 시크릿 관리 (External Secrets / SSM) — ESO(`gitops/apps/external-secrets.yaml`) + SSM read IRSA 역할(`terraform/environments/dev/external-secrets-irsa.tf`) + 예제

> Kyverno/ESO는 GitOps로 배포. 차트 버전은 실제 차트를 받아 스키마·키 존재를 검증했고,
> Kyverno 정책은 v1.18의 per-rule `validate.failureAction`(deprecated `spec.validationFailureAction` 아님)로 작성, terraform은 fmt/validate green. sample-app은 4개 정책 전부 통과하도록 설계됨.
> 실제 클러스터에서 admission/스캔/secret sync 되는지는 Phase 1~3과 함께 검증한다.
>
> **의도적 결정**: 정책은 Audit로 시작(Enforce 즉시 적용은 신뢰를 잃는 방식) + 인프라
> 네임스페이스 제외. Trivy 게이트는 fixable CRITICAL만(green main 유지). ESO의 SA↔IAM
> 연결은 계정별이라 example+문서로 제공.

---

### 스스로 지키는 원칙

- **매일 destroy.** EKS는 공짜가 아니다 — 배우려고 띄우고, 잘 땐 내린다.
- **모든 단계는 `main`을 green으로 유지.** 반쯤 깨진 상태로 merge하지 않는다.
- **정직한 상태 표시.** 체크박스는 계획이 아니라 실제로 동작하는 것을 반영한다.
