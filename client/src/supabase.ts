import { createClient } from "@supabase/supabase-js";
import { SignInUser, SignUpUser } from "./types";

export const supabaseClient = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_KEY
);

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
