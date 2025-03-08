/**
 * 사이드바 컴포넌트 - Next.js와 유사한 기능을 바닐라 JavaScript로 구현
 */

// 좌측 사이드바 컴포넌트 클래스
class LeftSidebar {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    this.state = {
      menuItems: [
        { id: 1, title: '홈', link: '#', active: true },
        { id: 2, title: '내 정보', link: '#', active: false },
        { id: 3, title: '친구', link: '#', active: false },
        { id: 4, title: '설정', link: '#', active: false },
      ],
    };
  }

  // 컴포넌트 렌더링
  render() {
    if (!this.container) return;

    const menuListHtml = this.state.menuItems
      .map(
        (item) => `
        <li class="sidebar-menu-item ${item.active ? 'active' : ''}">
          <a href="${item.link}" data-id="${item.id}">${item.title}</a>
        </li>
      `,
      )
      .join('');

    this.container.innerHTML = `
      <div class="sidebar-content">
        <h3 class="sidebar-title">Picnic</h3>
        <ul class="sidebar-menu">
          ${menuListHtml}
        </ul>
        <div class="sidebar-footer">
          <p>© 2023 Picnic</p>
        </div>
      </div>
    `;

    // 이벤트 리스너 등록
    this.addEventListeners();
  }

  // 이벤트 리스너 등록
  addEventListeners() {
    const menuItems = this.container.querySelectorAll('.sidebar-menu-item a');
    menuItems.forEach((item) => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        const id = parseInt(e.target.dataset.id);
        this.setActiveMenu(id);
      });
    });
  }

  // 활성 메뉴 설정
  setActiveMenu(id) {
    this.state.menuItems = this.state.menuItems.map((item) => ({
      ...item,
      active: item.id === id,
    }));
    this.render();
  }
}

// 우측 사이드바 컴포넌트 클래스
class RightSidebar {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    this.state = {
      notifications: [
        { id: 1, message: '새로운 친구 요청이 있습니다', time: '방금 전' },
        { id: 2, message: '새 메시지가 도착했습니다', time: '5분 전' },
      ],
      showNotifications: false,
    };
  }

  // 컴포넌트 렌더링
  render() {
    if (!this.container) return;

    const notificationsHtml = this.state.notifications
      .map(
        (notification) => `
        <div class="notification-item" data-id="${notification.id}">
          <p>${notification.message}</p>
          <small>${notification.time}</small>
        </div>
      `,
      )
      .join('');

    this.container.innerHTML = `
      <div class="sidebar-content">
        <h3 class="sidebar-title">정보</h3>
        <button id="toggle-notifications" class="btn">
          ${this.state.showNotifications ? '알림 숨기기' : '알림 보기'} (${
      this.state.notifications.length
    })
        </button>
        
        <div class="notifications-container" style="display: ${
          this.state.showNotifications ? 'block' : 'none'
        }">
          ${notificationsHtml}
        </div>
        
        <div class="user-actions">
          <button id="refresh-btn" class="btn">새로고침</button>
        </div>
      </div>
    `;

    // 이벤트 리스너 등록
    this.addEventListeners();
  }

  // 이벤트 리스너 등록
  addEventListeners() {
    const toggleBtn = this.container.querySelector('#toggle-notifications');
    if (toggleBtn) {
      toggleBtn.addEventListener('click', () => {
        this.state.showNotifications = !this.state.showNotifications;
        this.render();
      });
    }

    const refreshBtn = this.container.querySelector('#refresh-btn');
    if (refreshBtn) {
      refreshBtn.addEventListener('click', () => {
        this.fetchNotifications();
      });
    }
  }

  // 알림 데이터 가져오기 (실제로는 API 호출)
  fetchNotifications() {
    // API 호출을 시뮬레이션
    setTimeout(() => {
      this.state.notifications = [
        { id: 1, message: '새로운 친구 요청이 있습니다', time: '방금 전' },
        { id: 2, message: '새 메시지가 도착했습니다', time: '5분 전' },
        { id: 3, message: '새 게시물이 등록되었습니다', time: '지금' },
      ];
      this.render();
      alert('알림이 업데이트되었습니다.');
    }, 500);
  }
}

// 앱 초기화 함수
function initSidebarComponents() {
  // 스타일 적용
  applyStyles();

  // 좌측 사이드바 초기화
  const leftSidebar = new LeftSidebar('sidebar-left');
  leftSidebar.render();

  // 우측 사이드바 초기화
  const rightSidebar = new RightSidebar('sidebar-right');
  rightSidebar.render();
}

// 사이드바 스타일 적용
function applyStyles() {
  const style = document.createElement('style');
  style.textContent = `
    .sidebar-content {
      height: 100%;
      display: flex;
      flex-direction: column;
    }
    
    .sidebar-title {
      font-size: 1.5rem;
      margin-bottom: 1.5rem;
      color: #333;
    }
    
    .sidebar-menu {
      list-style: none;
      padding: 0;
      margin: 0 0 2rem 0;
      flex-grow: 1;
    }
    
    .sidebar-menu-item {
      margin-bottom: 0.5rem;
    }
    
    .sidebar-menu-item a {
      display: block;
      padding: 0.75rem 1rem;
      color: #666;
      text-decoration: none;
      border-radius: 0.25rem;
      transition: all 0.2s;
    }
    
    .sidebar-menu-item.active a {
      background-color: #f0f0f0;
      color: #333;
      font-weight: bold;
    }
    
    .sidebar-menu-item a:hover {
      background-color: #f8f8f8;
      color: #333;
    }
    
    .sidebar-footer {
      margin-top: auto;
      padding-top: 1rem;
      border-top: 1px solid #eee;
      color: #999;
      font-size: 0.8rem;
    }
    
    .notification-item {
      padding: 0.75rem;
      background-color: #f9f9f9;
      border-radius: 0.25rem;
      margin-bottom: 0.5rem;
    }
    
    .notification-item p {
      margin: 0 0 0.25rem 0;
      color: #333;
    }
    
    .notification-item small {
      color: #999;
    }
    
    .notifications-container {
      margin: 1rem 0;
    }
    
    .btn {
      padding: 0.5rem 1rem;
      background-color: #f0f0f0;
      border: none;
      border-radius: 0.25rem;
      cursor: pointer;
      font-size: 0.9rem;
      transition: all 0.2s;
    }
    
    .btn:hover {
      background-color: #e0e0e0;
    }
    
    .user-actions {
      margin-top: 1rem;
    }
  `;
  document.head.appendChild(style);
}

// DOM이 로드되면 사이드바 컴포넌트 초기화
document.addEventListener('DOMContentLoaded', initSidebarComponents);
