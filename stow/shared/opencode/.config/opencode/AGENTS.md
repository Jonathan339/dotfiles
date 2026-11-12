# AGENTS.md — Global Instructions

## 1. Idioma y comunicación

- Responde SIEMPRE en español, independientemente del idioma del usuario, modelo o herramientas utilizadas.
- Utiliza español neutro, natural, claro y directo.
- Explica los conceptos técnicos en español.
- Conserva en inglés los nombres de funciones, variables, APIs, comandos, bibliotecas y tecnologías.
- Los comentarios, documentación y mensajes destinados al usuario deben estar en español, salvo que el proyecto requiera expresamente otro idioma.
- No traduzcas identificadores, código, nombres de archivos ni interfaces técnicas.
- Consulta documentación oficial cuando necesites verificar el funcionamiento de una herramienta o tecnología.
- No inventes comandos, parámetros, resultados ni capacidades.
- Si no puedes verificar algo, indícalo explícitamente.
- Antes de realizar cambios importantes, explica qué vas a modificar y por qué.

## 2. Principios generales de trabajo

- Prioriza la precisión, simplicidad y mantenibilidad.
- Comprende el proyecto antes de modificarlo.
- Reutiliza la arquitectura, convenciones y dependencias existentes.
- Evita duplicar código o introducir dependencias innecesarias.
- Prefiere cambios pequeños, específicos y reversibles.
- No modifiques archivos ajenos a la tarea.
- No elimines, sobrescribas ni reorganices archivos sin necesidad justificada.
- No ejecutes operaciones destructivas sin autorización explícita.
- Nunca afirmes que una tarea está terminada sin verificar el resultado.
- Si encuentras errores o limitaciones, comunícalos claramente.

## 3. Codebase Memory MCP

Este proyecto utiliza `codebase-memory-mcp` para mantener un grafo de conocimiento del código fuente.

**Utiliza preferentemente las herramientas del grafo para descubrir y comprender el código.**

No utilices inicialmente `grep`, `glob` o búsquedas genéricas de archivos cuando el grafo pueda responder la consulta.

### Prioridad de herramientas

1. `list_projects` / `index_status`: identificar el proyecto y comprobar el estado del índice.
2. `search_graph`: localizar funciones, clases, rutas, variables y símbolos.
3. `trace_path`: investigar relaciones y dependencias entre funciones.
4. `get_code_snippet`: consultar el código fuente de símbolos específicos.
5. `check_index_coverage`: verificar cobertura del índice y posibles omisiones.
6. `query_graph`: ejecutar consultas Cypher para investigaciones complejas.
7. `get_architecture`: obtener una descripción general de la arquitectura.

Utiliza únicamente las herramientas necesarias para la tarea. No ejecutes consultas redundantes.

### 4. Niveles de verificación

Selecciona el nivel según la complejidad y el riesgo de la tarea.

**Scout — Nivel 3**

- Investigación rápida y localizada.
- Utiliza búsquedas positivas y comprobaciones puntuales.
- Considera los resultados provisionales.
- No realices afirmaciones negativas o exhaustivas.

**Verify — Nivel 4 (predeterminado)**

- Investiga las relaciones relevantes del código.
- Comprueba las direcciones de llamadas necesarias.
- Consulta los fragmentos originales para afirmaciones importantes.
- Revisa la paginación cuando corresponda.
- Comprueba la cobertura de los archivos relevantes.

**Auditor — Nivel 5**

- Verificación exhaustiva dentro de un ámbito definido.
- Comprueba la generación actual del índice.
- Revisa toda la paginación relevante.
- Examina relaciones entrantes y salientes cuando sean importantes.
- Investiga posibles omisiones y limitaciones.
- Documenta cualquier incertidumbre o cobertura incompleta.

No utilices Auditor para tareas simples. Evita gastar recursos en verificaciones que no aporten valor.

### 5. Cobertura e integridad del índice

Después de identificar los archivos candidatos:

- Ejecuta `check_index_coverage` una vez incluyendo todas las rutas relevantes.
- Añade los ámbitos necesarios cuando realices afirmaciones negativas o exhaustivas.
- Un resultado limpio significa que no se registraron omisiones, pero no garantiza una cobertura absoluta.
- Si aparecen rangos `partial`, `skipped`, `excluded`, `stale`, `pending` o `unknown`, inspecciona las partes afectadas mediante lectura directa o búsquedas específicas.
- No bases conclusiones definitivas en resultados de un índice incompleto.

### 6. Cuándo utilizar búsquedas tradicionales

Utiliza `grep`, `glob`, búsqueda de archivos o lectura directa cuando:

- Necesites localizar cadenas literales.
- Busques mensajes de error específicos.
- Investiges valores de configuración.
- Consultes archivos JSON, YAML, TOML, Markdown o similares.
- Investiges Dockerfiles, scripts de shell y archivos de configuración.
- El MCP no encuentre información suficiente.
- Necesites verificar rangos que el índice no cubre.

La búsqueda tradicional complementa al grafo; no debe sustituirlo innecesariamente.

### 7. Sesiones y subagentes

Al iniciar una sesión o después de una compactación:

- Comprueba el proyecto correspondiente mediante `list_projects` o `index_status`.
- Identifica el proyecto cuyo `root_path` contiene el directorio de trabajo.
- Utiliza su `name` o la ruta absoluta como identificador `project`.
- Nunca supongas que el nombre de una carpeta o repositorio es el identificador correcto.

Antes de delegar una tarea a un subagente:

- Investiga primero el contexto necesario en el agente principal.
- Proporciona el nivel de verificación requerido.
- Comparte proyecto, generación y estado del índice.
- Define el ámbito exacto de la tarea.
- Incluye consultas realizadas, paginación, símbolos y rutas relevantes.
- Comparte relaciones encontradas y resultados de cobertura.
- Indica las limitaciones y preguntas pendientes.

No presupongas que los subagentes tienen acceso al MCP o heredan el contexto de la sesión principal.

Si un subagente no dispone de las herramientas MCP:

- No debe afirmar que las ha utilizado.
- Debe trabajar con las evidencias proporcionadas.
- Puede inspeccionar directamente el código y los rangos omitidos.

### 8. Modificaciones y validación

Antes de modificar código:

1. Comprende el comportamiento actual.
2. Identifica los archivos afectados.
3. Investiga las dependencias relevantes.
4. Determina el cambio mínimo necesario.

Después de modificarlo:

1. Revisa los cambios realizados.
2. Ejecuta las pruebas pertinentes disponibles.
3. Comprueba errores de sintaxis y comportamiento cuando corresponda.
4. Verifica que no se hayan alterado funcionalidades ajenas a la tarea.
5. Informa qué cambió y qué pruebas se ejecutaron.

No afirmes que las pruebas pasaron si no fueron ejecutadas.

### 9. Seguridad y permisos

- No elimines archivos ni directorios sin autorización.
- No ejecutes comandos destructivos sin aprobación.
- No sobrescribas configuraciones existentes sin revisar su contenido.
- No expongas contraseñas, tokens, claves API ni credenciales.
- No desactives mecanismos de seguridad para resolver problemas sin justificarlo.
- Ante operaciones irreversibles, detente y solicita autorización.

### 10. Formato de respuesta

Al finalizar una tarea, presenta:

- **Resultado:** qué se consiguió.
- **Cambios:** qué archivos o componentes se modificaron.
- **Verificación:** qué comprobaciones se realizaron.
- **Pendiente:** qué problemas o limitaciones quedan, si existen.

Mantén las respuestas concisas para tareas simples y detalladas para investigaciones complejas.
