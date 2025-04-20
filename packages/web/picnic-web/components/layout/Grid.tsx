import React from 'react';

interface GridProps {
  children: React.ReactNode;
  className?: string;
  cols?: {
    default?: number;
    sm?: number;
    md?: number;
    lg?: number;
    xl?: number;
  };
  gap?: {
    default?: string;
    sm?: string;
    md?: string;
    lg?: string;
    xl?: string;
  };
}

const Grid: React.FC<GridProps> = ({
  children,
  className = '',
  cols = { default: 1, sm: 2, md: 3, lg: 4 },
  gap = { default: '4', sm: '6', md: '8' },
}) => {
  const getGridCols = () => {
    const defaultCols = cols.default ? `grid-cols-${cols.default}` : 'grid-cols-1';
    const smCols = cols.sm ? `sm:grid-cols-${cols.sm}` : '';
    const mdCols = cols.md ? `md:grid-cols-${cols.md}` : '';
    const lgCols = cols.lg ? `lg:grid-cols-${cols.lg}` : '';
    const xlCols = cols.xl ? `xl:grid-cols-${cols.xl}` : '';

    return `${defaultCols} ${smCols} ${mdCols} ${lgCols} ${xlCols}`;
  };

  const getGap = () => {
    const defaultGap = gap.default ? `gap-${gap.default}` : 'gap-4';
    const smGap = gap.sm ? `sm:gap-${gap.sm}` : '';
    const mdGap = gap.md ? `md:gap-${gap.md}` : '';
    const lgGap = gap.lg ? `lg:gap-${gap.lg}` : '';
    const xlGap = gap.xl ? `xl:gap-${gap.xl}` : '';

    return `${defaultGap} ${smGap} ${mdGap} ${lgGap} ${xlGap}`;
  };

  return (
    <div className={`grid ${getGridCols()} ${getGap()} ${className}`}>
      {children}
    </div>
  );
};

export default Grid; 