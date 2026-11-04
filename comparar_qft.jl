using QXTools, QXTns, QXZoo, QXGraphDecompositions
using DataStructures, ITensors, NDTensors, LightGraphs
using PyCall, TimerOutputs, LinearAlgebra, Statistics

site = pyimport("site")
site.addsitedir(raw"D:\ENZO\Herramientas\python_compar\Lib\site-packages")

BLAS.set_num_threads(1)

include(joinpath(@__DIR__, "src", "funcions_article.jl"))

function referencia_gn(circuito, entrada, salida)
    tnc = convert_to_tnc(
        circuito;
        no_input=false,
        no_output=false,
        input=entrada,
        output=salida,
        decompose=true
    )

    grafo = convert_to_graph(tnc)
    grafo_etiquetado = LabeledGraph(grafo)
    grafo_linea = line_graph_tris(grafo_etiquetado)

    plan = GN_pla(grafo, tnc.tn)

    return contract_tn!(tnc.tn, plan)
end

function comprobar(resultado, esperado)
    amplitud = resultado[]
    @assert isapprox(amplitud, esperado; atol=0.0, rtol=1e-10)
    return amplitud
end

function comparar(numero_qubits, numero_comunidades; repeticiones=10)
    @assert numero_qubits >= 3
    @assert numero_comunidades >= 2
    circuito = create_qft_circuit_bis(numero_qubits)
    entrada = repeat("0", numero_qubits)
    salida = repeat("0", numero_qubits)
    esperado = 2.0^(-numero_qubits / 2)

    ejecutar_gn() = referencia_gn(circuito, entrada, salida)

    ejecutar_compar() = ComParCPU(
        circuito,
        entrada,
        salida,
        numero_comunidades;
        timings=false,
        decompose=true
    )

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

    println("Qubits: ", numero_qubits)
    println("Hilos de Julia: ", Threads.nthreads())
    println("Repeticiones por metodo: ", repeticiones)
    println("Amplitud GN: ", amplitud_gn)
    println("Amplitud ComPar: ", amplitud_compar)
    println("Mediana GN: ", round(1000 * mediana_gn; digits=3), " ms")
    println("Comunidades solicitadas: ", numero_comunidades)
    println("Mediana ComPar QFT: ", round(1000 * mediana_compar; digits=3), " ms")
    println("Aceleracion: ", round(mediana_gn / mediana_compar; digits=3), "x")

    ruta = joinpath(
        @__DIR__,
        "qft_$(numero_qubits)_com_$(numero_comunidades)_hilos_$(Threads.nthreads()).csv"
    )

    open(ruta, "w") do archivo
        println(
            archivo,
            "repeticion,qubits,hilos,comunidades_solicitadas,",
            "gn_segundos,compar_segundos,gn_bytes,compar_bytes"
        )

        for i in eachindex(tiempos_gn)
            println(
                archivo,
                i, ",",
                numero_qubits, ",",
                Threads.nthreads(), ",",
                numero_comunidades, ",",
                tiempos_gn[i], ",",
                tiempos_compar[i], ",",
                bytes_gn[i], ",",
                bytes_compar[i]
            )
        end
    end

    println("Mediciones guardadas en: ", ruta)
    
end

numero_qubits = isempty(ARGS) ? 6 : parse(Int, ARGS[1])
numero_comunidades = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 2

comparar(numero_qubits, numero_comunidades)