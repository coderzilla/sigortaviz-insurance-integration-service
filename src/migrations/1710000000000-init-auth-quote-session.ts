import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitAuthQuoteSession1710000000000 implements MigrationInterface {
  name = 'InitAuthQuoteSession1710000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS customers (
        id char(36) NOT NULL,
        phoneNumber varchar(32) NOT NULL,
        email varchar(160) NULL,
        phoneVerifiedAt datetime NULL,
        emailVerifiedAt datetime NULL,
        status enum('ACTIVE','LOCKED','DELETED') NOT NULL DEFAULT 'ACTIVE',
        marketingConsent tinyint(1) NOT NULL DEFAULT 0,
        kvkkConsent tinyint(1) NOT NULL DEFAULT 0,
        anonymizedAt datetime NULL,
        createdAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        UNIQUE KEY UQ_customers_phoneNumber (phoneNumber)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS identities (
        id char(36) NOT NULL,
        userId char(36) NOT NULL,
        idNumber varchar(64) NOT NULL,
        idNumberHash varchar(128) NOT NULL,
        fullName varchar(160) NULL,
        birthDate date NULL,
        isPreferred tinyint(1) NOT NULL DEFAULT 0,
        createdAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        CONSTRAINT FK_identities_user FOREIGN KEY (userId) REFERENCES customers(id) ON DELETE CASCADE,
        UNIQUE KEY UQ_identities_user_id_hash (userId, idNumberHash)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS quote_sessions (
        id char(36) NOT NULL,
        userId char(36) NULL,
        phoneNumber varchar(32) NOT NULL,
        identityId char(36) NULL,
        productCode varchar(64) NOT NULL,
        status enum('IN_PROGRESS','SUBMITTED','COMPLETED','ABANDONED','EXPIRED') NOT NULL DEFAULT 'IN_PROGRESS',
        currentStep int NOT NULL DEFAULT 1,
        stepDataJson json NULL,
        leadIdentitySnapshotJson json NULL,
        idempotencyKey varchar(100) NULL,
        submittedAt datetime NULL,
        expiresAt datetime NULL,
        createdAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        CONSTRAINT FK_quote_sessions_user FOREIGN KEY (userId) REFERENCES customers(id) ON DELETE SET NULL,
        CONSTRAINT FK_quote_sessions_identity FOREIGN KEY (identityId) REFERENCES identities(id) ON DELETE SET NULL,
        UNIQUE KEY UQ_quote_sessions_idempotencyKey (idempotencyKey),
        KEY IDX_quote_sessions_phone_product_updated (phoneNumber, productCode, updatedAt),
        KEY IDX_quote_sessions_user_product_created (userId, productCode, createdAt)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS quote_session_step_events (
        id char(36) NOT NULL,
        quoteSessionId char(36) NOT NULL,
        step int NOT NULL,
        payloadJson json NOT NULL,
        createdAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        CONSTRAINT FK_qs_step_events_session FOREIGN KEY (quoteSessionId) REFERENCES quote_sessions(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS vehicle_assets (
        id char(36) NOT NULL,
        userId char(36) NOT NULL,
        plate varchar(16) NULL,
        vin varchar(32) NULL,
        modelYear int NULL,
        brand varchar(64) NULL,
        model varchar(64) NULL,
        usageType varchar(64) NULL,
        fuelType varchar(32) NULL,
        extraJson json NULL,
        createdAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        CONSTRAINT FK_vehicle_assets_user FOREIGN KEY (userId) REFERENCES customers(id) ON DELETE CASCADE,
        UNIQUE KEY UQ_vehicle_assets_user_plate (userId, plate),
        UNIQUE KEY UQ_vehicle_assets_user_vin (userId, vin)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS property_assets (
        id char(36) NOT NULL,
        userId char(36) NOT NULL,
        addressLine varchar(255) NULL,
        city varchar(64) NULL,
        district varchar(64) NULL,
        neighborhood varchar(64) NULL,
        buildingYear int NULL,
        sqm int NULL,
        usageType varchar(64) NULL,
        extraJson json NULL,
        createdAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        CONSTRAINT FK_property_assets_user FOREIGN KEY (userId) REFERENCES customers(id) ON DELETE CASCADE,
        KEY IDX_property_assets_user_address (userId, addressLine)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS quote_session_asset_snapshots (
        id char(36) NOT NULL,
        quoteSessionId char(36) NOT NULL,
        assetType enum('VEHICLE','PROPERTY') NOT NULL,
        assetId char(36) NULL,
        snapshotJson json NOT NULL,
        createdAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        CONSTRAINT FK_qs_asset_snapshots_session FOREIGN KEY (quoteSessionId) REFERENCES quote_sessions(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS otp_challenges (
        id char(36) NOT NULL,
        phoneNumber varchar(32) NOT NULL,
        purpose enum('LOGIN','REGISTER') NOT NULL DEFAULT 'LOGIN',
        codeHash varchar(256) NOT NULL,
        codeSalt varchar(64) NOT NULL,
        expiresAt datetime NOT NULL,
        attemptCount int NOT NULL DEFAULT 0,
        maxAttempts int NOT NULL DEFAULT 5,
        lastSentAt datetime NOT NULL,
        createdAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        KEY IDX_otp_challenges_phone_purpose (phoneNumber, purpose)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS otp_challenges`);
    await queryRunner.query(`DROP TABLE IF EXISTS quote_session_asset_snapshots`);
    await queryRunner.query(`DROP TABLE IF EXISTS property_assets`);
    await queryRunner.query(`DROP TABLE IF EXISTS vehicle_assets`);
    await queryRunner.query(`DROP TABLE IF EXISTS quote_session_step_events`);
    await queryRunner.query(`DROP TABLE IF EXISTS quote_sessions`);
    await queryRunner.query(`DROP TABLE IF EXISTS identities`);
    await queryRunner.query(`DROP TABLE IF EXISTS customers`);
  }
}
