import React from 'react';
import { Input } from 'antd';

interface TextEditorProps {
  value?: string;
  onChange?: (value: string) => void;
}

const TextEditor: React.FC<TextEditorProps> = ({ value, onChange }) => {
  // 여기서는 간단한 TextArea를 사용하지만, 실제로는 React-Quill 등의 WYSIWYG 에디터를 사용할 수 있습니다.
  return (
    <Input.TextArea
      value={value}
      onChange={(e) => onChange?.(e.target.value)}
      rows={10}
      placeholder="내용을 입력하세요"
    />
  );
};

export default TextEditor; 