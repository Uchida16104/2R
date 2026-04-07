import PouchDB from 'pouchdb'
import PouchDBFind from 'pouchdb-find'

PouchDB.plugin(PouchDBFind)

let db: PouchDB.Database | null = null

export function getDB(): PouchDB.Database {
  if (!db) {
    db = new PouchDB('2r_reservations')
  }
  return db
}

export function destroyDB(): Promise<void> {
  if (db) {
    const instance = db
    db = null
    return instance.destroy()
  }
  return Promise.resolve()
}
