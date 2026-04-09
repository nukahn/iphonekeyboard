# ipad keyboard — 개발 Phase 구조

## Phase 1: 앱 이름 변경 + 문서 생성 ✅
## Phase 2: 배너 광고 (Google AdMob + SPM) ✅
## Phase 3: 실시간 키 입력 스트리밍 ✅
## Phase 4: 커서 이동 / 선택 / 복사·붙여넣기 ✅
## Phase 5: 에러 핸들링 ✅
## Phase 6: 로컬라이제이션 (한국어 + 영어) ✅
## Phase 7: 앱 아이콘 ✅
## Phase 8: 유닛 테스트 ✅

---

## Phase 9: AdMob 실제 ID 설정 및 광고 검증

> 우선순위 1 — 코드 완성 후 첫 번째 작업

### AdMob 계정 설정
- [ ] Google AdMob 콘솔 (admob.google.com) 접속
- [ ] 새 앱 등록 → iOS → 앱 이름 "ipad keyboard"
- [ ] 앱 ID 발급 (형식: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`)
- [ ] 배너 광고 단위 생성 → 광고 단위 ID 발급 (형식: `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`)

### 코드 교체
- [ ] `project.yml` → `GADApplicationIdentifier`: 실제 앱 ID로 교체
- [ ] `RemoteKeyboard/Ads/AdManager.swift` → `bannerAdUnitID`: 실제 광고 단위 ID로 교체

### 광고 동작 검증 (시뮬레이터)
- [ ] `xcodegen generate` 후 빌드
- [ ] 시뮬레이터에서 iPhone 뷰 상단 배너 광고 노출 확인
- [ ] 시뮬레이터에서 iPad 뷰 상단 배너 광고 노출 확인
- [ ] 광고 로드 실패 시 배너 숨김 동작 확인

---

## Phase 10: 테스트 코드 품질 검사 + 로지컬 테스트

> 우선순위 2 — TestFlight 배포 전 품질 보증

### 10-1. 테스트 코드 품질 검사

**커버리지 분석**
- [ ] Xcode → Product → Test (⌘U) 실행
- [ ] Report Navigator → Coverage 탭에서 SharedKit 커버리지 확인 (목표: 80%+)
- [ ] 미커버 분기 식별 및 테스트 보완

**정적 분석**
- [ ] Xcode → Product → Analyze (⇧⌘B) 실행
- [ ] 경고 0건 달성 (메모리 누수, 미사용 변수, nil 역참조 등)

**테스트 견고성 검토**
- [ ] 각 테스트가 독립적으로 실행 가능한지 확인 (setUp/tearDown 격리)
- [ ] 테스트 간 공유 상태(static, singleton) 오염 여부 점검
- [ ] 비동기 타이밍 의존 테스트 없는지 확인

### 10-2. 로지컬 테스트 시나리오

아래 시나리오는 코드 레벨에서 논리적으로 검증한다 (실기기 불필요).

**메시지 프로토콜 로직**
- [ ] 빈 페이로드 메시지 파싱 시 크래시 없는지 확인
- [ ] deleteN에 0 전달 시 동작 확인
- [ ] 알 수 없는 MessageType prefix(0xFF 등) 수신 시 무시 동작 확인
- [ ] 매우 긴 텍스트(10,000자+) 인코딩/디코딩 정확성

**SharedStorage 로직**
- [ ] save → read → clear → read 순서 검증
- [ ] 타임스탬프 단조증가 보장 (동시 저장 시)
- [ ] App Group UserDefaults 초기화 실패 시 nil 안전 처리

**연결 상태 기계 로직**
- [ ] disconnected → searching → connecting → connected 순서 검증
- [ ] connected 상태에서 피어 추가 연결 시 상태 유지
- [ ] reconnect 지수 백오프 딜레이 값 검증 (1s → 2s → 4s → ... → 30s)

**실시간 스트리밍 델타 로직**
- [ ] 순수 삽입 (range.length == 0) 처리
- [ ] 순수 삭제 (replacementString == "") 처리
- [ ] 한글 조합 교체 (range.length > 0, string != "") 처리
- [ ] 빈 문자열 삽입 → 전송 없음 확인

**에러 핸들링 로직**
- [ ] send() 실패 → errorMessage 설정 → clearError() → nil 복귀
- [ ] 연속 reconnect 시 delay가 30s를 초과하지 않는지 확인

### 10-3. 추가 테스트 파일 작성 (필요 시)

- `ConnectionStateTests.swift`: 상태 기계 전이 검증
- `StreamingDeltaTests.swift`: 델타 계산 로직 검증 (StreamingTextView 분리 가능한 순수 함수)

---

## Phase 11: TestFlight 배포 + 실기기 테스트

> Phase 9, 10 완료 후 진행

### 사전 준비
- [ ] Apple Developer Program 계정 활성화 확인
- [ ] Xcode 코드 서명 설정 (App Group entitlement 포함 Provisioning Profile)
  - 메인 앱: `com.remotekeyboard.app`
  - 키보드 익스텐션: `com.remotekeyboard.app.keyboard`
- [ ] App Store Connect 앱 등록 (번들 ID: `com.remotekeyboard.app`)
- [ ] 개인정보 처리방침 URL 등록 (ATT 사용 → Apple 심사 필수)

### TestFlight 빌드 업로드
- [ ] Xcode → Product → Archive
- [ ] Xcode Organizer → Distribute App → App Store Connect
- [ ] App Store Connect → TestFlight → 빌드 처리 완료 대기
- [ ] 내부 테스터 초대 → TestFlight 앱 설치

### 실기기 테스트 항목
- [ ] iPhone ↔ iPad Multipeer 연결
- [ ] 실시간 타이핑 (영어/한글) → iPad 즉시 반영
- [ ] 커서 이동 / 복사·붙여넣기
- [ ] 배너 광고 노출 + ATT 프롬프트 (첫 실행)
- [ ] 키보드 익스텐션 설치 → 전환 → 입력
- [ ] 연결 끊김 → 재연결 버튼 동작
- [ ] 한국어/영어 기기 언어 전환 시 UI 언어 확인

---

## 출시 (App Store 제출)

- [ ] TestFlight 테스트 완료 후 App Store 심사 제출
- [ ] 광고 관련 심사 대응 (ATT, SKAdNetwork 설정 확인)
- [ ] 키보드 익스텐션 Open Access 이유 앱 설명에 명시 (심사 통과 필수)
