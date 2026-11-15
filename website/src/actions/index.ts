import { defineAction, ActionError } from 'astro:actions';
import { z } from 'astro/zod';
import { db } from "../db";
import { messages } from "../db/schema";

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
      const date = new Date;
      await db.insert(messages).values({
        name,
        message,
        date,
        ip
      });

      return {
        name,
        message,
        date,
      }
    }
  })
}
