"""각 장의 프롬프트를 모아 부록 B(docs/appendix/b-prompts.md)를 다시 만듭니다.

규칙: 장 본문에서 ```text 로 시작하는 코드 상자만 '프롬프트'로 모읍니다.
      프롬프트가 아닌 예시 글·양식은 ```plaintext 로 쓰면 모으지 않습니다.

실행: python scripts/collect_prompts.py
(GitHub Actions가 사이트를 만들 때마다 자동으로 실행합니다.)
"""

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
OUT = DOCS / "appendix" / "b-prompts.md"

# 장 파일은 '두 자리 숫자-이름.md' 형식입니다 (예: part2/04-gemini.md).
CHAPTER = re.compile(r"^\d{2}-.+\.md$")
HEADING = re.compile(r"^(#{2,5})\s+(.*)$")

INTRO = """# B. 프롬프트 모음

> 이 교재의 모든 장에 나온 프롬프트를 한곳에 모았습니다. 복사 버튼을 눌러 쓰고, `[대괄호]` 부분만 내 상황으로 바꾸세요.
> 이 페이지는 `scripts/collect_prompts.py` 가 각 장에서 자동으로 모아 만듭니다. 고칠 내용이 있으면 **해당 장**을 고쳐 주세요.

## 좋은 프롬프트의 여섯 조각

처음에는 아래 여섯 조각 중 **세 개만** 넣어도 결과가 확 달라집니다.

| 조각 | 묻는 것 | 예시 |
|---|---|---|
| 역할 | AI가 누구로서 답할까? | 너는 특수체육 수업 설계를 돕는 조교다. |
| 상황 | 나는 누구이고, 지금 어떤 상황인가? | 나는 예비교사를 가르치는 교수다. |
| 목표 | 결과로 무엇을 얻고 싶은가? | 학생 차이에 따라 참여 방법을 바꾸는 연습 |
| 조건 | 지켜야 할 시간·분량·대상·재료는? | 50분, 20명, 실내 체육관 |
| 형식 | 어떤 모양으로 받고 싶은가? | 표, 6개 항목, 400자 이내 |
| 금지 | 하지 말아야 할 것은? | 제공하지 않은 정보는 추정이라고 표시, 단정 금지 |

> ⚠️ **주의** 프롬프트에 실제 학생·고객·환자의 이름이나 연락처, 건강 정보를 넣지 마세요.

"""


def chapter_files():
    files = []
    for folder in sorted(DOCS.iterdir()):
        if folder.is_dir() and folder.name not in ("appendix", "examples", "assets", "stylesheets"):
            files += [p for p in folder.iterdir() if CHAPTER.match(p.name)]
    return sorted(files, key=lambda p: p.name)


def clean_heading(text):
    # 제목 앞의 번호·기호(①, 1., 3단계. 등)는 그대로 두고 꾸밈 기호만 정리합니다.
    return text.replace("**", "").strip()


def collect(path):
    lines = path.read_text(encoding="utf-8").split("\n")
    title = next((ln[2:].strip() for ln in lines if ln.startswith("# ")), path.stem)
    found, heading, i = [], None, 0
    while i < len(lines):
        m = HEADING.match(lines[i])
        if m:
            heading = clean_heading(m.group(2))
        if lines[i].strip() == "```text":
            j = i + 1
            while j < len(lines) and not lines[j].strip().startswith("```"):
                j += 1
            found.append((heading or title, "\n".join(lines[i + 1:j])))
            i = j
        i += 1
    return title, found


def main():
    parts = [INTRO]
    total = 0
    for path in chapter_files():
        title, prompts = collect(path)
        if not prompts:
            continue
        rel = path.relative_to(DOCS).as_posix()
        parts.append(f"## {title}\n\n📖 [본문에서 보기](../{rel})\n")
        last = None
        for heading, body in prompts:
            if heading != last:
                parts.append(f"### {heading}\n")
                last = heading
            parts.append(f"```text\n{body}\n```\n")
            total += 1
    parts.append(f"---\n📎 프롬프트 {total}개 · 각 장의 원자료는 해당 장 맨 아래를 참고하세요.\n")
    OUT.write_text("\n".join(parts), encoding="utf-8")
    print(f"{OUT.relative_to(ROOT)}: 프롬프트 {total}개")


if __name__ == "__main__":
    main()
