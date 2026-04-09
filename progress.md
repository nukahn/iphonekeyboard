# ipad keyboard — 진행 상황

## 2026-04-09 — 전체 Phase 1~8 완료

### Phase 1 ✅ 앱 이름 변경 + 문서 생성
- project.yml: CFBundleDisplayName → "ipad keyboard" (메인앱 + 익스텐션)
- project.yml: knownRegions, developmentLanguage 추가
- RemoteKeyboard/Info.plist + RemoteKeyboardExtension/Info.plist 수정
- 모든 UI 파일의 "RemoteKeyboard" → "ipad keyboard" 교체
- phases.md, progress.md, README.md 생성

### Phase 2 ✅ 배너 광고 (Google AdMob + SPM)
- project.yml: GoogleMobileAds SPM 패키지, GADApplicationIdentifier, ATT, SKAdNetwork
- RemoteKeyboard/Ads/BannerAdView.swift: adaptive banner UIViewRepresentable
- RemoteKeyboard/Ads/AdManager.swift: SDK 초기화 + ATT 싱글턴
- IPhoneSenderView, IPadReceiverView 상단에 BannerAdView 추가
- 익스텐션에는 광고 SDK 미연결 (Apple 정책 준수)

### Phase 3 ✅ 실시간 키 입력 스트리밍
- RemoteKeyboard/iPhone/StreamingTextView.swift: UITextView 기반 UIViewRepresentable
- shouldChangeTextIn 델리게이트로 한글 조합 포함 정확한 델타 감지
- IPhoneSenderView: 전송 버튼 제거, 실시간 스트리밍으로 교체
- MultipeerManager: send() 반환값 추가, sendDeleteBackward(count:) 오버로드

### Phase 4 ✅ 커서 이동 / 선택 / 복사·붙여넣기
- SharedConstants.swift: MessageType 확장 (cursorLeft~paste, 0x05~0x0B)
- MultipeerManager: 커서/편집 편의 메서드 추가
- IPhoneSenderView: 커서 버튼 행 (← → ↑ ↓ | 전체선택 복사 붙여넣기)
- KeyboardViewController: 새 메시지 타입 처리 (adjustTextPosition, UIPasteboard)
- IPadReceiverView: 로그 파싱에 새 타입 추가

### Phase 5 ✅ 에러 핸들링
- MultipeerManager: @Published errorMessage, send() try/catch, retry(), clearError()
- MultipeerManager: advertiser/browser 실패 시 errorMessage 설정
- IPhoneSenderView: .alert 바인딩, 재연결 버튼
- IPadReceiverView: .alert 바인딩, 재연결 버튼 (disconnected 시)
- KeyboardViewController: updateStatusLabel(error:) 에러 표시

### Phase 6 ✅ 로컬라이제이션 (한국어 + 영어)
- project.yml: knownRegions, developmentLanguage 설정
- ko.lproj/Localizable.strings + en.lproj/Localizable.strings (메인앱)
- RemoteKeyboardExtension/Resources/ ko.lproj + en.lproj
- UI 파일 4개 모두 String(localized:) 적용

### Phase 7 ✅ 앱 아이콘
- 1024x1024 PNG 아이콘 생성 (CoreGraphics: 키보드 + WiFi 모티프)
- Assets.xcassets/AppIcon.appiconset/Contents.json 업데이트

### Phase 8 ✅ 유닛 테스트
- project.yml: RemoteKeyboardTests 타겟 추가
- SharedStorage: DI 가능하도록 suiteName init 리팩터
- SharedConstantsTests.swift: raw value 안정성, 인코딩/디코딩
- SharedStorageTests.swift: save/read/clear, 타임스탬프, 한글
- MultipeerManagerTests.swift: 초기 상태, 역할, send 실패, 크래시 방지
- MessageProtocolTests.swift: 한글/이모지/유니코드, 경계값, 직렬화

## 다음 단계
- xcodegen generate 실행 후 Xcode 빌드 확인
- 실기기 테스트 (iPhone + iPad)
- AdMob 실제 광고 단위 ID 교체 (ca-app-pub-XXXXXXXX~YYYYYY)
- App Store Connect 등록 및 제출
