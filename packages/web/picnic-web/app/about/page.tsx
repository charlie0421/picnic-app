export default function About() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">피크닉 소개</h1>
      
      <div className="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 className="text-2xl font-semibold mb-4">우리의 비전</h2>
        <p className="text-gray-700 mb-6">
          피크닉은 사용자에게 가치 있는 서비스를 제공하기 위해 노력하고 있습니다. 
          우리의 목표는 사용자 경험을 개선하고 혁신적인 솔루션을 제공하는 것입니다.
        </p>
        
        <h2 className="text-2xl font-semibold mb-4">우리의 미션</h2>
        <p className="text-gray-700">
          사용자의 일상을 더 풍요롭게 만들고, 기술을 통해 일상의 문제를 해결하는 것이 
          우리의 미션입니다. 지속적인 개선과 혁신을 통해 사용자에게 최상의 서비스를 제공하겠습니다.
        </p>
      </div>
      
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-2xl font-semibold mb-4">팀 소개</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div className="bg-gray-50 p-4 rounded-md">
            <h3 className="text-xl font-medium mb-2">홍길동</h3>
            <p className="text-gray-600">CEO & 창립자</p>
            <p className="mt-2 text-gray-700">10년 이상의 기술 경험을 가진 전문가입니다.</p>
          </div>
          
          <div className="bg-gray-50 p-4 rounded-md">
            <h3 className="text-xl font-medium mb-2">김철수</h3>
            <p className="text-gray-600">CTO</p>
            <p className="mt-2 text-gray-700">최신 기술 트렌드를 선도하는 기술 리더입니다.</p>
          </div>
          
          <div className="bg-gray-50 p-4 rounded-md">
            <h3 className="text-xl font-medium mb-2">이영희</h3>
            <p className="text-gray-600">디자인 책임자</p>
            <p className="mt-2 text-gray-700">사용자 경험을 최우선으로 생각하는 디자이너입니다.</p>
          </div>
        </div>
      </div>
    </div>
  );
} 