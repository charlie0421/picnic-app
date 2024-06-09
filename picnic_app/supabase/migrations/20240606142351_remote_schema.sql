CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION chats.handle_new_user();


create policy "Anyone can upload an avatar."
on "storage"."objects"
as permissive
for insert
to public
with check ((bucket_id = 'avatars'::text));


create policy "Avatar images are publicly accessible."
on "storage"."objects"
as permissive
for select
to public
using ((bucket_id = 'avatars'::text));


create policy "storage.object_grant_create_auth_chats_assets"
on "storage"."objects"
as permissive
for insert
to public
with check (((bucket_id = 'chats_assets'::text) AND chats.is_chat_member(((storage.foldername(name))[1])::bigint)));


create policy "storage.object_grant_create_auth_chats_user_avatar"
on "storage"."objects"
as permissive
for insert
to public
with check (((bucket_id = 'chats_user_avatar'::text) AND chats.is_owner(((storage.foldername(name))[1])::uuid)));


create policy "storage.object_grant_delete_auth_chats_assets"
on "storage"."objects"
as permissive
for delete
to public
using (((bucket_id = 'chats_assets'::text) AND chats.is_chat_member(((storage.foldername(name))[1])::bigint)));


create policy "storage.object_grant_delete_auth_chats_user_avatar"
on "storage"."objects"
as permissive
for delete
to public
using (((bucket_id = 'chats_user_avatar'::text) AND chats.is_owner(((storage.foldername(name))[1])::uuid)));


create policy "storage.object_grant_read_auth_chats_assets"
on "storage"."objects"
as permissive
for select
to public
using (((bucket_id = 'chats_assets'::text) AND chats.is_chat_member(((storage.foldername(name))[1])::bigint)));


create policy "storage.object_grant_read_auth_chats_user_avatar"
on "storage"."objects"
as permissive
for select
to public
using (((bucket_id = 'chats_user_avatar'::text) AND chats.is_auth()));


create policy "storage.object_grant_update_auth_chats_assets"
on "storage"."objects"
as permissive
for update
to public
using (((bucket_id = 'chats_assets'::text) AND chats.is_chat_member(((storage.foldername(name))[1])::bigint)))
with check (((bucket_id = 'chats_assets'::text) AND chats.is_chat_member(((storage.foldername(name))[1])::bigint)));


create policy "storage.object_grant_update_auth_chats_user_avatar"
on "storage"."objects"
as permissive
for update
to public
using (((bucket_id = 'chats_user_avatar'::text) AND chats.is_owner(((storage.foldername(name))[1])::uuid)))
with check (((bucket_id = 'chats_user_avatar'::text) AND chats.is_owner(((storage.foldername(name))[1])::uuid)));



