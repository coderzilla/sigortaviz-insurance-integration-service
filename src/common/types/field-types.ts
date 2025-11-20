export type FieldTransformType =
  | 'NONE'
  | 'DATE_DDMMYYYY'
  | 'DATE_YYYYMMDD'
  | 'PHONE_E164'
  | 'TR_IDENTITY_TCKN'
  | 'UPPERCASE'
  | 'LOWERCASE';
// src/common/types/field-types.ts
export type FieldInputType =
  | 'text'
  | 'number'
  | 'date'
  | 'select'
  | 'radio'
  | 'checkbox'
  | 'phone'
  | 'email'
  | 'identity'
  | 'boolean';

export interface FieldOption {
  value: string;
  label: string;
}

export interface FieldValidationRules {
  regex?: string;
  minValue?: number;
  maxValue?: number;
  minLength?: number;
  maxLength?: number;
}

export interface FieldConfig {
  internalCode: string;    // e.g. "insuredBirthDate"
  label: string;
  description?: string;
  inputType: FieldInputType;
  required: boolean;
  orderIndex: number;
  placeholder?: string;
  options?: FieldOption[];
  validation?: FieldValidationRules;
  extraConfig?: Record<string, any>;
}
