-- ============================================================================
-- SCRIPT 03: PIPELINE ETL DE MIGRACIÓN TRANSACCIONAL (BD_Org -> BD_Dst)
-- Proyecto: Reto Técnico Data Testing - Choucair
-- Reglas cubiertas: 1, 2, 3, 4, 5, 6, 7 y 8
-- ============================================================================

USE BD_Dst;
GO

SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Limpieza previa de tablas destino para asegurar idempotencia
    DELETE FROM dbo.Vinculación;
    DELETE FROM dbo.Rechazos;

    DECLARE @FilasVinculacion INT = 0;
    DECLARE @FilasRechazos INT = 0;

    -- ========================================================================
    -- PASO A: MIGRACIÓN DE REGISTROS ACTIVOS -> dbo.Vinculación (Reglas 1 a 7)
    -- ========================================================================
    INSERT INTO dbo.Vinculación (
        Cedula,
        Nombre,
        Dirección,
        Teléfono,
        email,
        Sexo,
        FNacimiento,
        EstCivil,
        Estado,
        TipVinculación
    )
    SELECT 
        -- Regla 1 y 2: Unificación de cédulas
        COALESCE(aso.Cedula, aho.Cedula) AS Cedula,

        -- Regla 3 y 4: Prevalece Asociados; si es NULL o blanco (''), toma Ahorradores
        COALESCE(NULLIF(LTRIM(RTRIM(aso.Nombre)), ''), NULLIF(LTRIM(RTRIM(aho.Nombre)), '')) AS Nombre,
        COALESCE(NULLIF(LTRIM(RTRIM(aso.Dirección)), ''), NULLIF(LTRIM(RTRIM(aho.Dirección)), '')) AS Dirección,
        COALESCE(NULLIF(LTRIM(RTRIM(aso.Teléfono)), ''), NULLIF(LTRIM(RTRIM(aho.Teléfono)), '')) AS Teléfono,

        -- Email proviene exclusivamente de Ahorradores
        NULLIF(LTRIM(RTRIM(aho.email)), '') AS email,

        -- Regla 6: Homologación de Sexo (prevalece Asociados; 0 -> M, 1 -> F según especificación oficial)
        CASE COALESCE(NULLIF(LTRIM(RTRIM(aso.Sexo)), ''), NULLIF(LTRIM(RTRIM(aho.Sexo)), ''))
            WHEN '0' THEN 'M'
            WHEN '1' THEN 'F'
            ELSE 'ND' -- Forzará error de CHECK constraint si llega un dato corrupto (Data Quality Gate)
        END AS Sexo,

        -- Regla 3 y 4: Fecha de Nacimiento
        COALESCE(aso.FNacimiento, aho.FNacimiento) AS FNacimiento,

        -- Regla 7: Homologación de Estado Civil (prevalece Asociados)
        CASE COALESCE(NULLIF(LTRIM(RTRIM(aso.EstCivil)), ''), NULLIF(LTRIM(RTRIM(aho.EstCivil)), ''))
            WHEN '0' THEN 'SO'
            WHEN '1' THEN 'CA'
            WHEN '2' THEN 'UL'
            WHEN '3' THEN 'VI'
            ELSE 'ND' -- Forzará error de FK si llega un código inválido
        END AS EstCivil,

        -- Estado (prevalece Asociados)
        COALESCE(NULLIF(LTRIM(RTRIM(aso.Estado)), ''), NULLIF(LTRIM(RTRIM(aho.Estado)), '')) AS Estado,

        -- Regla 5: Tipo de Vinculación (Si existe en Asociados -> 'AS', solo Ahorradores -> 'AH')
        CASE 
            WHEN aso.Cedula IS NOT NULL THEN 'AS'
            ELSE 'AH'
        END AS TipVinculación

    FROM 
        (SELECT * FROM BD_Org.dbo.Asociados WHERE LTRIM(RTRIM(Estado)) = 'Activo') aso
    FULL OUTER JOIN 
        (SELECT * FROM BD_Org.dbo.Ahorradores WHERE LTRIM(RTRIM(Estado)) = 'Activo') aho
        ON LTRIM(RTRIM(aso.Cedula)) = LTRIM(RTRIM(aho.Cedula));

    SET @FilasVinculacion = @@ROWCOUNT;

    -- ========================================================================
    -- PASO B: MIGRACIÓN DE REGISTROS INACTIVOS -> dbo.Rechazos (Regla 8)
    -- ========================================================================
    INSERT INTO dbo.Rechazos (
        Cedula,
        Nombre,
        Dirección,
        Teléfono,
        email,
        Sexo,
        FNacimiento,
        EstCivil,
        Estado,
        TipVinculación
    )
    SELECT 
        COALESCE(aso.Cedula, aho.Cedula) AS Cedula,
        COALESCE(NULLIF(LTRIM(RTRIM(aso.Nombre)), ''), NULLIF(LTRIM(RTRIM(aho.Nombre)), '')) AS Nombre,
        COALESCE(NULLIF(LTRIM(RTRIM(aso.Dirección)), ''), NULLIF(LTRIM(RTRIM(aho.Dirección)), '')) AS Dirección,
        COALESCE(NULLIF(LTRIM(RTRIM(aso.Teléfono)), ''), NULLIF(LTRIM(RTRIM(aho.Teléfono)), '')) AS Teléfono,
        NULLIF(LTRIM(RTRIM(aho.email)), '') AS email,
        CASE COALESCE(NULLIF(LTRIM(RTRIM(aso.Sexo)), ''), NULLIF(LTRIM(RTRIM(aho.Sexo)), ''))
            WHEN '0' THEN 'M'
            WHEN '1' THEN 'F'
            ELSE 'ND'
        END AS Sexo,
        COALESCE(aso.FNacimiento, aho.FNacimiento) AS FNacimiento,
        CASE COALESCE(NULLIF(LTRIM(RTRIM(aso.EstCivil)), ''), NULLIF(LTRIM(RTRIM(aho.EstCivil)), ''))
            WHEN '0' THEN 'SO'
            WHEN '1' THEN 'CA'
            WHEN '2' THEN 'UL'
            WHEN '3' THEN 'VI'
            ELSE 'ND'
        END AS EstCivil,
        COALESCE(NULLIF(LTRIM(RTRIM(aso.Estado)), ''), NULLIF(LTRIM(RTRIM(aho.Estado)), '')) AS Estado,
        CASE 
            WHEN aso.Cedula IS NOT NULL THEN 'AS'
            ELSE 'AH'
        END AS TipVinculación
    FROM 
        (SELECT * FROM BD_Org.dbo.Asociados WHERE LTRIM(RTRIM(Estado)) = 'Inactivo') aso
    FULL OUTER JOIN 
        (SELECT * FROM BD_Org.dbo.Ahorradores WHERE LTRIM(RTRIM(Estado)) = 'Inactivo') aho
        ON LTRIM(RTRIM(aso.Cedula)) = LTRIM(RTRIM(aho.Cedula));

    SET @FilasRechazos = @@ROWCOUNT;

    -- Confirmación de la transacción si todo salió bien
    COMMIT TRANSACTION;

    PRINT '====================================================';
    PRINT 'MIGRACIÓN COMPLETADA EXITOSAMENTE';
    PRINT 'Registros cargados en Vinculación (Activos): ' + CAST(@FilasVinculacion AS VARCHAR);
    PRINT 'Registros cargados en Rechazos (Inactivos):   ' + CAST(@FilasRechazos AS VARCHAR);
    PRINT '====================================================';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'ERROR CRÍTICO EN LA MIGRACIÓN - SE EJECUTÓ ROLLBACK';
    PRINT 'Mensaje de Error: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO