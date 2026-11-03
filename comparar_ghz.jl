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
    @assert isapprox(amplitud, esperado; atol=1e-12, rtol=1e-12)
    return amplitud
end

function comparar(numero_qubits; repeticiones=10)
    circuito = create_ghz_circuit(numero_qubits)
    entrada = repeat("0", numero_qubits)
    salida = repeat("1", numero_qubits)
    esperado = inv(sqrt(2))

    ejecutar_gn() = referencia_gn(circuito, entrada, salida)

    ejecutar_compar() = ComParCPU_GHZ(
        circuito, entrada, salida;
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

    tnc_metadata = convert_to_tnc(
        circuito;
        no_input=false,
        no_output=false,
        input=entrada,
        output=salida,
        decompose=true
    )

    grafo_metadata = convert_to_graph(tnc_metadata)

    comunidades, _, modularidad = labelg_to_communitats_fastgreedy(
        LabeledGraph(grafo_metadata)
    )

    numero_comunidades = length(comunidades)
    tamanos_comunidades = length.(comunidades)

    println("Comunidades seleccionadas: ", numero_comunidades)
    println("Modularidad: ", modularidad)
    println(
        "Tensores por comunidad, minimo/mediana/maximo: ",
        minimum(tamanos_comunidades), "/",
        median(tamanos_comunidades), "/",
        maximum(tamanos_comunidades)
    )



    mediana_gn = median(tiempos_gn)
    mediana_compar = median(tiempos_compar)

    println("Qubits: ", numero_qubits)
    println("Hilos de Julia: ", Threads.nthreads())
    println("Repeticiones por metodo: ", repeticiones)
    println("Amplitud GN: ", amplitud_gn)
    println("Amplitud ComPar: ", amplitud_compar)
    println("Mediana GN: ", round(1000 * mediana_gn; digits=3), " ms")
    println("Mediana ComPar GHZ: ", round(1000 * mediana_compar; digits=3), " ms")
    println("Aceleracion: ", round(mediana_gn / mediana_compar; digits=3), "x")

    ruta = joinpath(
        @__DIR__,
        "ghz_completo_$(numero_qubits)_hilos_$(Threads.nthreads()).csv"
    )

    open(ruta, "w") do archivo
        println(
            archivo,
            "repeticion,qubits,hilos,comunidades,modularidad,",
            "gn_segundos,compar_segundos,gn_bytes,compar_bytes"
        )

        for i in eachindex(tiempos_gn)
            println(
                archivo,
                i, ",",
                numero_qubits, ",",
                Threads.nthreads(), ",",
                numero_comunidades, ",",
                modularidad, ",",
                tiempos_gn[i], ",",
                tiempos_compar[i], ",",
                bytes_gn[i], ",",
                bytes_compar[i]
            )
        end
    end

    println("Mediciones guardadas en: ", ruta)
end

numero_qubits = isempty(ARGS) ? 10 : parse(Int, ARGS[1])
comparar(numero_qubits)