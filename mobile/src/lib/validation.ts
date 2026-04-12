import { z } from 'zod';

export function parseEmail(value: string, invalidEmailMessage: string) {
  return z.string().trim().email(invalidEmailMessage).safeParse(value);
}

export function parsePassword(value: string, minLengthMessage: string) {
  return z.string().min(12, minLengthMessage).safeParse(value);
}
