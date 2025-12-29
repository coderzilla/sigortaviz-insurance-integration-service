-- Quick Sigorta configuration seed (Traffic + Travel)
-- Based on "Quick Sigorta - Acenteler API.postman_collection.json" inside quick-sigorta/
-- Field/internalCode values mirror request payload keys from the Postman docs.

START TRANSACTION;

-- Create base tables used by downstream carrier config
CREATE TABLE IF NOT EXISTS carriers (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `isActive` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_carriers_code (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS products (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  UNIQUE KEY uq_products_code (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Ensure carrier and product rows exist (do NOT delete carriers/products)
INSERT INTO carriers (code, name, isActive)
VALUES ('QUICK_SIGORTA', 'Quick Sigorta', 1)
ON DUPLICATE KEY UPDATE name = VALUES(name), isActive = VALUES(isActive);

INSERT INTO products (code, name, description) VALUES
('TRAFFIC', 'Traffic', 'Trafik sigortasi'),
('TRAVEL', 'Travel Health', 'Seyahat saglik sigortasi')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- Capture ids
SET @carrierQuick := (SELECT id FROM carriers WHERE code = 'QUICK_SIGORTA' ORDER BY id LIMIT 1);
SET @prodTraffic := (SELECT id FROM products WHERE code = 'TRAFFIC' ORDER BY id LIMIT 1);
SET @prodTravel := (SELECT id FROM products WHERE code = 'TRAVEL' ORDER BY id LIMIT 1);

-- Drop and recreate carrier-level tables (preserve carriers/products)
DROP TABLE IF EXISTS carrier_field_mappings;
DROP TABLE IF EXISTS carrier_product_fields;
DROP TABLE IF EXISTS carrier_product_field_sets;
DROP TABLE IF EXISTS carrier_products;

CREATE TABLE carrier_products (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `carrierId` INT NOT NULL,
  `productId` INT NOT NULL,
  `externalCode` VARCHAR(64) NOT NULL,
  `isActive` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_carrier_external (`carrierId`, `externalCode`),
  UNIQUE KEY uq_carrier_product (`carrierId`, `productId`),
  INDEX idx_carrier_products_product (`productId`),
  CONSTRAINT fk_carrier_products_carrier FOREIGN KEY (`carrierId`) REFERENCES carriers(`id`),
  CONSTRAINT fk_carrier_products_product FOREIGN KEY (`productId`) REFERENCES products(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE carrier_product_field_sets (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `carrierProductId` INT NOT NULL,
  `stage` VARCHAR(32) NOT NULL DEFAULT 'QUOTE',
  `version` INT NOT NULL,
  `isActive` TINYINT(1) NOT NULL DEFAULT 1,
  `validFrom` TIMESTAMP NULL DEFAULT NULL,
  `validTo` TIMESTAMP NULL DEFAULT NULL,
  `stepsJson` JSON NULL,
  `pageChangeRequestJson` JSON NULL,
  UNIQUE KEY uq_cpfs (`carrierProductId`, `stage`, `version`),
  CONSTRAINT fk_cpfs_cp FOREIGN KEY (`carrierProductId`) REFERENCES carrier_products(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE carrier_product_fields (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `fieldSetId` INT NOT NULL,
  `internalCode` VARCHAR(128) NOT NULL,
  `label` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `inputType` VARCHAR(50) NOT NULL,
  `required` TINYINT(1) NOT NULL DEFAULT 1,
  `isShown` TINYINT(1) NOT NULL DEFAULT 1,
  `orderIndex` INT NOT NULL,
  `placeholder` VARCHAR(255) NULL,
  `validationRegex` VARCHAR(255) NULL,
  `minLength` INT NULL,
  `maxLength` INT NULL,
  `minValue` DECIMAL(14,2) NULL,
  `maxValue` DECIMAL(14,2) NULL,
  `optionsJson` JSON NULL,
  `extraConfigJson` JSON NULL,
  `stepPathJson` JSON NULL,
  `page` INT NULL, -- legacy; safe to drop after migration
  `onBlurRequestJson` JSON NULL,
  UNIQUE KEY uq_cpf (`fieldSetId`, `internalCode`),
  CONSTRAINT fk_cpf_field_set FOREIGN KEY (`fieldSetId`) REFERENCES carrier_product_field_sets(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE carrier_field_mappings (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `carrierProductId` INT NOT NULL,
  `internalCode` VARCHAR(128) NOT NULL,
  `carrierParamName` VARCHAR(255) NOT NULL,
  `transformType` VARCHAR(64) NOT NULL DEFAULT 'NONE',
  `isRequiredForApi` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_cfm (`carrierProductId`, `internalCode`),
  CONSTRAINT fk_cfm_cp FOREIGN KEY (`carrierProductId`) REFERENCES carrier_products(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Link Quick to Traffic (externalCode 101)
INSERT INTO carrier_products (carrierId, productId, externalCode, isActive) VALUES
(@carrierQuick, @prodTraffic, '101', 1)
ON DUPLICATE KEY UPDATE externalCode = VALUES(externalCode), isActive = VALUES(isActive);

-- Link Quick to Travel (productId 600 in docs)
INSERT INTO carrier_products (carrierId, productId, externalCode, isActive) VALUES
(@carrierQuick, @prodTravel, '600', 1)
ON DUPLICATE KEY UPDATE externalCode = VALUES(externalCode), isActive = VALUES(isActive);

SET @cpTraffic := (SELECT id FROM carrier_products WHERE carrierId = @carrierQuick AND externalCode = '101' ORDER BY id LIMIT 1);
SET @cpTravel := (SELECT id FROM carrier_products WHERE carrierId = @carrierQuick AND externalCode = '600' ORDER BY id LIMIT 1);

-- Step templates
SET @stepsTraffic = JSON_ARRAY(
  JSON_OBJECT(
    'id', 'vehicle', 'title', 'Araç Bilgileri', 'order', 1,
    'children', JSON_ARRAY(
      JSON_OBJECT('id', 'license', 'title', 'Ruhsat Bilgileri', 'order', 1),
      JSON_OBJECT('id', 'features', 'title', 'Araç Özellikleri', 'order', 2)
    )
  ),
  JSON_OBJECT('id', 'contact', 'title', 'İletişim Bilgileri', 'order', 2),
  JSON_OBJECT('id', 'package', 'title', 'Paket Seçimi', 'order', 3)
);

SET @stepsTravel = JSON_ARRAY(
  JSON_OBJECT('id', 'trip', 'title', 'Seyahat Bilgileri', 'order', 1),
  JSON_OBJECT('id', 'insureds', 'title', 'Sigortalılar', 'order', 2),
  JSON_OBJECT('id', 'contact', 'title', 'İletişim', 'order', 3)
);

-- TRAFFIC (QUOTE)
INSERT INTO carrier_product_field_sets (carrierProductId, stage, version, isActive, validFrom, validTo, stepsJson, pageChangeRequestJson)
VALUES (@cpTraffic, 'QUOTE', 1, 1, NOW(), NULL, @stepsTraffic, NULL);

SET @trafficFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = @cpTraffic
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `stepPathJson`, `page`, `onBlurRequestJson`
) VALUES
(@trafficFieldSetId, 'insurerIdNumber', 'Sigorta Ettiren TCKN / VKN', NULL, 'identity', 1,
  1, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insurerBirthDate', 'Sigorta Ettiren Doğum Tarihi', NULL, 'date', 1,
  2, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insurerEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 1,
  3, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insurerPhoneNumber', 'Sigorta Ettiren Telefon', NULL, 'phone', 1,
  4, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insuredIdNumber', 'Sigortalı TCKN (farklıysa)', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'identity', 0,
  5, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insuredBirthDate', 'Sigortalı Doğum Tarihi', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'date', 0,
  6, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insuredEmail', 'Sigortalı E-posta', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'email', 0,
  7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insuredPhoneNumber', 'Sigortalı Telefon', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'phone', 0,
  8, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'packageType', 'Paket Tipi', NULL, 'select', 1,
  9, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/traffic/package-type', 'method', 'GET'),
  NULL, JSON_ARRAY('package'), NULL, NULL),
(@trafficFieldSetId, 'plateType', 'Plaka Tipi', NULL, 'select', 1,
  10, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'registered', 'label', 'Tescilli'),
    JSON_OBJECT('value', 'unregistered', 'label', 'Tescilsiz / Yeni Tescil'),
    JSON_OBJECT('value', 'foreign', 'label', 'Yabancı Plaka')
  ),
  NULL, JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'plateCityCode', 'Plaka İl Kodu', NULL, 'select', 0,
  11, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/location/city', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('registered','unregistered'))),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'plateNumber', 'Plaka No', 'Kayıtlı/galerici/yabancı senaryoları için', 'text', 0,
  12, '34ABC123', NULL, 4, 15, NULL, NULL, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('registered','foreign'))),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'registrationSerialCode', 'Tescil Seri Kodu', NULL, 'text', 0,
  13, 'GD', NULL, 1, 5, NULL, NULL, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'eq', 'value', 'registered')),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'registrationSerialNumber', 'Tescil Seri No', NULL, 'text', 0,
  14, '984352', NULL, 3, 12, NULL, NULL, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'eq', 'value', 'registered')),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'usageStyle', 'Kullanım Tarzı', NULL, 'select', 0,
  15, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/usage-style', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('unregistered','foreign'))),
  JSON_ARRAY('vehicle','features'), NULL, NULL),
(@trafficFieldSetId, 'modelYear', 'Model Yılı', NULL, 'select', 0,
  16, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/traffic/new-registration/year', 'method', 'GET'),
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('unregistered','foreign'))),
  JSON_ARRAY('vehicle','features'), NULL, NULL),
(@trafficFieldSetId, 'makeId', 'Marka', NULL, 'select', 0,
  17, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/make?usageStyleId={{usageStyle}}&yearId={{modelYear}}', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('unregistered','foreign'))),
  JSON_ARRAY('vehicle','features'), NULL, NULL),
(@trafficFieldSetId, 'engineNumber', 'Motor No', NULL, 'text', 0,
  18, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('unregistered','foreign'))),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'chassisNumber', 'Şasi No', NULL, 'text', 0,
  19, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('unregistered','foreign'))),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'policyDuration', 'Poliçe Süresi (gün)', 'Yabancı plakalı / galerici senaryosu için', 'number', 0,
  20, '1 veya 120', NULL, NULL, NULL, 1, 365, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'eq', 'value', 'foreign')),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'isDealer', 'Galerici Kısa Süreli', 'Dealer kısa süreli trafik (policyDuration 120)', 'boolean', 0,
  21, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, JSON_ARRAY('vehicle','features'), NULL, NULL);

-- TRAFFIC (PURCHASE)
INSERT INTO carrier_product_field_sets (carrierProductId, stage, version, isActive, validFrom, validTo, stepsJson, pageChangeRequestJson)
VALUES (@cpTraffic, 'PURCHASE', 1, 1, NOW(), NULL, @stepsTraffic, NULL);

SET @trafficPurchaseFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = @cpTraffic AND stage = 'PURCHASE'
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `stepPathJson`, `page`, `onBlurRequestJson`
) VALUES
(@trafficPurchaseFieldSetId, 'policyNo', 'Teklif / Poliçe No', NULL, 'text', 1,
  1, NULL, NULL, NULL, NULL, NULL, NULL, JSON_ARRAY('package'), NULL, NULL, NULL, NULL),
(@trafficPurchaseFieldSetId, 'paymentType', 'Ödeme Tipi', NULL, 'select', 1,
  2, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'card', 'label', 'Kredi Kartı'),
    JSON_OBJECT('value', 'cash', 'label', 'Nakit')
  ),
  NULL, JSON_ARRAY('package'), NULL, NULL),
(@trafficPurchaseFieldSetId, 'cardTokenId', 'Kart Token', 'Quick Sigorta kart token', 'text', 0,
  3, NULL, NULL, NULL, NULL, NULL, NULL, JSON_ARRAY('package'), NULL, NULL, NULL, NULL);

-- TRAFFIC field mappings (example)
INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpTraffic, 'insurerIdNumber', 'insurer.idNumber', 'TR_IDENTITY_TCKN', 1),
(@cpTraffic, 'insurerBirthDate', 'insurer.birthDate', 'DATE_YYYYMMDD', 1),
(@cpTraffic, 'insurerEmail', 'insurer.email', 'LOWERCASE', 1),
(@cpTraffic, 'insurerPhoneNumber', 'insurer.phoneNumber', 'PHONE_E164', 1),
(@cpTraffic, 'insuredIdNumber', 'insureds[].idNumber', 'TR_IDENTITY_TCKN', 0),
(@cpTraffic, 'insuredBirthDate', 'insureds[].birthDate', 'DATE_YYYYMMDD', 0),
(@cpTraffic, 'insuredEmail', 'insureds[].email', 'LOWERCASE', 0),
(@cpTraffic, 'insuredPhoneNumber', 'insureds[].phoneNumber', 'PHONE_E164', 0),
(@cpTraffic, 'packageType', 'questions.packageType', 'NONE', 1),
(@cpTraffic, 'plateType', 'questions.plateType', 'NONE', 1),
(@cpTraffic, 'plateCityCode', 'questions.plateCityCode', 'NONE', 0),
(@cpTraffic, 'plateNumber', 'questions.plateNumber', 'UPPERCASE', 0),
(@cpTraffic, 'registrationSerialCode', 'questions.registrationSerialCode', 'UPPERCASE', 0),
(@cpTraffic, 'registrationSerialNumber', 'questions.registrationSerialNumber', 'NONE', 0),
(@cpTraffic, 'usageStyle', 'questions.usageStyle', 'NONE', 0),
(@cpTraffic, 'modelYear', 'questions.modelYear', 'NONE', 0),
(@cpTraffic, 'makeId', 'questions.makeId', 'NONE', 0),
(@cpTraffic, 'engineNumber', 'questions.engineNumber', 'UPPERCASE', 0),
(@cpTraffic, 'chassisNumber', 'questions.chassisNumber', 'UPPERCASE', 0),
(@cpTraffic, 'policyDuration', 'questions.policyDuration', 'NONE', 0),
(@cpTraffic, 'isDealer', 'questions.isDealer', 'NONE', 0),
(@cpTraffic, 'policyNo', 'policyNo', 'NONE', 1),
(@cpTraffic, 'paymentType', 'paymentType', 'NONE', 1),
(@cpTraffic, 'cardTokenId', 'cardTokenId', 'NONE', 0);

-- TRAVEL (QUOTE) with repeatable insureds example
INSERT INTO carrier_product_field_sets (carrierProductId, stage, version, isActive, validFrom, validTo, stepsJson, pageChangeRequestJson)
VALUES (@cpTravel, 'QUOTE', 1, 1, NOW(), NULL, @stepsTravel, NULL);

SET @travelFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = @cpTravel AND stage = 'QUOTE'
  ORDER BY version DESC LIMIT 1
);
-- Quick Sigorta configuration seed (Traffic + Travel)
-- Based on "Quick Sigorta - Acenteler API.postman_collection.json" inside quick-sigorta/
-- Field/internalCode values mirror request payload keys from the Postman docs.

START TRANSACTION;

-- Create base tables used by downstream carrier config
CREATE TABLE IF NOT EXISTS carriers (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `isActive` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_carriers_code (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS products (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  UNIQUE KEY uq_products_code (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Ensure carrier and product rows exist (do NOT delete carriers/products)
INSERT INTO carriers (code, name, isActive)
VALUES ('QUICK_SIGORTA', 'Quick Sigorta', 1)
ON DUPLICATE KEY UPDATE name = VALUES(name), isActive = VALUES(isActive);

INSERT INTO products (code, name, description) VALUES
('TRAFFIC', 'Traffic', 'Trafik sigortasi'),
('TRAVEL', 'Travel Health', 'Seyahat saglik sigortasi')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- Capture ids
SET @carrierQuick := (SELECT id FROM carriers WHERE code = 'QUICK_SIGORTA' ORDER BY id LIMIT 1);
SET @prodTraffic := (SELECT id FROM products WHERE code = 'TRAFFIC' ORDER BY id LIMIT 1);
SET @prodTravel := (SELECT id FROM products WHERE code = 'TRAVEL' ORDER BY id LIMIT 1);

-- Drop and recreate carrier-level tables (preserve carriers/products)
DROP TABLE IF EXISTS carrier_field_mappings;
DROP TABLE IF EXISTS carrier_product_fields;
DROP TABLE IF EXISTS carrier_product_field_sets;
DROP TABLE IF EXISTS carrier_products;

CREATE TABLE carrier_products (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `carrierId` INT NOT NULL,
  `productId` INT NOT NULL,
  `externalCode` VARCHAR(64) NOT NULL,
  `isActive` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_carrier_external (`carrierId`, `externalCode`),
  UNIQUE KEY uq_carrier_product (`carrierId`, `productId`),
  INDEX idx_carrier_products_product (`productId`),
  CONSTRAINT fk_carrier_products_carrier FOREIGN KEY (`carrierId`) REFERENCES carriers(`id`),
  CONSTRAINT fk_carrier_products_product FOREIGN KEY (`productId`) REFERENCES products(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE carrier_product_field_sets (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `carrierProductId` INT NOT NULL,
  `stage` VARCHAR(32) NOT NULL DEFAULT 'QUOTE',
  `version` INT NOT NULL,
  `isActive` TINYINT(1) NOT NULL DEFAULT 1,
  `validFrom` TIMESTAMP NULL DEFAULT NULL,
  `validTo` TIMESTAMP NULL DEFAULT NULL,
  `stepsJson` JSON NULL,
  `pageChangeRequestJson` JSON NULL,
  UNIQUE KEY uq_cpfs (`carrierProductId`, `stage`, `version`),
  CONSTRAINT fk_cpfs_cp FOREIGN KEY (`carrierProductId`) REFERENCES carrier_products(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE carrier_product_fields (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `fieldSetId` INT NOT NULL,
  `internalCode` VARCHAR(128) NOT NULL,
  `label` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `inputType` VARCHAR(50) NOT NULL,
  `required` TINYINT(1) NOT NULL DEFAULT 1,
  `isShown` TINYINT(1) NOT NULL DEFAULT 1,
  `orderIndex` INT NOT NULL,
  `placeholder` VARCHAR(255) NULL,
  `validationRegex` VARCHAR(255) NULL,
  `minLength` INT NULL,
  `maxLength` INT NULL,
  `minValue` DECIMAL(14,2) NULL,
  `maxValue` DECIMAL(14,2) NULL,
  `optionsJson` JSON NULL,
  `extraConfigJson` JSON NULL,
  `stepPathJson` JSON NULL,
  `page` INT NULL, -- legacy; safe to drop after migration
  `onBlurRequestJson` JSON NULL,
  UNIQUE KEY uq_cpf (`fieldSetId`, `internalCode`),
  CONSTRAINT fk_cpf_field_set FOREIGN KEY (`fieldSetId`) REFERENCES carrier_product_field_sets(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE carrier_field_mappings (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `carrierProductId` INT NOT NULL,
  `internalCode` VARCHAR(128) NOT NULL,
  `carrierParamName` VARCHAR(255) NOT NULL,
  `transformType` VARCHAR(64) NOT NULL DEFAULT 'NONE',
  `isRequiredForApi` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_cfm (`carrierProductId`, `internalCode`),
  CONSTRAINT fk_cfm_cp FOREIGN KEY (`carrierProductId`) REFERENCES carrier_products(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Link Quick to Traffic (externalCode 101)
INSERT INTO carrier_products (carrierId, productId, externalCode, isActive) VALUES
(@carrierQuick, @prodTraffic, '101', 1)
ON DUPLICATE KEY UPDATE externalCode = VALUES(externalCode), isActive = VALUES(isActive);

-- Link Quick to Travel (productId 600 in docs)
INSERT INTO carrier_products (carrierId, productId, externalCode, isActive) VALUES
(@carrierQuick, @prodTravel, '600', 1)
ON DUPLICATE KEY UPDATE externalCode = VALUES(externalCode), isActive = VALUES(isActive);

SET @cpTraffic := (SELECT id FROM carrier_products WHERE carrierId = @carrierQuick AND externalCode = '101' ORDER BY id LIMIT 1);
SET @cpTravel := (SELECT id FROM carrier_products WHERE carrierId = @carrierQuick AND externalCode = '600' ORDER BY id LIMIT 1);

-- Step templates
SET @stepsTraffic = JSON_ARRAY(
  JSON_OBJECT(
    'id', 'vehicle', 'title', 'Araç Bilgileri', 'order', 1,
    'children', JSON_ARRAY(
      JSON_OBJECT('id', 'license', 'title', 'Ruhsat Bilgileri', 'order', 1),
      JSON_OBJECT('id', 'features', 'title', 'Araç Özellikleri', 'order', 2)
    )
  ),
  JSON_OBJECT('id', 'contact', 'title', 'İletişim Bilgileri', 'order', 2),
  JSON_OBJECT('id', 'package', 'title', 'Paket Seçimi', 'order', 3)
);

SET @stepsTravel = JSON_ARRAY(
  JSON_OBJECT('id', 'trip', 'title', 'Seyahat Bilgileri', 'order', 1),
  JSON_OBJECT('id', 'insureds', 'title', 'Sigortalılar', 'order', 2),
  JSON_OBJECT('id', 'contact', 'title', 'İletişim', 'order', 3)
);

-- TRAFFIC (QUOTE)
INSERT INTO carrier_product_field_sets (carrierProductId, stage, version, isActive, validFrom, validTo, stepsJson, pageChangeRequestJson)
VALUES (@cpTraffic, 'QUOTE', 1, 1, NOW(), NULL, @stepsTraffic, NULL);

SET @trafficFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = @cpTraffic
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `stepPathJson`, `page`, `onBlurRequestJson`
) VALUES
(@trafficFieldSetId, 'insurerIdNumber', 'Sigorta Ettiren TCKN / VKN', NULL, 'identity', 1,
  1, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insurerBirthDate', 'Sigorta Ettiren Doğum Tarihi', NULL, 'date', 1,
  2, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insurerEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 1,
  3, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insurerPhoneNumber', 'Sigorta Ettiren Telefon', NULL, 'phone', 1,
  4, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insuredIdNumber', 'Sigortalı TCKN (farklıysa)', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'identity', 0,
  5, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insuredBirthDate', 'Sigortalı Doğum Tarihi', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'date', 0,
  6, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insuredEmail', 'Sigortalı E-posta', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'email', 0,
  7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'insuredPhoneNumber', 'Sigortalı Telefon', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'phone', 0,
  8, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, JSON_ARRAY('contact'), NULL, NULL),
(@trafficFieldSetId, 'packageType', 'Paket Tipi', NULL, 'select', 1,
  9, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/traffic/package-type', 'method', 'GET'),
  NULL, JSON_ARRAY('package'), NULL, NULL),
(@trafficFieldSetId, 'plateType', 'Plaka Tipi', NULL, 'select', 1,
  10, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'registered', 'label', 'Tescilli'),
    JSON_OBJECT('value', 'unregistered', 'label', 'Tescilsiz / Yeni Tescil'),
    JSON_OBJECT('value', 'foreign', 'label', 'Yabancı Plaka')
  ),
  NULL, JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'plateCityCode', 'Plaka İl Kodu', NULL, 'select', 0,
  11, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/location/city', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('registered','unregistered'))),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'plateNumber', 'Plaka No', 'Kayıtlı/galerici/yabancı senaryoları için', 'text', 0,
  12, '34ABC123', NULL, 4, 15, NULL, NULL, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('registered','foreign'))),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'registrationSerialCode', 'Tescil Seri Kodu', NULL, 'text', 0,
  13, 'GD', NULL, 1, 5, NULL, NULL, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'eq', 'value', 'registered')),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'registrationSerialNumber', 'Tescil Seri No', NULL, 'text', 0,
  14, '984352', NULL, 3, 12, NULL, NULL, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'eq', 'value', 'registered')),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'usageStyle', 'Kullanım Tarzı', NULL, 'select', 0,
  15, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/usage-style', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('unregistered','foreign'))),
  JSON_ARRAY('vehicle','features'), NULL, NULL),
(@trafficFieldSetId, 'modelYear', 'Model Yılı', NULL, 'select', 0,
  16, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/traffic/new-registration/year', 'method', 'GET'),
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('unregistered','foreign'))),
  JSON_ARRAY('vehicle','features'), NULL, NULL),
(@trafficFieldSetId, 'makeId', 'Marka', NULL, 'select', 0,
  17, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/make?usageStyleId={{usageStyle}}&yearId={{modelYear}}', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('unregistered','foreign'))),
  JSON_ARRAY('vehicle','features'), NULL, NULL),
(@trafficFieldSetId, 'engineNumber', 'Motor No', NULL, 'text', 0,
  18, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('unregistered','foreign'))),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'chassisNumber', 'Şasi No', NULL, 'text', 0,
  19, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'in', 'value', JSON_ARRAY('unregistered','foreign'))),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'policyDuration', 'Poliçe Süresi (gün)', 'Yabancı plakalı / galerici senaryosu için', 'number', 0,
  20, '1 veya 120', NULL, NULL, NULL, 1, 365, NULL,
  JSON_OBJECT('requiredWhen', JSON_OBJECT('field', 'plateType', 'op', 'eq', 'value', 'foreign')),
  JSON_ARRAY('vehicle','license'), NULL, NULL),
(@trafficFieldSetId, 'isDealer', 'Galerici Kısa Süreli', 'Dealer kısa süreli trafik (policyDuration 120)', 'boolean', 0,
  21, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, JSON_ARRAY('vehicle','features'), NULL, NULL);

-- TRAFFIC (PURCHASE)
INSERT INTO carrier_product_field_sets (carrierProductId, stage, version, isActive, validFrom, validTo, stepsJson, pageChangeRequestJson)
VALUES (@cpTraffic, 'PURCHASE', 1, 1, NOW(), NULL, @stepsTraffic, NULL);

SET @trafficPurchaseFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = @cpTraffic AND stage = 'PURCHASE'
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `stepPathJson`, `page`, `onBlurRequestJson`
) VALUES
(@trafficPurchaseFieldSetId, 'policyNo', 'Teklif / Poliçe No', NULL, 'text', 1,
  1, NULL, NULL, NULL, NULL, NULL, NULL, JSON_ARRAY('package'), NULL, NULL, NULL, NULL),
(@trafficPurchaseFieldSetId, 'paymentType', 'Ödeme Tipi', NULL, 'select', 1,
  2, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'card', 'label', 'Kredi Kartı'),
    JSON_OBJECT('value', 'cash', 'label', 'Nakit')
  ),
  NULL, JSON_ARRAY('package'), NULL, NULL),
(@trafficPurchaseFieldSetId, 'cardTokenId', 'Kart Token', 'Quick Sigorta kart token', 'text', 0,
  3, NULL, NULL, NULL, NULL, NULL, NULL, JSON_ARRAY('package'), NULL, NULL, NULL, NULL);

-- TRAFFIC field mappings (example)
INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpTraffic, 'insurerIdNumber', 'insurer.idNumber', 'TR_IDENTITY_TCKN', 1),
(@cpTraffic, 'insurerBirthDate', 'insurer.birthDate', 'DATE_YYYYMMDD', 1),
(@cpTraffic, 'insurerEmail', 'insurer.email', 'LOWERCASE', 1),
(@cpTraffic, 'insurerPhoneNumber', 'insurer.phoneNumber', 'PHONE_E164', 1),
(@cpTraffic, 'insuredIdNumber', 'insureds[].idNumber', 'TR_IDENTITY_TCKN', 0),
(@cpTraffic, 'insuredBirthDate', 'insureds[].birthDate', 'DATE_YYYYMMDD', 0),
(@cpTraffic, 'insuredEmail', 'insureds[].email', 'LOWERCASE', 0),
(@cpTraffic, 'insuredPhoneNumber', 'insureds[].phoneNumber', 'PHONE_E164', 0),
(@cpTraffic, 'packageType', 'questions.packageType', 'NONE', 1),
(@cpTraffic, 'plateType', 'questions.plateType', 'NONE', 1),
(@cpTraffic, 'plateCityCode', 'questions.plateCityCode', 'NONE', 0),
(@cpTraffic, 'plateNumber', 'questions.plateNumber', 'UPPERCASE', 0),
(@cpTraffic, 'registrationSerialCode', 'questions.registrationSerialCode', 'UPPERCASE', 0),
(@cpTraffic, 'registrationSerialNumber', 'questions.registrationSerialNumber', 'NONE', 0),
(@cpTraffic, 'usageStyle', 'questions.usageStyle', 'NONE', 0),
(@cpTraffic, 'modelYear', 'questions.modelYear', 'NONE', 0),
(@cpTraffic, 'makeId', 'questions.makeId', 'NONE', 0),
(@cpTraffic, 'engineNumber', 'questions.engineNumber', 'UPPERCASE', 0),
(@cpTraffic, 'chassisNumber', 'questions.chassisNumber', 'UPPERCASE', 0),
(@cpTraffic, 'policyDuration', 'questions.policyDuration', 'NONE', 0),
(@cpTraffic, 'isDealer', 'questions.isDealer', 'NONE', 0),
(@cpTraffic, 'policyNo', 'policyNo', 'NONE', 1),
(@cpTraffic, 'paymentType', 'paymentType', 'NONE', 1),
(@cpTraffic, 'cardTokenId', 'cardTokenId', 'NONE', 0);

-- TRAVEL (QUOTE) with repeatable insureds example
INSERT INTO carrier_product_field_sets (carrierProductId, stage, version, isActive, validFrom, validTo, stepsJson, pageChangeRequestJson)
VALUES (@cpTravel, 'QUOTE', 1, 1, NOW(), NULL, @stepsTravel, NULL);

SET @travelFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = @cpTravel AND stage = 'QUOTE'
  ORDER BY version DESC LIMIT 1
);

INSERT INTO `carrier_product_fields`
(
  `fieldSetId`,
  `internalCode`,
  `label`,
  `description`,
  `inputType`,
  `required`,
  `orderIndex`,
  `placeholder`,
  `validationRegex`,
  `minLength`,
  `maxLength`,
  `minValue`,
  `maxValue`,
  `optionsJson`,
  `extraConfigJson`,
  `stepPathJson`,
  `page`,
  `onBlurRequestJson`
)
VALUES
(@travelFieldSetId,'tripType','Seyahat Tipi',NULL,'select',1,1,
 NULL,NULL,NULL,NULL,NULL,NULL,
 JSON_ARRAY(
   JSON_OBJECT('value','foreignVisa','label','Yurt Dışı Vize / Geniş'),
   JSON_OBJECT('value','domestic','label','Yurt İçi'),
   JSON_OBJECT('value','student','label','Öğrenci'),
   JSON_OBJECT('value','incoming','label','Incoming / Pasaportlu Giriş')
 ),
 NULL,JSON_ARRAY('trip'),NULL,NULL),

(@travelFieldSetId,'startDate','Başlangıç Tarihi',NULL,'date',1,2,
 'YYYY-AA-GG',NULL,NULL,NULL,NULL,NULL,
 NULL,NULL,JSON_ARRAY('trip'),NULL,NULL),

(@travelFieldSetId,'endDate','Bitiş Tarihi',NULL,'date',1,3,
 'YYYY-AA-GG',NULL,NULL,NULL,NULL,NULL,
 NULL,NULL,JSON_ARRAY('trip'),NULL,NULL),

(@travelFieldSetId,'geographicalArea','Seyahat Bölgesi',NULL,'select',0,4,
 NULL,NULL,NULL,NULL,NULL,NULL,
 JSON_OBJECT(
   'optionsEndpoint','{{api-gw-uri}}/api/common/option/travel-region',
   'method','GET',
   'valueKey','value',
   'labelKey','label'
 ),
 JSON_OBJECT(
   'requiredWhen',
   JSON_OBJECT('field','tripType','op','in','value',JSON_ARRAY('foreignVisa','student'))
 ),
 JSON_ARRAY('trip'),NULL,NULL),

(@travelFieldSetId,'countryOfTravel','Seyahat Ülkesi',NULL,'select',0,5,
 NULL,NULL,NULL,NULL,NULL,NULL,
 JSON_OBJECT(
   'optionsEndpoint','{{api-gw-uri}}/api/common/option/travel-country?travelRegion={{geographicalArea}}',
   'method','GET',
   'valueKey','value',
   'labelKey','label'
 ),
 JSON_OBJECT(
   'requiredWhen',
   JSON_OBJECT('field','tripType','op','in','value',JSON_ARRAY('foreignVisa','student'))
 ),
 JSON_ARRAY('trip'),NULL,NULL),

(@travelFieldSetId,'cityOfTravel','Seyahat Şehri',NULL,'select',0,6,
 NULL,NULL,NULL,NULL,NULL,NULL,
 JSON_OBJECT(
   'optionsEndpoint','{{api-gw-uri}}/api/location/city',
   'method','GET',
   'valueKey','id',
   'labelKey','name'
 ),
 JSON_OBJECT(
   'requiredWhen',
   JSON_OBJECT('field','tripType','op','eq','value','domestic')
 ),
 JSON_ARRAY('trip'),NULL,NULL),

(@travelFieldSetId,'packageType','Paket Tipi','foreignVisa senaryosu için','select',0,7,
 NULL,NULL,NULL,NULL,NULL,NULL,
 JSON_ARRAY(
   JSON_OBJECT('value','1','label','Quick Vize Seyahat'),
   JSON_OBJECT('value','2','label','Quick Yurt Dışı Geniş Paket')
 ),
 JSON_OBJECT(
   'requiredWhen',
   JSON_OBJECT('field','tripType','op','eq','value','foreignVisa')
 ),
 JSON_ARRAY('trip'),NULL,NULL),

(@travelFieldSetId,'covid19','Covid-19 Teminatı',NULL,'boolean',0,8,
 NULL,NULL,NULL,NULL,NULL,NULL,
 NULL,NULL,JSON_ARRAY('trip'),NULL,NULL),

(@travelFieldSetId,'travelAgencyBankruptcy','Seyahat Acentesi İflası',NULL,'boolean',0,9,
 NULL,NULL,NULL,NULL,NULL,NULL,
 NULL,NULL,JSON_ARRAY('trip'),NULL,NULL),

(@travelFieldSetId,'agencyCommissionRate','Acente Komisyon Oranı','Örn: 0.40','number',0,10,
 '0.40',NULL,NULL,NULL,0,1,
 NULL,NULL,JSON_ARRAY('trip'),NULL,NULL),

(@travelFieldSetId,'insurerIdNumber','Sigorta Ettiren TCKN / VKN',NULL,'identity',1,11,
 '11 haneli TCKN','^[0-9]{11}$',11,11,NULL,NULL,
 NULL,NULL,JSON_ARRAY('contact'),NULL,NULL),

(@travelFieldSetId,'insurerBirthDate','Sigorta Ettiren Doğum Tarihi',NULL,'date',1,12,
 'YYYY-AA-GG',NULL,NULL,NULL,NULL,NULL,
 NULL,NULL,JSON_ARRAY('contact'),NULL,NULL),

(@travelFieldSetId,'insurerEmail','Sigorta Ettiren E-posta',NULL,'email',1,13,
 NULL,NULL,NULL,120,NULL,NULL,
 NULL,NULL,JSON_ARRAY('contact'),NULL,NULL),

(@travelFieldSetId,'insurerPhoneNumber','Sigorta Ettiren Telefon',NULL,'phone',1,14,
 '5xxxxxxxxx',NULL,10,20,NULL,NULL,
 NULL,NULL,JSON_ARRAY('contact'),NULL,NULL),

(@travelFieldSetId,'insureds[].idNumber','Sigortalı TCKN / Pasaport',NULL,'identity',1,15,
 '11 haneli','^[0-9]{6,20}$',6,20,NULL,NULL,
 NULL,
 JSON_OBJECT('collection',JSON_OBJECT('arrayPath','insureds','autoPopulateFrom','insurer')),
 JSON_ARRAY('insureds'),NULL,NULL),

(@travelFieldSetId,'insureds[].birthDate','Sigortalı Doğum Tarihi',NULL,'date',1,16,
 'YYYY-AA-GG',NULL,NULL,NULL,NULL,NULL,
 NULL,NULL,JSON_ARRAY('insureds'),NULL,NULL),

(@travelFieldSetId,'insureds[].email','Sigortalı E-posta',NULL,'email',0,17,
 NULL,NULL,NULL,120,NULL,NULL,
 NULL,NULL,JSON_ARRAY('insureds'),NULL,NULL),

(@travelFieldSetId,'insureds[].phoneNumber','Sigortalı Telefon',NULL,'phone',0,18,
 '5xxxxxxxxx',NULL,10,20,NULL,NULL,
 NULL,NULL,JSON_ARRAY('insureds'),NULL,NULL),

(@travelFieldSetId,'insureds[].isMain','Ana Sigortalı','İlk kişi genelde ana sigortalıdır.','boolean',0,19,
 NULL,NULL,NULL,NULL,NULL,NULL,
 NULL,NULL,JSON_ARRAY('insureds'),NULL,NULL);


-- TRAVEL field mappings (example)
INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpTravel, 'tripType', 'questions.type', 'NONE', 1),
(@cpTravel, 'startDate', 'questions.startDate', 'DATE_YYYYMMDD', 1),
(@cpTravel, 'endDate', 'questions.endDate', 'DATE_YYYYMMDD', 1),
(@cpTravel, 'geographicalArea', 'questions.geographicalArea', 'NONE', 0),
(@cpTravel, 'countryOfTravel', 'questions.countryOfTravel', 'NONE', 0),
(@cpTravel, 'cityOfTravel', 'questions.cityOfTravel', 'NONE', 0),
(@cpTravel, 'packageType', 'questions.packageType', 'NONE', 0),
(@cpTravel, 'covid19', 'questions.covid19', 'NONE', 0),
(@cpTravel, 'travelAgencyBankruptcy', 'questions.travelAgencyBankruptcy', 'NONE', 0),
(@cpTravel, 'agencyCommissionRate', 'questions.agencyCommissionRate', 'NONE', 0),
(@cpTravel, 'insurerIdNumber', 'insurer.idNumber', 'TR_IDENTITY_TCKN', 1),
(@cpTravel, 'insurerBirthDate', 'insurer.birthDate', 'DATE_YYYYMMDD', 1),
(@cpTravel, 'insurerEmail', 'insurer.email', 'LOWERCASE', 1),
(@cpTravel, 'insurerPhoneNumber', 'insurer.phoneNumber', 'PHONE_E164', 1),
(@cpTravel, 'insureds[].idNumber', 'insureds[].idNumber', 'TR_IDENTITY_TCKN', 1),
(@cpTravel, 'insureds[].birthDate', 'insureds[].birthDate', 'DATE_YYYYMMDD', 1),
(@cpTravel, 'insureds[].email', 'insureds[].email', 'LOWERCASE', 0),
(@cpTravel, 'insureds[].phoneNumber', 'insureds[].phoneNumber', 'PHONE_E164', 0),
(@cpTravel, 'insureds[].isMain', 'insureds[].isMain', 'NONE', 0);

COMMIT;
