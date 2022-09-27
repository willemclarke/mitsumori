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

app.ports.supabaseSignUp.subscribe(async (user) => {
  const { session, error } = await supabase.signUp(user);
  if (session) {
    return app.ports.supabaseSignUpResponse.send(session);
  }

  if (error) {
    return app.ports.supabaseSignUpResponse.send(error);
  }
});
