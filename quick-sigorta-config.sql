-- Quick Sigorta configuration seed (forms + API mappings)
-- Based on "Quick Sigorta - Acenteler API.postman_collection.json"
-- Creates carrier product field sets, fields, and carrier field mappings for every Quick product.

-- Ensure carrier and product rows exist
INSERT INTO carriers (code, name, isActive)
VALUES ('QUICK_SIGORTA', 'Quick Sigorta', 1)
ON DUPLICATE KEY UPDATE name = VALUES(name), isActive = VALUES(isActive);

INSERT INTO products (code, name, description) VALUES
('TRAFFIC', 'Traffic', 'Trafik sigortasi'),
('CASCO', 'Casco', 'Kasko sigortasi'),
('HOME', 'Home', 'Konut/Dask'),
('HEALTH', 'Health', 'Saglik/Travel Saglik'),
('LIFE', 'Life', 'Ferdi Kaza')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- Capture ids defensively (in case duplicates exist) and reuse variables
SET @carrierQuick := (SELECT id FROM carriers WHERE code = 'QUICK_SIGORTA' ORDER BY id LIMIT 1);
SET @prodTraffic := (SELECT id FROM products WHERE code = 'TRAFFIC' ORDER BY id LIMIT 1);
SET @prodCasco := (SELECT id FROM products WHERE code = 'CASCO' ORDER BY id LIMIT 1);
SET @prodHome := (SELECT id FROM products WHERE code = 'HOME' ORDER BY id LIMIT 1);
SET @prodHealth := (SELECT id FROM products WHERE code = 'HEALTH' ORDER BY id LIMIT 1);
SET @prodLife := (SELECT id FROM products WHERE code = 'LIFE' ORDER BY id LIMIT 1);

-- Link Quick products to carrier external productIds from Postman collection
INSERT INTO carrier_products (carrierId, productId, externalCode, isActive) VALUES
(@carrierQuick, @prodTraffic, '101', 1),
(@carrierQuick, @prodCasco, '111', 1),
(@carrierQuick, @prodCasco, '112', 1),
(@carrierQuick, @prodHome, '202', 1),
(@carrierQuick, @prodHealth, '600', 1),
(@carrierQuick, @prodLife, '500', 1)
ON DUPLICATE KEY UPDATE externalCode = VALUES(externalCode), isActive = VALUES(isActive);

SET @cpTraffic := (SELECT id FROM carrier_products WHERE carrierId = @carrierQuick AND externalCode = '101' ORDER BY id LIMIT 1);
SET @cpCasco111 := (SELECT id FROM carrier_products WHERE carrierId = @carrierQuick AND externalCode = '111' ORDER BY id LIMIT 1);
SET @cpCasco112 := (SELECT id FROM carrier_products WHERE carrierId = @carrierQuick AND externalCode = '112' ORDER BY id LIMIT 1);
SET @cpDask := (SELECT id FROM carrier_products WHERE carrierId = @carrierQuick AND externalCode = '202' ORDER BY id LIMIT 1);
SET @cpTravel := (SELECT id FROM carrier_products WHERE carrierId = @carrierQuick AND externalCode = '600' ORDER BY id LIMIT 1);
SET @cpLife := (SELECT id FROM carrier_products WHERE carrierId = @carrierQuick AND externalCode = '500' ORDER BY id LIMIT 1);

-- TRAFFIC (productId 101) proposal payload
INSERT INTO carrier_product_field_sets (carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpTraffic,
  1, 1, NOW(), NULL, NULL
);
SET @trafficFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = (
    @cpTraffic
  )
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
(@trafficFieldSetId, 'insuredIdNumber', 'Sigortalı TCKN', NULL, 'identity', 1,
  5, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'insuredBirthDate', 'Sigortalı Doğum Tarihi', NULL, 'date', 1,
  6, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'insuredEmail', 'Sigortalı E-posta', NULL, 'email', 1,
  7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'insuredPhoneNumber', 'Sigortalı Telefon', NULL, 'text', 1,
  8, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'packageType', 'Paket Tipi', NULL, 'select', 1,
  9, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', '1', 'label', 'Normal'),
    JSON_OBJECT('value', '2', 'label', 'Süper')
  ),
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/traffic/package-type', 'method', 'GET'),
  1, NULL),
(@trafficFieldSetId, 'plateType', 'Plaka Tipi', NULL, 'select', 1,
  10, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'registered', 'label', 'Tescilli'),
    JSON_OBJECT('value', 'unregistered', 'label', 'Tescilsiz / Yeni Tescil')
  ),
  NULL, 1, NULL),
(@trafficFieldSetId, 'plateCityCode', 'Plaka İl Kodu', NULL, 'select', 1,
  11, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/location/city', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@trafficFieldSetId, 'usageStyle', 'Kullanım Tarzı', NULL, 'select', 1,
  12, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/usage-style', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@trafficFieldSetId, 'modelYear', 'Model Yılı', NULL, 'select', 1,
  13, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/traffic/new-registration/year', 'method', 'GET'),
  1, NULL),
(@trafficFieldSetId, 'makeId', 'Marka', NULL, 'select', 1,
  14, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/make?usageStyleId={{usageStyle}}&yearId={{modelYear}}', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@trafficFieldSetId, 'modelId', 'Model', 'Opsiyonel model seçimi', 'select', 0,
  15, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/model?usageStyleId={{usageStyle}}&yearId={{modelYear}}&brandId={{makeId}}', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@trafficFieldSetId, 'engineNumber', 'Motor No', NULL, 'text', 1,
  16, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, 1, NULL),
(@trafficFieldSetId, 'chassisNumber', 'Şasi No', NULL, 'text', 1,
  17, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpTraffic, 'insurerIdNumber', 'insurer.idNumber', 'NONE', 1),
(@cpTraffic, 'insurerBirthDate', 'insurer.birthDate', 'DATE_YYYY_MM_DD', 1),
(@cpTraffic, 'insurerEmail', 'insurer.email', 'LOWERCASE', 1),
(@cpTraffic, 'insurerPhoneNumber', 'insurer.phoneNumber', 'NONE', 1),
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

-- CASCO (productId 111)
INSERT INTO carrier_product_field_sets (carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpCasco111,
  1, 1, NOW(), NULL, NULL
);
SET @casco111FieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = (
    @cpCasco111
  )
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `page`, `onBlurRequestJson`
) VALUES
(@casco111FieldSetId, 'insurerIdNumber', 'Sigorta Ettiren TCKN', NULL, 'identity', 1,
  1, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@casco111FieldSetId, 'insurerBirthDate', 'Sigorta Ettiren Doğum Tarihi', NULL, 'date', 1,
  2, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@casco111FieldSetId, 'insurerEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 1,
  3, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@casco111FieldSetId, 'insurerPhoneNumber', 'Sigorta Ettiren Telefon', NULL, 'text', 1,
  4, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@casco111FieldSetId, 'insuredIdNumber', 'Sigortalı TCKN', NULL, 'identity', 1,
  5, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@casco111FieldSetId, 'insuredBirthDate', 'Sigortalı Doğum Tarihi', NULL, 'date', 1,
  6, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@casco111FieldSetId, 'insuredEmail', 'Sigortalı E-posta', NULL, 'email', 1,
  7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@casco111FieldSetId, 'insuredPhoneNumber', 'Sigortalı Telefon', NULL, 'text', 1,
  8, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@casco111FieldSetId, 'plateType', 'Plaka Tipi', NULL, 'select', 1,
  9, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'registered', 'label', 'Tescilli'),
    JSON_OBJECT('value', 'unregistered', 'label', 'Tescilsiz / Yeni Tescil')
  ),
  NULL, 1, NULL),
(@casco111FieldSetId, 'chassisNumber', 'Şasi No', NULL, 'text', 1,
  10, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, 1, NULL),
(@casco111FieldSetId, 'engineNumber', 'Motor No', NULL, 'text', 1,
  11, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, 1, NULL),
(@casco111FieldSetId, 'usageStyle', 'Kullanım Tarzı', NULL, 'select', 1,
  12, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/usage-style', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@casco111FieldSetId, 'makeId', 'Marka', NULL, 'select', 1,
  13, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/make?usageStyleId={{usageStyle}}&yearId={{modelYear}}', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@casco111FieldSetId, 'modelYear', 'Model Yılı', NULL, 'select', 1,
  14, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/kasko/new-registration/year', 'method', 'GET'),
  1, NULL),
(@casco111FieldSetId, 'plateCityCode', 'Plaka İl Kodu', NULL, 'select', 1,
  15, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/location/city', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@casco111FieldSetId, 'occupationCode', 'Meslek', NULL, 'select', 0,
  16, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option?questionKey=occupationCode&productId=111', 'method', 'GET'),
  1, NULL),
(@casco111FieldSetId, 'immCoverageLimit', 'IMM Teminat Limiti', NULL, 'select', 0,
  17, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/imm-coverage-limit?usageType=1&productId=111', 'method', 'GET'),
  1, NULL),
(@casco111FieldSetId, 'glassCoverageDeductibleOption', 'Cam Teminatı', NULL, 'select', 0,
  18, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/glass-coverage-deductible?usageType=1', 'method', 'GET'),
  1, NULL),
(@casco111FieldSetId, 'replacementVehicle', 'İkame Araç', NULL, 'select', 0,
  19, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/replacement-vehicle?usageType=1', 'method', 'GET'),
  1, NULL),
(@casco111FieldSetId, 'installment', 'Taksitli Ödeme', NULL, 'select', 0,
  20, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', 'true', 'label', 'Evet'), JSON_OBJECT('value', 'false', 'label', 'Hayır')),
  NULL, 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpCasco111, 'insurerIdNumber', 'insurer.idNumber', 'NONE', 1),
(@cpCasco111, 'insurerBirthDate', 'insurer.birthDate', 'DATE_YYYY_MM_DD', 1),
(@cpCasco111, 'insurerEmail', 'insurer.email', 'LOWERCASE', 1),
(@cpCasco111, 'insurerPhoneNumber', 'insurer.phoneNumber', 'NONE', 1),
(@cpCasco111, 'insuredIdNumber', 'insureds[0].idNumber', 'NONE', 1),
(@cpCasco111, 'insuredBirthDate', 'insureds[0].birthDate', 'DATE_YYYY_MM_DD', 1),
(@cpCasco111, 'insuredEmail', 'insureds[0].email', 'LOWERCASE', 1),
(@cpCasco111, 'insuredPhoneNumber', 'insureds[0].phoneNumber', 'NONE', 1),
(@cpCasco111, 'plateType', 'questions.plateType', 'NONE', 1),
(@cpCasco111, 'chassisNumber', 'questions.chassisNumber', 'NONE', 1),
(@cpCasco111, 'engineNumber', 'questions.engineNumber', 'NONE', 1),
(@cpCasco111, 'usageStyle', 'questions.usageStyle', 'NONE', 1),
(@cpCasco111, 'makeId', 'questions.makeId', 'NONE', 1),
(@cpCasco111, 'modelYear', 'questions.modelYear', 'NONE', 1),
(@cpCasco111, 'plateCityCode', 'questions.plateCityCode', 'NONE', 1),
(@cpCasco111, 'occupationCode', 'questions.occupationCode', 'NONE', 0),
(@cpCasco111, 'immCoverageLimit', 'questions.immCoverageLimit', 'NONE', 0),
(@cpCasco111, 'glassCoverageDeductibleOption', 'questions.glassCoverageDeductibleOption', 'NONE', 0),
(@cpCasco111, 'replacementVehicle', 'questions.replacementVehicle', 'NONE', 0),
(@cpCasco111, 'installment', 'payment.installment', 'BOOLEAN', 0);

-- CASCO (productId 112, Muafiyetli)
INSERT INTO carrier_product_field_sets (carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpCasco112,
  1, 1, NOW(), NULL, NULL
);
SET @casco112FieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = (
    @cpCasco112
  )
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `page`, `onBlurRequestJson`
) VALUES
(@casco112FieldSetId, 'insurerIdNumber', 'Sigorta Ettiren TCKN', NULL, 'identity', 1,
  1, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@casco112FieldSetId, 'insurerBirthDate', 'Sigorta Ettiren Doğum Tarihi', NULL, 'date', 1,
  2, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@casco112FieldSetId, 'insurerEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 1,
  3, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@casco112FieldSetId, 'insurerPhoneNumber', 'Sigorta Ettiren Telefon', NULL, 'text', 1,
  4, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@casco112FieldSetId, 'insuredIdNumber', 'Sigortalı TCKN', NULL, 'identity', 1,
  5, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@casco112FieldSetId, 'insuredBirthDate', 'Sigortalı Doğum Tarihi', NULL, 'date', 1,
  6, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@casco112FieldSetId, 'insuredEmail', 'Sigortalı E-posta', NULL, 'email', 1,
  7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@casco112FieldSetId, 'insuredPhoneNumber', 'Sigortalı Telefon', NULL, 'text', 1,
  8, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@casco112FieldSetId, 'plateType', 'Plaka Tipi', NULL, 'select', 1,
  9, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'registered', 'label', 'Tescilli'),
    JSON_OBJECT('value', 'unregistered', 'label', 'Tescilsiz / Yeni Tescil')
  ),
  NULL, 1, NULL),
(@casco112FieldSetId, 'chassisNumber', 'Şasi No', NULL, 'text', 1,
  10, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, 1, NULL),
(@casco112FieldSetId, 'engineNumber', 'Motor No', NULL, 'text', 1,
  11, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, 1, NULL),
(@casco112FieldSetId, 'usageStyle', 'Kullanım Tarzı', NULL, 'select', 1,
  12, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/usage-style', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@casco112FieldSetId, 'makeId', 'Marka', NULL, 'select', 1,
  13, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/auto/make?usageStyleId={{usageStyle}}&yearId={{modelYear}}', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@casco112FieldSetId, 'modelYear', 'Model Yılı', NULL, 'select', 1,
  14, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/kasko/new-registration/year', 'method', 'GET'),
  1, NULL),
(@casco112FieldSetId, 'plateCityCode', 'Plaka İl Kodu', NULL, 'select', 1,
  15, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/location/city', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@casco112FieldSetId, 'deductibleRate', 'Muafiyet Oranı', NULL, 'select', 0,
  16, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/imm-coverage-limit?usageType=1&productId=112', 'method', 'GET'),
  1, NULL),
(@casco112FieldSetId, 'immCoverageLimit', 'IMM Teminat Limiti', NULL, 'select', 0,
  17, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/imm-coverage-limit?usageType=1&productId=112', 'method', 'GET'),
  1, NULL),
(@casco112FieldSetId, 'installment', 'Taksitli Ödeme', NULL, 'select', 0,
  18, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', 'true', 'label', 'Evet'), JSON_OBJECT('value', 'false', 'label', 'Hayır')),
  NULL, 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpCasco112, 'insurerIdNumber', 'insurer.idNumber', 'NONE', 1),
(@cpCasco112, 'insurerBirthDate', 'insurer.birthDate', 'DATE_YYYY_MM_DD', 1),
(@cpCasco112, 'insurerEmail', 'insurer.email', 'LOWERCASE', 1),
(@cpCasco112, 'insurerPhoneNumber', 'insurer.phoneNumber', 'NONE', 1),
(@cpCasco112, 'insuredIdNumber', 'insureds[0].idNumber', 'NONE', 1),
(@cpCasco112, 'insuredBirthDate', 'insureds[0].birthDate', 'DATE_YYYY_MM_DD', 1),
(@cpCasco112, 'insuredEmail', 'insureds[0].email', 'LOWERCASE', 1),
(@cpCasco112, 'insuredPhoneNumber', 'insureds[0].phoneNumber', 'NONE', 1),
(@cpCasco112, 'plateType', 'questions.plateType', 'NONE', 1),
(@cpCasco112, 'chassisNumber', 'questions.chassisNumber', 'NONE', 1),
(@cpCasco112, 'engineNumber', 'questions.engineNumber', 'NONE', 1),
(@cpCasco112, 'usageStyle', 'questions.usageStyle', 'NONE', 1),
(@cpCasco112, 'makeId', 'questions.makeId', 'NONE', 1),
(@cpCasco112, 'modelYear', 'questions.modelYear', 'NONE', 1),
(@cpCasco112, 'plateCityCode', 'questions.plateCityCode', 'NONE', 1),
(@cpCasco112, 'deductibleRate', 'questions.deductibleRate', 'NONE', 0),
(@cpCasco112, 'immCoverageLimit', 'questions.immCoverageLimit', 'NONE', 0),
(@cpCasco112, 'installment', 'payment.installment', 'BOOLEAN', 0);

-- TRAVEL HEALTH (productId 600)
INSERT INTO carrier_product_field_sets (carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpTravel,
  1, 1, NOW(), NULL, NULL
);
SET @travelFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = (
    @cpTravel
  )
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `page`, `onBlurRequestJson`
) VALUES
(@travelFieldSetId, 'insurerIdNumber', 'Sigorta Ettiren TCKN', NULL, 'identity', 1,
  1, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@travelFieldSetId, 'insurerBirthDate', 'Sigorta Ettiren Doğum Tarihi', NULL, 'date', 1,
  2, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@travelFieldSetId, 'insurerEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 1,
  3, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@travelFieldSetId, 'insurerPhoneNumber', 'Sigorta Ettiren Telefon', NULL, 'text', 1,
  4, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@travelFieldSetId, 'insuredIdNumber', 'Sigortalı TCKN', NULL, 'identity', 1,
  5, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@travelFieldSetId, 'insuredBirthDate', 'Sigortalı Doğum Tarihi', NULL, 'date', 1,
  6, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@travelFieldSetId, 'insuredEmail', 'Sigortalı E-posta', NULL, 'email', 1,
  7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@travelFieldSetId, 'insuredPhoneNumber', 'Sigortalı Telefon', NULL, 'text', 1,
  8, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@travelFieldSetId, 'type', 'Paket Türü', 'foreignVisa / abroadExtended / domestic / student / passportEntry', 'select', 1,
  9, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'foreignVisa', 'label', 'Yurt Dışı Vize'),
    JSON_OBJECT('value', 'abroadExtended', 'label', 'Yurt Dışı Geniş'),
    JSON_OBJECT('value', 'domestic', 'label', 'Yurt İçi'),
    JSON_OBJECT('value', 'student', 'label', 'Öğrenci'),
    JSON_OBJECT('value', 'passportEntry', 'label', 'Pasaportlu Giriş')
  ),
  NULL, 1, NULL),
(@travelFieldSetId, 'startDate', 'Başlangıç Tarihi', NULL, 'date', 1,
  10, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@travelFieldSetId, 'endDate', 'Bitiş Tarihi', NULL, 'date', 1,
  11, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@travelFieldSetId, 'packageType', 'Plan', NULL, 'select', 1,
  12, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', '1', 'label', 'Standart'), JSON_OBJECT('value', '2', 'label', 'Plus')),
  NULL, 1, NULL),
(@travelFieldSetId, 'geographicalArea', 'Bölge', NULL, 'select', 1,
  13, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/travel-region', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@travelFieldSetId, 'countryOfTravel', 'Ülke', NULL, 'select', 0,
  14, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option/travel-country?travelRegion={{geographicalArea}}', 'method', 'GET', 'valueKey', 'id', 'labelKey', 'name'),
  1, NULL),
(@travelFieldSetId, 'covid19', 'Covid-19 Teminatı', NULL, 'select', 0,
  15, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', 'true', 'label', 'Evet'), JSON_OBJECT('value', 'false', 'label', 'Hayır')),
  NULL, 1, NULL),
(@travelFieldSetId, 'travelAgencyBankruptcy', 'Seyahat Acentesi İflas Teminatı', NULL, 'select', 0,
  16, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', 'true', 'label', 'Evet'), JSON_OBJECT('value', 'false', 'label', 'Hayır')),
  NULL, 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpTravel, 'insurerIdNumber', 'insurer.idNumber', 'NONE', 1),
(@cpTravel, 'insurerBirthDate', 'insurer.birthDate', 'DATE_ISO_STRING', 1),
(@cpTravel, 'insurerEmail', 'insurer.email', 'LOWERCASE', 1),
(@cpTravel, 'insurerPhoneNumber', 'insurer.phoneNumber', 'NONE', 1),
(@cpTravel, 'insuredIdNumber', 'insureds[0].idNumber', 'NONE', 1),
(@cpTravel, 'insuredBirthDate', 'insureds[0].birthDate', 'DATE_ISO_STRING', 1),
(@cpTravel, 'insuredEmail', 'insureds[0].email', 'LOWERCASE', 1),
(@cpTravel, 'insuredPhoneNumber', 'insureds[0].phoneNumber', 'NONE', 1),
(@cpTravel, 'type', 'questions.type', 'NONE', 1),
(@cpTravel, 'startDate', 'questions.startDate', 'DATE_ISO_STRING', 1),
(@cpTravel, 'endDate', 'questions.endDate', 'DATE_ISO_STRING', 1),
(@cpTravel, 'packageType', 'questions.packageType', 'NONE', 1),
(@cpTravel, 'geographicalArea', 'questions.geographicalArea', 'NONE', 1),
(@cpTravel, 'countryOfTravel', 'questions.countryOfTravel', 'NONE', 0),
(@cpTravel, 'covid19', 'questions.covid19', 'BOOLEAN', 0),
(@cpTravel, 'travelAgencyBankruptcy', 'questions.travelAgencyBankruptcy', 'BOOLEAN', 0);

-- DASK / HOME (productId 202)
INSERT INTO carrier_product_field_sets (carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpDask,
  1, 1, NOW(), NULL, NULL
);
SET @daskFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = (
    @cpDask
  )
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `page`, `onBlurRequestJson`
) VALUES
(@daskFieldSetId, 'insurerIdNumber', 'Sigorta Ettiren TCKN', NULL, 'identity', 1,
  1, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@daskFieldSetId, 'insurerBirthDate', 'Sigorta Ettiren Doğum Tarihi', NULL, 'date', 1,
  2, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@daskFieldSetId, 'insurerEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 1,
  3, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@daskFieldSetId, 'insurerPhoneNumber', 'Sigorta Ettiren Telefon', NULL, 'text', 1,
  4, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@daskFieldSetId, 'insuredIdNumber', 'Sigortalı TCKN', NULL, 'identity', 1,
  5, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@daskFieldSetId, 'insuredBirthDate', 'Sigortalı Doğum Tarihi', NULL, 'date', 1,
  6, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@daskFieldSetId, 'insuredEmail', 'Sigortalı E-posta', NULL, 'email', 1,
  7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@daskFieldSetId, 'insuredPhoneNumber', 'Sigortalı Telefon', NULL, 'text', 1,
  8, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@daskFieldSetId, 'type', 'İşlem Türü', 'newPolicy / renewal', 'select', 1,
  9, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', 'newPolicy', 'label', 'Yeni'), JSON_OBJECT('value', 'renewal', 'label', 'Yenileme')),
  NULL, 1, NULL),
(@daskFieldSetId, 'daskAddressCode', 'DASK Adres Kodu', NULL, 'text', 1,
  10, NULL, NULL, NULL, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@daskFieldSetId, 'insurerTitle', 'Sigorta Ettiren Sıfatı', NULL, 'select', 1,
  11, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option?questionKey=insurerTitle&productId=202', 'method', 'GET'),
  1, NULL),
(@daskFieldSetId, 'apartmentAreaSquareMeters', 'Brüt m2', NULL, 'text', 1,
  12, NULL, '^[0-9]+$', 1, 10, NULL, NULL, NULL, NULL, 1, NULL),
(@daskFieldSetId, 'buildingConstructionType', 'Bina İnşa Tarzı', NULL, 'select', 1,
  13, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option?questionKey=buildingConstructionType&productId=202', 'method', 'GET'),
  1, NULL),
(@daskFieldSetId, 'buildingConstructionYear', 'Bina İnşa Yılı', NULL, 'select', 1,
  14, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option?questionKey=buildingConstructionYear&productId=202', 'method', 'GET'),
  1, NULL),
(@daskFieldSetId, 'buildingTotalFloorCount', 'Toplam Kat Sayısı', NULL, 'select', 1,
  15, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option?questionKey=buildingTotalFloorCount&productId=202', 'method', 'GET'),
  1, NULL),
(@daskFieldSetId, 'apartmentUsageType', 'Daire Kullanım Şekli', NULL, 'select', 1,
  16, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option?questionKey=apartmentUsageType&productId=202', 'method', 'GET'),
  1, NULL),
(@daskFieldSetId, 'buildingPreviouslyDamaged', 'Bina Hasar Durumu', NULL, 'select', 1,
  17, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option?questionKey=buildingPreviouslyDamaged&productId=202', 'method', 'GET'),
  1, NULL),
(@daskFieldSetId, 'floorCode', 'Bulunduğu Kat', NULL, 'select', 1,
  18, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('optionsEndpoint', '{{api-gw-uri}}/api/common/option?questionKey=floorCode&productId=202', 'method', 'GET'),
  1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpDask, 'insurerIdNumber', 'insurer.idNumber', 'NONE', 1),
(@cpDask, 'insurerBirthDate', 'insurer.birthDate', 'DATE_ISO_STRING', 1),
(@cpDask, 'insurerEmail', 'insurer.email', 'LOWERCASE', 1),
(@cpDask, 'insurerPhoneNumber', 'insurer.phoneNumber', 'NONE', 1),
(@cpDask, 'insuredIdNumber', 'insureds[0].idNumber', 'NONE', 1),
(@cpDask, 'insuredBirthDate', 'insureds[0].birthDate', 'DATE_ISO_STRING', 1),
(@cpDask, 'insuredEmail', 'insureds[0].email', 'LOWERCASE', 1),
(@cpDask, 'insuredPhoneNumber', 'insureds[0].phoneNumber', 'NONE', 1),
(@cpDask, 'type', 'questions.type', 'NONE', 1),
(@cpDask, 'daskAddressCode', 'questions.daskAddressCode', 'NONE', 1),
(@cpDask, 'insurerTitle', 'questions.insurerTitle', 'NONE', 1),
(@cpDask, 'apartmentAreaSquareMeters', 'questions.apartmentAreaSquareMeters', 'NONE', 1),
(@cpDask, 'buildingConstructionType', 'questions.buildingConstructionType', 'NONE', 1),
(@cpDask, 'buildingConstructionYear', 'questions.buildingConstructionYear', 'NONE', 1),
(@cpDask, 'buildingTotalFloorCount', 'questions.buildingTotalFloorCount', 'NONE', 1),
(@cpDask, 'apartmentUsageType', 'questions.apartmentUsageType', 'NONE', 1),
(@cpDask, 'buildingPreviouslyDamaged', 'questions.buildingPreviouslyDamaged', 'NONE', 1),
(@cpDask, 'floorCode', 'questions.floorCode', 'NONE', 1);

-- LIFE / PERSONAL ACCIDENT (productId 500)
INSERT INTO carrier_product_field_sets (carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpLife,
  1, 1, NOW(), NULL, NULL
);
SET @lifeFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = (
    @cpLife
  )
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `page`, `onBlurRequestJson`
) VALUES
(@lifeFieldSetId, 'insurerIdNumber', 'Sigorta Ettiren TCKN', NULL, 'identity', 1,
  1, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@lifeFieldSetId, 'insurerBirthDate', 'Sigorta Ettiren Doğum Tarihi', NULL, 'date', 1,
  2, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@lifeFieldSetId, 'insuredIdNumber', 'Sigortalı TCKN', NULL, 'identity', 1,
  3, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@lifeFieldSetId, 'insuredBirthDate', 'Sigortalı Doğum Tarihi', NULL, 'date', 1,
  4, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@lifeFieldSetId, 'type', 'Ürün Türü', 'digitalCampaign vb.', 'select', 1,
  5, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', 'digitalCampaign', 'label', 'Dijital Kampanya')),
  NULL, 1, NULL),
(@lifeFieldSetId, 'paymentType', 'Ödeme Tipi', NULL, 'select', 1,
  6, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', 'cash', 'label', 'Nakit'), JSON_OBJECT('value', 'card', 'label', 'Kredi Kartı')),
  NULL, 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpLife, 'insurerIdNumber', 'insurer.idNumber', 'NONE', 1),
(@cpLife, 'insurerBirthDate', 'insurer.birthDate', 'DATE_ISO_STRING', 1),
(@cpLife, 'insuredIdNumber', 'insureds[0].idNumber', 'NONE', 1),
(@cpLife, 'insuredBirthDate', 'insureds[0].birthDate', 'DATE_ISO_STRING', 1),
(@cpLife, 'type', 'questions.type', 'NONE', 1),
(@cpLife, 'paymentType', 'payment.type', 'NONE', 1);
