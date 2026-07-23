# kubectl "no such host" — 재생성된 클러스터와 낡은 kubeconfig

- **발생**: 2026-07-23, Phase 4 검증 시작(클러스터 재생성) 중
- **증상**: 모든 `kubectl` 명령이 실패. apply/rollout/get 전부 같은 에러:

```
Unable to connect to the server: dial tcp: lookup
9F52761B....gr7.ap-northeast-2.eks.amazonaws.com: no such host
```

## 진단

에러를 뜯어보면 답이 들어 있다:

- `dial tcp: lookup ...: no such host` — **DNS에 그 주소가 없다.** 방화벽/자격증명
  문제가 아니라, kubectl이 바라보는 API 엔드포인트 자체가 세상에 존재하지 않는다.
- 엔드포인트의 긴 ID(`9F52761B...`)는 **클러스터마다 새로 발급**된다. 어제
  검증에서 쓴 클러스터의 ID와 오늘 만든 클러스터의 ID는 다르다.

즉 kubectl은 **어제 `update-kubeconfig` 했던, 이미 destroy된 클러스터**를
가리키고 있었다. 이 프로젝트는 비용 때문에 매일 destroy → 다음 검증 때
재생성하는데, kubeconfig는 자동으로 따라오지 않는다.

확인 방법:

```bash
# 오늘 클러스터가 실제로 존재하는가?
aws eks list-clusters --region ap-northeast-2
# -> ["eks-gitops-dev"] 가 나오면 클러스터는 살아있고, kubeconfig만 낡은 것
```

## 해결

apply가 끝난 클러스터에 대해 kubeconfig를 갱신하면 끝:

```bash
aws eks update-kubeconfig --region ap-northeast-2 --name eks-gitops-dev
kubectl get nodes   # 노드가 보이면 해결
```

(클러스터가 아예 없었다면 — `list-clusters`가 빈 목록 — 그건 apply를 아직 안 한
것이므로 `terraform apply`부터.)

## 교훈

- **destroy/재생성 환경에서 `update-kubeconfig`는 "계정당 1회"가 아니라
  "apply마다 1회"다.** 클러스터 이름(`eks-gitops-dev`)은 같아도 엔드포인트는
  매번 바뀐다.
- `no such host`는 네트워크 장애처럼 보이지만, 이 워크플로우에선 십중팔구
  "죽은 클러스터를 가리키는 kubeconfig"다. `aws eks list-clusters` 한 줄로
  즉시 판별된다.
- 재생성 루틴을 스크립트/Makefile로 묶는다면 apply 직후에 update-kubeconfig를
  포함시키는 게 안전하다 (사람이 까먹는 단계는 자동화가 답).
