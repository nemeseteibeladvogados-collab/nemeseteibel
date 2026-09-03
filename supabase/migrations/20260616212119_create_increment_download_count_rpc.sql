
CREATE OR REPLACE FUNCTION increment_download_count(material_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE materials
  SET download_count = download_count + 1
  WHERE id = material_id;
END;
$$;
;
