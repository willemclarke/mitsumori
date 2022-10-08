import { createClient } from "@supabase/supabase-js";
import { ClientQuote, SignInUser, SignUpUser } from "./types";

export const supabaseClient = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_KEY
);

export const getQuotes = async (userId: string) => {
  return supabaseClient
    .from("quotes")
    .select("*")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });
};

export const insertQuote = async (quote: ClientQuote) => {
  return supabaseClient.from("quotes").insert([
    {
      quote_text: quote.quote,
      quote_author: quote.author,
      user_id: quote.userId,
    },
  ]);
};

export const updateQuote = async (quote: ClientQuote) => {
  return supabaseClient
    .from("quotes")
    .update({
      quote_text: quote.quote,
      quote_author: quote.author,
      quote_reference: quote.reference,
    })
    .eq("id", quote.quoteId);
};

export const deleteQuote = async (quoteId: string) => {
  return supabaseClient.from("quotes").delete().eq("id", quoteId);
};

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
