import '@testing-library/jest-dom';
import { render, screen } from '@testing-library/react';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

describe('LoadingSpinner 컴포넌트', () => {
  it('정상적으로 렌더링됩니다', () => {
    const { container } = render(<LoadingSpinner />);
    
    // 컨테이너 요소를 확인합니다
    const spinnerContainer = container.querySelector('div.flex.justify-center.items-center');
    expect(spinnerContainer).toBeInTheDocument();
    
    // 스피너 요소를 확인합니다
    const spinnerElement = container.querySelector('div.animate-spin');
    expect(spinnerElement).toBeInTheDocument();
    expect(spinnerElement).toHaveClass('rounded-full');
    expect(spinnerElement).toHaveClass('border-t-2');
    expect(spinnerElement).toHaveClass('border-b-2');
    expect(spinnerElement).toHaveClass('border-primary');
  });
  
  it('추가 클래스를 받아 적용합니다', () => {
    const { container } = render(<LoadingSpinner className="test-class" />);
    
    // 컨테이너에 추가 클래스가 적용되었는지 확인합니다
    const spinnerContainer = container.querySelector('div.flex.justify-center.items-center');
    expect(spinnerContainer).toHaveClass('test-class');
    
    // 기본 클래스도 유지되는지 확인합니다
    expect(spinnerContainer).toHaveClass('flex');
    expect(spinnerContainer).toHaveClass('justify-center');
    expect(spinnerContainer).toHaveClass('items-center');
  });
}); 