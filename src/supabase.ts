import { createClient } from "@supabase/supabase-js";

export const supabaseClient = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_KEY
);

export interface SignUpUser {
  email: string;
  username: string;
  password: string;
}

export interface SignInUser {
  email: string;
  username: string;
  password: string;
}

export const signUp = (user: SignUpUser) => {
  return supabaseClient.auth.signUp(
    { email: user.email, password: user.password },
    { data: { username: user.username } }
  );
};

export const signIn = (user: SignInUser) => {
  return supabaseClient.auth.signIn({
    email: user.email,
    password: user.password,
  });
};

export const signOut = async () => supabaseClient.auth.signOut();

export const session = () => supabaseClient.auth.session();
