import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
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
  return supabase.auth.signUp(
    { email: user.email, password: user.password },
    { data: { username: user.username } }
  );
};

export const signIn = (user: SignInUser) => {
  return supabase.auth.signIn({
    email: user.email,
    password: user.password,
  });
};

export const onAuthChange = async () =>
  supabase.auth.onAuthStateChange((event, session) => {
    console.log({ event, session });
  });

export const signOut = async () => supabase.auth.signOut();

export const session = () => supabase.auth.session();
