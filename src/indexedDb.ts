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

export const getQuotes = async (key: string): Promise<Quote[] | undefined> => {
  const db = await openDbConnection();
  return db.get(objectStoreName, key);
};

export const setQuotes = async (key: string, value: Quote): Promise<void> => {
  const db = await openDbConnection();
  const existingQuotes = await getQuotes(key);

  if (!existingQuotes) {
    await db.put(objectStoreName, [value], key);
    return;
  }
  await db.put(objectStoreName, [...existingQuotes, value], key);
};
