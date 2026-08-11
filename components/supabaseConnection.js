import { createClient } from '@supabase/supabase-js';

// Replace with your actual Supabase URL and Anon Key
const supabaseUrl = "https://ywuoycwwtvynagrukdow.supabase.co";
const supabaseKey = "sb_publishable_XM2f_-CC6lDsGnD2eTiZXA_TDpImgKJ";

export const supabase = createClient(supabaseUrl, supabaseKey);