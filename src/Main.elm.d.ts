import { Quote } from "./main";

export namespace Elm {
  export namespace Main {
    export interface App {
      ports: {
        dataStoreGetQuotes: {
          subscribe(callback: (key: string) => Promise<void>): void;
        };
        dataStoreGetQuoteResponse: {
          send(data: [key: string, value: Quote[] | undefined]): Promise<void>;
        };
        dataStoreSetQuote: {
          subscribe(
            callback: (data: [key: string, value: Quote]) => Promise<void>
          ): void;
        };
      };
    }

    export function init(options: { node?: HTMLElement | null }): Elm.Main.App;
  }
}
