# Análisis Técnico, Supuestos y Mapeo STM (Source-to-Target)

## 1. Validación de Especificación Oficial y Reglas de Negocio
Con base en la guía oficial (`reto-data-testing.pdf`), se establecen y validan los siguientes criterios al 100% de apego a la especificación:

1. **Homologación de Sexo (Regla 6 Oficial):** La especificación define expresamente el mapeo de origen a destino:
   * `0` $\rightarrow$ `'M'` (Masculino)
   * `1` $\rightarrow$ `'F'` (Femenino)
2. **Homologación de Estado Civil (Regla 7 Oficial):** La especificación define expresamente el catálogo y homologación:
   * `0` $\rightarrow$ `'SO'` (Soltero)
   * `1` $\rightarrow$ `'CA'` (Casado)
   * `2` $\rightarrow$ `'UL'` (Unión Libre)
   * `3` $\rightarrow$ `'VI'` (Viudo)
3. **Valores de Estado (Regla 8):** Se estandariza el campo `Estado` con los valores `'Activo'` (migra a `dbo.Vinculación`) e `'Inactivo'` (migra a `dbo.Rechazos`).
4. **Definición de "Campo en Blanco" (Regla 4):** Se considera campo en blanco tanto valores `NULL` como cadenas vacías (`''`) o compuestas únicamente por espacios en blanco (`'   '`), sanitizadas mediante `NULLIF(LTRIM(RTRIM(...)), '')`.
5. **Caso Borde (Activo en una tabla / Inactivo en otra):** Si una misma `Cedula` figura como `Activo` en `Asociados` e `Inactivo` en `Ahorradores`, prevalece su estado activo en `Vinculación` (Regla 3) y el registro inactivo de ahorrador se audita en `Rechazos` (Regla 8).

---

## 2. Matriz de Mapeo (Source-to-Target Mapping)

| Tabla Destino (`BD_Dst`) | Campo Destino | Tipo Dato Propuesto | Origen 1 (`BD_Org.Asociados`) | Origen 2 (`BD_Org.Ahorradores`) | Regla de Transformación Aplicada |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Vinculación / Rechazos** | `Cedula` | `VARCHAR(20) PK` | `Cedula` | `Cedula` | **Regla 1 y 2:** Unificación por llave única `COALESCE(aso.Cedula, aho.Cedula)`. |
| **Vinculación / Rechazos** | `Nombre` | `VARCHAR(100)` | `Nombre` | `Nombre` | **Regla 3 y 4:** Prevalece `Asociados`. Si es `NULL` o vacío, toma `Ahorradores`. |
| **Vinculación / Rechazos** | `Dirección` | `VARCHAR(150)` | `Dirección` | `Dirección` | **Regla 3 y 4:** Prevalece `Asociados`. Si es `NULL` o vacío, toma `Ahorradores`. |
| **Vinculación / Rechazos** | `Teléfono` | `VARCHAR(20)` | `Teléfono` | `Teléfono` | **Regla 3 y 4:** Prevalece `Asociados`. Si es `NULL` o vacío, toma `Ahorradores`. |
| **Vinculación / Rechazos** | `email` | `VARCHAR(100)` | *No existe* | `email` | Se mapea directo desde `Ahorradores` (queda `NULL` si solo es Asociado). |
| **Vinculación / Rechazos** | `Sexo` | `CHAR(2)` | `Sexo` | `Sexo` | **Regla 3, 4 y 6:** Prevalece `Asociados`, homologado (`0->M`, `1->F`). CHECK `IN ('M', 'F')`. |
| **Vinculación / Rechazos** | `FNacimiento` | `DATE` | `FNacimiento` | `FNacimiento` | **Regla 3 y 4:** Prevalece `Asociados`. Si es `NULL`, toma `Ahorradores`. |
| **Vinculación / Rechazos** | `EstCivil` | `CHAR(2)` | `EstCivil` | `EstCivil` | **Regla 3, 4 y 7:** Prevalece `Asociados`, homologado (`0->SO`, `1->CA`, `2->UL`, `3->VI`). FK a `EstadoCivil`. |
| **Vinculación / Rechazos** | `Estado` | `VARCHAR(15)` | `Estado` | `Estado` | **Regla 8:** `'Activo'` migra a `Vinculación`; `'Inactivo'` migra a `Rechazos`. |
| **Vinculación / Rechazos** | `TipVinculación` | `CHAR(2)` | *Derivado* | *Derivado* | **Regla 5:** Si existe en `Asociados` (solo o en ambos) $\rightarrow$ `'AS'`. Solo en `Ahorradores` $\rightarrow$ `'AH'`. FK a `TipoVinculo`. |
