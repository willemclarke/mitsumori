import { openDB, DBSchema } from "idb";
import { Quote } from "./main";

const databaseName = "Mitsumori";
const objectStoreName = "MitsumoriStore";

interface MitsumoriDB extends DBSchema {
  MitsumoriStore: {
    key: number;
    value: Quote;
  };
}

const openDbConnection = () => {
  return openDB<MitsumoriDB>(databaseName, 1, {
    upgrade: (db) => {
      db.createObjectStore(objectStoreName, {
        keyPath: "id",
        autoIncrement: true,
      });
    },
  });
};

export const getQuotes = async (): Promise<Quote[] | undefined> => {
  const db = await openDbConnection();
  return db.getAll(objectStoreName);
};

export const setQuotes = async (value: Quote): Promise<void> => {
  const db = await openDbConnection();
  await db.put(objectStoreName, value, value.id);
};
