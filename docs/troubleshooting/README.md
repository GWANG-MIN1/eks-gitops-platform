# 트러블슈팅 기록

라이브 클러스터 검증 중 실제로 만난 문제들. 전부 **클러스터에서 진단 →
Git 수정 → push → ArgoCD 자동 반영**으로 해결했다 (`kubectl edit` 0회).

| # | 문제 | 한 줄 요약 |
|---|------|-----------|
| [01](01-max-pods-t3-medium.md) | Too many pods | t3.medium은 노드당 파드 17개가 상한 — CPU보다 IP 한도가 먼저 만석 |
| [02](02-loki-read-only-filesystem.md) | Loki CrashLoop | persistence를 끄면 `/var/loki`에 아무도 볼륨을 안 꽂아준다 + read-only rootfs |
| [03](03-crd-permanent-outofsync.md) | CRD 영구 OutOfSync | k8s 1.30이 1.31+ 필드(`selectableFields`)를 조용히 버려서 Git과 영원히 불일치 |

작성 형식: 증상 → 진단 과정(명령·출력 포함) → 해결 → 교훈.
