import { ApiError, Session } from "@supabase/supabase-js";
import { ClientQuote, SignInUser, SignUpUser, SupabaseFlags } from "./types";

export namespace Elm {
  export namespace Main {
    export interface App {
      ports: {
        getQuotes: {
          subscribe(callback: (userId: string) => Promise<void>): void;
        };
        addQuote: {
          subscribe(callback: (data: ClientQuote) => Promise<void>): void;
        };
        editQuote: {
          subscribe(callback: (data: ClientQuote) => Promise<void>): void;
        };
        deleteQuote: {
          subscribe(
            callback: (data: ClientQuote | null) => Promise<void>
          ): void;
        };
        quoteResponse: {
          send(data: any): Promise<void>;
        };
        signUp: {
          subscribe(callback: (user: SignUpUser) => Promise<void>): void;
        };
        signUpResponse: {
          send(data: Session | ApiError): Promise<void>;
        };
        signIn: {
          subscribe(callback: (user: SignInUser) => Promise<void>): void;
        };
        signInResponse: {
          send(data: Session | ApiError): Promise<void>;
        };
        signOut: {
          subscribe(callback: () => Promise<void>): void;
        };
        session: {
          subscribe(callback: () => Promise<void>): void;
        };
        sessionResponse: {
          send(data: Session | null): Promise<void>;
        };
      };
    }

    export function init(options: {
      node?: HTMLElement | null;
      flags: { seed: number; supabase: SupabaseFlags };
    }): Elm.Main.App;
  }
}
