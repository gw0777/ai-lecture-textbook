/*
 * NVIDIA Build 텍스트 모델 호출 예제 (15장 「NVIDIA Build로 모델 비교하기」)
 * ----------------------------------------------------------------------
 * 필요한 것: Node.js 18 이상 (node --version 으로 확인), NVIDIA Build에서 발급한 API 키
 *
 * 사용법
 *   1) 프롬프트를 텍스트 파일로 저장합니다. 예: prompt.txt
 *      (파일을 주지 않으면 아래 DEFAULT_PROMPT 예시로 실행됩니다.)
 *   2) API 키를 환경변수로 설정하고 실행합니다. 키를 이 파일 안에 직접 적지 마세요.
 *
 *   [Windows 명령 프롬프트(cmd)]
 *     set NVIDIA_API_KEY=발급받은키
 *     node nvidia-build-chat.mjs prompt.txt
 *
 *   [Windows PowerShell]
 *     $env:NVIDIA_API_KEY = "발급받은키"
 *     node nvidia-build-chat.mjs prompt.txt
 *
 *   [다른 모델로 비교하기]
 *     cmd:        set NVIDIA_MODEL=모델ID
 *     PowerShell: $env:NVIDIA_MODEL = "모델ID"
 *
 * 주의
 *   - 모델 ID는 모델 페이지의 Build > 코드 예제에 표시된 값을 그대로 쓰세요.
 *     아래 기본값은 2026.10 기준 Nemotron Ultra 모델 페이지 주소에서 가져온 것이며 바뀔 수 있습니다.
 *   - 음성·영상 모델은 호출 방식이 다를 수 있습니다. 이 예제는 텍스트 대화 모델용입니다.
 *   - API 키는 공개 HTML, 카카오톡, 공개 저장소에 절대 올리지 마세요.
 */

import { readFile } from 'node:fs/promises';

const API_URL = 'https://integrate.api.nvidia.com/v1/chat/completions';

// 모델 페이지에서 정확한 모델 ID를 확인한 뒤 NVIDIA_MODEL 환경변수로 바꿔 쓰세요.
const MODEL = process.env.NVIDIA_MODEL || 'nvidia/nemotron-3-ultra-550b-a55b';

const DEFAULT_PROMPT = [
  '너는 수업 복습 자료를 만드는 조교다.',
  '아래 내용을 바탕으로 카카오톡 복사용 안내문(400자 이내)과 핵심 배움 3개를 작성해줘.',
  '수업 내용: Gemini로 질문하기, Gemini Notebook으로 자료 요약하기',
  '제공하지 않은 날짜·장소·이름은 넣지 마.',
].join('\n');

async function loadPrompt() {
  const file = process.argv[2];
  if (!file) {
    console.log('ℹ️ 프롬프트 파일을 주지 않아 기본 예시 프롬프트로 실행합니다.\n');
    return DEFAULT_PROMPT;
  }
  try {
    return (await readFile(file, 'utf8')).trim();
  } catch {
    console.error(`❌ 프롬프트 파일을 읽을 수 없습니다: ${file}`);
    console.error('   파일 이름과 위치(현재 폴더 기준)를 확인하세요.');
    process.exit(1);
  }
}

async function main() {
  const apiKey = process.env.NVIDIA_API_KEY;
  if (!apiKey) {
    console.error('❌ NVIDIA_API_KEY 환경변수가 없습니다.');
    console.error('   cmd:        set NVIDIA_API_KEY=발급받은키');
    console.error('   PowerShell: $env:NVIDIA_API_KEY = "발급받은키"');
    process.exit(1);
  }

  const prompt = await loadPrompt();
  console.log(`🤖 모델: ${MODEL}\n`);

  let response;
  try {
    response = await fetch(API_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        model: MODEL,
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.3,
        max_tokens: 2048,
      }),
    });
  } catch (err) {
    console.error('❌ 서버에 연결하지 못했습니다.');
    console.error('   인터넷 연결을 확인하세요. 학교·회사 네트워크라면 전산팀에');
    console.error('   integrate.api.nvidia.com 으로 HTTPS 통신이 가능한지 문의하세요.');
    console.error(`   (상세: ${err.message})`);
    process.exit(1);
  }

  if (!response.ok) {
    const detail = await response.text().catch(() => '');
    const hints = {
      401: 'API 키가 올바르지 않습니다. 키를 다시 복사하거나 새로 발급하세요.',
      403: '이 모델을 사용할 권한이 없거나 무료 한도를 넘었습니다. Build 화면에서 조건을 확인하세요.',
      404: '모델 ID를 찾을 수 없습니다. 모델 페이지의 코드 예제에서 정확한 ID를 확인하세요.',
      429: '요청이 너무 많습니다. 잠시 후 다시 시도하세요.',
    };
    console.error(`❌ 요청 실패 (HTTP ${response.status})`);
    console.error(`   ${hints[response.status] || '모델 페이지의 안내와 사용 조건을 확인하세요.'}`);
    if (detail) console.error(`   서버 응답: ${detail.slice(0, 500)}`);
    process.exit(1);
  }

  const data = await response.json();
  const reply = data?.choices?.[0]?.message?.content;
  if (!reply) {
    console.error('❌ 응답에 답변 내용이 없습니다. 서버 응답을 확인하세요:');
    console.error(JSON.stringify(data, null, 2).slice(0, 1000));
    process.exit(1);
  }

  console.log(reply);
  console.log('\n✅ 완료. 이 답변은 초안입니다. 날짜·이름·사실은 직접 확인하세요.');
}

main();
