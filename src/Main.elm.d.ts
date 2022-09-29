import { ApiError, Session } from "@supabase/supabase-js";
import { SignInUser, SignUpUser } from "./supabase";

interface Supabase {
  supabaseUrl: string;
  supabaseKey: string;
}

export namespace Elm {
  export namespace Main {
    export interface App {
      ports: {
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
      flags: { seed: number; supabase: Supabase };
    }): Elm.Main.App;
  }
}
