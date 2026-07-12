# 아키텍처

목표로 하는 설계와 그 이유를 정리한 문서입니다. 각 단계가 구현되면서 계속 채워지는
살아있는(living) 문서입니다.

## 개요

플랫폼은 네 개의 레이어로 나뉘고, 각 레이어를 서로 다른 도구가 맡아 책임이 겹치지
않게 했습니다.

| 레이어 | 담당 도구 | 책임 |
|--------|-----------|------|
| Infrastructure | Terraform | VPC, EKS 컨트롤 플레인, 노드 그룹, IAM |
| Delivery | ArgoCD (GitOps) | Git의 상태를 클러스터에 반영(reconcile) |
| Observability | Prometheus / Grafana / Loki | 메트릭, 대시보드, 로그, 알림 |
| Security | Trivy / Kyverno / kube-bench | 이미지 스캔, admission 정책, CIS 점검 |

## 왜 이렇게 나눴나

- **Terraform은 클러스터 경계까지만 담당합니다.** EKS 클러스터와 그 주변 클라우드
  리소스(VPC, IAM, 노드 그룹)를 프로비저닝하지만, 클러스터 *안*의 워크로드는 관리하지
  않습니다. 그건 GitOps의 몫입니다. 둘을 섞으면(예: Terraform에서 Helm release 배포)
  느린 클라우드 상태와 빠른 앱 상태가 엉켜서 롤백이 괴로워집니다.
- **클러스터 안의 모든 것은 ArgoCD가 관리합니다** — *app-of-apps* 패턴을 씁니다.
  하나의 root `Application`이 `gitops/apps/`를 가리키고, 그 아래의 각 child Application이
  하나의 관심사(observability 스택, security 스택, 샘플 워크로드)를 맡습니다. Git이
  단일 진실 공급원(single source of truth)이고, `git revert`가 곧 롤백입니다.
- **Observability와 security도 손으로 붙이는 게 아니라 GitOps를 *통해* 배포**됩니다 —
  그래서 나머지 모든 것과 마찬가지로 재현 가능하고 추적 가능합니다.

## 네트워크 설계 (Phase 1)

- 하나의 VPC에 public / private 서브넷을 2개 이상의 AZ에 걸쳐 배치합니다.
- EKS 노드는 **private** 서브넷에 두고, load balancer만 public 서브넷에 둡니다.
- 아웃바운드용 NAT gateway를 사용하고, NAT 비용 절감을 위한 VPC endpoint는 이후 검토합니다.

## 배포 흐름 (Phase 2)

```
개발자 → git push → ArgoCD가 drift 감지 → sync → 클러스터가 수렴(converge)
```

## 열어둔 질문 / 다시 볼 결정들

- autoscaling: managed node group vs. Karpenter
- admission 정책: Kyverno vs. OPA/Gatekeeper
- Loki 스토리지 백엔드(S3) 용량 산정과 보존(retention) 기간

_이 항목들은 일부러 열어뒀습니다 — 해당 단계를 구현하면서 답을 채웁니다._
