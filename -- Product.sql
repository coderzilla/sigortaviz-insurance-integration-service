-- Product
INSERT INTO products (code, name, description)
VALUES ('HEALTH', 'Health Insurance', 'Health insurance product')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- Carrier
INSERT INTO carriers (code, name, isActive)
VALUES ('AXA', 'Axa Sigorta', 1)
ON DUPLICATE KEY UPDATE name = VALUES(name), isActive = VALUES(isActive);

-- Carrier product
INSERT INTO carrier_products (carrierId, productId, externalCode, isActive)
VALUES (
  (SELECT id FROM carriers WHERE code = 'AXA'),
  (SELECT id FROM products WHERE code = 'HEALTH'),
  'AXA_HEALTH_STD',
  1
)
ON DUPLICATE KEY UPDATE externalCode = VALUES(externalCode), isActive = VALUES(isActive);

-- Field set (version 1) with an optional page-change trigger
INSERT INTO carrier_product_field_sets (
  carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson
) VALUES (
  (SELECT id FROM carrier_products WHERE carrierId = (SELECT id FROM carriers WHERE code = 'AXA')
    AND productId = (SELECT id FROM products WHERE code = 'HEALTH')),
  1,
  1,
  NOW(),
  NULL,
  JSON_OBJECT(
    'url', 'https://mock.axa.com/form/page-change',
    'method', 'POST',
    'params', JSON_OBJECT(
      'carrierProductCode', 'AXA_HEALTH_STD',
      'currentPage', '{{currentPage}}',
      'nextPage', '{{nextPage}}',
      'quoteId', '{{quoteId}}'
    )
  )
);

-- Grab the field_set id for convenience inside this session
SET @fieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = (
    SELECT id FROM carrier_products WHERE carrierId = (SELECT id FROM carriers WHERE code = 'AXA')
      AND productId = (SELECT id FROM products WHERE code = 'HEALTH')
  )
  ORDER BY version DESC
  LIMIT 1
);

-- Fields (2 pages). Adjust orderIndex as needed within each page.
INSERT INTO carrier_product_fields (
  fieldSetId, internalCode, label, description, inputType, required,
  orderIndex, placeholder, validationRegex, minLength, maxLength,
  minValue, maxValue, optionsJson, extraConfigJson, page, onBlurRequestJson
) VALUES
-- Page 1
(@fieldSetId, 'insuredFullName', 'Sigortalı Ad Soyad', NULL, 'text', 1,
  1, 'Ad Soyad', NULL, 3, 80, NULL, NULL, NULL, NULL, 1, NULL),
(@fieldSetId, 'insuredTckn', 'TCKN', '11 haneli kimlik numarası', 'identity', 1,
  2, 'TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1,
  JSON_OBJECT(
    'url', 'https://mock.axa.com/validate/tckn',
    'method', 'POST',
    'params', JSON_OBJECT(
      'tckn', '{{value}}',
      'birthDate', '{{form.insuredBirthDate}}'
    )
  )),
(@fieldSetId, 'insuredBirthDate', 'Doğum Tarihi', NULL, 'date', 1,
  3, 'GG/AA/YYYY', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@fieldSetId, 'email', 'E-posta', NULL, 'email', 0,
  4, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),

-- Page 2
(@fieldSetId, 'planCode', 'Plan', 'Seçtiğiniz sağlık planı', 'select', 1,
  1, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(
    JSON_OBJECT('value', 'STD', 'label', 'Standard Plan'),
    JSON_OBJECT('value', 'PLUS', 'label', 'Plus Plan'),
    JSON_OBJECT('value', 'PREMIUM', 'label', 'Premium Plan')
  ),
  NULL, 2, NULL),
(@fieldSetId, 'coverageStartDate', 'Poliçe Başlangıç', NULL, 'date', 1,
  2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL);

-- Example carrier field mappings for API payload
INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi)
VALUES
((SELECT id FROM carrier_products WHERE carrierId = (SELECT id FROM carriers WHERE code = 'AXA')
  AND productId = (SELECT id FROM products WHERE code = 'HEALTH')), 'insuredFullName', 'insured_full_name', 'UPPERCASE', 1),
((SELECT id FROM carrier_products WHERE carrierId = (SELECT id FROM carriers WHERE code = 'AXA')
  AND productId = (SELECT id FROM products WHERE code = 'HEALTH')), 'insuredTckn', 'insured_tckn', 'TR_IDENTITY_TCKN', 1),
((SELECT id FROM carrier_products WHERE carrierId = (SELECT id FROM carriers WHERE code = 'AXA')
  AND productId = (SELECT id FROM products WHERE code = 'HEALTH')), 'insuredBirthDate', 'insured_birthdate', 'DATE_DDMMYYYY', 1),
((SELECT id FROM carrier_products WHERE carrierId = (SELECT id FROM carriers WHERE code = 'AXA')
  AND productId = (SELECT id FROM products WHERE code = 'HEALTH')), 'email', 'email', 'LOWERCASE', 0),
((SELECT id FROM carrier_products WHERE carrierId = (SELECT id FROM carriers WHERE code = 'AXA')
  AND productId = (SELECT id FROM products WHERE code = 'HEALTH')), 'planCode', 'plan_code', 'NONE', 1),
((SELECT id FROM carrier_products WHERE carrierId = (SELECT id FROM carriers WHERE code = 'AXA')
  AND productId = (SELECT id FROM products WHERE code = 'HEALTH')), 'coverageStartDate', 'coverage_start_date', 'DATE_DDMMYYYY', 1)
ON DUPLICATE KEY UPDATE carrierParamName = VALUES(carrierParamName),
  transformType = VALUES(transformType),
  isRequiredForApi = VALUES(isRequiredForApi);

-- Quick Sigorta carrier and products from Postman collection
INSERT INTO carriers (code, name, isActive)
VALUES ('QUICK_SIGORTA', 'Quick Sigorta', 1)
ON DUPLICATE KEY UPDATE name = VALUES(name), isActive = VALUES(isActive);

-- Ensure core products exist (Traffic, Casco, Home/Dask, Health/Travel, Life/PA)
INSERT INTO products (code, name, description) VALUES
('TRAFFIC', 'Traffic', 'Trafik sigortasi'),
('CASCO', 'Casco', 'Kasko sigortasi'),
('HOME', 'Home', 'Konut/Dask'),
('HEALTH', 'Health', 'Saglik/Travel Saglik'),
('LIFE', 'Life', 'Ferdi Kaza')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- Carrier products mapping Quick productIds to internal codes
INSERT INTO carrier_products (carrierId, productId, externalCode, isActive) VALUES
((SELECT id FROM carriers WHERE code = 'QUICK_SIGORTA'),
 (SELECT id FROM products WHERE code = 'TRAFFIC'),
 '101', 1),
((SELECT id FROM carriers WHERE code = 'QUICK_SIGORTA'),
 (SELECT id FROM products WHERE code = 'CASCO'),
 '111', 1),
((SELECT id FROM carriers WHERE code = 'QUICK_SIGORTA'),
 (SELECT id FROM products WHERE code = 'CASCO'),
 '112', 1),
((SELECT id FROM carriers WHERE code = 'QUICK_SIGORTA'),
 (SELECT id FROM products WHERE code = 'HOME'),
 '202', 1),
((SELECT id FROM carriers WHERE code = 'QUICK_SIGORTA'),
 (SELECT id FROM products WHERE code = 'HEALTH'),
 '600', 1),
((SELECT id FROM carriers WHERE code = 'QUICK_SIGORTA'),
 (SELECT id FROM products WHERE code = 'LIFE'),
 '500', 1)
ON DUPLICATE KEY UPDATE externalCode = VALUES(externalCode), isActive = VALUES(isActive);

-- Orient Sigorta carrier and generic product mappings (WSDL-based, no explicit external codes)
INSERT INTO carriers (code, name, isActive)
VALUES ('ORIENT_SIGORTA', 'Orient Sigorta', 1)
ON DUPLICATE KEY UPDATE name = VALUES(name), isActive = VALUES(isActive);

INSERT INTO carrier_products (carrierId, productId, externalCode, isActive) VALUES
((SELECT id FROM carriers WHERE code = 'ORIENT_SIGORTA'),
 (SELECT id FROM products WHERE code = 'TRAFFIC'),
 'TRAFFIC', 1),
((SELECT id FROM carriers WHERE code = 'ORIENT_SIGORTA'),
 (SELECT id FROM products WHERE code = 'CASCO'),
 'CASCO', 1),
((SELECT id FROM carriers WHERE code = 'ORIENT_SIGORTA'),
 (SELECT id FROM products WHERE code = 'HOME'),
 'HOME', 1),
((SELECT id FROM carriers WHERE code = 'ORIENT_SIGORTA'),
 (SELECT id FROM products WHERE code = 'HEALTH'),
 'HEALTH', 1),
((SELECT id FROM carriers WHERE code = 'ORIENT_SIGORTA'),
 (SELECT id FROM products WHERE code = 'LIFE'),
 'LIFE', 1)
ON DUPLICATE KEY UPDATE externalCode = VALUES(externalCode), isActive = VALUES(isActive);
