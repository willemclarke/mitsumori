import { getQuotes, setQuotes } from "./indexedDb";
import { Elm } from "./Main.elm";

export interface Quote {
  quote: string;
}

if (process.env.NODE_ENV === "development") {
  const ElmDebugTransform = await import("elm-debug-transformer");

  ElmDebugTransform.register({
    simple_mode: true,
  });
}

const root = document.getElementById("elm");
const app = Elm.Main.init({ node: root });

app.ports.dataStoreGetQuotes.subscribe((key) => {
  return getQuotes(key).then((value) =>
    app.ports.dataStoreGetQuoteResponse.send([key, value])
  );
});

app.ports.dataStoreSetQuote.subscribe(([key, value]) => {
  console.log({ key, value });
  return setQuotes(key, value);
});
