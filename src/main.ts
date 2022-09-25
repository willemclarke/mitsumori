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
    supabaseUrl: import.meta.env.VITE_SUPABASE_URL,
    supabaseKey: import.meta.env.VITE_SUPABASE_KEY,
    seed: Math.floor(Math.random() * 0x0fffffff),
  },
});

app.ports.signUp.subscribe(async (user) => {
  const { session, error } = await supabase.signUp(user);

  if (!session) {
    return app.ports.signUpResonse.send(error);
  }
  return app.ports.signUpResonse.send(session);
});
