import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "https://mfmmmlmbmhogybwcfhqm.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mbW1tbG1ibWhvZ3lid2NmaHFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjI0NjQ0MzQsImV4cCI6MTk3ODA0MDQzNH0.UMgK0VTp_QhOUQsj1FO7hB8S3_FRHerT6t5hyBES4tE";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export interface User {
  email: string;
  username: string;
  password: string;
}

export const signUp = async (user: User) => {
  return await supabase.auth.signUp(
    { email: user.email, password: user.password },
    { data: { username: user.username } }
  );
};

export const signIn = async (user: Omit<User, "username">) =>
  await supabase.auth.signIn({ email: user.email, password: user.password });
