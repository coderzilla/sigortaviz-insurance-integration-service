// src/common/constants.ts
export const OTP_EXPIRES_SECONDS = Number(process.env.OTP_EXPIRES_SECONDS ?? 300); // 5 minutes
export const OTP_RESEND_SECONDS = Number(process.env.OTP_RESEND_SECONDS ?? 60);
export const OTP_MAX_ATTEMPTS = Number(process.env.OTP_MAX_ATTEMPTS ?? 5);
export const OTP_SECRET = process.env.OTP_SECRET ?? 'otp-secret';
export const ID_HASH_SECRET = process.env.ID_HASH_SECRET ?? 'id-hash-secret';
export const JWT_SECRET = process.env.JWT_SECRET ?? 'jwt-secret';
export const ACCESS_TOKEN_EXPIRES_SECONDS = Number(
  process.env.ACCESS_TOKEN_EXPIRES_SECONDS ?? 3600,
);
export const LEAD_TOKEN_EXPIRES_SECONDS = Number(
  process.env.LEAD_TOKEN_EXPIRES_SECONDS ?? 1800,
);
export const QUOTE_SESSION_TTL_MINUTES = Number(
  process.env.QUOTE_SESSION_TTL_MINUTES ?? 1440, // 24h
);
