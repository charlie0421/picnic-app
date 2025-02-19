// Supabase 클라이언트 초기화
const supabaseClient = supabase.createClient(
  config.SUPABASE_URL,
  config.SUPABASE_ANON_KEY,
);

// 전역 변수
let voteData = null;
let shortUrl = '';
let lastVoteId = '';
let branchInstance = null;
let currentHash = 'dev';
let previousVoteCounts = {};

// 초기화 함수
function init() {
  // Branch SDK 초기화
  if (typeof branch !== 'undefined' && config.BRANCH_KEY) {
    branch.init(config.BRANCH_KEY);
    branchInstance = branch;
  } else {
    console.error(
      'BRANCH_KEY가 정의되지 않았거나 Branch SDK를 불러올 수 없습니다.',
    );
  }
  // 투표 데이터 폴링 및 버전 체크 시작
  fetchVotes();
  setInterval(fetchVotes, 1000);
}

// 투표 데이터 가져오기
async function fetchVotes() {
  const { data, error } = await supabaseClient
    .from('vote')
    .select(
      `id, vote_category, title, start_at, stop_at, vote_item(
      id,
      vote_total,
      artist(
        id,
        name,
        image,
        artist_group(
          id,
          name,
          image,
          created_at,
          updated_at,
          deleted_at
        ),
        created_at,
        updated_at,
        deleted_at
      ),
      created_at,
      updated_at,
      deleted_at
    )`,
    )
    .lte('start_at', 'now()')
    .gte('stop_at', 'now()')
    .order('vote_total', { ascending: false, foreignTable: 'vote_item' })
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error('투표 데이터를 가져오는 중 오류 발생:', error);
    return;
  }
  if (data) {
    voteData = {
      voteInfo: {
        id: data.id,
        vote_category: data.vote_category,
        title: data.title,
        start_at: data.start_at,
        stop_at: data.stop_at,
      },
      topThree: data.vote_item ? data.vote_item : [],
    };
    updateUI(voteData);
    generateShortUrl(voteData);
  }
}

// 버전 체크 함수 (별도 API 엔드포인트가 존재해야 합니다)
async function checkVersion() {
  try {
    console.log('버전 정보를 가져옵니다...');
    const response = await fetch('/api/version');
    if (!response.ok) {
      throw new Error(`HTTP 오류 발생: ${response.status}`);
    }
    const json = await response.json();
    const hash = json.hash;
    console.log('현재 해시:', currentHash, '새로운 해시:', hash);
    if (currentHash === 'dev') {
      currentHash = hash;
    } else if (hash !== currentHash) {
      location.reload();
    }
  } catch (error) {
    console.error('버전 체크 중 오류 발생:', error);
  }
}

// UI 업데이트 함수 (순위 리스트 및 QR 코드 갱신)
function updateUI(voteData) {
  const rankingList = document.getElementById('rankingList');
  rankingList.innerHTML = '';
  if (voteData.topThree && voteData.topThree.length > 0) {
    voteData.topThree.slice(0, 3).forEach((item, index) => {
      const rank = index + 1;
      const rankItem = document.createElement('div');
      rankItem.className = 'rankItem';

      // 순위 이미지
      const rankImage = document.createElement('div');
      rankImage.className = `rankImage${rank}`;
      const img = document.createElement('img');
      if (rank === 1) img.src = 'images/1st.svg';
      else if (rank === 2) img.src = 'images/2nd.svg';
      else if (rank === 3) img.src = 'images/3rd.svg';
      img.alt = rank + '등';
      rankImage.appendChild(img);
      rankItem.appendChild(rankImage);

      // 기둥 영역 (RankCard 내용)
      const rankPillar = document.createElement('div');
      rankPillar.className = 'rankPillar';

      // 카드 영역: 아티스트 이미지, 그룹명
      const card = document.createElement('div');
      card.className = 'card';
      if (item.artist && item.artist.image) {
        const artistImg = document.createElement('img');
        const photoSize = rank === 1 ? 200 : rank === 2 ? 172 : 130;
        artistImg.src =
          config.CDN_URL + '/' + item.artist.image + '?w=' + photoSize;
        artistImg.alt = item.artist.name.en || item.artist.name.ko || '';
        card.appendChild(artistImg);
      } else {
        const noImageDiv = document.createElement('div');
        noImageDiv.textContent = 'No Image';
        noImageDiv.style.backgroundColor = '#374151';
        noImageDiv.style.width = '100%';
        noImageDiv.style.height = '100%';
        noImageDiv.style.display = 'flex';
        noImageDiv.style.justifyContent = 'center';
        noImageDiv.style.alignItems = 'center';
        card.appendChild(noImageDiv);
      }

      // 그룹명 표시
      const groupNameDiv = document.createElement('div');
      groupNameDiv.className = `groupName${rank}`;
      if (
        item.artist &&
        item.artist.artist_group &&
        item.artist.artist_group.name
      ) {
        groupNameDiv.textContent =
          item.artist.artist_group.name.en ||
          item.artist.artist_group.name.ko ||
          '';
      }
      card.appendChild(groupNameDiv);

      // 투표 수 표시 - 기존 카드 영역에서 분리하여 voteCountWrapper에 배치
      const newVote = item.vote_total;
      const previousVote = previousVoteCounts[item.id];
      const shouldAnimate =
        typeof previousVote !== 'undefined' && previousVote !== newVote;
      previousVoteCounts[item.id] = newVote;

      const voteCountDiv = document.createElement('div');
      voteCountDiv.className = 'voteCount';
      voteCountDiv.textContent = newVote.toLocaleString();
      // 등수에 따른 크기 차별화를 위한 클래스 추가
      voteCountDiv.classList.add(`voteCount${rank}`);
      if (shouldAnimate) {
        voteCountDiv.classList.add('animate');
        voteCountDiv.addEventListener(
          'animationend',
          function () {
            voteCountDiv.classList.remove('animate');
          },
          { once: true },
        );
      }

      // 카드와 투표 수 컨테이너를 순서대로 추가
      rankPillar.appendChild(card);
      const voteCountWrapper = document.createElement('div');
      voteCountWrapper.className = 'voteCountWrapper';
      voteCountWrapper.appendChild(voteCountDiv);
      rankPillar.appendChild(voteCountWrapper);

      // 1등일 경우 세로 텍스트 (아티스트 이름) 추가
      if (rank === 1) {
        const verticalNameDiv = document.createElement('div');
        verticalNameDiv.className = 'verticalName';
        if (item.artist && item.artist.name) {
          verticalNameDiv.textContent =
            item.artist.name.en || item.artist.name.ko || '';
        }
        rankPillar.appendChild(verticalNameDiv);
      }

      rankItem.appendChild(rankPillar);
      rankingList.appendChild(rankItem);
    });
  } else {
    rankingList.textContent = '투표 데이터가 없습니다.';
  }
  updateQRCode();
}

// Branch SDK를 이용해 Short URL 생성 (투표 데이터 변경 시 호출)
function generateShortUrl(voteData) {
  if (voteData && voteData.voteInfo && voteData.voteInfo.id && branchInstance) {
    if (lastVoteId === voteData.voteInfo.id) return;
    lastVoteId = voteData.voteInfo.id;
    const data = {
      $canonical_url: `https://applink.picnic.fan/vote/detail/${voteData.voteInfo.id}`,
      $desktop_url: `https://applink.picnic.fan/vote/detail/${voteData.voteInfo.id}`,
      $og_title: voteData.voteInfo.title
        ? voteData.voteInfo.title.en || ''
        : '',
      $og_description: '투표 결과 확인하기',
    };
    branchInstance.link({ data: data }, function (err, link) {
      if (err) {
        console.error('Branch short URL 생성 오류:', err);
      } else {
        shortUrl = link || '';
        updateQRCode();
        console.log('생성된 short URL:', link);
      }
    });
  }
}

// QR 코드 갱신 함수
function updateQRCode() {
  const qrContainer = document.getElementById('qrCodeContainer');
  qrContainer.innerHTML = '';
  const value =
    shortUrl ||
    (voteData && voteData.voteInfo && voteData.voteInfo.id
      ? `https://applink.picnic.fan/vote/detail/${voteData.voteInfo.id}`
      : '');
  if (value) {
    new QRCode(qrContainer, {
      text: value,
      width: 110,
      height: 110,
    });
  }
}

// DOMContentLoaded 시 초기화
document.addEventListener('DOMContentLoaded', init);
