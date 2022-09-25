import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_KEY
);

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
