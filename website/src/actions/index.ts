import { defineAction, ActionError } from 'astro:actions';
import { z } from 'astro/zod';
import { db } from "../db";
import { messages, users} from "../db/schema";
import { eq } from 'drizzle-orm';

const COOLDOWN_MS = 10_000;
const TIMEOUT_MS = 600_000

export const server = {
  sendEntry: defineAction({
    input: z.object({
      name: z.string(),
      message: z.string()
    }),
    handler: async ({ name, message }, context) => {
      const forwardedFor = context.request.headers.get('x-forwarded-for')
      let ip = forwardedFor
              ? forwardedFor.split(',')[0].trim()
              : context.clientAddress;
      if (ip == '::1') {
        ip = "localhost"
      }
      const nameValid = name.length >= 1 && name.length <= 50
      const messageValid = message.length >= 1 && message.length <= 500
      if (!nameValid && !messageValid) {
        throw new ActionError({
          code: 'NOT_ACCEPTABLE',
          message: `406 - Not acceptable. Your name and message cannot be empty. Here's your ip: ${ip}`
        })
      }

      const [user] = await db.select().from(users).where(eq(users.ip, ip));
      const latestMs = user?.latest ? new Date(user.latest).getTime() : 0;

      const date = new Date();
      const dt = date.getTime() - latestMs
      const warnings = user?.warnings ?? 0;
      const limited = user?.limited ?? 0;

      if (limited >= 5) {
        throw new ActionError({
          code: 'NOT_ACCEPTABLE',
          message: `406 - Not acceptable. You were timed out FOREVER. This is your ${user.limited} timeout`
        })
      }
      if (warnings>=4) {
        if (dt > TIMEOUT_MS) {
          await db.update(users).set({ warnings: 0 }).where(eq(users.ip, ip));
        } else {
          throw new ActionError({
            code: 'NOT_ACCEPTABLE',
            message: `406 - Not acceptable. You were timed out for an hour. This is your ${limited} timeout`
          })
        }
      } else if (dt <= COOLDOWN_MS) {
        const nextWarnings = warnings + 1;
        const nextLimited = nextWarnings >= 4 ? limited + 1 : limited;

        await db.insert(users).values({ ip, warnings: nextWarnings, limited: nextLimited }).onConflictDoUpdate({ target: users.ip, set: { warnings: nextWarnings, limited: nextLimited } });
        let msg = `406 - Not acceptable. You should stop spamming that send button.`;
        if (nextLimited >= 5) {
          msg = `406 - Not acceptable. You were timed out FOREVER. This is your ${nextLimited} timeout`;
        } else if (nextWarnings >= 4) {
          msg = `406 - Not acceptable. You were timed out for an hour. This is your ${nextLimited} timeout`;
        }
        throw new ActionError({
          code: 'NOT_ACCEPTABLE',
          message: msg,
        })
      }

      await db.insert(messages).values({
        name,
        message,
        date,
        ip
      });
      await db.insert(users).values({ ip, latest: date }).onConflictDoUpdate({ target: users.ip, set: { latest: date } });
      return {
        name,
        message,
        date,
      }
    }
  })
}
