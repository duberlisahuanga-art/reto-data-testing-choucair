-- ============================================================================
-- SCRIPT 02: CARGA DE DATA SINTÉTICA CONTROLADA (DML - QA TEST DATA)
-- Proyecto: Reto Técnico Data Testing - Migración BD_Org -> BD_Dst
-- Cumplimiento estricto con especificación oficial:
-- Regla 6: Sexo (0 = M, 1 = F)
-- Regla 7: EstadoCivil (0 = SO, 1 = CA, 2 = UL, 3 = VI)
-- ============================================================================

USE BD_Org;
GO

-- Limpieza previa para idempotencia de pruebas
DELETE FROM dbo.Asociados;
DELETE FROM dbo.Ahorradores;
GO

-- 1. Inserción en Tabla Origen: Asociados (6 registros)
INSERT INTO dbo.Asociados (Cedula, Nombre, Dirección, Teléfono, Sexo, FNacimiento, EstCivil, Estado)
VALUES
-- Caso 1001: Solo Asociado Activo (Sexo=0 -> M, EstCivil=0 -> SO)
('1001', 'Carlos Mendoza', 'Av. Javier Prado 450, San Isidro', '999111222', '0', '1990-05-15', '0', 'Activo'),

-- Caso 1003: En ambos (Activo). Deben prevalecer estos datos sobre Ahorradores (Sexo=1 -> F, EstCivil=1 -> CA)
('1003', 'Lucía Fernández (Dato Oficial Asociado)', 'Calle Los Pinos 120', '988777666', '1', '1988-11-20', '1', 'Activo'),

-- Caso 1004: En ambos (Activo), pero Dirección es vacía '', Teléfono tiene espacios '   ' y EstCivil es NULL (Sexo=0 -> M)
('1004', 'Jorge Ramírez', '', '   ', '0', '1985-03-10', NULL, 'Activo'),

-- Caso 1005: Solo Asociado Inactivo -> Debe ir a Rechazos (Sexo=1 -> F, EstCivil=3 -> VI)
('1005', 'Elena Torres', 'Jr. Las Camelias 890', '977666555', '1', '1975-08-30', '3', 'Inactivo'),

-- Caso 1007: Inactivo en ambas tablas -> Debe unificarse en Rechazos prevaleciendo Asociados (Sexo=0 -> M, EstCivil=2 -> UL)
('1007', 'Ricardo Gómez (Asociado Inactivo)', 'Av. Arequipa 2300', '966555444', '0', '1982-01-12', '2', 'Inactivo'),

-- Caso 1008: Caso Borde -> Activo en Asociados, Inactivo en Ahorradores (Sexo=1 -> F, EstCivil=0 -> SO)
('1008', 'Sofía Vargas', 'Av. Salaverry 1450', '955444333', '1', '1995-07-22', '0', 'Activo');
GO

-- 2. Inserción en Tabla Origen: Ahorradores (6 registros)
INSERT INTO dbo.Ahorradores (Cedula, Nombre, Dirección, Teléfono, email, Sexo, FNacimiento, EstCivil, Estado)
VALUES
-- Caso 1002: Solo Ahorrador Activo -> Debe pasar como AH (Sexo=0 -> M, EstCivil=2 -> UL)
('1002', 'Andrés Silva', 'Av. El Ejército 310, Miraflores', '944333222', 'andres.silva@email.com', '0', '1992-09-14', '2', 'Activo'),

-- Caso 1003: Duplicado con Asociados -> Solo debe aportar el email; el resto se ignora por Regla 3
('1003', 'Lucía Fernández (Dato Antiguo Ahorrador)', 'Dirección Antigua 999', '900000000', 'lucia.fernandez@email.com', '1', '1988-11-20', '0', 'Activo'),

-- Caso 1004: Completa los blancos de Asociados (Dirección, Teléfono, EstCivil=1 -> CA) y aporta email
('1004', 'Jorge Ramírez', 'Av. Larco 780, Miraflores', '933222111', 'jorge.ramirez@email.com', '0', '1985-03-10', '1', 'Activo'),

-- Caso 1006: Solo Ahorrador Inactivo -> Debe ir a Rechazos como AH (Sexo=1 -> F, EstCivil=1 -> CA)
('1006', 'Patricia Castro', 'Calle Berlín 412', '922111000', 'patricia.castro@email.com', '1', '1980-12-05', '1', 'Inactivo'),

-- Caso 1007: Inactivo en ambas tablas -> Aporta email en Rechazos, pero prevalece Asociados
('1007', 'Ricardo Gómez (Ahorrador Inactivo)', 'Dirección Vieja 111', '911000999', 'ricardo.gomez@email.com', '0', '1982-01-12', '0', 'Inactivo'),

-- Caso 1008: Caso Borde -> Inactivo aquí, pero Activo en Asociados
('1008', 'Sofía Vargas', 'Av. Salaverry 1450', '955444333', 'sofia.vargas@email.com', '1', '1995-07-22', '0', 'Inactivo');
GO

-- Verificación rápida de lo cargado en origen:
SELECT 'Asociados' AS Tabla, COUNT(*) AS Total FROM dbo.Asociados
UNION ALL
SELECT 'Ahorradores' AS Tabla, COUNT(*) AS Total FROM dbo.Ahorradores;
GO
