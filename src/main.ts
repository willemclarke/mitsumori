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
      supabaseUrl: import.meta.env.VITE_SUPABASE_URL_GRAPHQL,
      supabaseKey: import.meta.env.VITE_SUPABASE_KEY,
    },
  },
});

app.ports.editQuote.subscribe(async (clientQuote) => {
  const { data, error } = await supabase.updateQuote(clientQuote);
  if (data) {
    const { data: quotes, error } = await supabase.getQuotes(
      clientQuote.userId ?? ""
    );
    return app.ports.quoteResponse.send(quotes ?? error);
  }

  if (error) {
    return app.ports.quoteResponse.send(error);
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
  const { error } = await supabase.signOut();

  if (!error) {
    return app.ports.signOutResponse.send("Success");
  }

  return app.ports.signOutResponse.send(error);
});

app.ports.getSession.subscribe(async () => {
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
