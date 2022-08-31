import { openDB, DBSchema } from "idb";
import { Quote } from "./main";

const databaseName = "Mitsumori";
const objectStoreName = "MitsumoriStore";

interface MitsumoriDB extends DBSchema {
  MitsumoriStore: {
    key: string;
    value: Quote[];
  };
}

const openDbConnection = () => {
  return openDB<MitsumoriDB>(databaseName, 1, {
    upgrade: (db) => {
      db.createObjectStore(objectStoreName);
    },
  });
};

export const getQuotes = async (key: string) => {
  console.log("inside here");
  const db = await openDbConnection();
  return db.get(objectStoreName, key);
};

export const setQuotes = async (key: string, value: Quote): Promise<void> => {
  console.log("inside here setQuotes");
  const db = await openDbConnection();
  const existingQuotes = await getQuotes(key);
  if (!existingQuotes) {
    return;
  }
  await db.put(objectStoreName, [...existingQuotes, value], key);
};
