import { User } from "./supabase";

export namespace Elm {
  export namespace Main {
    export interface App {
      ports: {
        signUp: {
          subscribe(callback: (user: User) => Promise<void>): void;
        };
        signUpResonse: {
          send(data: unknown): Promise<void>;
        };
      };
    }

    export function init(options: {
      node?: HTMLElement | null;
      flags: { seed: number; supabaseUrl: string; supabaseKey: string };
    }): Elm.Main.App;
  }
}
