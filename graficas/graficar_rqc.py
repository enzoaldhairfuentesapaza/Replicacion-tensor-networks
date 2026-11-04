import csv
from pathlib import Path
from statistics import median

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


def main():
    carpeta = Path(__file__).resolve().parents[1] / "resultados" / "rqc" / "datos"
    resultados = []

    for ruta in carpeta.glob("rqc_*_s42_h4.csv"):
        with ruta.open(encoding="utf-8-sig", newline="") as archivo:
            filas = list(csv.DictReader(archivo))

        if not filas:
            continue

        primera = filas[0]
        gn = median(float(f["gn_segundos"]) for f in filas)
        compar = median(float(f["compar_segundos"]) for f in filas)

        resultados.append({
            "lado": int(primera["lado"]),
            "qubits": int(primera["qubits"]),
            "profundidad": int(primera["profundidad"]),
            "comunidades": int(primera["comunidades_solicitadas"]),
            "semilla": int(primera["semilla"]),
            "hilos": int(primera["hilos"]),
            "repeticiones": len(filas),
            "gn_ms": gn * 1000,
            "compar_ms": compar * 1000,
            "aceleracion": gn / compar,
            "gn_asignados_mib": median(
                int(f["gn_bytes"]) for f in filas
            ) / 2**20,
            "compar_asignados_mib": median(
                int(f["compar_bytes"]) for f in filas
            ) / 2**20,
        })

    resultados.sort(
        key=lambda f: (f["lado"], f["profundidad"], f["comunidades"])
    )

    if not resultados:
        raise SystemExit("No se encontraron CSV RQC para semilla 42 y 4 hilos.")

    salida = carpeta.parent / "graficas"
    salida.mkdir(exist_ok=True)

    with (salida / "resumen_rqc.csv").open(
        "w", encoding="utf-8", newline=""
    ) as archivo:
        escritor = csv.DictWriter(
            archivo, fieldnames=list(resultados[0])
        )
        escritor.writeheader()
        escritor.writerows(resultados)

    etiquetas = [
        f'{f["lado"]}x{f["lado"]}\nd={f["profundidad"]}, c={f["comunidades"]}'
        for f in resultados
    ]
    posiciones = np.arange(len(resultados))

    def guardar(figura, nombre):
        figura.tight_layout()
        figura.savefig(salida / f"{nombre}.png", dpi=200)
        figura.savefig(salida / f"{nombre}.pdf")
        plt.close(figura)

    for nombre, campo_gn, campo_compar, titulo, unidad in [
        (
            "tiempos_rqc", "gn_ms", "compar_ms",
            "RQC: tiempo total por configuración", "Mediana (ms)"
        ),
        (
            "asignaciones_rqc",
            "gn_asignados_mib", "compar_asignados_mib",
            "RQC: asignaciones acumuladas de Julia",
            "Mediana de asignaciones (MiB)"
        ),
    ]:
        figura, eje = plt.subplots(figsize=(11, 5))
        eje.bar(
            posiciones - 0.2,
            [f[campo_gn] for f in resultados],
            width=0.4, label="GN"
        )
        eje.bar(
            posiciones + 0.2,
            [f[campo_compar] for f in resultados],
            width=0.4, label="ComPar"
        )
        eje.set_xticks(posiciones)
        eje.set_xticklabels(etiquetas, fontsize=8)
        eje.set(ylabel=unidad, title=titulo)
        eje.grid(axis="y", alpha=0.25)
        eje.set_axisbelow(True)
        eje.legend()
        guardar(figura, nombre)

    figura, eje = plt.subplots(figsize=(11, 5))
    valores = [f["aceleracion"] for f in resultados]
    barras = eje.bar(posiciones, valores)
    eje.bar_label(barras, fmt="%.2fx", padding=3, fontsize=8)
    eje.axhline(1, color="gray", linestyle="--")
    eje.set_xticks(posiciones)
    eje.set_xticklabels(etiquetas, fontsize=8)
    eje.set(
        ylabel="Mediana GN / mediana ComPar",
        title="RQC: aceleración total, semilla 42 y 4 hilos",
        ylim=(0, max(valores) * 1.2)
    )
    eje.grid(axis="y", alpha=0.25)
    eje.set_axisbelow(True)
    guardar(figura, "aceleracion_rqc")

    for fila in resultados:
        print(
            f'{fila["lado"]}x{fila["lado"]}, '
            f'd={fila["profundidad"]}, c={fila["comunidades"]}: '
            f'GN={fila["gn_ms"]:.3f} ms, '
            f'ComPar={fila["compar_ms"]:.3f} ms, '
            f'S={fila["aceleracion"]:.3f}x'
        )

    print(f"\nResultados guardados en: {salida}")


if __name__ == "__main__":
    main()