<p align="center">
  <img src="assets/icon.png" width="160" alt="FxxkScroll 아이콘">
</p>

<h1 align="center">FxxkScroll</h1>

<p align="center">
  쇼츠, 릴스, 틱톡만 브라우저에서 골라 막아 주는<br>
  macOS 메뉴 막대 앱입니다.
</p>

<p align="center">
  <a href="https://github.com/Kyun92/fxxkscroll/releases/latest"><b>내려받기</b></a>
  &nbsp;|&nbsp;
  <a href="README.md">English</a>
</p>

<p align="center">
  <img src="assets/demo.gif" width="720" alt="FxxkScroll 애니메이션">
</p>

## 만든 이유

강의 하나 보려고 유튜브를 열었는데 40분 뒤에도 쇼츠를 넘기고 있습니다.

유튜브와 인스타그램에서 끊고 싶었던 건 짧은 영상뿐이어서 그 페이지만 골라 막았습니다. 검색하고 긴 영상 보고 메시지 주고받는 건 평소대로 하면 됩니다. 나쁜 습관은 시작하기 어려워야 한다는 《아주 작은 습관의 힘》의 규칙도 그대로 따랐습니다.

- 쇼츠, 릴스, 틱톡 페이지를 열면 그 탭에 곧바로 차단 화면이 뜹니다.
- 차단을 끄려면 30초를 기다려야 하고 그사이 다른 창으로 넘어가면 처음부터 다시 기다려야 합니다.
- 오늘 몇 번 막혔는지는 메뉴를 열면 보입니다.

## 막는 주소

| 패턴 | 막는 곳 |
|---|---|
| `youtube.com/shorts/*` | 유튜브 쇼츠 |
| `instagram.com/reels/*` | 인스타그램 릴스 탭 |
| `instagram.com/reel/*` | 릴스 영상 하나하나 |
| `tiktok.com` | 틱톡 전체 |

메뉴 막대에서 **차단 목록 > 현재 탭 추가** 또는 **직접 추가…**로 주소를 더할 수 있습니다. 지울 때는 목록에서 ⌥ 키를 누르고 있으면 삭제 메뉴가 나옵니다.

패턴은 이렇게 씁니다.
- `facebook.com/reel/*`처럼 `*`를 붙이면 그 뒤에 어떤 주소가 와도 걸리니 페이스북 릴스를 한 번에 막을 수 있습니다.
- 사이트 전체를 막으려면 경로 없이 사이트 주소만 적습니다. `x.com` 한 줄이면 X 전체를 못 엽니다.
- `youtube.com/shorts/*`만 넣어도 `m.youtube.com/shorts/...`까지 걸리니 하위 도메인은 따로 적지 않아도 됩니다.

## 설치

macOS 13 Ventura 이상이면 Apple 실리콘 맥이든 인텔 맥이든 쓸 수 있습니다.

1. [Releases](https://github.com/Kyun92/fxxkscroll/releases/latest)에서 `FxxkScroll-x.y.z.zip`을 내려받습니다.
2. 압축을 풀고 `FxxkScroll.app`을 **응용 프로그램** 폴더로 옮깁니다.
3. 앱을 엽니다. 처음에는 macOS가 실행을 막으니 아래 안내대로 풀면 됩니다.

### "FxxkScroll을(를) 열 수 없습니다"가 나올 때

유료 Apple 개발자 인증서로 서명하지 않은 앱이라서 처음 실행하면 macOS가 막습니다. 아래 둘 중 하나만 하면 됩니다.

- **시스템 설정 > 개인정보 보호 및 보안**을 열고 아래로 내려 FxxkScroll 옆의 **그래도 열기**를 누릅니다.
- 터미널에서 아래 명령을 실행합니다.
  ```sh
  xattr -dr com.apple.quarantine /Applications/FxxkScroll.app
  ```

새 버전을 받을 때마다 한 번씩만 하면 됩니다. 전체 소스는 이 저장소에 올려 두었으니 앱이 무슨 일을 하는지 확인하거나 직접 빌드해 보셔도 됩니다.

### 브라우저 권한

탭 주소를 알아야 차단할 수 있어서 브라우저마다 처음 한 번은 macOS가 이렇게 묻습니다.

> "FxxkScroll"이(가) "Google Chrome"을(를) 제어하려고 합니다.

**확인**을 누릅니다. **허용 안 함**을 눌러서 메뉴에 "권한 필요"가 나온다면 **시스템 설정 > 개인정보 보호 및 보안 > 자동화 > FxxkScroll**에서 다시 켜 주면 됩니다.

새 버전으로 바꾼 뒤에는 macOS가 권한을 한 번 더 물어볼 수도 있습니다.

## 브라우저

| 브라우저 | 상태 |
|---|---|
| Google Chrome | 확인함 |
| Safari | 지원 |
| Arc, Microsoft Edge, Brave, Vivaldi, Chromium | 지원, 아직 확인 못 함 |

Firefox는 다른 앱이 탭 주소를 읽지 못하게 막혀 있어서 지원하지 않습니다.

## 개인정보

- 열린 탭의 주소를 1초에 한 번쯤 읽어서 맥 안에서 바로 확인합니다.
- 인터넷으로는 아무것도 보내지 않고 따로 수집하는 정보도 없습니다.
- 차단 목록은 `~/Library/Application Support/FxxkScroll/rules.json`에 저장됩니다.

## 동작 방식

HTTPS가 페이지 경로를 암호화하기 때문에 DNS나 방화벽으로 막으려 하면 youtube.com 전체를 막을 수밖에 없습니다. 그래서 FxxkScroll은 켜져 있는 브라우저에 AppleScript로 탭 주소를 물어보고 주소가 차단 목록과 맞을 때 그 탭에 앱 안의 차단 화면을 띄웁니다.

## 소스에서 빌드

```sh
brew install xcodegen
git clone https://github.com/Kyun92/fxxkscroll.git
cd fxxkscroll
xcodegen generate
open FxxkScroll.xcodeproj
```

테스트는 `xcodebuild -project FxxkScroll.xcodeproj -scheme FxxkScroll -destination 'platform=macOS' test`로 돌립니다.

디버그 빌드를 새로 할 때마다 브라우저 권한을 다시 받고 싶지 않다면 `Config/Local.xcconfig.example`을 `Config/Local.xcconfig`로 복사하고 본인 팀 ID를 넣으면 됩니다.

`scripts/release.sh`를 돌리면 배포용 zip이 생깁니다.

## 라이선스

[MIT](LICENSE)

