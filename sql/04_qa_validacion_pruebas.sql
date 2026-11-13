-- ============================================================================
-- SCRIPT 04: SUITE DE PRUEBAS DE CALIDAD DE DATOS Y VOLUMETRÍA (QA / DATA TESTING)
-- Proyecto: Reto Técnico Data Testing - Choucair
-- Reglas validadas: 1, 2, 3, 4, 5, 6, 7, 8 y 9
-- ============================================================================

USE BD_Dst;
GO

-- ============================================================================
-- QA-01: VALIDACIÓN DE VOLUMETRÍA ORIGEN VS. DESTINO (REGLA 9)
-- Verifica que la cantidad de cédulas únicas activas e inactivas cuadre al 100%
-- ============================================================================
WITH OrigenActivos AS (
    SELECT LTRIM(RTRIM(Cedula)) AS Cedula FROM BD_Org.dbo.Asociados WHERE LTRIM(RTRIM(Estado)) = 'Activo'
    UNION -- UNION elimina duplicados entre ambas tablas (cumpliendo Regla 1 y 2)
    SELECT LTRIM(RTRIM(Cedula)) AS Cedula FROM BD_Org.dbo.Ahorradores WHERE LTRIM(RTRIM(Estado)) = 'Activo'
),
OrigenInactivos AS (
    SELECT LTRIM(RTRIM(Cedula)) AS Cedula FROM BD_Org.dbo.Asociados WHERE LTRIM(RTRIM(Estado)) = 'Inactivo'
    UNION
    SELECT LTRIM(RTRIM(Cedula)) AS Cedula FROM BD_Org.dbo.Ahorradores WHERE LTRIM(RTRIM(Estado)) = 'Inactivo'
)
SELECT 
    'QA-01A: Volumetría Activos (Vinculación)' AS Caso_Prueba,
    (SELECT COUNT(*) FROM OrigenActivos) AS Total_Origen_Unicos,
    (SELECT COUNT(*) FROM BD_Dst.dbo.Vinculación) AS Total_Destino,
    CASE 
        WHEN (SELECT COUNT(*) FROM OrigenActivos) = (SELECT COUNT(*) FROM BD_Dst.dbo.Vinculación)
        THEN 'PASS' ELSE 'FAIL'
    END AS Estado_QA
UNION ALL
SELECT 
    'QA-01B: Volumetría Inactivos (Rechazos)' AS Caso_Prueba,
    (SELECT COUNT(*) FROM OrigenInactivos) AS Total_Origen_Unicos,
    (SELECT COUNT(*) FROM BD_Dst.dbo.Rechazos) AS Total_Destino,
    CASE 
        WHEN (SELECT COUNT(*) FROM OrigenInactivos) = (SELECT COUNT(*) FROM BD_Dst.dbo.Rechazos)
        THEN 'PASS' ELSE 'FAIL'
    END AS Estado_QA;
GO

-- ============================================================================
-- QA-02: PRUEBAS DE INTEGRIDAD, UNICIDAD Y REGLAS DE NEGOCIO (0 ERRORES ESPERADOS)
-- Cada fila representa una aserción de calidad. Si Hallazgos = 0 -> PASS
-- ============================================================================
SELECT 
    'QA-02A: Unicidad de Cédulas en Vinculación (Regla 1)' AS Caso_Prueba,
    COUNT(*) AS Hallazgos_Anomalos,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Estado_QA
FROM (
    SELECT Cedula FROM BD_Dst.dbo.Vinculación GROUP BY Cedula HAVING COUNT(*) > 1
) t

UNION ALL

SELECT 
    'QA-02B: Cero registros Inactivos en Vinculación (Regla 8)' AS Caso_Prueba,
    COUNT(*) AS Hallazgos_Anomalos,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Estado_QA
FROM BD_Dst.dbo.Vinculación
WHERE LTRIM(RTRIM(Estado)) <> 'Activo'

UNION ALL

SELECT 
    'QA-02C: Cero registros Activos en Rechazos (Regla 8)' AS Caso_Prueba,
    COUNT(*) AS Hallazgos_Anomalos,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Estado_QA
FROM BD_Dst.dbo.Rechazos
WHERE LTRIM(RTRIM(Estado)) <> 'Inactivo'

UNION ALL

SELECT 
    'QA-02D: Homologación válida de Sexo M/F (Regla 6)' AS Caso_Prueba,
    COUNT(*) AS Hallazgos_Anomalos,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Estado_QA
FROM BD_Dst.dbo.Vinculación
WHERE Sexo NOT IN ('M', 'F') OR Sexo IS NULL

UNION ALL

SELECT 
    'QA-02E: Integridad Referencial con EstadoCivil (Regla 7)' AS Caso_Prueba,
    COUNT(*) AS Hallazgos_Anomalos,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Estado_QA
FROM BD_Dst.dbo.Vinculación v
LEFT JOIN BD_Dst.dbo.EstadoCivil ec ON v.EstCivil = ec.Codigo
WHERE ec.Codigo IS NULL

UNION ALL

SELECT 
    'QA-02F: Integridad Referencial con TipoVinculo (Regla 5)' AS Caso_Prueba,
    COUNT(*) AS Hallazgos_Anomalos,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Estado_QA
FROM BD_Dst.dbo.Vinculación v
LEFT JOIN BD_Dst.dbo.TipoVinculo tv ON v.TipVinculación = tv.Codigo
WHERE tv.Codigo IS NULL

UNION ALL

SELECT 
    'QA-02G: Relleno de campos en blanco desde Ahorradores (Regla 4)' AS Caso_Prueba,
    COUNT(*) AS Hallazgos_Anomalos,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Estado_QA
FROM BD_Dst.dbo.Vinculación
WHERE Cedula = '1004' 
  AND (Dirección IS NULL OR LTRIM(RTRIM(Dirección)) = '' 
       OR Teléfono IS NULL OR LTRIM(RTRIM(Teléfono)) = ''
       OR EstCivil IS NULL);
GO

-- ============================================================================
-- QA-03: INSPECCIÓN VISUAL DE RESULTADOS FINALES (AUDITORÍA DE CONTENIDO)
-- ============================================================================
SELECT 'DESTINO: VINCULACIÓN (ACTIVOS)' AS Tabla, * FROM BD_Dst.dbo.Vinculación ORDER BY Cedula;
SELECT 'DESTINO: RECHAZOS (INACTIVOS)' AS Tabla, * FROM BD_Dst.dbo.Rechazos ORDER BY Cedula;
GO