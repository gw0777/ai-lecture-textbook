/*
 * 유튜브 검색 결과 영상 주소 한 번에 가져오기 (크롬 한방! 북마클릿)
 * ------------------------------------------------------------------
 * - 이 파일은 "읽기 쉬운 설명용 원본"입니다.
 * - 실제로 북마크에 붙여 넣을 한 줄짜리 버전은 youtube-links-bookmarklet.txt 에 있습니다.
 * - 동작: 유튜브 검색 결과 페이지(/results)에서 실행하면
 *   화면에 불러와진 일반 영상의 주소를 중복 없이 모아 한 줄에 하나씩 클립보드에 복사합니다.
 * - 광고, 쇼츠 묶음, 추천 묶음(셸프)은 건너뜁니다.
 * - 클립보드 복사가 막히면 화면에 텍스트 상자를 띄워 직접 복사할 수 있게 합니다.
 * - 유튜브 화면 구조가 바뀌면 작동하지 않을 수 있습니다. (2026.10 기준 작성)
 */
(async function () {
  // 1) 검색 결과 페이지인지 확인합니다.
  if (!/(^|\.)youtube\.com$/.test(location.hostname) || location.pathname !== '/results') {
    alert('유튜브 검색 결과 페이지에서 실행해 주세요.');
    return;
  }

  // 2) 영상 카드의 제목 링크를 모두 찾습니다.
  //    (a#video-title 과 같은 뜻입니다. 북마크 주소 안에서 '#' 이 잘리는 일을 막으려고
  //     [id="video-title"] 로 적었습니다. 같은 이유로 CSS에도 '%' 를 쓰지 않았습니다.)
  const titleLinks = document.querySelectorAll('ytd-video-renderer a[id="video-title"]');

  // 3) 광고·쇼츠·추천 묶음은 건너뛰고, 영상 ID만 뽑아 중복 없이 모읍니다.
  const skipArea =
    'ytd-ad-slot-renderer, ytd-reel-shelf-renderer, ytd-shelf-renderer, [hidden]';
  const links = new Set();

  titleLinks.forEach(function (a) {
    if (a.closest(skipArea)) return;
    const href = a.getAttribute('href');
    if (!href) return;
    const url = new URL(href, location.origin);
    const id = url.searchParams.get('v'); // /watch?v=영상ID 형태만 사용
    if (id) links.add('https://www.youtube.com/watch?v=' + id);
  });

  if (links.size === 0) {
    alert('가져올 영상이 없습니다. 화면을 조금 내려 영상을 불러온 뒤 다시 실행해 보세요.');
    return;
  }

  // 4) 한 줄에 하나씩 이어 붙입니다.
  const text = Array.from(links).join('\n');

  // 5) 클립보드에 복사합니다. 실패하면 텍스트 상자를 띄웁니다.
  try {
    await navigator.clipboard.writeText(text);
    alert(links.size + '개의 영상 주소를 복사했습니다. 메모장이나 문서에 붙여 넣으세요(Ctrl+V).');
  } catch (err) {
    showTextBox(text, links.size);
  }

  // 클립보드가 막혔을 때 쓰는 대체 화면
  function showTextBox(content, count) {
    const old = document.getElementById('yt-links-box');
    if (old) old.remove();

    const box = document.createElement('div');
    box.id = 'yt-links-box';
    box.style.cssText =
      'position:fixed;top:10vh;left:0;right:0;margin:auto;z-index:999999;' +
      'width:90vw;max-width:640px;background:white;color:black;padding:16px;border-radius:12px;' +
      'box-shadow:0 8px 32px rgba(0,0,0,.35);font:14px/1.5 sans-serif;';

    const title = document.createElement('p');
    title.textContent = count + '개의 영상 주소입니다. 전체 선택(Ctrl+A) 후 복사(Ctrl+C)하세요.';
    title.style.margin = '0 0 8px';

    const area = document.createElement('textarea');
    area.value = content;
    area.style.cssText = 'display:block;width:85vw;max-width:600px;height:240px;font:12px monospace;';

    const close = document.createElement('button');
    close.textContent = '닫기';
    close.style.cssText = 'margin-top:8px;padding:6px 16px;cursor:pointer;';
    close.onclick = function () {
      box.remove();
    };

    box.append(title, area, close);
    document.body.appendChild(box);
    area.focus();
    area.select();
  }
})();
