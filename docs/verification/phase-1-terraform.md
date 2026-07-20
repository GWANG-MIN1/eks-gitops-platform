# Phase 1 검증 기록 — Terraform 기반 구성

- **일시**: 2026-07-20
- **환경**: 실계정 (ap-northeast-2), Terraform v1.14.3, EKS 1.30
- **결과**: ✅ 전 항목 통과

## 검증 흐름

```bash
# 1. remote state 백엔드 (계정당 1회)
cd terraform/bootstrap
terraform init && terraform apply          # S3 버킷 + DynamoDB 잠금테이블

# 2. dev 환경
cd ../environments/dev
cp backend.hcl.example backend.hcl         # bootstrap output으로 채움 (git-ignored)
terraform init -backend-config=backend.hcl
terraform plan
terraform apply                            # ~15-20분

# 3. 접속
aws eks update-kubeconfig --region ap-northeast-2 --name eks-gitops-dev
```

## 항목별 결과

| 로드맵 항목 | 확인 방법 | 결과 |
|------------|-----------|------|
| EKS + managed node group | `kubectl get nodes` | 노드 2개 `Ready` (v1.30.14-eks), INTERNAL-IP 사설대역 ✅ |
| 코어 애드온 | `kubectl get pods -n kube-system` | coredns / aws-node / kube-proxy / eks-pod-identity-agent 전부 Running ✅ |
| VPC (≥2 AZ) | `aws ec2 describe-subnets --filters "Name=tag:Name,Values=eks-gitops-dev-vpc*"` | 서브넷 4개(private 2 + public 2)가 `2a`/`2c` 분산 ✅ |
| Remote state | `aws s3 ls s3://<state-bucket>/dev/` | `terraform.tfstate` 존재 (S3 저장 확인) ✅ |
| IRSA (OIDC) | `aws iam list-open-id-connect-providers` | `oidc.eks.ap-northeast-2...` provider 생성됨 ✅ |

## 메모

- apply 도중 특이사항 없음. SPOT 노드 2대 정상 기동.
- `terraform destroy` → 다음 날 `apply` 재현이 가능한 상태(멱등) 확인 — 매일 destroy 원칙 유지.
- backend.hcl / tfvars 등 계정 종속 파일은 git-ignore로 레포에 남지 않음.

## 검증 중 만난 사소한 것들

- `aws` CLI 조회 시 `--region ap-northeast-2` 누락하면 기본 리전으로 조회되어 빈 결과가 나옴 → 리전 명시 습관화.
- PowerShell에서는 bash식 `\` 줄바꿈이 동작하지 않음 → 명령은 한 줄로.
