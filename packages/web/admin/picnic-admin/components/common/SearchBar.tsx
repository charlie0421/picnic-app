'use client';

import React, { useState } from 'react';
import { Input, Row, Col } from 'antd';

interface SearchBarProps {
  placeholder?: string;
  onSearch: (value: string) => void;
  width?: number | string;
}

export const SearchBar: React.FC<SearchBarProps> = ({
  placeholder = '검색어를 입력하세요',
  onSearch,
  width = 300,
}) => {
  const [inputValue, setInputValue] = useState<string>('');

  // 검색 핸들러
  const handleSearch = (value: string) => {
    onSearch(value.trim());
  };

  // 검색어 초기화 핸들러
  const handleClear = () => {
    setInputValue('');
    onSearch('');
  };

  // 입력 핸들러
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(e.target.value);
    if (!e.target.value) {
      handleClear();
    }
  };

  return (
    <Row gutter={[16, 16]} style={{ marginBottom: '16px' }} align='middle'>
      <Col>
        <Input.Search
          placeholder={placeholder}
          value={inputValue}
          onChange={handleInputChange}
          onSearch={handleSearch}
          style={{ width }}
          allowClear
        />
      </Col>
    </Row>
  );
};

export default SearchBar;
