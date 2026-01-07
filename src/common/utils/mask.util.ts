// src/common/utils/mask.util.ts
export const maskPhone = (phone?: string | null): string => {
  if (!phone) return '';
  const digits = phone.replace(/\D/g, '');
  if (digits.length <= 4) {
    return `${'*'.repeat(Math.max(0, digits.length - 1))}${digits.slice(-1)}`;
  }
  const visible = digits.slice(-2);
  return `${'*'.repeat(Math.max(0, digits.length - visible.length))}${visible}`;
};

export const maskIdNumber = (idNumber?: string | null): string => {
  if (!idNumber) return '';
  const normalized = idNumber.trim();
  if (normalized.length <= 3) {
    return `${'*'.repeat(Math.max(0, normalized.length - 1))}${normalized.slice(-1)}`;
  }
  return `${normalized.slice(0, 1)}${'*'.repeat(Math.max(0, normalized.length - 3))}${normalized.slice(-2)}`;
};

export const maskEmail = (email?: string | null): string => {
  if (!email) return '';
  const [user, domain] = email.split('@');
  if (!domain) return '***';
  const maskedUser =
    user.length <= 2
      ? `${user[0] ?? ''}*`
      : `${user[0]}${'*'.repeat(user.length - 2)}${user.slice(-1)}`;
  return `${maskedUser}@${domain}`;
};
