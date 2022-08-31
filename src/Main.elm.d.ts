import { Quote } from "./main";

export namespace Elm {
  export namespace Main {
    export interface App {
      ports: {
        getQuotes: {
          subscribe(callback: (key: string) => Promise<void>): void;
        };
        getQuotesResponse: {
          send(data: [string, Quote[] | undefined]): Promise<void>;
        };
        setQuote: {
          subscribe(callback: (data: [string, Quote]) => Promise<void>): void;
        };
      };
    }

    export function init(options: { node?: HTMLElement | null }): Elm.Main.App;
  }
}
