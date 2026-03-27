# Skill: Review — Phản biện logic & chất lượng

## Khi nào dùng
- Review code trước khi merge
- Kiểm tra chất lượng sau khi refactor
- Đánh giá PR/commit
- User yêu cầu review

## Review Process

### Step 1: Đọc hiểu scope

- Thay đổi ảnh hưởng những file/module nào?
- Mục đích của thay đổi là gì?
- Có đúng scope yêu cầu không? (không thêm/bớt ngoài yêu cầu)

### Step 2: Kiểm tra 4C

Dùng framework 4C từ `skills/verification/SKILL.md`:
- **Correctness**: Logic đúng?
- **Completeness**: Đủ file, đủ state handling?
- **Context-fit**: Đúng convention dự án?
- **Consequence**: Rủi ro deploy?

### Step 3: Performance Review

Kiểm tra theo performance checklist:

```
[ ] KHÔNG tạo Repository() trực tiếp — dùng provider         [HIGH]
[ ] invalidate() truyền đúng parameter .family                [HIGH]
[ ] CachedNetworkImage có memCacheWidth                       [HIGH]
[ ] ListView dùng .builder / .separated                       [HIGH]
[ ] TabBarView + ListView có AutomaticKeepAliveClientMixin    [HIGH]
[ ] Search input có debounce (300ms)                          [MEDIUM]
[ ] Animation max 2 effects, stagger max 5                    [MEDIUM]
[ ] Dispose tất cả controllers                                [MEDIUM]
[ ] ref.watch trong build, ref.read trong callback            [MEDIUM]
[ ] Dùng select() khi chỉ cần 1 field                        [LOW]
[ ] const constructor cho static widgets                      [LOW]
[ ] Check mounted trước setState trong async                  [LOW]
```

### Step 4: Anti-pattern Check

Scan code cho các anti-patterns:

```
[ ] Không có Color(0xFF...) hardcode?
[ ] Không có duplicate logic (nên dùng AppHelpers)?
[ ] Không có setState trong ConsumerWidget?
[ ] Không có import chéo giữa features?
[ ] Không có Dio() instance mới?
[ ] Không có throw exception từ Repository?
[ ] Không có private widget dùng chung trong view?
[ ] Không có ref.read(derivedProvider) trong GoRouter redirect?
```

### Step 5: Output Review Report

Format báo cáo:

```markdown
## Review: [Tên thay đổi]

### Summary
[1-2 câu mô tả thay đổi]

### Issues Found
- **[CRITICAL]** [mô tả] — file:line
- **[HIGH]** [mô tả] — file:line
- **[MEDIUM]** [mô tả] — file:line
- **[LOW]** [mô tả] — file:line

### Suggestions
- [Gợi ý cải thiện nếu có]

### Verdict
✅ PASS / ⚠️ PASS WITH NOTES / ❌ NEEDS FIX
```

## Severity Levels

| Level | Mô tả | Action |
|-------|-------|--------|
| **CRITICAL** | Bug chắc chắn xảy ra, crash, data loss | PHẢI fix trước khi merge |
| **HIGH** | Performance issue, memory leak, wrong logic | Nên fix trước merge |
| **MEDIUM** | Convention violation, missing edge case | Fix nếu có thời gian |
| **LOW** | Code style, optimization nhỏ | Nice-to-have |

## Quick Review (cho task nhỏ)

```
[ ] Logic đúng yêu cầu?
[ ] Không break existing flow?
[ ] Đúng convention? (AppColors, AppHelpers, const, provider)
[ ] Không có anti-pattern?
→ PASS / NEEDS FIX
```
