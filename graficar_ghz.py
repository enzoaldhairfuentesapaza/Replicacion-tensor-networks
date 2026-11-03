import csv
from pathlib import Path
from statistics import median

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


def cargar_resultados(carpeta):
    resultados = []

    for ruta in carpeta.glob("ghz_completo_*_hilos_4.csv"):
        with ruta.open(encoding="utf-8-sig", newline="") as archivo:
            filas = list(csv.DictReader(archivo))

        if not filas:
            continue

        tiempo_gn = median(float(f["gn_segundos"]) for f in filas)
        tiempo_compar = median(float(f["compar_segundos"]) for f in filas)

        resultados.append({
            "qubits": int(filas[0]["qubits"]),
            "hilos": int(filas[0]["hilos"]),
            "repeticiones": len(filas),
            "comunidades": int(filas[0]["comunidades"]),
            "modularidad": float(filas[0]["modularidad"]),
            "gn_ms": tiempo_gn * 1000,
            "compar_ms": tiempo_compar * 1000,
            "aceleracion": tiempo_gn / tiempo_compar,
            "gn_asignados_mib": median(
                int(f["gn_bytes"]) for f in filas
            ) / 2**20,
            "compar_asignados_mib": median(
                int(f["compar_bytes"]) for f in filas
            ) / 2**20,
        })

    return sorted(resultados, key=lambda fila: fila["qubits"])


def guardar_figura(figura, carpeta, nombre):
    figura.tight_layout()
    figura.savefig(carpeta / f"{nombre}.png", dpi=200)
    figura.savefig(carpeta / f"{nombre}.pdf")
    plt.close(figura)


def main():
    carpeta = Path(__file__).resolve().parent
    resultados = cargar_resultados(carpeta)

    if not resultados:
        raise SystemExit("No se encontraron CSV completos de cuatro hilos.")

    salida = carpeta / "resultados_ghz"
    salida.mkdir(exist_ok=True)

    with (salida / "resumen_ghz.csv").open(
        "w", encoding="utf-8", newline=""
    ) as archivo:
        escritor = csv.DictWriter(
            archivo, fieldnames=list(resultados[0])
        )
        escritor.writeheader()
        escritor.writerows(resultados)

    qubits = [f["qubits"] for f in resultados]

    figura, eje = plt.subplots(figsize=(7, 4.5))
    eje.plot(qubits, [f["gn_ms"] for f in resultados], "o-", label="GN")
    eje.plot(
        qubits, [f["compar_ms"] for f in resultados],
        "s-", label="ComPar GHZ, 4 hilos"
    )
    eje.set(
        xlabel="Qubits",
        ylabel="Mediana del tiempo total (ms)",
        title="GHZ: tiempo de preparación, planificación y contracción",
        yscale="log"
    )
    eje.grid(True, which="both", alpha=0.3)
    eje.legend()
    guardar_figura(figura, salida, "tiempos_ghz")

    figura, eje = plt.subplots(figsize=(7, 4.5))
    eje.plot(
        qubits, [f["aceleracion"] for f in resultados], "o-"
    )
    eje.axhline(1, color="gray", linestyle="--")
    eje.set(
        xlabel="Qubits",
        ylabel="Mediana GN / mediana ComPar",
        title="GHZ: aceleración de ComPar respecto de GN"
    )
    eje.grid(True, alpha=0.3)
    guardar_figura(figura, salida, "aceleracion_ghz")

    figura, eje = plt.subplots(figsize=(7, 4.5))
    eje.plot(
        qubits, [f["gn_asignados_mib"] for f in resultados],
        "o-", label="GN"
    )
    eje.plot(
        qubits, [f["compar_asignados_mib"] for f in resultados],
        "s-", label="ComPar GHZ, 4 hilos"
    )
    eje.set(
        xlabel="Qubits",
        ylabel="Mediana de bytes asignados por Julia (MiB)",
        title="GHZ: asignaciones acumuladas por llamada",
        yscale="log"
    )
    eje.grid(True, which="both", alpha=0.3)
    eje.legend()
    guardar_figura(figura, salida, "asignaciones_ghz")

    print("Qubits | Comunidades | Modularidad | GN ms | ComPar ms | Aceleración")
    for fila in resultados:
        print(
            f'{fila["qubits"]:6d} | '
            f'{fila["comunidades"]:11d} | '
            f'{fila["modularidad"]:11.4f} | '
            f'{fila["gn_ms"]:8.3f} | '
            f'{fila["compar_ms"]:9.3f} | '
            f'{fila["aceleracion"]:8.3f}x'
        )

    print(f"\nResultados guardados en: {salida}")


if __name__ == "__main__":
    main()