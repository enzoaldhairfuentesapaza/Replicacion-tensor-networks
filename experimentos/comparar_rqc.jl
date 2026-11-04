using QXTools, QXTns, QXZoo, QXGraphDecompositions
using DataStructures, ITensors, NDTensors, LightGraphs
using PyCall, TimerOutputs, LinearAlgebra, Statistics

site = pyimport("site")
ruta_paquetes = get(ENV, "COMPAR_PYTHON_PACKAGES", raw"D:\ENZO\Herramientas\python_compar\Lib\site-packages")
if isdir(ruta_paquetes)
    site.addsitedir(ruta_paquetes)
end

BLAS.set_num_threads(1)

include(joinpath(@__DIR__, "..", "src", "funcions_article.jl"))

function red_cerrada(circuito, entrada, salida)
    return convert_to_tnc(
        circuito;
        no_input=false,
        no_output=false,
        input=entrada,
        output=salida,
        decompose=true
    )
end

function referencia_gn(circuito, entrada, salida)
    tnc = red_cerrada(circuito, entrada, salida)
    grafo = convert_to_graph(tnc)
    grafo_etiquetado = LabeledGraph(grafo)
    grafo_linea = line_graph_tris(grafo_etiquetado)
    plan = GN_pla(grafo, tnc.tn)
    return contract_tn!(tnc.tn, plan)
end

function referencia_minfill(circuito, entrada, salida)
    tnc = red_cerrada(circuito, entrada, salida)
    _, plan = min_fill_contraction_plan_tw(tnc.tn)
    return contract_tn!(tnc.tn, plan)
end

function comprobar(resultado, esperado)
    amplitud = resultado[]

    @assert isfinite(real(amplitud)) && isfinite(imag(amplitud))
    @assert isapprox(amplitud, esperado; atol=1e-12, rtol=1e-9)

    return amplitud
end

function comparar_rqc(lado, profundidad, comunidades;
                      semilla=42, repeticiones=5)
    numero_qubits = lado^2

    println(
        "\nRQC: ", lado, "x", lado,
        ", profundidad=", profundidad,
        ", comunidades=", comunidades,
        ", semilla=", semilla
    )
    flush(stdout)

    circuito = create_rqc_circuit(
        lado, lado, profundidad, semilla;
        final_h=true
    )

    entrada = repeat("0", numero_qubits)
    salida = repeat("0", numero_qubits)

    ejecutar_gn() = referencia_gn(circuito, entrada, salida)

    ejecutar_compar() = ComParCPU(
        circuito, entrada, salida, comunidades;
        timings=false,
        decompose=true
    )

    esperado = referencia_minfill(circuito, entrada, salida)[]
    amplitud_gn = comprobar(ejecutar_gn(), esperado)
    amplitud_compar = comprobar(ejecutar_compar(), esperado)

    tiempos_gn = Float64[]
    tiempos_compar = Float64[]
    bytes_gn = Int[]
    bytes_compar = Int[]

    function registrar!(tiempos, asignaciones, ejecutar)
        GC.gc()
        medicion = @timed ejecutar()
        comprobar(medicion.value, esperado)
        push!(tiempos, medicion.time)
        push!(asignaciones, medicion.bytes)
    end

    for repeticion in 1:repeticiones
        if isodd(repeticion)
            registrar!(tiempos_gn, bytes_gn, ejecutar_gn)
            registrar!(tiempos_compar, bytes_compar, ejecutar_compar)
        else
            registrar!(tiempos_compar, bytes_compar, ejecutar_compar)
            registrar!(tiempos_gn, bytes_gn, ejecutar_gn)
        end
    end

    mediana_gn = median(tiempos_gn)
    mediana_compar = median(tiempos_compar)

    nombre = "rqc_$(lado)x$(lado)_d$(profundidad)_c$(comunidades)" *
             "_s$(semilla)_h$(Threads.nthreads()).csv"

    carpeta_datos = mkpath(joinpath(@__DIR__, "..", "resultados", "rqc", "datos"))
    ruta = joinpath(carpeta_datos, nombre)

    open(ruta, "w") do archivo
        println(
            archivo,
            "repeticion,lado,qubits,profundidad,semilla,final_h,",
            "entrada,salida,hilos,comunidades_solicitadas,",
            "gn_segundos,compar_segundos,gn_bytes,compar_bytes,",
            "amplitud_real,amplitud_imag"
        )

        for i in eachindex(tiempos_gn)
            println(
                archivo,
                i, ",", lado, ",", numero_qubits, ",",
                profundidad, ",", semilla, ",true,",
                entrada, ",", salida, ",",
                Threads.nthreads(), ",", comunidades, ",",
                tiempos_gn[i], ",", tiempos_compar[i], ",",
                bytes_gn[i], ",", bytes_compar[i], ",",
                real(esperado), ",", imag(esperado)
            )
        end
    end

    println("Validacion GN / min-fill / ComPar: correcta")
    println("Amplitud GN: ", amplitud_gn)
    println("Amplitud ComPar: ", amplitud_compar)
    println("Probabilidad de la salida: ", abs2(esperado))
    println("Mediana GN: ", round(1000 * mediana_gn; digits=3), " ms")
    println("Mediana ComPar: ", round(1000 * mediana_compar; digits=3), " ms")
    println("Aceleracion: ", round(mediana_gn / mediana_compar; digits=3), "x")
    println(
        "Asignaciones GN / ComPar: ",
        round(median(bytes_gn) / 2^20; digits=2), " / ",
        round(median(bytes_compar) / 2^20; digits=2), " MiB"
    )
    println("CSV: ", ruta)
    flush(stdout)
end

if isempty(ARGS)
    comparar_rqc(3, 8, 4)
else
    length(ARGS) == 3 || error("Uso: comparar_rqc.jl lado profundidad comunidades")
    comparar_rqc(parse.(Int, ARGS)...)
end
