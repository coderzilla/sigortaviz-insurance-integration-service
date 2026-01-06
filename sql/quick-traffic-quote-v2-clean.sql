START TRANSACTION;

SET @carrierId := (SELECT id FROM carriers WHERE code = 'QUICK_SIGORTA' LIMIT 1);
SET @productId := (SELECT id FROM products WHERE code = 'TRAFFIC' LIMIT 1);
SET @carrierProductId := (
  SELECT id FROM carrier_products
  WHERE carrierId = @carrierId AND productId = @productId
  ORDER BY id LIMIT 1
);

UPDATE carrier_product_field_sets
SET isActive = 0
WHERE carrierProductId = @carrierProductId AND stage = 'QUOTE';

SET @newVersion := (
  SELECT COALESCE(MAX(version), 0) + 1
  FROM carrier_product_field_sets
  WHERE carrierProductId = @carrierProductId AND stage = 'QUOTE'
);

SET @stepsTraffic := JSON_ARRAY(
  JSON_OBJECT(
    'id', 'quote', 'title', 'Teklif Bilgileri', 'order', 1,
    'children', JSON_ARRAY(
      JSON_OBJECT(
        'id', 'basic', 'title', 'Temel Bilgiler', 'order', 1,
        'children', JSON_ARRAY(
          JSON_OBJECT('id', 'auth', 'title', 'Kimlik ve İletişim', 'order', 1),
          JSON_OBJECT('id', 'security', 'title', 'Güvenlik Doğrulama', 'order', 2)
        )
      ),
      JSON_OBJECT('id', 'occupation', 'title', 'Meslek Bilgileri', 'order', 2),
      JSON_OBJECT('id', 'personal', 'title', 'Kişisel Bilgiler', 'order', 3)
    )
  ),
  JSON_OBJECT(
    'id', 'vehicle', 'title', 'Araç Bilgileri', 'order', 2,
    'children', JSON_ARRAY(
      JSON_OBJECT(
        'id', 'license', 'title', 'Ruhsat Bilgileri', 'order', 1,
        'children', JSON_ARRAY(
          JSON_OBJECT('id', 'page1', 'title', 'Plaka', 'order', 1),
          JSON_OBJECT('id', 'page2', 'title', 'Araç Detayları', 'order', 2)
        )
      )
    )
  ),
  JSON_OBJECT('id', 'contact', 'title', 'İletişim Bilgileri', 'order', 3),
  JSON_OBJECT('id', 'package', 'title', 'Paket Seçimi', 'order', 4)
);

INSERT INTO carrier_product_field_sets (
  `carrierProductId`, `stage`, `version`, `isActive`, `validFrom`, `validTo`, `stepsJson`, `pageChangeRequestJson`
) VALUES (
  @carrierProductId,
  'QUOTE',
  @newVersion,
  1,
  NOW(),
  NULL,
  @stepsTraffic,
  JSON_OBJECT(
    'url', '{{api-gw-uri}}/api/customer/check',
    'method', 'POST',
    'params', JSON_OBJECT(
      'idNumber', '{{insurerIdNumber}}',
      'phoneNumber', '{{insurerPhoneNumber}}'
    )
  )
);

SET @fieldSetId := LAST_INSERT_ID();

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`, `isShown`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `stepPathJson`, `page`, `onBlurRequestJson`
) VALUES
(@fieldSetId,'insurerIdNumber','Sigorta Ettiren TCKN / VKN',NULL,'identity',1,1,1,'11 haneli TCKN','^[0-9]{11}$',11,11,NULL,NULL,NULL,NULL,JSON_ARRAY('quote','basic','auth'),NULL,NULL),
(@fieldSetId,'insurerPhoneNumber','Sigorta Ettiren Telefon',NULL,'phone',1,1,2,'5xxxxxxxxx',NULL,10,20,NULL,NULL,NULL,NULL,JSON_ARRAY('quote','basic','auth'),NULL,NULL),
(@fieldSetId,'securityCode','Güvenlik Kodu','Kayıtlı değilse doğrulama kodu','text',0,1,1,'XXXXXX',NULL,4,8,NULL,NULL,NULL,NULL,JSON_ARRAY('quote','basic','security'),NULL,NULL),
(@fieldSetId,'occupationCode','Meslek Seç',NULL,'select',1,1,1,NULL,NULL,NULL,NULL,NULL,NULL,
  JSON_OBJECT('optionsEndpoint','{{api-gw-uri}}/api/common/option?questionKey=occupationCode&productId=101','method','GET','valueKey','value','labelKey','label'),
  NULL,JSON_ARRAY('quote','occupation'),NULL,NULL),
(@fieldSetId,'insurerBirthDate','Sigorta Ettiren Doğum Tarihi',NULL,'date',1,1,1,'YYYY-AA-GG',NULL,NULL,NULL,NULL,NULL,NULL,NULL,JSON_ARRAY('quote','personal'),NULL,NULL),
(@fieldSetId,'insurerEmail','Sigorta Ettiren E-posta',NULL,'email',1,1,2,'ornek@mail.com',NULL,NULL,120,NULL,NULL,NULL,NULL,JSON_ARRAY('quote','personal'),NULL,NULL),
(@fieldSetId,'insuredBirthDate','Sigortalı Doğum Tarihi','Boş bırakılırsa sigorta ettiren kullanılır.','date',0,0,3,'YYYY-AA-GG',NULL,NULL,NULL,NULL,NULL,NULL,
  JSON_OBJECT('autoPopulateFrom','insurerBirthDate'),
  JSON_ARRAY('quote','personal'),NULL,NULL),
(@fieldSetId,'insuredEmail','Sigortalı E-posta','Boş bırakılırsa sigorta ettiren kullanılır.','email',0,0,4,'ornek@mail.com',NULL,NULL,120,NULL,NULL,NULL,
  JSON_OBJECT('autoPopulateFrom','insurerEmail'),
  JSON_ARRAY('quote','personal'),NULL,NULL),
(@fieldSetId,'insuredPhoneNumber','Sigortalı Telefon','Boş bırakılırsa sigorta ettiren kullanılır.','phone',0,0,5,'5xxxxxxxxx',NULL,10,20,NULL,NULL,NULL,
  JSON_OBJECT('autoPopulateFrom','insurerPhoneNumber'),
  JSON_ARRAY('quote','personal'),NULL,NULL),
(@fieldSetId,'insuredIdNumber','Sigortalı TCKN (farklıysa)','Boş bırakılırsa sigorta ettiren kullanılır.','identity',0,0,6,'11 haneli TCKN','^[0-9]{11}$',11,11,NULL,NULL,NULL,
  JSON_OBJECT('autoPopulateFrom','insurerIdNumber'),
  JSON_ARRAY('quote','personal'),NULL,NULL),
(@fieldSetId,'packageType','Paket Tipi',NULL,'select',1,1,1,NULL,NULL,NULL,NULL,NULL,NULL,
  JSON_OBJECT('optionsEndpoint','{{api-gw-uri}}/api/common/option/traffic/package-type','method','GET'),
  NULL,JSON_ARRAY('package'),NULL,NULL),
(@fieldSetId,'plateType','Plaka Tipi',NULL,'select',1,1,1,NULL,NULL,NULL,NULL,NULL,NULL,
  JSON_ARRAY(JSON_OBJECT('value','registered','label','Tescilli'),JSON_OBJECT('value','unregistered','label','Tescilsiz / Yeni Tescil')),
  NULL,JSON_ARRAY('vehicle','license','page1'),NULL,NULL),
(@fieldSetId,'plateNumber','Plaka No','Tescilli senaryo için','text',0,1,2,'34ABC123',NULL,4,15,NULL,NULL,NULL,
  JSON_OBJECT('requiredWhen',JSON_OBJECT('field','plateType','op','eq','value','registered'),'visibleWhen',JSON_OBJECT('field','plateType','op','eq','value','registered')),
  JSON_ARRAY('vehicle','license','page1'),NULL,NULL),
(@fieldSetId,'plateCityCode','Plaka İl Kodu',NULL,'select',0,1,3,NULL,NULL,NULL,NULL,NULL,NULL,
  JSON_OBJECT('optionsEndpoint','{{api-gw-uri}}/api/location/city','method','GET','valueKey','id','labelKey','name'),
  JSON_OBJECT('requiredWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered'),'visibleWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered')),
  JSON_ARRAY('vehicle','license','page1'),NULL,NULL),
(@fieldSetId,'registrationSerialCode','Tescil Seri Kodu',NULL,'text',0,1,1,'GD',NULL,1,5,NULL,NULL,NULL,
  JSON_OBJECT('requiredWhen',JSON_OBJECT('field','plateType','op','eq','value','registered'),'visibleWhen',JSON_OBJECT('field','plateType','op','eq','value','registered')),
  JSON_ARRAY('vehicle','license','page2'),NULL,NULL),
(@fieldSetId,'registrationSerialNumber','Tescil Seri No',NULL,'text',0,1,2,'984352',NULL,3,12,NULL,NULL,NULL,
  JSON_OBJECT('requiredWhen',JSON_OBJECT('field','plateType','op','eq','value','registered'),'visibleWhen',JSON_OBJECT('field','plateType','op','eq','value','registered')),
  JSON_ARRAY('vehicle','license','page2'),NULL,NULL),
(@fieldSetId,'usageStyle','Kullanım Tarzı',NULL,'select',0,1,3,NULL,NULL,NULL,NULL,NULL,NULL,
  JSON_OBJECT('optionsEndpoint','{{api-gw-uri}}/api/auto/usage-style','method','GET','valueKey','id','labelKey','name'),
  JSON_OBJECT('requiredWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered'),'visibleWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered')),
  JSON_ARRAY('vehicle','license','page2'),NULL,NULL),
(@fieldSetId,'modelYear','Model Yılı',NULL,'select',0,1,4,NULL,NULL,NULL,NULL,NULL,NULL,
  JSON_OBJECT('optionsEndpoint','{{api-gw-uri}}/api/common/option/traffic/new-registration/year','method','GET'),
  JSON_OBJECT('requiredWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered'),'visibleWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered')),
  JSON_ARRAY('vehicle','license','page2'),NULL,NULL),
(@fieldSetId,'makeId','Marka',NULL,'select',0,1,5,NULL,NULL,NULL,NULL,NULL,NULL,
  JSON_OBJECT('optionsEndpoint','{{api-gw-uri}}/api/auto/make?usageStyleId={{usageStyle}}&yearId={{modelYear}}','method','GET','valueKey','id','labelKey','name'),
  JSON_OBJECT('requiredWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered'),'visibleWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered')),
  JSON_ARRAY('vehicle','license','page2'),NULL,NULL),
(@fieldSetId,'engineNumber','Motor No',NULL,'text',0,1,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
  JSON_OBJECT('requiredWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered'),'visibleWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered')),
  JSON_ARRAY('vehicle','license','page2'),NULL,NULL),
(@fieldSetId,'chassisNumber','Şasi No',NULL,'text',0,1,7,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
  JSON_OBJECT('requiredWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered'),'visibleWhen',JSON_OBJECT('field','plateType','op','eq','value','unregistered')),
  JSON_ARRAY('vehicle','license','page2'),NULL,NULL),
(@fieldSetId,'isDealer','Galerici Kısa Süreli','Dealer kısa süreli trafik (policyDuration 120)','boolean',0,1,8,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,JSON_ARRAY('vehicle','license','page2'),NULL,NULL);

COMMIT;
