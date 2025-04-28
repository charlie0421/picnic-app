// app/page.tsx
import { redirect } from 'next/navigation';

export default function Home() {
  redirect('/vote');
  return null;
}