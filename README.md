# Replicación de simulación cuántica con redes de tensores

Este repositorio contiene la implementación del algoritmo de contracción multietapa (`ComPar`) diseñado para la simulación eficiente de circuitos cuánticos. El algoritmo aprovecha los métodos de contracción de redes tensoriales paralelas para representar y calcular circuitos cuánticos complejos de manera eficiente.

El desarrollo original se basa en el [paquete QXTools para Julia](https://juliaqx.github.io/QXTools.jl). QXTools es un marco de código abierto que facilita la creación, manipulación y simulación de redes tensoriales asociadas a circuitos cuánticos. Integra bibliotecas de última generación para operaciones tensoriales y admite técnicas avanzadas de paralelización tanto en CPU como en GPU.

El trabajo original describe varias variantes del algoritmo multietapa, que aprovechan tanto los multiprocesadores multinúcleo como las GPU para la contracción paralela de tensores. Estas variantes corresponden a los algoritmos y experimentos descritos en el artículo. La evaluación realizada en esta replicación cubre por ahora las variantes CPU; GPU y slicing/MPI quedan pendientes.

## Autores y referencia original

El algoritmo ComPar y la implementación base son trabajo de **Alfred M. Pastor, Jose M. Badia y Maribel Castillo**. Este repositorio parte de su [repositorio original Multistage_contraction](https://github.com/alfred-miquel/Multistage_contraction), conservando sus licencias y atribución.

**Referencia:** Pastor, A. M., Badia, J. M., Castillo, M. I. (2025). *A community detection-based parallel algorithm for quantum circuit simulation using tensor networks*. The Journal of Supercomputing, 81, 450. https://doi.org/10.1007/s11227-025-06918-3

Título en español: «Un algoritmo paralelo basado en la detección de comunidades para la simulación de circuitos cuánticos utilizando redes tensoriales».

**Replicación experimental:** Enzo Aldhair Fuentes Apaza. Las aportaciones de esta replicación comprenden la configuración del entorno, los scripts de validación y medición, las gráficas y la documentación de los experimentos GHZ, QFT y RQC en CPU.

## Organización

| Carpeta | Contenido |
| --- | --- |
| `src/` | Implementación original de los autores |
| `Notebooks/` | Notebooks originales |
| `experimentos/` | Una configuración por ejecución para GHZ, QFT o RQC |
| `graficas/` | Generación de resúmenes y gráficas a partir de los CSV |
| `resultados/<familia>/datos/` | Mediciones individuales |
| `resultados/<familia>/graficas/` | Resúmenes CSV y figuras PNG/PDF |
| `docs/avances/` | Registro de los avances experimentales |
| `docs/historico/` | README original de los autores |
| `historico/` | Script exploratorio y mediciones iniciales |

## Entorno

Se utilizó Windows 11, Ryzen 5 5600H, 8 GB de RAM, Julia 1.7.3 y Python 3.10.11.
Las versiones de paquetes están en `Manifest.toml` y `requirements-python.txt`.

Desde la raíz del repositorio, instalar las dependencias de Julia:

```powershell
& "D:\ENZO\Herramientas\julia-1.7.3\bin\julia.exe" --project=.
```

Dentro de Julia:

```julia
using Pkg
Pkg.instantiate()
```

Preparar Python, si aún no existe el entorno:

```powershell
& "D:\ENZO\Herramientas\Python310\python.exe" -m venv D:\ENZO\Herramientas\python_compar
& "D:\ENZO\Herramientas\python_compar\Scripts\python.exe" -m pip install -r requirements-python.txt
```

Para enlazar PyCall, ejecutar en Julia y reiniciar después:

```julia
using Pkg
ENV["PYTHON"] = raw"D:\ENZO\Herramientas\python_compar\Scripts\python.exe"
Pkg.build("PyCall")
```

Los scripts reconocen por defecto los paquetes de ese entorno. En otro equipo se puede indicar la carpeta:

```powershell
$env:COMPAR_PYTHON_PACKAGES = "D:\ENZO\Herramientas\python_compar\Lib\site-packages"
```

## Ejecutar un ejemplo

Todos los comandos se ejecutan desde la raíz. Cada archivo evalúa una sola configuración; realiza calentamiento y varias repeticiones para calcular la mediana.

```powershell
& "D:\ENZO\Herramientas\julia-1.7.3\bin\julia.exe" --project=. --threads=4 .\experimentos\comparar_ghz.jl
& "D:\ENZO\Herramientas\julia-1.7.3\bin\julia.exe" --project=. --threads=4 .\experimentos\comparar_qft.jl
& "D:\ENZO\Herramientas\julia-1.7.3\bin\julia.exe" --project=. --threads=4 .\experimentos\comparar_rqc.jl
```

| Script | Ejemplo predeterminado | Argumentos opcionales |
| --- | --- | --- |
| GHZ | 10 qubits, comunidades automáticas | `qubits` |
| QFT | 6 qubits, 2 comunidades | `qubits comunidades` |
| RQC | 3×3, profundidad 8, 4 comunidades, semilla 42 | `lado profundidad comunidades` |

Por ejemplo, `comparar_rqc.jl 4 16 8` evalúa únicamente esa configuración.
GHZ y QFT utilizan diez repeticiones; RQC utiliza cinco. BLAS utiliza un hilo.
Una nueva ejecución reemplaza el CSV de la misma configuración.

## Generar gráficas

```powershell
& "D:\ENZO\Herramientas\python_compar\Scripts\python.exe" .\graficas\graficar_ghz.py
& "D:\ENZO\Herramientas\python_compar\Scripts\python.exe" .\graficas\graficar_qft.py
& "D:\ENZO\Herramientas\python_compar\Scripts\python.exe" .\graficas\graficar_rqc.py
```

Estos programas resumen las mediciones existentes, sin ejecutar nuevos circuitos. Actualmente filtran cuatro hilos y, para RQC, semilla 42.

## Alcance y resultados

Se validaron GHZ hasta 999 qubits, QFT hasta 18 y RQC hasta cuadrículas 4×4 con profundidades 8 y 16.
La serie GHZ final alcanzó 16.289× frente a GN para 999 qubits. QFT de 18 qubits con ocho comunidades obtuvo 2.172×. RQC tuvo mejoras y un caso pequeño ligeramente más lento con ComPar.

Los tiempos incluyen preparación, planificación y contracción; excluyen inicio del proceso, carga inicial de paquetes y creación del circuito. La referencia GN adapta el código original para fijar entrada, salida y descomposición.
QFT incluye las dos CNOT adicionales de la función de los autores.
RQC valida consistencia entre GN, min-fill y ComPar; no utiliza un simulador independiente de vector de estado.

Las asignaciones de memoria son acumuladas de Julia, no memoria máxima ocupada. Los resultados corresponden a esta laptop y las configuraciones registradas. GPU y slicing/MPI quedan pendientes.

## Procedencia

Código base: https://github.com/alfred-miquel/Multistage_contraction

Commit original: `b05dcb39a919cb411b494b1ec382c7f7e84babc2`.
Se conservan el historial, `LICENSE`, `GPL.txt` y el [README original](docs/historico/README_original.md).
Los documentos de `docs/avances/` conservan los nombres y rutas mencionados durante cada etapa; la estructura vigente es la de este README.
