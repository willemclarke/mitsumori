import { Elm } from "./Main.elm";
import * as supabase from "./supabase";

if (process.env.NODE_ENV === "development") {
  const ElmDebugTransform = await import("elm-debug-transformer");

  ElmDebugTransform.register({
    simple_mode: true,
  });
}

const root = document.getElementById("elm");

const app = Elm.Main.init({
  node: root,
  flags: {
    seed: Math.floor(Math.random() * 0x0fffffff),
    supabase: {
      supabaseUrl: import.meta.env.VITE_SUPABASE_URL,
      supabaseKey: import.meta.env.VITE_SUPABASE_KEY,
    },
  },
});

app.ports.getQuotes.subscribe(async (userId) => {
  const { data: quotes, error } = await supabase.getQuotes(userId);
  if (quotes) {
    // TODO: better name for port since it gets used for adding a quote and sending them back
    // and also just getting quotes
    return app.ports.addQuoteResponse.send(quotes);
  }

  if (error) {
    return app.ports.addQuoteResponse.send(error);
  }
});

app.ports.addQuote.subscribe(async (clientQuote) => {
  const { data, error } = await supabase.insertQuote(clientQuote);
  if (data) {
    const { data: quotes, error } = await supabase.getQuotes(
      clientQuote.userId ?? ""
    );
    return app.ports.addQuoteResponse.send(quotes ?? error);
  }

  if (error) {
    app.ports.addQuoteResponse.send(error);
  }
});

app.ports.signUp.subscribe(async (user) => {
  const { session, error } = await supabase.signUp(user);

  if (session) {
    return app.ports.signUpResponse.send(session);
  }

  if (error) {
    return app.ports.signUpResponse.send(error);
  }
});

app.ports.signIn.subscribe(async (user) => {
  const { session, error } = await supabase.signIn(user);

  if (session) {
    return app.ports.signInResponse.send(session);
  }

  if (error) {
    return app.ports.signInResponse.send(error);
  }
});

app.ports.signOut.subscribe(async () => {
  await supabase.signOut();
});

app.ports.session.subscribe(async () => {
  const session = supabase.session();
  return app.ports.sessionResponse.send(session);
});

const onAuthChange = () => {
  return supabase.supabaseClient.auth.onAuthStateChange((event, session) => {
    switch (event) {
      case "TOKEN_REFRESHED": {
        console.log("inside token refreshed");
        console.log("Refreshing user session/token");
        return app.ports.sessionResponse.send(session);
      }
      default:
        return;
    }
  });
};
onAuthChange();
