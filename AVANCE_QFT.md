# Segundo avance: QFT en CPU

Se utiliza create_qft_circuit_bis del repositorio de los autores:
un QFT seguido de dos puertas CNOT adicionales.

Se comparan la referencia GN adaptada con estados explícitos y
ComParCPU, utilizando cuatro hilos de Julia y un hilo BLAS.

La entrada y la salida consultada son cadenas de ceros.
La amplitud teórica utilizada para validación es 2^(-n/2).
Se aplica tolerancia relativa de 1e-10.

Se evaluaron circuitos de 6 a 18 qubits y distintas configuraciones
de 2, 4 y 8 comunidades. No todas las combinaciones fueron evaluadas.

Cada configuración utiliza calentamiento y diez mediciones por método,
alternando el orden de los métodos.

Los tiempos incluyen conversión, preparación, planificación y contracción.
Excluyen el inicio del proceso, la carga inicial de paquetes y la creación
inicial del circuito.

Para 18 qubits:

- Cuatro comunidades: GN 542.554 ms; ComPar 330.329 ms; aceleración 1.642x.
- Ocho comunidades: GN 637.663 ms; ComPar 293.585 ms; aceleración 2.172x.

Las referencias GN presentan variación entre procesos. Cada aceleración
se calcula con la referencia obtenida en su propia prueba.

La memoria reportada corresponde a asignaciones acumuladas de Julia,
no a memoria máxima ocupada ni al total de asignaciones internas de Python.

Las mediciones individuales están en qft\_\*.csv.
Las gráficas y el resumen están en resultados_qft/.

Esta es una replicación parcial en CPU; no reproduce todavía las escalas
grandes, las variantes GPU ni slicing/MPI del artículo.
