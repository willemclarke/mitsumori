import { Quote } from "./main";

export namespace Elm {
  export namespace Main {
    export interface App {
      ports: {
        dataStoreGetQuotes: {
          subscribe(callback: () => Promise<void>): void;
        };
        dataStoreGetQuoteResponse: {
          send(data: Quote[] | undefined): Promise<void>;
        };
        dataStoreSetQuote: {
          subscribe(callback: (data: Quote) => Promise<void>): void;
        };
      };
    }

    export function init(options: {
      node?: HTMLElement | null;
      flags: { seed: number };
    }): Elm.Main.App;
  }
}
