# t3.medium의 max-pods=17 한계 — "Too many pods"

- **발생**: 2026-07-20, Phase 2 검증 중
- **증상**: Helm hook Job 2개(`kyverno-migrate-resources`, `kube-prometheus-stack-admission-create`)가
  10분 이상 `Pending`. 그 여파로 kyverno / kube-prometheus-stack Application이 `OutOfSync`에서 멈춤.

## 진단

```bash
kubectl -n kyverno describe pod kyverno-migrate-resources-xxxxx
```

Events에 원인이 그대로 적혀 있었다:

```
Warning  FailedScheduling  ...  0/2 nodes are available: 2 Too many pods.
                                preemption: 0/2 nodes are available:
                                2 No preemption victims found for incoming pod.
```

CPU/메모리 부족이 아니라 **파드 개수 상한**. AWS VPC CNI는 파드마다 VPC IP를
할당하는데, 인스턴스 타입별로 ENI×IP 수가 정해져 있다. **t3.medium은 노드당
최대 17개 파드**. 당시 전체 파드를 세어보니 34개 = 17 × 2노드, 정확히 만석이었다.

## 해결

노드를 3대로 확장. 여기서 두 번째 함정:

```bash
terraform apply -var="node_desired_size=3"
# → "No changes. Your infrastructure matches the configuration."
```

**Terraform이 변경을 인식하지 못한다.** terraform-aws-modules/eks는
`scaling_config[0].desired_size`를 `ignore_changes`로 두는데, 오토스케일러
(Karpenter/CA)가 조절하는 값을 Terraform이 되돌리며 싸우지 않게 하려는
의도적 설계다. 생성 이후의 노드 수는 Terraform 관할이 아니므로 AWS API로 직접 조정:

```bash
aws eks update-nodegroup-config --cluster-name eks-gitops-dev \
  --nodegroup-name <nodegroup-name> --scaling-config desiredSize=3 \
  --region ap-northeast-2
```

새 노드가 약 2분 만에 `Ready`가 되었고, Pending 파드 2개가 즉시 스케줄되며
Application들도 정상 sync로 진행됐다.

## 교훈

- **인스턴스 타입이 파드 밀도를 결정한다.** 작은 노드 여러 대는 CPU/메모리보다
  IP 한도에 먼저 부딪힐 수 있다. 파드 수가 많은 스택(관측성+보안)을 얹을 땐
  `노드수 × max-pods`부터 계산할 것.
- **`desired_size`는 apply로 안 바뀐다** (ignore_changes). day-2 노드 스케일은
  `aws eks update-nodegroup-config` 또는 오토스케일러의 몫.
- 장기적 대안: 노드 증설 대신 **VPC CNI prefix delegation**을 켜면 노드당
  max-pods를 크게 올릴 수 있다 (후속 과제).
