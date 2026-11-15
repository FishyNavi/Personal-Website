import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";


export const messages = sqliteTable('messages', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  message: text('message').notNull(),
  date: integer('date', {mode: 'timestamp'}),
  ip: text('ip').notNull(),
});
export const users = sqliteTable('users', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  ip: text('ip').unique().notNull(),
  latest: integer('latest', { mode: 'timestamp' }),
  warnings: integer('warnings'),
  limited: integer('limited'),
  blacklisted: integer('blacklisted', { mode:'boolean'}),
})
