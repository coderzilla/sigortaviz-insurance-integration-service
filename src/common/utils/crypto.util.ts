// src/common/utils/crypto.util.ts
import crypto from 'node:crypto';

const DEFAULT_HASH_ALGO = 'sha256';

export const createOtpSalt = (): string =>
  crypto.randomBytes(16).toString('hex');

export const hashOtpCode = (
  code: string,
  salt: string,
  secret: string,
  algo: string = DEFAULT_HASH_ALGO,
): string => {
  return crypto.createHmac(algo, `${salt}:${secret}`).update(code).digest('hex');
};

export const timingSafeEqualStr = (a: string, b: string): boolean => {
  const aBuf = Buffer.from(a);
  const bBuf = Buffer.from(b);
  if (aBuf.length !== bBuf.length) {
    return false;
  }
  return crypto.timingSafeEqual(aBuf, bBuf);
};

export const hashIdNumber = (
  idNumber: string,
  secret: string,
  algo: string = DEFAULT_HASH_ALGO,
): string => {
  return crypto.createHmac(algo, secret).update(idNumber).digest('hex');
};

export const generateRandomCode = (digits = 6): string => {
  const max = 10 ** digits;
  const code = Math.floor(Math.random() * max)
    .toString()
    .padStart(digits, '0');
  return code;
};

export const deepMerge = (
  target: Record<string, any>,
  source: Record<string, any>,
): Record<string, any> => {
  const output: Record<string, any> = Array.isArray(target)
    ? [...target]
    : { ...target };
  Object.keys(source || {}).forEach((key) => {
    const value = source[key];
    if (
      value &&
      typeof value === 'object' &&
      !Array.isArray(value) &&
      typeof target[key] === 'object' &&
      target[key] !== null &&
      !Array.isArray(target[key])
    ) {
      output[key] = deepMerge(target[key], value);
    } else {
      output[key] = value;
    }
  });
  return output;
};
