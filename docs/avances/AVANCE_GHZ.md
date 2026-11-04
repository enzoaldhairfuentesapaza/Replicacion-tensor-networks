# Replicación experimental: primer avance GHZ

Autor de la replicación: Enzo Aldhair Fuentes Apaza.

## Procedencia

Este proyecto parte del repositorio:
https://github.com/alfred-miquel/Multistage_contraction

Commit base: b05dcb39a919cb411b494b1ec382c7f7e84babc2

Artículo: Alfred M. Pastor, Jose M. Badia y Maribel Castillo.
A community detection-based parallel algorithm for quantum circuit
simulation using tensor networks.
DOI: https://doi.org/10.1007/s11227-025-06918-3

Se conservan los archivos de licencia y el código de los autores.
Los scripts de experimentación y visualización documentan esta replicación.

## Alcance del avance

Validación de amplitudes GHZ y comparación de la referencia GN con
ComParCPU_GHZ, que utiliza Fast Greedy para seleccionar comunidades.

La referencia GN adapta la conversión del circuito para especificar
explícitamente entrada, salida y descomposición.

Se evaluaron 10, 50, 100, 200, 500 y 999 qubits.
Cada método se calentó antes de realizar diez mediciones.
Se alternó el orden de ejecución de los métodos.

## Entorno

- Windows 11.
- AMD Ryzen 5 5600H: 6 núcleos y 12 hilos.
- RAM física: 8 GB.
- Julia 1.7.3.
- Python 3.10.11.
- PyCall 1.96.4.
- Dependencias Julia: Project.toml y Manifest.toml.
- Dependencias Python: requirements-python.txt.
- Experimento final: 4 hilos de Julia y 1 hilo BLAS.

La GPU no se utilizó en estas mediciones.

## Resultados de la serie final

| Qubits | Comunidades |   GN (ms) | ComPar GHZ (ms) | Aceleración |
| -----: | ----------: | --------: | --------------: | ----------: |
|     10 |           6 |    10.550 |           8.464 |      1.247x |
|     50 |          14 |    61.217 |          33.124 |      1.848x |
|    100 |          21 |   169.352 |          62.712 |      2.700x |
|    200 |          28 |   613.630 |         127.054 |      4.830x |
|    500 |          46 |  3333.495 |         353.608 |      9.427x |
|    999 |          66 | 12727.038 |         781.323 |     16.289x |

Los tiempos son medianas de llamadas completas, incluyendo preparación,
planificación y contracción. Excluyen el inicio de Julia, la carga inicial
de paquetes y la creación inicial del circuito.

La aceleración combina diferencias de estrategia y paralelismo.

## Archivos

- comparar_ghz.jl: comparación GN y ComPar GHZ.
- medir_compar.jl: pruebas iniciales de hilos y comunidades.
- graficar_ghz.py: generación de gráficas y resumen.
- ghz*completo*\*.csv: mediciones de la serie final.
- ghz\_\*.csv sin el prefijo completo: mediciones exploratorias anteriores.
- resultados_ghz/: resumen y gráficas de la serie final.

## Limitaciones

Las asignaciones acumuladas de Julia no representan memoria máxima
ocupada ni incluyen necesariamente todas las asignaciones internas de Python.

Las comunidades y la modularidad se obtienen en una detección adicional
fuera del tiempo medido.

Los scripts contienen rutas locales de Python que deben adaptarse
antes de ejecutarlos en otro equipo.

Este avance cubre GHZ en CPU. Quedan pendientes QFT, RQC, GPU y slicing/MPI.
