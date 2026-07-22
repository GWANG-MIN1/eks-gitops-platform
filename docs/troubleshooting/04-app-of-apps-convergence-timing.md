# app-of-apps 수렴 타이밍 — "배포가 안 된 건가?" 착시

- **발생**: 2026-07-22, Phase 3 검증(클러스터 재생성) 중
- **증상**: `root-app.yaml` 적용 직후 여러 화면이 "고장난 것처럼" 보였다.
  - `kubectl -n observability get pods` → `No resources found`
  - `kubectl -n argocd get applications` → root만 나오고 자식 앱은 SYNC/HEALTH 칸이 **비어 있음**
  - 잠시 후엔 자식 앱이 `OutOfSync` / `Missing` / `Progressing` 상태

실제로는 **장애가 아니라 정상적인 수렴(convergence) 과정**이다. GitOps는 선언 →
실제 반영까지 시간차가 있고, 그 중간 상태가 알림처럼 보일 뿐이다.

## 왜 이렇게 보이나 (수렴 순서)

```
root-app apply
  → (1) root가 gitops/apps/의 자식 Application 7개를 "생성"  (SYNC/HEALTH 아직 빈칸)
  → (2) 각 자식 앱이 차트/매니페스트를 pull → 배포 시작        (Progressing)
  → (3) 네임스페이스·파드 생성                                (이때부터 pods 보임)
  → (4) 최종 8/8 Synced/Healthy
```

- kube-prometheus-stack은 CRD가 많아 (2)~(4)에 **수 분** 걸린다. 그동안
  `OutOfSync`/`Missing`으로 보이는 것은 "설치 진행 중"이라는 뜻.
- 특수 케이스: ArgoCD 설치 **직후 곧바로** root-app을 적용하면, repo-server가
  아직 안 떠서 첫 비교가 `Unknown`(`connection refused`)으로 남을 수 있다 —
  이것도 1~2분 내 자동 회복된다.

## "수렴 중"과 "진짜 멈춤"을 구별하는 법

기다리는 게 답이지만, 정말 멈춘 건지 확인하려면:

```bash
# 1) 앱들이 시간이 지나며 상태가 "변하는가" (Progressing -> Synced 로 진행되면 정상)
kubectl -n argocd get applications

# 2) 파드가 Pending에 오래 머물면 자리 부족일 수 있음 (별도 이슈 01 참고)
kubectl get pods -A | grep -iE "pending|crash"

# 3) 특정 앱이 계속 안 움직이면 이유를 직접 확인
kubectl -n argocd get application <name> -o jsonpath="{.status.conditions}{'\n'}"

# 4) 즉시 재시도를 걸고 싶으면 (3분 폴링을 기다리지 않고)
kubectl -n argocd annotate application <name> argocd.argoproj.io/refresh=normal --overwrite
```

판단 기준: **상태가 계속 변하고 있으면 → 기다린다.** 같은 상태로 10분 이상
정지 + Pending/Crash가 있으면 → 그때부터 실제 진단(이슈 01~03).

## 교훈

- **GitOps에서 "즉시 반영"을 기대하지 말 것.** 선언형은 수렴형이라, 중간 상태
  (빈칸/Progressing/OutOfSync)를 장애로 오해하기 쉽다. 처음엔 대부분 "더 기다리면
  되는" 상황이다.
- 조급하면 `argocd.argoproj.io/refresh` 어노테이션으로 폴링(기본 3분)을 앞당길 수
  있다 — 근본 해결이 아니라 관찰을 빠르게 하는 용도.
- 이 착시를 한 번 겪고 나면, 진짜 멈춘 상태(이슈 01의 `Too many pods`,
  02의 CrashLoop)와 구별하는 눈이 생긴다. 그게 이 기록의 목적.
