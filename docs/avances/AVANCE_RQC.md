# Tercer avance: circuitos cuánticos aleatorios en CPU

Se utiliza create_rqc_circuit de QXZoo, siguiendo el notebook
RQC de los autores.

## Configuración

- Cuadrículas: 2x2, 3x3 y 4x4.
- Profundidades evaluadas: 8 y 16.
- Comunidades solicitadas: 2, 4 u 8 según el caso.
- Semilla: 42.
- final_h=true.
- Entrada y salida consultada: todos ceros.
- Cuatro hilos de Julia y un hilo BLAS.
- Cinco mediciones por método después del calentamiento.
- Orden de los métodos alternado entre repeticiones.

No se evaluó el producto completo de todas las configuraciones.

## Validación

Se contrastaron las amplitudes obtenidas mediante GN, minimum fill-in
y ComPar, con tolerancia absoluta 1e-12 y relativa 1e-9.

Los ocho casos pasaron las comprobaciones.

Esta validación comprueba consistencia entre planes de contracción.
No es una referencia independiente mediante simulación de vector de estado.

## Resultados

En los casos evaluados, la aceleración total estuvo entre 0.970x y 1.697x.
El caso 2x2 de profundidad 8 fue ligeramente más lento con ComPar.

Para 4x4 y profundidad 16:

- Cuatro comunidades: GN 129.562 ms; ComPar 86.182 ms.
- Ocho comunidades: GN 100.852 ms; ComPar 75.035 ms.

Las referencias GN varían entre procesos. Cada aceleración se calcula
con la referencia obtenida en su propia prueba.

## Archivos

- comparar_rqc.jl: validación y mediciones.
- graficar_rqc.py: gráficas y resumen.
- rqc\_\*.csv: mediciones individuales y parámetros.
- resultados_rqc/: resumen y gráficas.

## Límites

Se evaluó una sola semilla y circuitos pequeños en CPU.
Los resultados no representan todas las distribuciones de circuitos RQC.

Los tiempos incluyen preparación, planificación y contracción.
Excluyen inicio de Julia, carga inicial de paquetes, creación del circuito
y validación adicional mediante minimum fill-in.

La memoria corresponde a asignaciones acumuladas de Julia, no a memoria
máxima ocupada ni a todas las asignaciones internas de Python.

Quedan pendientes las variantes GPU y slicing/MPI del artículo.
