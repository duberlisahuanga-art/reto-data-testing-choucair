-- ============================================================================
-- SCRIPT 01: CREACIÓN DE BASES DE DATOS Y ESQUEMAS (DDL)
-- Proyecto: Reto Técnico Data Testing - Migración BD_Org -> BD_Dst
-- ============================================================================

USE master;
GO

-- 1. Reinicio limpio si las bases ya existen
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'BD_Org')
BEGIN
    ALTER DATABASE BD_Org SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BD_Org;
END
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'BD_Dst')
BEGIN
    ALTER DATABASE BD_Dst SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BD_Dst;
END
GO

CREATE DATABASE BD_Org;
CREATE DATABASE BD_Dst;
GO

-- ============================================================================
-- 2. CREACIÓN DE TABLAS EN BASE DE DATOS ORIGEN (BD_Org)
-- ============================================================================
USE BD_Org;
GO

CREATE TABLE dbo.Asociados (
    Cedula      VARCHAR(20)  NOT NULL PRIMARY KEY,
    Nombre      VARCHAR(100) NULL,
    Dirección   VARCHAR(150) NULL,
    Teléfono    VARCHAR(20)  NULL,
    Sexo        VARCHAR(10)  NULL,
    FNacimiento DATE         NULL,
    EstCivil    VARCHAR(10)  NULL,
    Estado      VARCHAR(15)  NOT NULL
);

CREATE TABLE dbo.Ahorradores (
    Cedula      VARCHAR(20)  NOT NULL PRIMARY KEY,
    Nombre      VARCHAR(100) NULL,
    Dirección   VARCHAR(150) NULL,
    Teléfono    VARCHAR(20)  NULL,
    email       VARCHAR(100) NULL,
    Sexo        VARCHAR(10)  NULL,
    FNacimiento DATE         NULL,
    EstCivil    VARCHAR(10)  NULL,
    Estado      VARCHAR(15)  NOT NULL
);
GO

-- ============================================================================
-- 3. CREACIÓN DE TABLAS MAESTRAS Y DESTINO (BD_Dst)
-- ============================================================================
USE BD_Dst;
GO

-- Catálogo Estado Civil (Regla 7)
CREATE TABLE dbo.EstadoCivil (
    Codigo      CHAR(2)     NOT NULL PRIMARY KEY,
    Descripcion VARCHAR(50) NOT NULL
);

INSERT INTO dbo.EstadoCivil (Codigo, Descripcion) VALUES
('SO', 'Soltero'),
('CA', 'Casado'),
('UL', 'Unión Libre'),
('VI', 'Viudo');

-- Catálogo Tipo Vínculo (Regla 5)
CREATE TABLE dbo.TipoVinculo (
    Codigo      CHAR(2)     NOT NULL PRIMARY KEY,
    Descripcion VARCHAR(50) NOT NULL
);

INSERT INTO dbo.TipoVinculo (Codigo, Descripcion) VALUES
('AS', 'Asociado'),
('AH', 'Ahorrador');

-- Entidad Principal Destino: Vinculación
CREATE TABLE dbo.Vinculación (
    Cedula         VARCHAR(20)  NOT NULL PRIMARY KEY,
    Nombre         VARCHAR(100) NULL,
    Dirección      VARCHAR(150) NULL,
    Teléfono       VARCHAR(20)  NULL,
    email          VARCHAR(100) NULL,
    Sexo           CHAR(2)      NOT NULL CHECK (Sexo IN ('M', 'F')),
    FNacimiento    DATE         NULL,
    EstCivil       CHAR(2)      NOT NULL FOREIGN KEY REFERENCES dbo.EstadoCivil(Codigo),
    Estado         VARCHAR(15)  NOT NULL,
    TipVinculación CHAR(2)      NOT NULL FOREIGN KEY REFERENCES dbo.TipoVinculo(Codigo)
);

-- Entidad Destino de Inactivos: Rechazos (Regla 8)
CREATE TABLE dbo.Rechazos (
    Cedula         VARCHAR(20)  NOT NULL PRIMARY KEY,
    Nombre         VARCHAR(100) NULL,
    Dirección      VARCHAR(150) NULL,
    Teléfono       VARCHAR(20)  NULL,
    email          VARCHAR(100) NULL,
    Sexo           CHAR(2)      NOT NULL CHECK (Sexo IN ('M', 'F')),
    FNacimiento    DATE         NULL,
    EstCivil       CHAR(2)      NOT NULL FOREIGN KEY REFERENCES dbo.EstadoCivil(Codigo),
    Estado         VARCHAR(15)  NOT NULL,
    TipVinculación CHAR(2)      NOT NULL FOREIGN KEY REFERENCES dbo.TipoVinculo(Codigo)
);
GO