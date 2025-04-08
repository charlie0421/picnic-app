import React from 'react';

interface ItemCardProps {
  title: string;
  description: string;
}

export default function ItemCard({ title, description }: ItemCardProps) {
  return (
    <div className="item-card">
      <h3>{title}</h3>
      <p>{description}</p>
    </div>
  );
}
