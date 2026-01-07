export enum ProductCode {
  TRAFFIC = 'TRAFFIC',
  HEALTH = 'HEALTH',
  CASCO = 'CASCO',
  HOME = 'HOME',
  LIFE = 'LIFE',
  PET = 'PET',
}

export type CarrierCode =
  | 'ALLIANZ'
  | 'SOMPO'
  | 'TURKEY_INSURANCE'
  | 'ANADOLU_SIGORTA'
  | 'AXA'
  | string;

export enum UserStatus {
  ACTIVE = 'ACTIVE',
  LOCKED = 'LOCKED',
  DELETED = 'DELETED',
}

export enum QuoteSessionStatus {
  IN_PROGRESS = 'IN_PROGRESS',
  SUBMITTED = 'SUBMITTED',
  COMPLETED = 'COMPLETED',
  ABANDONED = 'ABANDONED',
  EXPIRED = 'EXPIRED',
}

export enum AssetType {
  VEHICLE = 'VEHICLE',
  PROPERTY = 'PROPERTY',
}

export enum OtpPurpose {
  LOGIN = 'LOGIN',
  REGISTER = 'REGISTER',
}

  
