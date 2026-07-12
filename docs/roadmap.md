# 로드맵

단계별로 만들어 나갑니다. 각 단계는 독립적으로 `apply` 가능하고, 저장소를 항상
동작하는 상태로 남깁니다. 체크박스는 작업이 실제로 반영될 때 갱신해서 상태를 항상
정직하게 유지합니다.

## Phase 1 — Terraform 기반 구성 🚧

목표: `environments/dev`에서 `terraform apply` 하면 접근 가능한 EKS 클러스터가 뜬다.

- [ ] Remote state 백엔드 (S3 + DynamoDB 잠금)
- [ ] VPC 모듈 (public/private 서브넷, NAT, 2개 이상 AZ)
- [ ] EKS 모듈 (컨트롤 플레인 + managed node group)
- [ ] 서비스 계정용 IAM(IRSA) 기본 구성
- [ ] CI에서 `terraform fmt` / `validate` 통과(green)

## Phase 2 — ArgoCD 기반 GitOps ⬜

목표: 클러스터 상태를 Git에 선언하고 자동으로 반영한다.

- [ ] ArgoCD 설치 (bootstrap manifest)
- [ ] app-of-apps root Application
- [ ] GitOps로 샘플 워크로드 배포
- [ ] push → sync 흐름 문서화

## Phase 3 — Observability ⬜

목표: 메트릭, 대시보드, 로그를 수동 설정 없이 바로 볼 수 있게 한다.

- [ ] kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
- [ ] 로그 집계용 Loki
- [ ] 기본 대시보드와 의미 있는 알림 몇 개

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
