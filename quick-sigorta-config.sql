-- Quick Sigorta configuration seed (TRAFFIC only)
-- Based on "Quick Sigorta - Acenteler API.postman_collection.json"
-- Idempotent: removes existing QUICK_SIGORTA configs then recreates TRAFFIC (productId=101) only.

START TRANSACTION;

-- Ensure carrier and product rows exist (do NOT delete carriers/products)
INSERT INTO carriers (code, name, isActive)
VALUES ('QUICK_SIGORTA', 'Quick Sigorta', 1)
ON DUPLICATE KEY UPDATE name = VALUES(name), isActive = VALUES(isActive);

INSERT INTO products (code, name, description) VALUES
('TRAFFIC', 'Traffic', 'Trafik sigortasi')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- Capture ids
SET @carrierQuick := (SELECT id FROM carriers WHERE code = 'QUICK_SIGORTA' ORDER BY id LIMIT 1);
SET @prodTraffic := (SELECT id FROM products WHERE code = 'TRAFFIC' ORDER BY id LIMIT 1);

-- Drop and recreate carrier-level tables (preserve carriers/products)
DROP TABLE IF EXISTS carrier_field_mappings;
DROP TABLE IF EXISTS carrier_product_fields;
DROP TABLE IF EXISTS carrier_product_field_sets;
DROP TABLE IF EXISTS carrier_products;

CREATE TABLE carrier_products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  carrierId INT NOT NULL,
  productId INT NOT NULL,
  externalCode VARCHAR(64) NOT NULL,
  isActive TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_carrier_external (carrierId, externalCode),
  UNIQUE KEY uq_carrier_product (carrierId, productId),
  INDEX idx_carrier_products_product (productId),
  CONSTRAINT fk_carrier_products_carrier FOREIGN KEY (carrierId) REFERENCES carriers(id),
  CONSTRAINT fk_carrier_products_product FOREIGN KEY (productId) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE carrier_product_field_sets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  carrierProductId INT NOT NULL,
  stage VARCHAR(32) NOT NULL DEFAULT 'QUOTE',
  version INT NOT NULL,
  isActive TINYINT(1) NOT NULL DEFAULT 1,
  validFrom TIMESTAMP NULL DEFAULT NULL,
  validTo TIMESTAMP NULL DEFAULT NULL,
  pageChangeRequestJson LONGTEXT NULL,
  UNIQUE KEY uq_cpfs (carrierProductId, stage, version),
  CONSTRAINT fk_cpfs_cp FOREIGN KEY (carrierProductId) REFERENCES carrier_products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE carrier_product_fields (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fieldSetId INT NOT NULL,
  internalCode VARCHAR(128) NOT NULL,
  label VARCHAR(255) NOT NULL,
  description TEXT NULL,
  inputType VARCHAR(50) NOT NULL,
  required TINYINT(1) NOT NULL DEFAULT 1,
  orderIndex INT NOT NULL,
  placeholder VARCHAR(255) NULL,
  validationRegex VARCHAR(255) NULL,
  minLength INT NULL,
  maxLength INT NULL,
  minValue DECIMAL(14,2) NULL,
  maxValue DECIMAL(14,2) NULL,
  optionsJson LONGTEXT NULL,
  extraConfigJson LONGTEXT NULL,
  page INT NOT NULL DEFAULT 1,
  onBlurRequestJson LONGTEXT NULL,
  UNIQUE KEY uq_cpf (fieldSetId, internalCode),
  CONSTRAINT fk_cpf_field_set FOREIGN KEY (fieldSetId) REFERENCES carrier_product_field_sets(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE carrier_field_mappings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  carrierProductId INT NOT NULL,
  internalCode VARCHAR(128) NOT NULL,
  carrierParamName VARCHAR(255) NOT NULL,
  transformType VARCHAR(64) NOT NULL DEFAULT 'NONE',
  isRequiredForApi TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_cfm (carrierProductId, internalCode),
  CONSTRAINT fk_cfm_cp FOREIGN KEY (carrierProductId) REFERENCES carrier_products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Link Quick to Traffic (externalCode 101)
INSERT INTO carrier_products (carrierId, productId, externalCode, isActive) VALUES
(@carrierQuick, @prodTraffic, '101', 1)
ON DUPLICATE KEY UPDATE externalCode = VALUES(externalCode), isActive = VALUES(isActive);

SET @cpTraffic := (SELECT id FROM carrier_products WHERE carrierId = @carrierQuick AND externalCode = '101' ORDER BY id LIMIT 1);

-- TRAFFIC (QUOTE)
INSERT INTO carrier_product_field_sets (carrierProductId, stage, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpTraffic,
  'QUOTE',
  1, 1, NOW(), NULL, NULL
);
SET @trafficFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = @cpTraffic
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `page`, `onBlurRequestJson`
) VALUES
(@trafficFieldSetId, 'insurerIdNumber', 'Sigorta Ettiren TCKN', NULL, 'identity', 1,
  1, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'insurerBirthDate', 'Sigorta Ettiren Doğum Tarihi', NULL, 'date', 1,
  2, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'insurerEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 1,
  3, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'insurerPhoneNumber', 'Sigorta Ettiren Telefon', NULL, 'text', 1,
  4, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'secondHandPurchase', '2. El Araç Satın Alacağım', NULL, 'radio', 1,
  5, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'false', 'label', 'Hayır'),
    JSON_OBJECT('value', 'true', 'label', 'Evet')
  ),
  NULL, 1, NULL),
(@trafficFieldSetId, 'insuredIdNumber', 'Sigortalı TCKN', NULL, 'identity', 1,
  6, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'insuredBirthDate', 'Sigortalı Doğum Tarihi', NULL, 'date', 1,
  7, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'insuredEmail', 'Sigortalı E-posta', NULL, 'email', 1,
  8, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'insuredPhoneNumber', 'Sigortalı Telefon', NULL, 'text', 1,
  9, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'ownerIdNumber', 'Ruhsat sahibi TC No veya Vergi No', NULL, 'identity', 1,
  10, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT(
    'visibleWhen', JSON_OBJECT('field', 'secondHandPurchase', 'op', 'eq', 'value', 'false'),
    'requiredWhen', JSON_OBJECT('field', 'secondHandPurchase', 'op', 'eq', 'value', 'false')
  ),
  1, NULL),
(@trafficFieldSetId, 'ownerPhoneNumber', 'Ruhsat sahibi Cep Telefonu', NULL, 'text', 1,
  11, NULL, NULL, 10, 20, NULL, NULL, NULL, NULL,
  JSON_OBJECT(
    'visibleWhen', JSON_OBJECT('field', 'secondHandPurchase', 'op', 'eq', 'value', 'false'),
    'requiredWhen', JSON_OBJECT('field', 'secondHandPurchase', 'op', 'eq', 'value', 'false')
  ),
  1, NULL),
(@trafficFieldSetId, 'buyerIdNumber', 'Satın Alacak Kişi TC No veya Vergi No', NULL, 'identity', 1,
  12, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT(
    'visibleWhen', JSON_OBJECT('field', 'secondHandPurchase', 'op', 'eq', 'value', 'true'),
    'requiredWhen', JSON_OBJECT('field', 'secondHandPurchase', 'op', 'eq', 'value', 'true')
  ),
  1, NULL),
(@trafficFieldSetId, 'buyerPhoneNumber', 'Satın Alacak Kişi Cep Telefonu', NULL, 'text', 1,
  13, NULL, NULL, 10, 20, NULL, NULL, NULL, NULL,
  JSON_OBJECT(
    'visibleWhen', JSON_OBJECT('field', 'secondHandPurchase', 'op', 'eq', 'value', 'true'),
    'requiredWhen', JSON_OBJECT('field', 'secondHandPurchase', 'op', 'eq', 'value', 'true')
  ),
  1, NULL),
(@trafficFieldSetId, 'packageType', 'Paket Tipi', NULL, 'select', 1,
  14, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/traffic/package-type', 'method', 'GET'),
  NULL,
  1, NULL),
(@trafficFieldSetId, 'plateType', 'Plaka Tipi', NULL, 'select', 1,
  15, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'registered', 'label', 'Tescilli'),
    JSON_OBJECT('value', 'unregistered', 'label', 'Tescilsiz / Yeni Tescil'),
    JSON_OBJECT('value', 'foreign', 'label', 'Yabancı Plaka')
  ),
  NULL, 1, NULL),
(@trafficFieldSetId, 'plateCityCode', 'Plaka İl Kodu', NULL, 'select', 1,
  16, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/location/city', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  NULL,
  1, NULL),
(@trafficFieldSetId, 'usageStyle', 'Kullanım Tarzı', NULL, 'select', 1,
  17, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/usage-style', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  NULL,
  1, NULL),
(@trafficFieldSetId, 'modelYear', 'Model Yılı', NULL, 'select', 1,
  18, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/traffic/new-registration/year', 'method', 'GET'),
  NULL,
  1, NULL),
(@trafficFieldSetId, 'makeId', 'Marka', NULL, 'select', 1,
  19, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/make?usageStyleId={{usageStyle}}&yearId={{modelYear}}', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  NULL,
  1, NULL),
(@trafficFieldSetId, 'modelId', 'Model', 'Opsiyonel model seçimi', 'select', 0,
  20, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/model?usageStyleId={{usageStyle}}&yearId={{modelYear}}&brandId={{makeId}}', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  NULL,
  1, NULL),
(@trafficFieldSetId, 'engineNumber', 'Motor No', NULL, 'text', 1,
  21, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'chassisNumber', 'Şasi No', NULL, 'text', 1,
  22, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpTraffic, 'insurerIdNumber', 'insurer.idNumber', 'NONE', 1),
(@cpTraffic, 'insurerBirthDate', 'insurer.birthDate', 'DATE_YYYY_MM_DD', 1),
(@cpTraffic, 'insurerEmail', 'insurer.email', 'LOWERCASE', 1),
(@cpTraffic, 'insurerPhoneNumber', 'insurer.phoneNumber', 'NONE', 1),
(@cpTraffic, 'secondHandPurchase', 'questions.secondHandPurchase', 'BOOLEAN', 1),
(@cpTraffic, 'ownerIdNumber', 'questions.ownerIdNumber', 'NONE', 0),
(@cpTraffic, 'ownerPhoneNumber', 'questions.ownerPhoneNumber', 'NONE', 0),
(@cpTraffic, 'buyerIdNumber', 'questions.buyerIdNumber', 'NONE', 0),
(@cpTraffic, 'buyerPhoneNumber', 'questions.buyerPhoneNumber', 'NONE', 0),
(@cpTraffic, 'insuredIdNumber', 'insureds[0].idNumber', 'NONE', 1),
(@cpTraffic, 'insuredBirthDate', 'insureds[0].birthDate', 'DATE_YYYY_MM_DD', 1),
(@cpTraffic, 'insuredEmail', 'insureds[0].email', 'LOWERCASE', 1),
(@cpTraffic, 'insuredPhoneNumber', 'insureds[0].phoneNumber', 'NONE', 1),
(@cpTraffic, 'packageType', 'questions.packageType', 'NONE', 1),
(@cpTraffic, 'plateType', 'questions.plateType', 'NONE', 1),
(@cpTraffic, 'plateCityCode', 'questions.plateCityCode', 'NONE', 1),
(@cpTraffic, 'usageStyle', 'questions.usageStyle', 'NONE', 1),
(@cpTraffic, 'modelYear', 'questions.modelYear', 'NONE', 1),
(@cpTraffic, 'makeId', 'questions.makeId', 'NONE', 1),
(@cpTraffic, 'modelId', 'questions.modelId', 'NONE', 0),
(@cpTraffic, 'engineNumber', 'questions.engineNumber', 'NONE', 1),
(@cpTraffic, 'chassisNumber', 'questions.chassisNumber', 'NONE', 1);

-- TRAFFIC PURCHASE
INSERT INTO carrier_product_field_sets (carrierProductId, stage, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpTraffic,
  'PURCHASE',
  1, 1, NOW(), NULL, NULL
);
SET @trafficPurchaseFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = @cpTraffic AND stage = 'PURCHASE'
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `page`, `onBlurRequestJson`
) VALUES
(@trafficPurchaseFieldSetId, 'policyNo', 'Teklif / Policy No', 'proposal/has-policy yanıtındaki policyNo', 'text', 1,
  1, NULL, NULL, NULL, 64, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficPurchaseFieldSetId, 'renewalNo', 'Yenileme No', 'varsayılan 0', 'number', 0,
  2, '0', NULL, NULL, NULL, 0, NULL, NULL, NULL, 1, NULL),
(@trafficPurchaseFieldSetId, 'endorsNo', 'Zeyil No', NULL, 'number', 0,
  3, '0', NULL, NULL, NULL, 0, NULL, NULL, NULL, 1, NULL),
(@trafficPurchaseFieldSetId, 'paymentType', 'Ödeme Tipi', 'card veya cash', 'select', 1,
  4, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'card', 'label', 'Kredi Kartı'),
    JSON_OBJECT('value', 'cash', 'label', 'Nakit')
  ),
  NULL, 1, NULL),
(@trafficPurchaseFieldSetId, 'cardTokenId', 'Kart Token', 'Kart saklama token', 'text', 0,
  5, NULL, NULL, NULL, 128, NULL, NULL, NULL, NULL, 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpTraffic, 'policyNo', 'policyNo', 'NONE', 1),
(@cpTraffic, 'renewalNo', 'renewalNo', 'NONE', 0),
(@cpTraffic, 'endorsNo', 'endorsNo', 'NONE', 0),
(@cpTraffic, 'paymentType', 'paymentType', 'LOWERCASE', 1),
(@cpTraffic, 'cardTokenId', 'cardTokenId', 'NONE', 0);

-- End of Quick Sigorta TRAFFIC seed

COMMIT;
