# CRD 영구 OutOfSync — k8s 1.30이 selectableFields를 버린다

- **발생**: 2026-07-20, Phase 2 검증 중
- **증상**: kyverno(11개 CRD)와 external-secrets(1개 CRD) Application이 `Healthy`인데
  `OutOfSync`에서 영원히 안 빠짐. hard refresh로도 해소 안 됨.

## 진단 과정 (가설 → 반증 → 확정)

**1) 어떤 리소스가 걸렸는지 좁히기:**

```bash
kubectl -n argocd get application kyverno -o jsonpath=\
"{range .status.resources[?(@.status=='OutOfSync')]}{.kind}/{.name}{'\n'}{end}"
# → 전부 CustomResourceDefinition, 그중에서도 policies.kyverno.io 그룹만
```

**2) 1차 가설(웹훅 caBundle 주입)은 반증됨** — 라이브 CRD의
`spec.conversion.webhook.clientConfig.caBundle`이 비어 있었다. 추측을 버리고
실제 diff를 봐야 했다.

**3) ArgoCD UI의 DIFF 탭**에서 실마리: `selectableFields`가 한쪽에만 존재,
`labels: {}` / `annotations: {}`도 diff로 표시.

**4) 원본 대조 — 차트(desired) vs 라이브(cluster):**

```bash
# desired: 차트 템플릿에 selectableFields 존재
tar -xzO kyverno/.../policies.kyverno.io_validatingpolicies.yaml < kyverno-3.8.2.tgz \
  | grep -c selectableFields    # → 3

# live: API 서버가 저장한 CRD에는 없음
kubectl get crd validatingpolicies.policies.kyverno.io -o yaml \
  | grep -c selectableFields    # → 0

kubectl version   # Server: v1.30.14-eks
```

**확정된 원인 2가지:**

1. **`spec.versions[].selectableFields`는 k8s 1.31+ 기능.** 차트(kyverno v1.18,
   ESO v2.7)가 생성한 CRD에는 들어있지만, **1.30 API 서버는 모르는 필드라서
   조용히 버린다.** Git에는 있고 클러스터에는 영원히 없으니 diff가 못 사라짐.
2. (kyverno만 추가로) kyverno-api 서브차트가 CRD metadata에 **빈 맵을 문자
   그대로 렌더링**(`labels: {}` / `annotations: {}`). API 서버는 빈 맵을
   저장하지 않고 필드를 없애므로, server-side apply diff가 이를 영구 차이로
   본다.

## 해결

두 Application에 `ignoreDifferences` + `RespectIgnoreDifferences` 추가
(`gitops/apps/kyverno.yaml`, `gitops/apps/external-secrets.yaml`):

```yaml
ignoreDifferences:
  - group: apiextensions.k8s.io
    kind: CustomResourceDefinition
    jqPathExpressions:
      - .spec.versions[].selectableFields
    jsonPointers:            # kyverno만 — 차트가 실제 값을 안 넣는 필드라 잃는 것 없음
      - /metadata/labels
      - /metadata/annotations
syncPolicy:
  syncOptions:
    - RespectIgnoreDifferences=true   # 무시하기로 한 필드를 sync 때 재적용하지도 않음
```

push 후 external-secrets는 selectableFields 무시만으로 `Synced`,
kyverno는 metadata 무시까지 추가해 `Synced` — 최종 8/8 Synced/Healthy 달성.

## 교훈

- **차트가 만든 CRD와 클러스터 버전의 skew**는 "영구 OutOfSync"라는 형태로
  나타난다. API 서버는 모르는 필드를 에러 없이 버리므로 겉으로는 멀쩡하다.
- 진단은 **가설이 아니라 증거로**: OutOfSync 리소스 목록 → UI diff → 차트
  원본과 라이브를 직접 대조. 1차 가설(caBundle)은 확인 명령 한 줄로 기각됐다.
- `ignoreDifferences`는 마지막 수단이되, **왜 무시하는지 주석으로 남길 것.**
  클러스터를 1.31+로 올리면 selectableFields 항목은 제거해야 한다 (재검토 트리거).
