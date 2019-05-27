# TMI-Release
TMI for Release



## Coding Convention

스타일 쉐어 컨벤션 사용

https://github.com/StyleShare/swift-style-guide



## Commit log Convention

```
제목은 타입 라벨을 맨 앞에 붙어 타입(Type): 제목 형식으로 작성한다. 각 타입 라벨은 아래와 같다.

feat: 새로운 기능을 추가할 경우
fix: 버그를 고친 경우
docs: 문서 수정한 경우
style: 코드 포맷 변경, 세미 콜론 누락, 코드 수정이 없는 경우
refactor: 프로덕션 코드 리팩터링
test: 테스트 추가, 테스트 리팩터링 (프로덕션 코드 변경 없음)
chore: 빌드 테스크 업데이트, 패키지 매니저 설정할 경우 (프로덕션 코드 변경 없음)

제목의 처음은 "Fix", "Add", "Change"와 같은 명령어로 시작한다. 
Modify/Add/Delete/Refactor/Update 를 사용한다.
총 글자 수는 50자 이내며 마지막에 마침표(.)를 붙이지 않는다.

본문 (선택)
본문은 커밋의 상세 내용을 작성한다. 제목과 본문 사이에 한 줄 비운다. 본문은 한 줄에 72자 이내로 작성한다. 
한 줄을 띄워 문단으로 나누거나 불렛을 사용해 내용을 구분한다.

꼬리말 (선택)
꼬리말에는 이슈 트래커 ID를 추가한다.

Resolves: #123
See also: #456, #789

```



```
example

feat: Add OCR feature to recognize text

텍스트를 인식하기 위해 OCR 기능을 추가했습니다.
```

