# ipad keyboard

iPhone을 iPad의 블루투스/WiFi 키보드로 사용하는 iOS 앱.
인터넷 없이 로컬 네트워크(Multipeer Connectivity)로 동작합니다.

## 동작 방식

```
iPhone (ipad keyboard 앱)
  → 문자 입력/삭제/커서 이동
  → Multipeer Connectivity (로컬 WiFi/BT)
iPad (ipad keyboard 앱)
  → App Group UserDefaults에 저장
  → Darwin 알림 발송
iPad 키보드 익스텐션 (ipad keyboard Keyboard)
  → Darwin 알림 수신
  → textDocumentProxy로 현재 앱에 텍스트 삽입
```

## 요구사항

- iPhone + iPad (각각 iOS 16.0+)
- 동일 WiFi 또는 Bluetooth 범위 내
- iPad에 커스텀 키보드 익스텐션 등록 필요 (앱 내 안내 참조)

## 빌드 방법

```bash
# XcodeGen으로 프로젝트 재생성
xcodegen generate

# Xcode로 열기
open RemoteKeyboard.xcodeproj
```

## 아키텍처

| 디렉토리 | 역할 |
|---------|------|
| `RemoteKeyboard/` | 메인 앱 (iPhone 송신 UI + iPad 수신 UI) |
| `RemoteKeyboardExtension/` | 커스텀 키보드 익스텐션 |
| `SharedKit/Sources/` | 공유 코드 (MultipeerManager, SharedStorage 등) |

## 메시지 프로토콜

1바이트 prefix + payload 형식:

| Prefix | 타입 | 페이로드 |
|--------|------|---------|
| 0x01 | 텍스트 삽입 | UTF-8 문자열 |
| 0x02 | 삭제 (1자) | 없음 |
| 0x03 | 삭제 (N자) | UTF-8 숫자 문자열 |
| 0x04 | 엔터 | 없음 |
| 0x05 | 커서 ← | 없음 |
| 0x06 | 커서 → | 없음 |
| 0x07 | 커서 ↑ | 없음 |
| 0x08 | 커서 ↓ | 없음 |
| 0x09 | 전체 선택 | 없음 |
| 0x0A | 복사 | 없음 |
| 0x0B | 붙여넣기 | 없음 |

## iPad 키보드 설정 방법

1. iPad에서 `ipad keyboard` 앱 실행
2. "키보드 설정 방법 보기" 탭
3. 설정 → 일반 → 키보드 → 키보드 → 새 키보드 추가 → ipad keyboard
4. ipad keyboard → 전체 허용 활성화
5. 어떤 앱에서든 🌐 버튼으로 키보드 전환
