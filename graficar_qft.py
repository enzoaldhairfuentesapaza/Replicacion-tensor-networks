import csv
from pathlib import Path
from statistics import median

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


def main():
    carpeta = Path(__file__).resolve().parent
    resultados = []

    for ruta in carpeta.glob("qft_*_com_*_hilos_4.csv"):
        with ruta.open(encoding="utf-8-sig", newline="") as archivo:
            filas = list(csv.DictReader(archivo))

        if not filas:
            continue

        gn = median(float(f["gn_segundos"]) for f in filas)
        compar = median(float(f["compar_segundos"]) for f in filas)

        resultados.append({
            "qubits": int(filas[0]["qubits"]),
            "comunidades": int(filas[0]["comunidades_solicitadas"]),
            "hilos": int(filas[0]["hilos"]),
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

    resultados.sort(key=lambda f: (f["qubits"], f["comunidades"]))

    if not resultados:
        raise SystemExit("No se encontraron CSV QFT de cuatro hilos.")

    salida = carpeta / "resultados_qft"
    salida.mkdir(exist_ok=True)

    with (salida / "resumen_qft.csv").open(
        "w", encoding="utf-8", newline=""
    ) as archivo:
        escritor = csv.DictWriter(
            archivo, fieldnames=list(resultados[0])
        )
        escritor.writeheader()
        escritor.writerows(resultados)

    configuraciones = sorted({f["comunidades"] for f in resultados})

    def guardar(figura, nombre):
        figura.tight_layout()
        figura.savefig(salida / f"{nombre}.png", dpi=200)
        figura.savefig(salida / f"{nombre}.pdf")
        plt.close(figura)

    figura, eje = plt.subplots(figsize=(8, 5))
    for comunidades in configuraciones:
        grupo = [
            f for f in resultados if f["comunidades"] == comunidades
        ]
        x = [f["qubits"] for f in grupo]

        linea, = eje.plot(
            x, [f["compar_ms"] for f in grupo], "o-",
            label=f"ComPar, {comunidades} comunidades"
        )
        eje.plot(
            x, [f["gn_ms"] for f in grupo], "--",
            color=linea.get_color(), alpha=0.7,
            label=f"GN, referencia de prueba c={comunidades}"
        )

    eje.set(
        xlabel="Qubits",
        ylabel="Mediana del tiempo total (ms)",
        title="QFT con dos CNOT adicionales: tiempos en CPU",
        yscale="log"
    )
    eje.grid(True, which="both", alpha=0.3)
    eje.legend(fontsize=8)
    guardar(figura, "tiempos_qft")

    figura, eje = plt.subplots(figsize=(8, 5))
    for comunidades in configuraciones:
        grupo = [
            f for f in resultados if f["comunidades"] == comunidades
        ]
        eje.plot(
            [f["qubits"] for f in grupo],
            [f["aceleracion"] for f in grupo],
            "o-", label=f"{comunidades} comunidades"
        )

    eje.axhline(1, color="gray", linestyle="--")
    eje.set(
        xlabel="Qubits",
        ylabel="Mediana GN / mediana ComPar",
        title="QFT: aceleración total, 4 hilos de Julia"
    )
    eje.grid(True, alpha=0.3)
    eje.legend()
    guardar(figura, "aceleracion_qft")

    figura, eje = plt.subplots(figsize=(8, 5))
    for comunidades in configuraciones:
        grupo = [
            f for f in resultados if f["comunidades"] == comunidades
        ]
        x = [f["qubits"] for f in grupo]

        linea, = eje.plot(
            x, [f["compar_asignados_mib"] for f in grupo],
            "o-", label=f"ComPar, {comunidades} comunidades"
        )
        eje.plot(
            x, [f["gn_asignados_mib"] for f in grupo], "--",
            color=linea.get_color(), alpha=0.7,
            label=f"GN, referencia de prueba c={comunidades}"
        )

    eje.set(
        xlabel="Qubits",
        ylabel="Mediana de asignaciones Julia (MiB)",
        title="QFT: asignaciones acumuladas por llamada",
        yscale="log"
    )
    eje.grid(True, which="both", alpha=0.3)
    eje.legend(fontsize=8)
    guardar(figura, "asignaciones_qft")

    for fila in resultados:
        print(
            f'n={fila["qubits"]:2d}, '
            f'c={fila["comunidades"]}: '
            f'GN={fila["gn_ms"]:.3f} ms, '
            f'ComPar={fila["compar_ms"]:.3f} ms, '
            f'S={fila["aceleracion"]:.3f}x'
        )

    print(f"\nResultados guardados en: {salida}")


if __name__ == "__main__":
    main()