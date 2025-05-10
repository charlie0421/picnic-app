import React, {useCallback, useEffect, useState} from 'react';
import {useLanguageStore} from '@/stores/languageStore';
import {VoteItem} from '@/types/interfaces';
import {getLocalizedString} from '@/utils/api/strings';

interface VoteSearchProps {
  onSearch: (query: string) => void;
  onFilterChange?: (filter: SearchFilter) => void;
  searchResults?: VoteItem[];
  totalItems?: number;
  isLoading?: boolean;
  placeholder?: string;
  className?: string;
  filter?: 'all' | 'artist' | 'group';
  disabled?: boolean;
}

type SearchFilter = 'all' | 'artist' | 'group';

const VoteSearch: React.FC<VoteSearchProps> = ({
  onSearch,
  onFilterChange,
  searchResults = [],
  totalItems = 0,
  isLoading = false,
  placeholder,
  className = '',
  filter,
  disabled = false,
}) => {
  const { t } = useLanguageStore();
  const [searchQuery, setSearchQuery] = useState('');
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [selectedFilter, setSelectedFilter] = useState<SearchFilter>('all');
  const [debouncedQuery, setDebouncedQuery] = useState('');

  // 디바운스 처리
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedQuery(searchQuery);
    }, 300);

    return () => clearTimeout(timer);
  }, [searchQuery]);

  // 검색 실행
  useEffect(() => {
    onSearch(debouncedQuery);
  }, [debouncedQuery, onSearch]);

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (disabled) return;
    const query = e.target.value;
    setSearchQuery(query);
    setShowSuggestions(query.length > 0);
  };

  const clearSearch = () => {
    if (disabled) return;
    setSearchQuery('');
    setShowSuggestions(false);
    onSearch('');
  };

  const handleFilterChange = (filter: SearchFilter) => {
    if (disabled) return;
    setSelectedFilter(filter);
    onFilterChange?.(filter);
  };

  const highlightMatch = (text: string) => {
    if (!searchQuery) return text;
    const regex = new RegExp(`(${searchQuery})`, 'gi');
    return text.split(regex).map((part, i) =>
      regex.test(part) ? (
        <span key={i} className='bg-yellow-200'>
          {part}
        </span>
      ) : (
        part
      ),
    );
  };

  const getFilteredResults = useCallback(() => {
    if (!searchResults) return [];

    return searchResults.filter((item) => {
      if (selectedFilter === 'all') return true;
      if (selectedFilter === 'artist') return item.artist?.name;
      if (selectedFilter === 'group') return item.artist?.name;
      return true;
    });
  }, [searchResults, selectedFilter]);

  return (
    <div className={`relative ${className}`}>
      <div className='relative'>
        <input
          type='text'
          value={searchQuery}
          onChange={handleSearch}
          placeholder={placeholder || t('text_vote_where_is_my_bias')}
          className={`w-full p-3 pl-12 rounded-full border border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent ${
            disabled ? 'bg-gray-100 cursor-not-allowed opacity-75' : ''
          }`}
          disabled={disabled}
        />
        <div className='absolute left-4 top-1/2 transform -translate-y-1/2'>
          <svg
            xmlns='http://www.w3.org/2000/svg'
            className={`h-5 w-5 ${
              disabled ? 'text-gray-400' : 'text-gray-600'
            }`}
            fill='none'
            viewBox='0 0 24 24'
            stroke='currentColor'
          >
            <path
              strokeLinecap='round'
              strokeLinejoin='round'
              strokeWidth={2}
              d='M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z'
            />
          </svg>
        </div>
        {searchQuery && !disabled && (
          <button
            onClick={clearSearch}
            className='absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-600'
          >
            <svg
              xmlns='http://www.w3.org/2000/svg'
              className='h-5 w-5'
              fill='none'
              viewBox='0 0 24 24'
              stroke='currentColor'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                strokeWidth={2}
                d='M6 18L18 6M6 6l12 12'
              />
            </svg>
          </button>
        )}
      </div>

      {isLoading && !disabled && (
        <div className='absolute right-4 top-1/2 transform -translate-y-1/2'>
          <div className='animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-primary'></div>
        </div>
      )}

      {showSuggestions && searchQuery && !disabled && (
        <div className='absolute z-10 w-full mt-2 bg-white rounded-lg shadow-lg border border-gray-200 max-h-60 overflow-y-auto'>
          {getFilteredResults().length > 0 ? (
            getFilteredResults().map((item) => (
              <div
                key={item.id}
                className='p-3 hover:bg-gray-50 cursor-pointer border-b border-gray-100 last:border-b-0'
              >
                <div className='flex items-center'>
                  <div className='flex-1'>
                    <p className='font-medium'>
                      {highlightMatch(
                        getLocalizedString(item.artist?.name) || '',
                      )}
                    </p>
                    <p className='text-sm text-gray-600'>
                      {highlightMatch(
                        getLocalizedString(item.artist?.name) ||
                          '',
                      )}
                    </p>
                  </div>
                  <div className='text-sm text-gray-500'>
                    {item.voteTotal?.toLocaleString() || 0} {t('label_votes')}
                  </div>
                </div>
              </div>
            ))
          ) : (
            <div className='p-3 text-center text-gray-500'>
              {t('text_no_search_results')}
            </div>
          )}
        </div>
      )}

      {searchQuery && !disabled && (
        <div className='mt-2 text-sm text-gray-500'>
          {t('text_search_results_count', {
            count: getFilteredResults().length.toString(),
            total: totalItems.toString(),
          })}
        </div>
      )}
    </div>
  );
};

export default VoteSearch;
