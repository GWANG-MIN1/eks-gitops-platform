# Loki CrashLoopBackOff — "mkdir /var/loki: read-only file system"

- **발생**: 2026-07-20, Phase 2 검증 중
- **증상**: `loki-0` 파드가 `1/2 CrashLoopBackOff`, 재시작 8회. loki 컨테이너가
  기동 즉시 exit 1로 사망 반복.

## 진단

```bash
kubectl -n observability logs loki-0 -c loki --tail=30
```

```
mkdir /var/loki: read-only file system
error initialising module: ruler-storage
level=error ... msg="error running loki" err="mkdir /var/loki: read-only file system ..."
```

`kubectl describe pod loki-0`의 Mounts 목록을 보니 `/etc/loki/config`, `/rules`,
`/tmp`는 있는데 **`/var/loki`가 없었다.**

원인 조합:
1. 이 클러스터는 EBS CSI 드라이버가 없어 **`persistence.enabled: false`**로 구성
   (PVC를 만들면 영원히 Pending이므로 의도된 결정).
2. loki 차트는 persistence가 켜져 있을 때만 PVC를 `/var/loki`에 마운트한다.
   껐더니 **그 경로에 아무 볼륨도 남지 않았다.**
3. 컨테이너는 보안상 **read-only 루트 파일시스템**으로 돌기 때문에 Loki가
   `/var/loki`를 스스로 만들 수 없다 → 기동 실패.

## 해결 — Git 수정만으로 (GitOps 루프 실증)

`observability/loki/values.yaml`에 쓰기 가능한 임시 볼륨을 명시:

```yaml
singleBinary:
  persistence:
    enabled: false
  extraVolumes:
    - name: loki-data
      emptyDir: {}
  extraVolumeMounts:
    - name: loki-data
      mountPath: /var/loki
```

`git push` 이후 **kubectl 조작 없이** ArgoCD가 변경을 감지해 StatefulSet을
롤링 재배포했고, `loki-0`이 `2/2 Running`으로 복구됐다. 클러스터 장애를
Git 커밋으로 고친 첫 사례 — push→sync 루프의 실전 증명이기도 하다.

## 교훈

- **"persistence off"는 "볼륨 불필요"가 아니다.** 앱이 쓰는 경로에는 여전히
  쓰기 가능한 무언가(emptyDir)가 있어야 한다. read-only rootfs와 조합되면
  기동조차 못 한다.
- 차트의 기본 동작(PVC가 경로를 채워주는 것)을 끌 때는 **그 기본이 해주던
  일이 무엇인지**까지 따라가서 대체해야 한다.
- 로그 첫 줄(`mkdir ...: read-only file system`)이 이미 정답이었다 —
  CrashLoop은 `logs -c <container>`부터.
