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

> **2026-07-20 실계정 검증 완료** — 상세 기록: [verification/phase-1-terraform.md](verification/phase-1-terraform.md)

## Phase 2 — ArgoCD 기반 GitOps ✅ (라이브 sync 검증 완료)

목표: 클러스터 상태를 Git에 선언하고 자동으로 반영한다.

- [x] ArgoCD 설치 (bootstrap manifest) — `gitops/bootstrap/argocd/` (kustomize, v2.13.4 고정)
- [x] app-of-apps root Application — `gitops/bootstrap/root-app.yaml`
- [x] GitOps로 샘플 워크로드 배포 — `gitops/apps/sample-app`
- [x] push → sync 흐름 문서화 — `gitops/README.md`

> **2026-07-20 라이브 검증 완료** — 8/8 Application Synced/Healthy, push→sync
> 왕복 실증. 상세 기록: [verification/phase-2-gitops.md](verification/phase-2-gitops.md) ·
> 검증 중 잡은 이슈 3건: [troubleshooting/](troubleshooting/)

## Phase 3 — Observability ✅ (라이브 검증 완료)

목표: 메트릭, 대시보드, 로그를 수동 설정 없이 바로 볼 수 있게 한다.

- [x] kube-prometheus-stack (Prometheus + Grafana + Alertmanager) — `observability/kube-prometheus-stack/` (차트 87.16.1 고정)
- [x] 로그 집계용 Loki — `observability/loki/` (SingleBinary) + `observability/promtail/`, Grafana 데이터소스로 연결
- [x] 기본 대시보드와 의미 있는 알림 몇 개 — 기본 대시보드는 차트 제공, 알림은 `observability/kube-prometheus-stack/alerts.yaml` (ArgoCD 드리프트/헬스, sample-app down)

> **2026-07-22 라이브 검증 완료** — Prometheus 타겟 up(+ArgoCD ServiceMonitor 3종),
> `argocd_app_info` 8 series, Grafana mixin 대시보드 자동배포+실데이터, Loki에서
> `{namespace="sample-app"}` 398줄 조회, 커스텀 알림 3종(platform.*) 로드 확인.
> 상세: [verification/phase-3-observability.md](verification/phase-3-observability.md)
> (알림 실제 Firing 검증은 다음 세션 과제). 수렴 타이밍 착시=[troubleshooting/04](troubleshooting/04-app-of-apps-convergence-timing.md).
>
> 의도적으로 정한 것: **EKS 컨트롤플레인(etcd/scheduler/controller-manager)은 스크레이프
> 불가라 비활성화**(안 그러면 영구 red + 무의미한 알림), **PVC 없음**(EBS CSI 드라이버
> 미설치 → PVC는 Pending에서 멈춤, 게다가 매일 destroy). 영속화는 별도 작업.

## Phase 4 — DevSecOps ✅ (라이브 검증 완료)

목표: 보안 가드레일이 나중에 덧붙이는 게 아니라 자동으로 돌아가게 한다.

- [x] CI에서 Trivy 이미지 스캔 — `.github/workflows/security-ci.yml` (fixable CRITICAL 게이트, HIGH·IaC report-only)
- [x] Kyverno admission 정책 — `security/kyverno/policies/` (`:latest` 금지, resource 필수, non-root, privilege 제한). **Audit 모드**로 시작(→ 검증 후 Enforce)
- [x] kube-bench CIS 벤치마크 실행 — `security/kube-bench/job-eks.yaml` (`make kube-bench`)
- [x] 시크릿 관리 (External Secrets / SSM) — ESO(`gitops/apps/external-secrets.yaml`) + SSM read IRSA 역할(`terraform/environments/dev/external-secrets-irsa.tf`) + 예제

> **2026-07-23 라이브 검증 완료** — Kyverno가 bad-pod(`:latest`, root, 리소스없음)에
> FAIL 4건 기록(sample-app은 PASS 5/FAIL 0), kube-bench EKS 리포트 수령,
> **IRSA 전체 체인 실측**(Terraform 역할 → SA 어노테이션 → ClusterSecretStore
> `Valid` → SSM 값이 K8s Secret으로 `SecretSynced`), Trivy CI는 CVE 차단→수정→통과
> 이력으로 증명. 상세: [verification/phase-4-devsecops.md](verification/phase-4-devsecops.md) ·
> kubeconfig 함정 = [troubleshooting/05](troubleshooting/05-stale-kubeconfig-after-recreate.md)
>
> **의도적 결정**: 정책은 Audit로 시작(Enforce 즉시 적용은 신뢰를 잃는 방식) + 인프라
> 네임스페이스 제외. Trivy 게이트는 fixable CRITICAL만(green main 유지). ESO의 SA↔IAM
> 연결은 계정별이라 example+문서로 제공. 후속: Audit→Enforce 전환, kube-bench FAIL
> 1건 조치, Grafana를 grafana-admin Secret에 연결, SampleAppDown Firing 실증.

---

### 스스로 지키는 원칙

- **매일 destroy.** EKS는 공짜가 아니다 — 배우려고 띄우고, 잘 땐 내린다.
- **모든 단계는 `main`을 green으로 유지.** 반쯤 깨진 상태로 merge하지 않는다.
- **정직한 상태 표시.** 체크박스는 계획이 아니라 실제로 동작하는 것을 반영한다.
