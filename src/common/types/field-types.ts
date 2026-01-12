export type FieldTransformType =
  | 'NONE'
  | 'DATE_DDMMYYYY'
  | 'DATE_YYYYMMDD'
  | 'PHONE_E164'
  | 'TR_IDENTITY_TCKN'
  | 'UPPERCASE'
  | 'LOWERCASE';

export type FormStage = 'QUOTE' | 'PURCHASE';

export interface StepDefinition {
  id: string; // unique path segment
  title: string; // display label
  order: number; // ordering among siblings
  children?: StepDefinition[]; // nested steps
  actions?: ActionDefinition[]; // optional actions tied to this step (UI-driven)
}

export interface StepsConfig {
  steps: StepDefinition[];
  defaults?: Record<string, any>;
}

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

export interface FieldOptionSource {
  optionsEndpoint: string;
  method?: 'GET' | 'POST';
  valueKey?: string;
  labelKey?: string;
  params?: Record<string, any>;
}

export interface FieldValidationRules {
  regex?: string;
  minValue?: number;
  maxValue?: number;
  minLength?: number;
  maxLength?: number;
}

export interface RequestTriggerConfig {
  url: string;
  method?: 'GET' | 'POST';
  params?: Record<string, any>;
  headers?: Record<string, string>;
}

export interface FieldConditionRule {
  field: string;
  op: 'eq' | 'in';
  value: any;
}

export interface CollectionConfig {
  arrayPath: string;              // where to place the collection in payload (e.g., customFields.insureds)
  repeatFor?: string;             // field containing roles/keys to drive repetition (e.g., customFields.insuredRoles)
  roleKey?: string;               // property name on items to store the role (e.g., "role")
  roleToTitle?: Record<string, string>;
  allowAddForRole?: string[];
  autoPopulateFrom?: 'insurer' | 'insuredPerson' | string; // source object to copy when auto-creating
  autoPopulateRoles?: string[];
  hideFormWhenRolesSubset?: string[];
}

export interface FieldExtraConfig {
  multiple?: boolean;                  // for selects supporting multi-select
  collectionTarget?: string;           // path to collection for multi-select-driven groups
  collection?: CollectionConfig;       // repeatable group config
  autoPopulateFrom?: 'insurer' | 'insuredPerson' | string; // copy values from another entity when present
  visibleWhen?: FieldConditionRule;    // client-side visibility rule
  requiredWhen?: FieldConditionRule;   // client-side required rule
}

export interface FieldConfig {
  internalCode: string;    // e.g. "insuredBirthDate"
  label: string;
  description?: string;
  inputType: FieldInputType;
  required: boolean;
  isShown?: boolean;       // whether the field should be rendered (default true)
  orderIndex: number;      // order inside its step
  stepPath?: string[];     // hierarchical path of steps (e.g. ["vehicle","license"])
  placeholder?: string;
  options?: FieldOption[] | FieldOptionSource;
  validation?: FieldValidationRules;
  extraConfig?: FieldExtraConfig;
  onBlurRequest?: RequestTriggerConfig; // request to send on blur with valid value
}

export type ActionTrigger = 'onEnter' | 'onBlur' | 'onSubmit' | 'manual';

export interface ActionDefinition {
  id: string;
  trigger: ActionTrigger;
  type: 'http';
  method: 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE';
  url: string;
  headers?: Record<string, string>;
  bodyTemplate?: Record<string, any>;
  dependsOn?: string[]; // action ids that must succeed first
  resultMap?: Record<string, string>; // maps response fields to state paths
  errorHandling?: { showInline?: boolean; toast?: boolean };
  onSuccess?: Array<
    | { type: 'storeToken'; tokenPath: string }
    | { type: 'continueStep'; stepId: string }
    | { type: string; [key: string]: any }
  >;
}

export interface ProductFormConfig {
  fields: FieldConfig[];
  pageChangeRequest?: RequestTriggerConfig; // optional request to trigger between page changes
  steps?: StepDefinition[]; // hierarchical structure for grouping fields
  stepsConfig?: StepsConfig; // full steps object including defaults
}
