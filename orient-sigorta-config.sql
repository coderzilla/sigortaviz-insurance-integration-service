-- Orient Sigorta configuration seed (SOAP Policy/Utility/Security WSDLs)
-- Builds carrier product field sets, fields and API mappings for TRAFFIC and HEALTH.
-- Field options refer to SOAP operations exposed in:
--   SecurityService.svc (GetAuthenticationKey)
--   UtilityService.svc (GetListSource, GetMarkaModel, GetUavtDetail)
--   PolicyService.svc (GetVehicleInfoByPlate, GetPoliciesFromSegmentation_017, CreatePolicy, MakePolicyPayment)

-- Ensure carrier and core products exist
INSERT INTO carriers (code, name, isActive)
VALUES ('ORIENT_SIGORTA', 'Orient Sigorta', 1)
ON DUPLICATE KEY UPDATE name = VALUES(name), isActive = VALUES(isActive);

INSERT INTO products (code, name, description) VALUES
('CASCO', 'Casco', 'Kasko')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- Cache ids defensively to avoid multi-row subqueries
SET @carrierOrient := (SELECT id FROM carriers WHERE code = 'ORIENT_SIGORTA' ORDER BY id LIMIT 1);
SET @prodCasco := (SELECT id FROM products WHERE code = 'CASCO' ORDER BY id LIMIT 1);

-- Link Orient carrier products (external codes are aligned with internal codes in WSDL usage)
INSERT INTO carrier_products (carrierId, productId, externalCode, isActive) VALUES
(@carrierOrient, @prodCasco, 'CASCO', 1)
ON DUPLICATE KEY UPDATE externalCode = VALUES(externalCode), isActive = VALUES(isActive);

SET @cpCasco := (SELECT id FROM carrier_products WHERE carrierId = @carrierOrient AND externalCode = 'CASCO' ORDER BY id LIMIT 1);

-- CASCO (uses PolicyService + UtilityService lookups)
INSERT INTO carrier_product_field_sets (carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpCasco,
  1, 1, NOW(), NULL, NULL
);
SET @orientTrafficFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = (
    @cpCasco
  )
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `page`, `onBlurRequestJson`
) VALUES
(@orientTrafficFieldSetId, 'authKey', 'Auth Key', 'GetAuthenticationKey (SecurityService)', 'text', 0,
  1, NULL, NULL, NULL, 200, NULL, NULL, NULL,
  JSON_OBJECT('soapOperation', 'ISecurityService/GetAuthenticationKey'), 1, NULL),
(@orientTrafficFieldSetId, 'insuredIdNumber', 'Sigortalı TCKN', NULL, 'identity', 1,
  2, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@orientTrafficFieldSetId, 'insuredBirthDate', 'Sigortalı Doğum Tarihi', NULL, 'date', 1,
  3, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@orientTrafficFieldSetId, 'insuredEmail', 'Sigortalı E-posta', NULL, 'email', 0,
  4, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@orientTrafficFieldSetId, 'insuredPhoneNumber', 'Sigortalı Telefon', NULL, 'text', 0,
  5, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@orientTrafficFieldSetId, 'plateNo', 'Plaka', 'GetVehicleInfoByPlate (PolicyService)', 'text', 1,
  6, '34ABC123', NULL, 4, 15, NULL, NULL, NULL,
  JSON_OBJECT('soapOperation', 'IPolicyService/GetVehicleInfoByPlate'), 1, NULL),
(@orientTrafficFieldSetId, 'chassisNumber', 'Şasi No', 'CheckPertVehicle (PolicyService)', 'text', 1,
  7, NULL, NULL, NULL, 50, NULL, NULL, NULL,
  JSON_OBJECT('soapOperation', 'IPolicyService/CheckPertVehicle'), 1, NULL),
(@orientTrafficFieldSetId, 'engineNumber', 'Motor No', NULL, 'text', 1,
  8, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, 1, NULL),
(@orientTrafficFieldSetId, 'brandCode', 'Marka Kodu', 'GetBirlikMarkaKod / UtilityService.GetMarkaModel', 'select', 1,
  9, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('soapOperation', 'IUtilityService/GetMarkaModel', 'valueKey', 'Code', 'labelKey', 'Name'),
  1, NULL),
(@orientTrafficFieldSetId, 'modelCode', 'Model Kodu', 'GetMarkaModel (model list)', 'select', 1,
  10, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('soapOperation', 'IUtilityService/GetMarkaModel', 'valueKey', 'Code', 'labelKey', 'Name'),
  1, NULL),
(@orientTrafficFieldSetId, 'modelYear', 'Model Yılı', NULL, 'select', 1,
  11, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('soapOperation', 'IUtilityService/GetListSource', 'listKey', 'ModelYear'),
  1, NULL),
(@orientTrafficFieldSetId, 'usageCode', 'Kullanım Tarzı', NULL, 'select', 1,
  12, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('soapOperation', 'IUtilityService/GetListSource', 'listKey', 'UsageType'),
  1, NULL),
(@orientTrafficFieldSetId, 'segmentationCode', 'Segmentasyon Kodu', 'GetPoliciesFromSegmentation_017', 'text', 0,
  13, NULL, NULL, NULL, 50, NULL, NULL, NULL,
  JSON_OBJECT('soapOperation', 'IPolicyService/GetPoliciesFromSegmentation_017'), 1, NULL),
(@orientTrafficFieldSetId, 'paymentMethod', 'Ödeme Tipi', 'MakePolicyPayment / MakePolicyPaymentRSA', 'select', 1,
  14, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', 'CreditCard', 'label', 'Kredi Kartı'), JSON_OBJECT('value', 'Cash', 'label', 'Nakit')),
  JSON_OBJECT('soapOperation', 'IPolicyService/MakePolicyPaymentV3'), 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpCasco, 'authKey', 'AuthKey', 'NONE', 0),
(@cpCasco, 'insuredIdNumber', 'Insured.TCKN', 'NONE', 1),
(@cpCasco, 'insuredBirthDate', 'Insured.BirthDate', 'DATE_YYYY_MM_DD', 1),
(@cpCasco, 'insuredEmail', 'Insured.Email', 'LOWERCASE', 0),
(@cpCasco, 'insuredPhoneNumber', 'Insured.PhoneNumber', 'NONE', 0),
(@cpCasco, 'plateNo', 'Vehicle.PlateNo', 'UPPERCASE', 1),
(@cpCasco, 'chassisNumber', 'Vehicle.ChassisNo', 'UPPERCASE', 1),
(@cpCasco, 'engineNumber', 'Vehicle.EngineNo', 'UPPERCASE', 1),
(@cpCasco, 'brandCode', 'Vehicle.BrandCode', 'NONE', 1),
(@cpCasco, 'modelCode', 'Vehicle.ModelCode', 'NONE', 1),
(@cpCasco, 'modelYear', 'Vehicle.ModelYear', 'NONE', 1),
(@cpCasco, 'usageCode', 'Vehicle.UsageCode', 'NONE', 1),
(@cpCasco, 'segmentationCode', 'QuoteRequest.SegmentationCode', 'NONE', 0),
(@cpCasco, 'paymentMethod', 'Payment.Method', 'NONE', 1);
