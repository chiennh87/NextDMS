# Branch Protection Rules

Hướng dẫn cấu hình Branch Protection Rules trên GitHub.

## Cấu hình qua GitHub UI

### Bước 1: Vào Settings > Branches
- Repository → **Settings** → **Branches** → **Add branch protection rule**

### Bước 2: Cấu hình cho main branch

**Branch name pattern:** `main`

#### ✅ Enable these options:

| Tùy chọn | Mô tả |
|----------|--------|
| **Require a pull request before merging** | Bắt buộc tạo PR trước khi merge |
| **Require approvals** | Cần tối thiểu 2 approvers |
| **Dismiss stale pull request approvals** | Hủy approval cũ khi có commit mới |
| **Require review from Code Owners** | Yêu cầu review từ code owner |
| **Require status checks to pass** | Bắt buộc CI pass |
| **Require branches to be up to date** | Branch phải update trước khi merge |
| **Require linear history** | Rebase thay vì merge commit |
| **Include administrators** | Áp dụng cả cho admin |
| **Restrict who can push** | Chỉ owner được push trực tiếp |
| **Allow force pushes** | ❌ TẮT |
| **Allow deletions** | ❌ TẮT |

#### Status checks required:
- `Lint Code`
- `Run Tests`
- `Build Docker Image`

### Bước 3: Cấu hình cho develop branch

**Branch name pattern:** `develop`

| Tùy chọn | Mô tả |
|----------|--------|
| **Require a pull request before merging** | Bắt buộc tạo PR |
| **Require approvals** | Cần tối thiểu 1 approver |
| **Require status checks to pass** | Bắt buộc CI pass |
| **Allow force pushes** | ✅ BẬT (cho hotfix) |

## Cấu hình qua GitHub CLI (Advanced)

```bash
# Cài đặt GitHub CLI
# https://cli.github.com/

# Login
gh auth login

# Cấu hình branch protection cho main
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/OWNER/REPO/branches/main/protection \
  -F required_status_checks[strict]=true \
  -F required_status_checks[checks][][context]=Lint \
  -F required_status_checks[checks][][context]=Test \
  -F enforce_admins=true \
  -F required_pull_request_reviews[dismiss_stale_reviews]=true \
  -F required_pull_request_reviews[require_code_owner_reviews]=true \
  -F required_pull_request_reviews[required_approving_review_count]=2 \
  -F restrictions=null
```

## Workflow cho Contributors

1. **Tạo branch từ `develop`:**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/my-feature
   ```

2. **Push và tạo PR:**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   git push origin feature/my-feature
   # Tạo PR trên GitHub: feature/my-feature -> develop
   ```

3. **Sau khi PR merge vào develop và được test:**
   - Tạo PR từ `develop` → `main`
   - Cần 2 approvals
   - Status checks phải pass
   - Squash merge

## Commit Message Convention

Sử dụng [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semi colons, etc.
- `refactor`: Refactoring production code
- `test`: Adding tests
- `chore`: Updating build tasks, package manager configs, etc.

### Examples:
```bash
feat(orders): add new order validation
fix(cache): resolve race condition in stock check
docs(readme): update deployment guide
test(usecase): add unit tests for order creation
```