export interface SignUpUser {
  email: string;
  username: string;
  password: string;
}

export interface SignInUser {
  email: string;
  password: string;
}

export interface SupabaseFlags {
  supabaseUrl: string;
  supabaseKey: string;
}
