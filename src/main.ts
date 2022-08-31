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

app.ports.getQuotes.subscribe((key) => {
  console.log("dwdwdwd");
  return getQuotes(key).then((value) =>
    app.ports.getQuotesResponse.send([key, value])
  );
});

app.ports.setQuote.subscribe(([key, value]) => {
  console.log("dwkdwdwd");
  return setQuotes(key, value);
});
