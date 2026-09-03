
-- Políticas de Storage para o bucket 'materials'
-- Admins autenticados podem fazer upload
CREATE POLICY "auth_upload_materials"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'materials');

-- Admins autenticados podem deletar
CREATE POLICY "auth_delete_materials"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'materials');

-- Qualquer pessoa pode gerar signed URL (SELECT necessário para createSignedUrl)
CREATE POLICY "public_read_materials"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (bucket_id = 'materials');

-- Permite que anon e authenticated chamem o RPC de incremento
GRANT EXECUTE ON FUNCTION increment_download_count(UUID) TO anon, authenticated;
;
