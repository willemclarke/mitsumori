import { getQuotes, setQuotes } from "./indexedDb";
import { Elm } from "./Main.elm";

export interface Quote {
  quote: string;
  id: number;
}

if (process.env.NODE_ENV === "development") {
  const ElmDebugTransform = await import("elm-debug-transformer");

  ElmDebugTransform.register({
    simple_mode: true,
  });
}

const root = document.getElementById("elm");
const app = Elm.Main.init({
  node: root,
  flags: { seed: Math.floor(Math.random() * 0x0fffffff) },
});

app.ports.dataStoreGetQuotes.subscribe(() => {
  return getQuotes().then((quotes) =>
    app.ports.dataStoreGetQuoteResponse.send(quotes)
  );
});

app.ports.dataStoreSetQuote.subscribe(async (value) => {
  return setQuotes(value).then(() =>
    getQuotes().then((quotes) =>
      app.ports.dataStoreGetQuoteResponse.send(quotes)
    )
  );
});
