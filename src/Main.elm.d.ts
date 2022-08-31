export namespace Elm {
  export namespace Main {
    export interface App {
      ports: {
        localStorageGet: {
          subscribe(callback: (key: string) => Promise<void>): void;
        };
        localStorageSet: {
          subscribe(
            callback: (
              data: [key: string, value: Record<string, unknown>]
            ) => Promise<void>
          ): void;
        };
      };
    }

    export function init(options: {
      node?: HTMLElement | null;
      //   flags: Flags
    }): Elm.Main.App;
  }
}
