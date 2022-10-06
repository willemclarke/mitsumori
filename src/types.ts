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

export interface SupabaseFlags {
  supabaseUrl: string;
  supabaseKey: string;
}

export interface ClientQuote {
  quote: string;
  author: string;
  userId: string | null;
}

export interface SupabaseQuote {
  id: string;
  quote_text: string;
  quote_author: string;
  created_at: string;
  user_id: string;
}
