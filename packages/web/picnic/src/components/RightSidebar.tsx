import React, { useState, useEffect } from 'react';

export default function RightSidebar() {
  const [notifications, setNotifications] = useState([
    { id: 1, message: '새로운 친구 요청이 있습니다', time: '방금 전' },
    { id: 2, message: '새 메시지가 도착했습니다', time: '5분 전' },
  ]);
  const [showNotifications, setShowNotifications] = useState(false);

  useEffect(() => {
    // 부모 창(Flutter)로부터 메시지 수신
    const handleMessage = (event) => {
      if (event.data && event.data.type === 'UPDATE_NOTIFICATIONS') {
        setNotifications(event.data.notifications || []);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  const handleToggleNotifications = () => {
    setShowNotifications(!showNotifications);
  };

  const handleRefresh = () => {
    // 새로운 알림을 가져오는 로직 (실제로는 API 호출)
    setTimeout(() => {
      setNotifications([
        { id: 1, message: '새로운 친구 요청이 있습니다', time: '방금 전' },
        { id: 2, message: '새 메시지가 도착했습니다', time: '5분 전' },
        { id: 3, message: '새 게시물이 등록되었습니다', time: '지금' },
      ]);

      // Flutter 앱에 알림이 업데이트되었음을 알림
      if (window.parent && window.parent !== window) {
        window.parent.postMessage(
          {
            type: 'NOTIFICATIONS_UPDATED',
            count: 3,
          },
          '*',
        );
      }
    }, 500);
  };

  return (
    <div className='sidebar-content'>
      <h3 className='sidebar-title'>정보</h3>
      <button onClick={handleToggleNotifications} className='btn'>
        {showNotifications ? '알림 숨기기' : '알림 보기'} (
        {notifications.length})
      </button>

      {showNotifications && (
        <div className='notifications-container'>
          {notifications.map((notification) => (
            <div key={notification.id} className='notification-item'>
              <p>{notification.message}</p>
              <small>{notification.time}</small>
            </div>
          ))}
        </div>
      )}

      <div className='user-actions'>
        <button onClick={handleRefresh} className='btn'>
          새로고침
        </button>
      </div>
    </div>
  );
}
