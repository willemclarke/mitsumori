export namespace Elm {
  export namespace Main {
    export interface App {
      // type ports inside here when the need arises
    }

    export function init(options: {
      node?: HTMLElement | null;
      //   flags: Flags
    }): Elm.Main.App;
  }
}
