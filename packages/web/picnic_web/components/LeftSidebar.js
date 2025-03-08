import React, { useState, useEffect } from 'react';

export default function LeftSidebar() {
  const [menuItems, setMenuItems] = useState([
    { id: 1, title: '홈', link: '#', active: true },
    { id: 2, title: '내 정보', link: '#', active: false },
    { id: 3, title: '친구', link: '#', active: false },
    { id: 4, title: '설정', link: '#', active: false },
  ]);

  // 컴포넌트가 마운트될 때 부모 창에 로드 완료 신호 전송
  useEffect(() => {
    // 로드 완료 신호를 부모 창에 전달
    if (window.parent && window.parent !== window) {
      window.parent.postMessage(
        {
          type: 'SIDEBAR_LOADED',
          location: 'left',
        },
        '*',
      );
    }

    // 부모로부터의 메시지 수신 처리
    const handleParentMessage = (event) => {
      if (event.data && event.data.type === 'REFRESH_SIDEBAR') {
        console.log('사이드바 새로고침 요청 수신');
        // 필요한 경우 상태 업데이트
      }
    };

    window.addEventListener('message', handleParentMessage);
    return () => {
      window.removeEventListener('message', handleParentMessage);
    };
  }, []);

  const handleMenuClick = (id) => {
    setMenuItems(
      menuItems.map((item) => ({
        ...item,
        active: item.id === id,
      })),
    );

    // 필요한 경우 Flutter 앱에 메시지 전달
    if (window.parent && window.parent !== window) {
      window.parent.postMessage(
        {
          type: 'MENU_SELECTED',
          menuId: id,
        },
        '*',
      );
    }
  };

  return (
    <div className='sidebar-content'>
      <h3 className='sidebar-title'>Picnic</h3>
      <ul className='sidebar-menu'>
        {menuItems.map((item) => (
          <li
            key={item.id}
            className={`sidebar-menu-item ${item.active ? 'active' : ''}`}
          >
            <a
              href={item.link}
              onClick={(e) => {
                e.preventDefault();
                handleMenuClick(item.id);
              }}
            >
              {item.title}
            </a>
          </li>
        ))}
      </ul>
      <div className='sidebar-footer'>
        <p>© 2023 Picnic</p>
      </div>
    </div>
  );
}
