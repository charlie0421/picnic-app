-- Staging security baseline. Legacy integer user tables remain deny-by-default
-- until their ownership model is migrated to auth.users UUIDs.

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'album', 'album_image', 'album_image_user', 'article',
    'article_comment', 'article_comment_like', 'article_comment_report',
    'article_image', 'article_image_user', 'banner', 'celeb', 'celeb_user',
    'gallery', 'gallery_user', 'library', 'library_image', 'mystar_group',
    'mystar_member', 'point_history', 'point_sst', 'prame-users', 'reward',
    'user', 'user_agreement', 'user_comment_like', 'user_comment_report',
    'vote', 'vote_comment', 'vote_comment_like', 'vote_comment_report',
    'vote_item', 'vote_pick'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
  end loop;
end
$$;

create policy "public_read_article" on public.article for select to anon, authenticated using (deleted_at is null);
create policy "public_read_article_image" on public.article_image for select to anon, authenticated using (deleted_at is null);
create policy "public_read_banner" on public.banner for select to anon, authenticated using (deleted_at is null and (start_at is null or start_at <= now()) and (end_at is null or end_at >= now()));
create policy "public_read_celeb" on public.celeb for select to anon, authenticated using (deleted_at is null);
create policy "public_read_gallery" on public.gallery for select to anon, authenticated using (deleted_at is null);
create policy "public_read_mystar_group" on public.mystar_group for select to anon, authenticated using (deleted_at is null);
create policy "public_read_mystar_member" on public.mystar_member for select to anon, authenticated using (deleted_at is null);
create policy "public_read_reward" on public.reward for select to anon, authenticated using (deleted_at is null and (start_at is null or start_at <= now()) and (end_at is null or end_at >= now()));
create policy "public_read_vote" on public.vote for select to anon, authenticated using (deleted_at is null and (visible_at is null or visible_at <= now()));
create policy "public_read_vote_item" on public.vote_item for select to anon, authenticated using (deleted_at is null);

drop policy if exists "policy_user_profiles" on public.user_profiles;
create policy "user_profiles_select_own" on public.user_profiles for select to authenticated using ((select auth.uid()) = id);
create policy "user_profiles_insert_own" on public.user_profiles for insert to authenticated with check ((select auth.uid()) = id);
create policy "user_profiles_update_own" on public.user_profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy "celeb_user_select_own" on public.celeb_user for select to authenticated using ((select auth.uid()) = user_id);
create policy "celeb_user_insert_own" on public.celeb_user for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "celeb_user_delete_own" on public.celeb_user for delete to authenticated using ((select auth.uid()) = user_id);

create policy "article_image_user_select_own" on public.article_image_user for select to authenticated using ((select auth.uid()) = user_id);
create policy "article_image_user_insert_own" on public.article_image_user for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "article_image_user_delete_own" on public.article_image_user for delete to authenticated using ((select auth.uid()) = user_id);

alter function public.handle_new_user() set search_path = '';
revoke execute on function public.handle_new_user() from public, anon, authenticated;
