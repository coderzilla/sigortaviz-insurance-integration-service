-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Anamakine: localhost:8889
-- Üretim Zamanı: 29 Ara 2025, 10:04:32
-- Sunucu sürümü: 8.0.40
-- PHP Sürümü: 8.3.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Veritabanı: `sigortavizz`
--

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `carrier_product_fields`
--

CREATE TABLE `carrier_product_fields` (
  `id` int NOT NULL,
  `fieldSetId` int NOT NULL,
  `internalCode` varchar(128) NOT NULL,
  `label` varchar(255) NOT NULL,
  `description` text,
  `inputType` varchar(50) NOT NULL,
  `required` tinyint(1) NOT NULL DEFAULT '1',
  `isShown` tinyint(1) NOT NULL DEFAULT '1',
  `orderIndex` int NOT NULL,
  `placeholder` varchar(255) DEFAULT NULL,
  `validationRegex` varchar(255) DEFAULT NULL,
  `minLength` int DEFAULT NULL,
  `maxLength` int DEFAULT NULL,
  `minValue` decimal(14,2) DEFAULT NULL,
  `maxValue` decimal(14,2) DEFAULT NULL,
  `optionsJson` json DEFAULT NULL,
  `extraConfigJson` json DEFAULT NULL,
  `stepPathJson` json DEFAULT NULL,
  `page` int DEFAULT NULL,
  `onBlurRequestJson` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Tablo döküm verisi `carrier_product_fields`
--

INSERT INTO `carrier_product_fields` (`id`, `fieldSetId`, `internalCode`, `label`, `description`, `inputType`, `required`, `isShown`, `orderIndex`, `placeholder`, `validationRegex`, `minLength`, `maxLength`, `minValue`, `maxValue`, `optionsJson`, `extraConfigJson`, `stepPathJson`, `page`, `onBlurRequestJson`) VALUES
(1, 1, 'insurerIdNumber', 'Sigorta Ettiren TCKN / VKN', NULL, 'identity', 1, 1, 1, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, '[\"contact\"]', NULL, NULL),
(2, 1, 'insurerBirthDate', 'Sigorta Ettiren Doğum Tarihi', NULL, 'date', 1, 1, 2, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[\"contact\"]', NULL, NULL),
(3, 1, 'insurerEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 1, 1, 3, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, NULL, '[\"contact\"]', NULL, NULL),
(4, 1, 'insurerPhoneNumber', 'Sigorta Ettiren Telefon', NULL, 'phone', 1, 1, 4, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, '[\"contact\"]', NULL, NULL),
(5, 1, 'insuredIdNumber', 'Sigortalı TCKN (farklıysa)', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'identity', 0, 0, 5, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, '{\"autoPopulateFrom\": \"insurerIdNumber\"}', '[\"contact\"]', NULL, NULL),
(6, 1, 'insuredBirthDate', 'Sigortalı Doğum Tarihi', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'date', 0, 0, 6, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, '{\"autoPopulateFrom\": \"insurerBirthDate\"}', '[\"contact\"]', NULL, NULL),
(7, 1, 'insuredEmail', 'Sigortalı E-posta', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'email', 0, 0, 7, 'ornek@mail.com', NULL, NULL, 120, NULL, NULL, NULL, '{\"autoPopulateFrom\": \"insurerEmail\"}', '[\"contact\"]', NULL, NULL),
(8, 1, 'insuredPhoneNumber', 'Sigortalı Telefon', 'Boş bırakılırsa sigorta ettiren kullanılır.', 'phone', 0, 0, 8, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, '{\"autoPopulateFrom\": \"insurerPhoneNumber\"}', '[\"contact\"]', NULL, NULL),
(9, 1, 'packageType', 'Paket Tipi', NULL, 'select', 1, 1, 9, NULL, NULL, NULL, NULL, NULL, NULL, '{\"method\": \"GET\", \"optionsEndpoint\": \"{{api-gw-uri}}/api/common/option/traffic/package-type\"}', NULL, '[\"package\"]', NULL, NULL),
(10, 1, 'plateType', 'Plaka Tipi', NULL, 'select', 1, 1, 10, NULL, NULL, NULL, NULL, NULL, NULL, '[{\"label\": \"Tescilli\", \"value\": \"registered\"}, {\"label\": \"Tescilsiz / Yeni Tescil\", \"value\": \"unregistered\"}, {\"label\": \"Yabancı Plaka\", \"value\": \"foreign\"}]', NULL, '[\"vehicle\", \"license\"]', NULL, NULL),
(11, 1, 'plateCityCode', 'Plaka İl Kodu', NULL, 'select', 0, 1, 11, NULL, NULL, NULL, NULL, NULL, NULL, '{\"method\": \"GET\", \"labelKey\": \"name\", \"valueKey\": \"id\", \"optionsEndpoint\": \"{{api-gw-uri}}/api/location/city\"}', '{\"requiredWhen\": {\"op\": \"in\", \"field\": \"plateType\", \"value\": [\"registered\", \"unregistered\"]}}', '[\"vehicle\", \"license\"]', NULL, NULL),
(12, 1, 'plateNumber', 'Plaka No', 'Kayıtlı/galerici/yabancı senaryoları için', 'text', 0, 1, 12, '34ABC123', NULL, 4, 15, NULL, NULL, NULL, '{\"requiredWhen\": {\"op\": \"in\", \"field\": \"plateType\", \"value\": [\"registered\", \"foreign\"]}}', '[\"vehicle\", \"license\"]', NULL, NULL),
(13, 1, 'registrationSerialCode', 'Tescil Seri Kodu', NULL, 'text', 0, 1, 13, 'GD', NULL, 1, 5, NULL, NULL, NULL, '{\"requiredWhen\": {\"op\": \"eq\", \"field\": \"plateType\", \"value\": \"registered\"}}', '[\"vehicle\", \"license\"]', NULL, NULL),
(14, 1, 'registrationSerialNumber', 'Tescil Seri No', NULL, 'text', 0, 1, 14, '984352', NULL, 3, 12, NULL, NULL, NULL, '{\"requiredWhen\": {\"op\": \"eq\", \"field\": \"plateType\", \"value\": \"registered\"}}', '[\"vehicle\", \"license\"]', NULL, NULL),
(15, 1, 'usageStyle', 'Kullanım Tarzı', NULL, 'select', 0, 1, 15, NULL, NULL, NULL, NULL, NULL, NULL, '{\"method\": \"GET\", \"labelKey\": \"name\", \"valueKey\": \"id\", \"optionsEndpoint\": \"{{api-gw-uri}}/api/auto/usage-style\"}', '{\"requiredWhen\": {\"op\": \"in\", \"field\": \"plateType\", \"value\": [\"unregistered\", \"foreign\"]}}', '[\"vehicle\", \"features\"]', NULL, NULL),
(16, 1, 'modelYear', 'Model Yılı', NULL, 'select', 0, 1, 16, NULL, NULL, NULL, NULL, NULL, NULL, '{\"method\": \"GET\", \"optionsEndpoint\": \"{{api-gw-uri}}/api/common/option/traffic/new-registration/year\"}', '{\"requiredWhen\": {\"op\": \"in\", \"field\": \"plateType\", \"value\": [\"unregistered\", \"foreign\"]}}', '[\"vehicle\", \"features\"]', NULL, NULL),
(17, 1, 'makeId', 'Marka', NULL, 'select', 0, 1, 17, NULL, NULL, NULL, NULL, NULL, NULL, '{\"method\": \"GET\", \"labelKey\": \"name\", \"valueKey\": \"id\", \"optionsEndpoint\": \"{{api-gw-uri}}/api/auto/make?usageStyleId={{usageStyle}}&yearId={{modelYear}}\"}', '{\"requiredWhen\": {\"op\": \"in\", \"field\": \"plateType\", \"value\": [\"unregistered\", \"foreign\"]}}', '[\"vehicle\", \"features\"]', NULL, NULL),
(18, 1, 'engineNumber', 'Motor No', NULL, 'text', 0, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{\"requiredWhen\": {\"op\": \"in\", \"field\": \"plateType\", \"value\": [\"unregistered\", \"foreign\"]}}', '[\"vehicle\", \"license\"]', NULL, NULL),
(19, 1, 'chassisNumber', 'Şasi No', NULL, 'text', 0, 1, 19, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{\"requiredWhen\": {\"op\": \"in\", \"field\": \"plateType\", \"value\": [\"unregistered\", \"foreign\"]}}', '[\"vehicle\", \"license\"]', NULL, NULL),
(20, 1, 'policyDuration', 'Poliçe Süresi (gün)', 'Yabancı plakalı / galerici senaryosu için', 'number', 0, 1, 20, '1 veya 120', NULL, NULL, NULL, 1.00, 365.00, NULL, '{\"requiredWhen\": {\"op\": \"eq\", \"field\": \"plateType\", \"value\": \"foreign\"}}', '[\"vehicle\", \"license\"]', NULL, NULL),
(21, 1, 'isDealer', 'Galerici Kısa Süreli', 'Dealer kısa süreli trafik (policyDuration 120)', 'boolean', 0, 1, 21, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[\"vehicle\", \"features\"]', NULL, NULL),
(22, 2, 'policyNo', 'Teklif / Poliçe No', NULL, 'text', 1, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '[\"package\"]', NULL, NULL, NULL, NULL),
(23, 2, 'paymentType', 'Ödeme Tipi', NULL, 'select', 1, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, '[{\"label\": \"Kredi Kartı\", \"value\": \"card\"}, {\"label\": \"Nakit\", \"value\": \"cash\"}]', NULL, '[\"package\"]', NULL, NULL),
(24, 2, 'cardTokenId', 'Kart Token', 'Quick Sigorta kart token', 'text', 0, 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, '[\"package\"]', NULL, NULL, NULL, NULL),
(25, 3, 'tripType', 'Seyahat Tipi', NULL, 'select', 1, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '[{\"label\": \"Yurt Dışı Vize / Geniş\", \"value\": \"foreignVisa\"}, {\"label\": \"Yurt İçi\", \"value\": \"domestic\"}, {\"label\": \"Öğrenci\", \"value\": \"student\"}, {\"label\": \"Incoming / Pasaportlu Giriş\", \"value\": \"incoming\"}]', NULL, '[\"trip\"]', NULL, NULL),
(26, 3, 'startDate', 'Başlangıç Tarihi', NULL, 'date', 1, 1, 2, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[\"trip\"]', NULL, NULL),
(27, 3, 'endDate', 'Bitiş Tarihi', NULL, 'date', 1, 1, 3, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[\"trip\"]', NULL, NULL),
(28, 3, 'geographicalArea', 'Seyahat Bölgesi', NULL, 'select', 0, 1, 4, NULL, NULL, NULL, NULL, NULL, NULL, '{\"method\": \"GET\", \"labelKey\": \"label\", \"valueKey\": \"value\", \"optionsEndpoint\": \"{{api-gw-uri}}/api/common/option/travel-region\"}', '{\"requiredWhen\": {\"op\": \"in\", \"field\": \"tripType\", \"value\": [\"foreignVisa\", \"student\"]}}', '[\"trip\"]', NULL, NULL),
(29, 3, 'countryOfTravel', 'Seyahat Ülkesi', NULL, 'select', 0, 1, 5, NULL, NULL, NULL, NULL, NULL, NULL, '{\"method\": \"GET\", \"labelKey\": \"label\", \"valueKey\": \"value\", \"optionsEndpoint\": \"{{api-gw-uri}}/api/common/option/travel-country?travelRegion={{geographicalArea}}\"}', '{\"requiredWhen\": {\"op\": \"in\", \"field\": \"tripType\", \"value\": [\"foreignVisa\", \"student\"]}}', '[\"trip\"]', NULL, NULL),
(30, 3, 'cityOfTravel', 'Seyahat Şehri', NULL, 'select', 0, 1, 6, NULL, NULL, NULL, NULL, NULL, NULL, '{\"method\": \"GET\", \"labelKey\": \"name\", \"valueKey\": \"id\", \"optionsEndpoint\": \"{{api-gw-uri}}/api/location/city\"}', '{\"requiredWhen\": {\"op\": \"eq\", \"field\": \"tripType\", \"value\": \"domestic\"}}', '[\"trip\"]', NULL, NULL),
(31, 3, 'packageType', 'Paket Tipi', 'foreignVisa senaryosu için', 'select', 0, 1, 7, NULL, NULL, NULL, NULL, NULL, NULL, '[{\"label\": \"Quick Vize Seyahat\", \"value\": \"1\"}, {\"label\": \"Quick Yurt Dışı Geniş Paket\", \"value\": \"2\"}]', '{\"requiredWhen\": {\"op\": \"eq\", \"field\": \"tripType\", \"value\": \"foreignVisa\"}}', '[\"trip\"]', NULL, NULL),
(32, 3, 'covid19', 'Covid-19 Teminatı', NULL, 'boolean', 0, 1, 8, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[\"trip\"]', NULL, NULL),
(33, 3, 'travelAgencyBankruptcy', 'Seyahat Acentesi İflası', NULL, 'boolean', 0, 1, 9, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[\"trip\"]', NULL, NULL),
(34, 3, 'agencyCommissionRate', 'Acente Komisyon Oranı', 'Örn: 0.40', 'number', 0, 1, 10, '0.40', NULL, NULL, NULL, 0.00, 1.00, NULL, NULL, '[\"trip\"]', NULL, NULL),
(35, 3, 'insurerIdNumber', 'Sigorta Ettiren TCKN / VKN', NULL, 'identity', 1, 1, 11, '11 haneli TCKN', '^[0-9]{11}$', 11, 11, NULL, NULL, NULL, NULL, '[\"contact\"]', NULL, NULL),
(36, 3, 'insurerBirthDate', 'Sigorta Ettiren Doğum Tarihi', NULL, 'date', 1, 1, 12, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[\"contact\"]', NULL, NULL),
(37, 3, 'insurerEmail', 'Sigorta Ettiren E-posta', NULL, 'email', 1, 1, 13, NULL, NULL, NULL, 120, NULL, NULL, NULL, NULL, '[\"contact\"]', NULL, NULL),
(38, 3, 'insurerPhoneNumber', 'Sigorta Ettiren Telefon', NULL, 'phone', 1, 1, 14, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, '[\"contact\"]', NULL, NULL),
(39, 3, 'insureds[].idNumber', 'Sigortalı TCKN / Pasaport', NULL, 'identity', 1, 1, 15, '11 haneli', '^[0-9]{6,20}$', 6, 20, NULL, NULL, NULL, '{\"collection\": {\"arrayPath\": \"insureds\", \"autoPopulateFrom\": \"insurer\"}}', '[\"insureds\"]', NULL, NULL),
(40, 3, 'insureds[].birthDate', 'Sigortalı Doğum Tarihi', NULL, 'date', 1, 1, 16, 'YYYY-AA-GG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[\"insureds\"]', NULL, NULL),
(41, 3, 'insureds[].email', 'Sigortalı E-posta', NULL, 'email', 0, 1, 17, NULL, NULL, NULL, 120, NULL, NULL, NULL, NULL, '[\"insureds\"]', NULL, NULL),
(42, 3, 'insureds[].phoneNumber', 'Sigortalı Telefon', NULL, 'phone', 0, 1, 18, '5xxxxxxxxx', NULL, 10, 20, NULL, NULL, NULL, NULL, '[\"insureds\"]', NULL, NULL),
(43, 3, 'insureds[].isMain', 'Ana Sigortalı', 'İlk kişi genelde ana sigortalıdır.', 'boolean', 0, 1, 19, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[\"insureds\"]', NULL, NULL);

--
-- Dökümü yapılmış tablolar için indeksler
--

--
-- Tablo için indeksler `carrier_product_fields`
--
ALTER TABLE `carrier_product_fields`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_cpf` (`fieldSetId`,`internalCode`);

--
-- Dökümü yapılmış tablolar için AUTO_INCREMENT değeri
--

--
-- Tablo için AUTO_INCREMENT değeri `carrier_product_fields`
--
ALTER TABLE `carrier_product_fields`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- Dökümü yapılmış tablolar için kısıtlamalar
--

--
-- Tablo kısıtlamaları `carrier_product_fields`
--
ALTER TABLE `carrier_product_fields`
  ADD CONSTRAINT `fk_cpf_field_set` FOREIGN KEY (`fieldSetId`) REFERENCES `carrier_product_field_sets` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;


-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Anamakine: localhost:8889
-- Üretim Zamanı: 29 Ara 2025, 10:05:05
-- Sunucu sürümü: 8.0.40
-- PHP Sürümü: 8.3.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Veritabanı: `sigortavizz`
--

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `carrier_product_field_sets`
--

CREATE TABLE `carrier_product_field_sets` (
  `id` int NOT NULL,
  `carrierProductId` int NOT NULL,
  `stage` varchar(32) NOT NULL DEFAULT 'QUOTE',
  `version` int NOT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `validFrom` timestamp NULL DEFAULT NULL,
  `validTo` timestamp NULL DEFAULT NULL,
  `stepsJson` json DEFAULT NULL,
  `pageChangeRequestJson` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Tablo döküm verisi `carrier_product_field_sets`
--

INSERT INTO `carrier_product_field_sets` (`id`, `carrierProductId`, `stage`, `version`, `isActive`, `validFrom`, `validTo`, `stepsJson`, `pageChangeRequestJson`) VALUES
(1, 1, 'QUOTE', 1, 1, '2025-12-26 11:04:20', NULL, '[{\"id\": \"vehicle\", \"order\": 1, \"title\": \"Araç Bilgileri\", \"children\": [{\"id\": \"license\", \"order\": 1, \"title\": \"Ruhsat Bilgileri\"}, {\"id\": \"features\", \"order\": 2, \"title\": \"Araç Özellikleri\"}]}, {\"id\": \"contact\", \"order\": 2, \"title\": \"İletişim Bilgileri\"}, {\"id\": \"package\", \"order\": 3, \"title\": \"Paket Seçimi\"}]', NULL),
(2, 1, 'PURCHASE', 1, 1, '2025-12-26 11:04:20', NULL, '[{\"id\": \"vehicle\", \"order\": 1, \"title\": \"Araç Bilgileri\", \"children\": [{\"id\": \"license\", \"order\": 1, \"title\": \"Ruhsat Bilgileri\"}, {\"id\": \"features\", \"order\": 2, \"title\": \"Araç Özellikleri\"}]}, {\"id\": \"contact\", \"order\": 2, \"title\": \"İletişim Bilgileri\"}, {\"id\": \"package\", \"order\": 3, \"title\": \"Paket Seçimi\"}]', NULL),
(3, 2, 'QUOTE', 1, 1, '2025-12-26 11:04:20', NULL, '[{\"id\": \"trip\", \"order\": 1, \"title\": \"Seyahat Bilgileri\"}, {\"id\": \"insureds\", \"order\": 2, \"title\": \"Sigortalılar\"}, {\"id\": \"contact\", \"order\": 3, \"title\": \"İletişim\"}]', NULL);

--
-- Dökümü yapılmış tablolar için indeksler
--

--
-- Tablo için indeksler `carrier_product_field_sets`
--
ALTER TABLE `carrier_product_field_sets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_cpfs` (`carrierProductId`,`stage`,`version`);

--
-- Dökümü yapılmış tablolar için AUTO_INCREMENT değeri
--

--
-- Tablo için AUTO_INCREMENT değeri `carrier_product_field_sets`
--
ALTER TABLE `carrier_product_field_sets`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Dökümü yapılmış tablolar için kısıtlamalar
--

--
-- Tablo kısıtlamaları `carrier_product_field_sets`
--
ALTER TABLE `carrier_product_field_sets`
  ADD CONSTRAINT `fk_cpfs_cp` FOREIGN KEY (`carrierProductId`) REFERENCES `carrier_products` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
