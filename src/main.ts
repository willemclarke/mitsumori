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
  return getQuotes().then((value) =>
    app.ports.dataStoreGetQuoteResponse.send(value)
  );
});

app.ports.dataStoreSetQuote.subscribe(async (value) => {
  await setQuotes(value);
  return getQuotes().then((value) =>
    app.ports.dataStoreGetQuoteResponse.send(value)
  );
});
