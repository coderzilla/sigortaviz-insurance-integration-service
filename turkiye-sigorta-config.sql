-- Türkiye Sigorta (Pusula Üretim Web Service) configuration seed
-- Derived from PusulaUretimWebService Dokümanı_V0.5 (product codes, key params).
-- Builds carrier product field sets, fields, and carrier field mappings for main Pusula products.

-- Carrier
INSERT INTO carriers (code, name, isActive)
VALUES ('TURKIYE_SIGORTA', 'Türkiye Sigorta', 1)
ON DUPLICATE KEY UPDATE name = VALUES(name), isActive = VALUES(isActive);

-- Core products used in the document (product code table)
INSERT INTO products (code, name, description) VALUES
('TRAFFIC', 'Traffic', 'Zorunlu Trafik (Pusula 15101)'),
('HOME', 'Home', 'Konut / DASK (Pusula 12102 / 21100)'),
('LIFE', 'Life', 'Ferdi Kaza (Pusula 13100)')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- Cache ids defensively to avoid multi-row subqueries
SET @carrierTs := (SELECT id FROM carriers WHERE code = 'TURKIYE_SIGORTA' ORDER BY id LIMIT 1);
SET @prodTraffic := (SELECT id FROM products WHERE code = 'TRAFFIC' ORDER BY id LIMIT 1);
SET @prodHome := (SELECT id FROM products WHERE code = 'HOME' ORDER BY id LIMIT 1);
SET @prodLife := (SELECT id FROM products WHERE code = 'LIFE' ORDER BY id LIMIT 1);

-- Carrier products mapped to Pusula product codes
INSERT INTO carrier_products (carrierId, productId, externalCode, isActive) VALUES
(@carrierTs, @prodTraffic, '15101', 1),
(@carrierTs, @prodHome, '12102', 1), -- Konut Paket
(@carrierTs, @prodHome, '21100', 1), -- DASK
(@carrierTs, @prodLife, '13100', 1)
ON DUPLICATE KEY UPDATE externalCode = VALUES(externalCode), isActive = VALUES(isActive);

SET @cpTraffic := (SELECT id FROM carrier_products WHERE carrierId = @carrierTs AND externalCode = '15101' ORDER BY id LIMIT 1);
SET @cpHome12102 := (SELECT id FROM carrier_products WHERE carrierId = @carrierTs AND externalCode = '12102' ORDER BY id LIMIT 1);
SET @cpDask21100 := (SELECT id FROM carrier_products WHERE carrierId = @carrierTs AND externalCode = '21100' ORDER BY id LIMIT 1);
SET @cpLife13100 := (SELECT id FROM carrier_products WHERE carrierId = @carrierTs AND externalCode = '13100' ORDER BY id LIMIT 1);

-- -----------------------------------------------------------------------------
-- TRAFFIC (product code 15101) - teklifOlustur / policeOlustur inputs
-- -----------------------------------------------------------------------------
INSERT INTO carrier_product_field_sets (carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpTraffic,
  1, 1, NOW(), NULL, NULL
);
SET @tsTrafficFieldSetId := (
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
(@tsTrafficFieldSetId, 'authKey', 'Auth Key', 'Güvenlik servisi anahtarı', 'text', 0,
  1, NULL, NULL, NULL, 200, NULL, NULL, NULL, NULL, 1, NULL),
(@tsTrafficFieldSetId, 'urunKodu', 'Ürün Kodu', 'Pusula ürün kodu (15101)', 'select', 1,
  2, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', '15101', 'label', 'Trafik')), NULL, 1, NULL),
(@tsTrafficFieldSetId, 'tanzimTarihi', 'Tanzim Tarihi', NULL, 'date', 1,
  3, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@tsTrafficFieldSetId, 'sigortaEttirenTckn', 'Sigorta Ettiren TCKN', NULL, 'identity', 1,
  4, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@tsTrafficFieldSetId, 'sigortaEttirenAdSoyad', 'Sigorta Ettiren Ad Soyad', NULL, 'text', 1,
  5, NULL, NULL, 3, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@tsTrafficFieldSetId, 'sigortaEttirenTelefon', 'Sigorta Ettiren Telefon', NULL, 'text', 1,
  6, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@tsTrafficFieldSetId, 'sigortaEttirenEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 0,
  7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@tsTrafficFieldSetId, 'sigortaliTckn', 'Sigortalı TCKN', NULL, 'identity', 1,
  8, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@tsTrafficFieldSetId, 'sigortaliDogumTarihi', 'Sigortalı Doğum Tarihi', NULL, 'date', 1,
  9, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@tsTrafficFieldSetId, 'plaka', 'Plaka', NULL, 'text', 1,
  10, '34ABC123', NULL, 4, 15, NULL, NULL, NULL, NULL, 1, NULL),
(@tsTrafficFieldSetId, 'tasitTipi', 'Taşıt Tipi', 'TarifeSorusu', 'select', 1,
  11, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.TasitTipi'), NULL, 1, NULL),
(@tsTrafficFieldSetId, 'kullanimTarzi', 'Kullanım Tarzı', 'TarifeSorusu', 'select', 1,
  12, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.KullanimTarzi'), NULL, 1, NULL),
(@tsTrafficFieldSetId, 'markaKodu', 'Marka Kodu', NULL, 'text', 1,
  13, NULL, NULL, NULL, 20, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.MarkaKodu'), 1, NULL),
(@tsTrafficFieldSetId, 'modelKodu', 'Model Kodu', NULL, 'text', 1,
  14, NULL, NULL, NULL, 20, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.ModelKodu'), 1, NULL),
(@tsTrafficFieldSetId, 'modelYili', 'Model Yılı', NULL, 'select', 1,
  15, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.ModelYili'), NULL, 1, NULL),
(@tsTrafficFieldSetId, 'saseNo', 'Şasi No', NULL, 'text', 1,
  16, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, 1, NULL),
(@tsTrafficFieldSetId, 'motorNo', 'Motor No', NULL, 'text', 1,
  17, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, 1, NULL),
(@tsTrafficFieldSetId, 'odemeAraci', 'Ödeme Aracı', 'Ödeme aracı tablosu', 'select', 1,
  18, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'OdemeAraci'), NULL, 1, NULL),
(@tsTrafficFieldSetId, 'taksitSayisi', 'Taksit Sayısı', NULL, 'select', 0,
  19, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'OdemePlani'), NULL, 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpTraffic, 'authKey', 'GirisBilgileri.AuthKey', 'NONE', 0),
(@cpTraffic, 'urunKodu', 'TeklifBilgisi.UrunKodu', 'NONE', 1),
(@cpTraffic, 'tanzimTarihi', 'TeklifBilgisi.TanzimTarihi', 'DATE_YYYY_MM_DD', 1),
(@cpTraffic, 'sigortaEttirenTckn', 'SigortaEttiren.KimlikNo', 'NONE', 1),
(@cpTraffic, 'sigortaEttirenAdSoyad', 'SigortaEttiren.AdSoyad', 'NONE', 1),
(@cpTraffic, 'sigortaEttirenTelefon', 'SigortaEttiren.Gsm', 'NONE', 1),
(@cpTraffic, 'sigortaEttirenEmail', 'SigortaEttiren.Email', 'LOWERCASE', 0),
(@cpTraffic, 'sigortaliTckn', 'Sigortalilar[0].KimlikNo', 'NONE', 1),
(@cpTraffic, 'sigortaliDogumTarihi', 'Sigortalilar[0].DogumTarihi', 'DATE_YYYY_MM_DD', 1),
(@cpTraffic, 'plaka', 'TarifeSorulari.Plaka', 'UPPERCASE', 1),
(@cpTraffic, 'tasitTipi', 'TarifeSorulari.TasitTipi', 'NONE', 1),
(@cpTraffic, 'kullanimTarzi', 'TarifeSorulari.KullanimTarzi', 'NONE', 1),
(@cpTraffic, 'markaKodu', 'TarifeSorulari.MarkaKodu', 'NONE', 1),
(@cpTraffic, 'modelKodu', 'TarifeSorulari.ModelKodu', 'NONE', 1),
(@cpTraffic, 'modelYili', 'TarifeSorulari.ModelYili', 'NONE', 1),
(@cpTraffic, 'saseNo', 'TarifeSorulari.SaseNo', 'UPPERCASE', 1),
(@cpTraffic, 'motorNo', 'TarifeSorulari.MotorNo', 'UPPERCASE', 1),
(@cpTraffic, 'odemeAraci', 'OdemeBilgisi.OdemeAraci', 'NONE', 1),
(@cpTraffic, 'taksitSayisi', 'OdemeBilgisi.TaksitSayisi', 'NONE', 0);

-- -----------------------------------------------------------------------------
-- HOME / KONUT (product code 12102) - Konut Paket
-- -----------------------------------------------------------------------------
INSERT INTO carrier_product_field_sets (carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpHome12102,
  1, 1, NOW(), NULL, NULL
);
SET @tsHomeFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = (
    @cpHome12102
  )
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `page`, `onBlurRequestJson`
) VALUES
(@tsHomeFieldSetId, 'authKey', 'Auth Key', 'Güvenlik servisi anahtarı', 'text', 0,
  1, NULL, NULL, NULL, 200, NULL, NULL, NULL, NULL, 1, NULL),
(@tsHomeFieldSetId, 'urunKodu', 'Ürün Kodu', 'Pusula ürün kodu (12102)', 'select', 1,
  2, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', '12102', 'label', 'Konut Paket')), NULL, 1, NULL),
(@tsHomeFieldSetId, 'tanzimTarihi', 'Tanzim Tarihi', NULL, 'date', 1,
  3, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@tsHomeFieldSetId, 'sigortaEttirenTckn', 'Sigorta Ettiren TCKN', NULL, 'identity', 1,
  4, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@tsHomeFieldSetId, 'sigortaEttirenAdSoyad', 'Sigorta Ettiren Ad Soyad', NULL, 'text', 1,
  5, NULL, NULL, 3, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@tsHomeFieldSetId, 'sigortaEttirenTelefon', 'Sigorta Ettiren Telefon', NULL, 'text', 1,
  6, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@tsHomeFieldSetId, 'sigortaEttirenEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 0,
  7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@tsHomeFieldSetId, 'uavtKod', 'UAVT Kod', 'Adres kodu', 'text', 1,
  8, NULL, NULL, NULL, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@tsHomeFieldSetId, 'konutBrutM2', 'Brüt m2', NULL, 'text', 1,
  9, NULL, '^[0-9]+$', 1, 10, NULL, NULL, NULL, NULL, 1, NULL),
(@tsHomeFieldSetId, 'yapiTarzi', 'Yapı Tarzı', 'UrunRiskBilgileri', 'select', 1,
  10, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.YapiTarzi'), NULL, 1, NULL),
(@tsHomeFieldSetId, 'yapiYasi', 'Yapı Yaşı', NULL, 'select', 1,
  11, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.YapiYasi'), NULL, 1, NULL),
(@tsHomeFieldSetId, 'katSayisi', 'Kat Sayısı', NULL, 'select', 1,
  12, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.KatSayisi'), NULL, 1, NULL),
(@tsHomeFieldSetId, 'kat', 'Bulunduğu Kat', NULL, 'select', 1,
  13, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.Kat'), NULL, 1, NULL),
(@tsHomeFieldSetId, 'disCepheKaplamasi', 'Dış Cephe Kaplaması', NULL, 'select', 0,
  14, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.DisCepheKaplamasi'), NULL, 1, NULL),
(@tsHomeFieldSetId, 'odemeAraci', 'Ödeme Aracı', 'Ödeme aracı tablosu', 'select', 1,
  15, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'OdemeAraci'), NULL, 1, NULL),
(@tsHomeFieldSetId, 'taksitSayisi', 'Taksit Sayısı', NULL, 'select', 0,
  16, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'OdemePlani'), NULL, 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpHome12102, 'authKey', 'GirisBilgileri.AuthKey', 'NONE', 0),
(@cpHome12102, 'urunKodu', 'TeklifBilgisi.UrunKodu', 'NONE', 1),
(@cpHome12102, 'tanzimTarihi', 'TeklifBilgisi.TanzimTarihi', 'DATE_YYYY_MM_DD', 1),
(@cpHome12102, 'sigortaEttirenTckn', 'SigortaEttiren.KimlikNo', 'NONE', 1),
(@cpHome12102, 'sigortaEttirenAdSoyad', 'SigortaEttiren.AdSoyad', 'NONE', 1),
(@cpHome12102, 'sigortaEttirenTelefon', 'SigortaEttiren.Gsm', 'NONE', 1),
(@cpHome12102, 'sigortaEttirenEmail', 'SigortaEttiren.Email', 'LOWERCASE', 0),
(@cpHome12102, 'uavtKod', 'TarifeSorulari.UavtKod', 'NONE', 1),
(@cpHome12102, 'konutBrutM2', 'TarifeSorulari.KonutBrutM2', 'NONE', 1),
(@cpHome12102, 'yapiTarzi', 'TarifeSorulari.YapiTarzi', 'NONE', 1),
(@cpHome12102, 'yapiYasi', 'TarifeSorulari.YapiYasi', 'NONE', 1),
(@cpHome12102, 'katSayisi', 'TarifeSorulari.KatSayisi', 'NONE', 1),
(@cpHome12102, 'kat', 'TarifeSorulari.Kat', 'NONE', 1),
(@cpHome12102, 'disCepheKaplamasi', 'TarifeSorulari.DisCepheKaplamasi', 'NONE', 0),
(@cpHome12102, 'odemeAraci', 'OdemeBilgisi.OdemeAraci', 'NONE', 1),
(@cpHome12102, 'taksitSayisi', 'OdemeBilgisi.TaksitSayisi', 'NONE', 0);

-- -----------------------------------------------------------------------------
-- DASK (product code 21100) - Zorunlu Deprem Sigortası
-- -----------------------------------------------------------------------------
INSERT INTO carrier_product_field_sets (carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpDask21100,
  1, 1, NOW(), NULL, NULL
);
SET @tsDaskFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = (
    @cpDask21100
  )
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `page`, `onBlurRequestJson`
) VALUES
(@tsDaskFieldSetId, 'authKey', 'Auth Key', 'Güvenlik servisi anahtarı', 'text', 0,
  1, NULL, NULL, NULL, 200, NULL, NULL, NULL, NULL, 1, NULL),
(@tsDaskFieldSetId, 'urunKodu', 'Ürün Kodu', 'Pusula ürün kodu (21100)', 'select', 1,
  2, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', '21100', 'label', 'DASK')), NULL, 1, NULL),
(@tsDaskFieldSetId, 'tanzimTarihi', 'Tanzim Tarihi', NULL, 'date', 1,
  3, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@tsDaskFieldSetId, 'sigortaEttirenTckn', 'Sigorta Ettiren TCKN', NULL, 'identity', 1,
  4, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@tsDaskFieldSetId, 'sigortaEttirenAdSoyad', 'Sigorta Ettiren Ad Soyad', NULL, 'text', 1,
  5, NULL, NULL, 3, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@tsDaskFieldSetId, 'sigortaEttirenTelefon', 'Sigorta Ettiren Telefon', NULL, 'text', 1,
  6, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@tsDaskFieldSetId, 'sigortaEttirenEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 0,
  7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@tsDaskFieldSetId, 'uavtKod', 'UAVT Kod', 'Adres kodu', 'text', 1,
  8, NULL, NULL, NULL, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@tsDaskFieldSetId, 'binaInsaaTarzi', 'Bina İnşa Tarzı', 'UrunRiskBilgileri', 'select', 1,
  9, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.BinaInsaaTarzi'), NULL, 1, NULL),
(@tsDaskFieldSetId, 'binaYapimYili', 'Bina Yapım Yılı', 'UrunRiskBilgileri', 'select', 1,
  10, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.BinaYapimYili'), NULL, 1, NULL),
(@tsDaskFieldSetId, 'binaToplamKat', 'Toplam Kat', NULL, 'select', 1,
  11, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.BinaToplamKat'), NULL, 1, NULL),
(@tsDaskFieldSetId, 'bulunduguKat', 'Bulunduğu Kat', NULL, 'select', 1,
  12, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.BulunduguKat'), NULL, 1, NULL),
(@tsDaskFieldSetId, 'brutM2', 'Brüt m2', NULL, 'text', 1,
  13, NULL, '^[0-9]+$', 1, 10, NULL, NULL, NULL, NULL, 1, NULL),
(@tsDaskFieldSetId, 'odemeAraci', 'Ödeme Aracı', 'Ödeme aracı tablosu', 'select', 1,
  14, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'OdemeAraci'), NULL, 1, NULL),
(@tsDaskFieldSetId, 'taksitSayisi', 'Taksit Sayısı', NULL, 'select', 0,
  15, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'OdemePlani'), NULL, 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpDask21100, 'authKey', 'GirisBilgileri.AuthKey', 'NONE', 0),
(@cpDask21100, 'urunKodu', 'TeklifBilgisi.UrunKodu', 'NONE', 1),
(@cpDask21100, 'tanzimTarihi', 'TeklifBilgisi.TanzimTarihi', 'DATE_YYYY_MM_DD', 1),
(@cpDask21100, 'sigortaEttirenTckn', 'SigortaEttiren.KimlikNo', 'NONE', 1),
(@cpDask21100, 'sigortaEttirenAdSoyad', 'SigortaEttiren.AdSoyad', 'NONE', 1),
(@cpDask21100, 'sigortaEttirenTelefon', 'SigortaEttiren.Gsm', 'NONE', 1),
(@cpDask21100, 'sigortaEttirenEmail', 'SigortaEttiren.Email', 'LOWERCASE', 0),
(@cpDask21100, 'uavtKod', 'TarifeSorulari.UavtKod', 'NONE', 1),
(@cpDask21100, 'binaInsaaTarzi', 'TarifeSorulari.BinaInsaaTarzi', 'NONE', 1),
(@cpDask21100, 'binaYapimYili', 'TarifeSorulari.BinaYapimYili', 'NONE', 1),
(@cpDask21100, 'binaToplamKat', 'TarifeSorulari.BinaToplamKat', 'NONE', 1),
(@cpDask21100, 'bulunduguKat', 'TarifeSorulari.BulunduguKat', 'NONE', 1),
(@cpDask21100, 'brutM2', 'TarifeSorulari.BrutM2', 'NONE', 1),
(@cpDask21100, 'odemeAraci', 'OdemeBilgisi.OdemeAraci', 'NONE', 1),
(@cpDask21100, 'taksitSayisi', 'OdemeBilgisi.TaksitSayisi', 'NONE', 0);

-- -----------------------------------------------------------------------------
-- FERDI KAZA (product code 13100)
-- -----------------------------------------------------------------------------
INSERT INTO carrier_product_field_sets (carrierProductId, version, isActive, validFrom, validTo, pageChangeRequestJson)
VALUES (
  @cpLife13100,
  1, 1, NOW(), NULL, NULL
);
SET @tsLifeFieldSetId := (
  SELECT id FROM carrier_product_field_sets
  WHERE carrierProductId = (
    @cpLife13100
  )
  ORDER BY version DESC LIMIT 1
);

INSERT INTO carrier_product_fields (
  `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`,
  `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`,
  `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `page`, `onBlurRequestJson`
) VALUES
(@tsLifeFieldSetId, 'authKey', 'Auth Key', 'Güvenlik servisi anahtarı', 'text', 0,
  1, NULL, NULL, NULL, 200, NULL, NULL, NULL, NULL, 1, NULL),
(@tsLifeFieldSetId, 'urunKodu', 'Ürün Kodu', 'Pusula ürün kodu (13100)', 'select', 1,
  2, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_ARRAY(JSON_OBJECT('value', '13100', 'label', 'Ferdi Kaza')), NULL, 1, NULL),
(@tsLifeFieldSetId, 'tanzimTarihi', 'Tanzim Tarihi', NULL, 'date', 1,
  3, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@tsLifeFieldSetId, 'sigortaEttirenTckn', 'Sigorta Ettiren TCKN', NULL, 'identity', 1,
  4, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@tsLifeFieldSetId, 'sigortaEttirenAdSoyad', 'Sigorta Ettiren Ad Soyad', NULL, 'text', 1,
  5, NULL, NULL, 3, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@tsLifeFieldSetId, 'sigortaEttirenTelefon', 'Sigorta Ettiren Telefon', NULL, 'text', 1,
  6, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, 1, NULL),
(@tsLifeFieldSetId, 'sigortaEttirenEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 0,
  7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, 1, NULL),
(@tsLifeFieldSetId, 'sigortaliTckn', 'Sigortalı TCKN', NULL, 'identity', 1,
  8, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, 1, NULL),
(@tsLifeFieldSetId, 'sigortaliDogumTarihi', 'Sigortalı Doğum Tarihi', NULL, 'date', 1,
  9, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL),
(@tsLifeFieldSetId, 'meslek', 'Meslek', 'UrunRiskBilgileri', 'select', 0,
  10, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.Meslek'), NULL, 1, NULL),
(@tsLifeFieldSetId, 'teminatPaketi', 'Teminat Paketi', NULL, 'select', 1,
  11, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'UrunRiskBilgileri.TeminatPaketi'), NULL, 1, NULL),
(@tsLifeFieldSetId, 'odemeAraci', 'Ödeme Aracı', 'Ödeme aracı tablosu', 'select', 1,
  12, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'OdemeAraci'), NULL, 1, NULL),
(@tsLifeFieldSetId, 'taksitSayisi', 'Taksit Sayısı', NULL, 'select', 0,
  13, NULL, NULL, NULL, NULL, NULL, NULL,
  JSON_OBJECT('listSource', 'OdemePlani'), NULL, 1, NULL);

INSERT INTO carrier_field_mappings (carrierProductId, internalCode, carrierParamName, transformType, isRequiredForApi) VALUES
(@cpLife13100, 'authKey', 'GirisBilgileri.AuthKey', 'NONE', 0),
(@cpLife13100, 'urunKodu', 'TeklifBilgisi.UrunKodu', 'NONE', 1),
(@cpLife13100, 'tanzimTarihi', 'TeklifBilgisi.TanzimTarihi', 'DATE_YYYY_MM_DD', 1),
(@cpLife13100, 'sigortaEttirenTckn', 'SigortaEttiren.KimlikNo', 'NONE', 1),
(@cpLife13100, 'sigortaEttirenAdSoyad', 'SigortaEttiren.AdSoyad', 'NONE', 1),
(@cpLife13100, 'sigortaEttirenTelefon', 'SigortaEttiren.Gsm', 'NONE', 1),
(@cpLife13100, 'sigortaEttirenEmail', 'SigortaEttiren.Email', 'LOWERCASE', 0),
(@cpLife13100, 'sigortaliTckn', 'Sigortalilar[0].KimlikNo', 'NONE', 1),
(@cpLife13100, 'sigortaliDogumTarihi', 'Sigortalilar[0].DogumTarihi', 'DATE_YYYY_MM_DD', 1),
(@cpLife13100, 'meslek', 'TarifeSorulari.Meslek', 'NONE', 0),
(@cpLife13100, 'teminatPaketi', 'TarifeSorulari.TeminatPaketi', 'NONE', 1),
(@cpLife13100, 'odemeAraci', 'OdemeBilgisi.OdemeAraci', 'NONE', 1),
(@cpLife13100, 'taksitSayisi', 'OdemeBilgisi.TaksitSayisi', 'NONE', 0);
