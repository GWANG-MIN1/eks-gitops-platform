# 로드맵

단계별로 만들어 나갑니다. 각 단계는 독립적으로 `apply` 가능하고, 저장소를 항상
동작하는 상태로 남깁니다. 체크박스는 작업이 실제로 반영될 때 갱신해서 상태를 항상
정직하게 유지합니다.

## Phase 1 — Terraform 기반 구성 ✅ (코드 완료 · apply 검증 전)

목표: `environments/dev`에서 `terraform apply` 하면 접근 가능한 EKS 클러스터가 뜬다.

- [x] Remote state 백엔드 (S3 + DynamoDB 잠금) — `terraform/bootstrap/`
- [x] VPC 모듈 (public/private 서브넷, NAT, 2개 이상 AZ)
- [x] EKS 모듈 (컨트롤 플레인 + managed node group)
- [x] 서비스 계정용 IAM(IRSA) 기본 구성 — EKS OIDC provider
- [x] CI에서 `terraform fmt` / `validate` 통과(green)

> 코드와 CI(fmt/validate)는 완료. 실제 `apply`로 라이브 클러스터를 띄우는 검증은
> 비용 때문에 필요할 때만 — 매일 destroy 원칙에 따라 계정에서 별도로 확인한다.
> (체크박스는 "코드+검증(fmt/validate) 완료"를 뜻하며, apply-tested를 뜻하지 않는다.)

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

## Phase 4 — DevSecOps ⬜

목표: 보안 가드레일이 나중에 덧붙이는 게 아니라 자동으로 돌아가게 한다.

- [ ] CI에서 Trivy 이미지 스캔
- [ ] Kyverno admission 정책 (`:latest` 금지, resource limit 필수 등)
- [ ] kube-bench CIS 벤치마크 실행
- [ ] 시크릿 관리 (External Secrets / SSM)

---

### 스스로 지키는 원칙

- **매일 destroy.** EKS는 공짜가 아니다 — 배우려고 띄우고, 잘 땐 내린다.
- **모든 단계는 `main`을 green으로 유지.** 반쯤 깨진 상태로 merge하지 않는다.
- **정직한 상태 표시.** 체크박스는 계획이 아니라 실제로 동작하는 것을 반영한다.
