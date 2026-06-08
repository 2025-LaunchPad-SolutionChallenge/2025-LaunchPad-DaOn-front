# 2026-05-31 작업 정리 (Front 팀 공유용)

## 목적
- 오늘 인증/회원 관련 플로우를 백엔드 중심으로 정리했고, 프론트 연동 포인트를 맞추는 작업을 진행함.
- 특히 `withdraw`(회원탈퇴) API 스펙이 변경되어 프론트 후속 구현이 필요함.

---

## 1) 로그인/회원가입 플로우 변경 사항

### 프론트 로그인 플로우
- Google/Firebase 로그인 성공 후 `firebaseToken` 획득
- `POST /api/v1/auth/login` 호출
  - `200`이면 토큰 저장 후 홈 이동
  - `404 (USER_NOT_FOUND)`이면 추가 입력 없이 `POST /api/v1/auth/register` 즉시 호출
- register 성공 시 토큰 저장 후 홈 이동

### register 요청 스펙
- 현재 register는 아래 요청도 허용:
```json
{
  "firebaseToken": "..."
}
```
- `name`, `birthDate`는 optional

---

## 2) 백엔드 register 관련 반영 내용

- `name`/`birthDate` optional 처리
- `name` 미입력 시 Firebase 토큰의 `name`/`display_name` 사용 (없으면 null)
- `birthDate` 미입력 시 null 저장
- Google 토큰에서 `email`, `picture` 추출해 DB 저장
- DB 변경:
  - `Users.name` nullable
  - `Users.email` nullable 컬럼 추가

---

## 3) withdraw API 스펙 변경 (중요)

### 변경된 요청 형태
```
DELETE /api/v1/auth/withdraw
Authorization: Bearer {accessToken}
Body: 없음
```

### 백엔드 동작
- accessToken에서 `sub(user_id)`, `firebase_uid` 추출
- 해당 `firebase_uid` Firebase Admin SDK로 삭제 시도
- DB 유저 삭제
- 해당 유저 refresh 세션 전체 무효화(블랙리스트)

---

## 4) 프론트 후속 작업 필요 사항 (핵심)

## 🚨 아직 프론트에서 `withdraw` API 호출 구현이 없음
- 현재 프론트 코드 기준으로 `DELETE /api/v1/auth/withdraw`를 실제 호출하는 로직이 없음.
- 그래서 "DB는 삭제됐는데 Firebase는 안 지워진다" 같은 상황 검증이 프론트 기준으로는 정확히 수행되지 않음.

### 프론트 팀에서 구현해야 할 내용
- 마이페이지(또는 설정)에서 회원탈퇴 액션 시:
  1. `DELETE /api/v1/auth/withdraw` 호출 (Body 없이)
  2. Header에 `Authorization: Bearer {accessToken}` 포함
  3. 성공 시 로컬 `access_token`, `refresh_token`, `token_type` 삭제
  4. 로그인 화면으로 이동
  5. 실패 코드별 사용자 안내 (`UNAUTHORIZED`, 서버오류 등)

---

## 5) 참고 사항

- 기존에 withdraw 테스트를 위해 토큰 출력용 디버그 버튼을 사용했음.
- 현재 상태는 **클립보드 복사 로직 제거**되어 있고, 버튼 누르면 터미널 로그 출력만 함.

---

## 6) 권장 체크리스트 (프론트 구현 후)

- [ ] 로그인(기존 유저) 정상
- [ ] 로그인 404 시 자동 register 정상
- [ ] 탈퇴 호출 시 200 응답 확인
- [ ] 탈퇴 후 재로그인 시 `USER_NOT_FOUND` 확인
- [ ] 탈퇴 후 refresh 재사용 시 `REVOKED_REFRESH_TOKEN` 확인

