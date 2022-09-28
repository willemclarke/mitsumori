import { ApiError, Session } from "@supabase/supabase-js";
import { User } from "./supabase";

interface Supabase {
  supabaseUrl: string;
  supabaseKey: string;
}

export namespace Elm {
  export namespace Main {
    export interface App {
      ports: {
        supabaseSignUp: {
          subscribe(callback: (user: User) => Promise<void>): void;
        };
        supabaseSignUpResponse: {
          send(data: Session | ApiError): Promise<void>;
        };
        subabaseSignOut: {
          subscribe(callback: () => Promise<void>): void;
        };
        supabaseSession: {
          subscribe(callback: () => Promise<void>): void;
        };
        subabaseSessionResponse: {
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
