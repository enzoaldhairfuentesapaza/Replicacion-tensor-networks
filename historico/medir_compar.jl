using QXTools, QXTns, QXZoo, QXGraphDecompositions
using DataStructures, ITensors, NDTensors, LightGraphs
using PyCall, TimerOutputs, LinearAlgebra, Statistics

site = pyimport("site")
site.addsitedir(raw"D:\ENZO\Herramientas\python_compar\Lib\site-packages")

BLAS.set_num_threads(1)


include(joinpath(@__DIR__, "..", "src", "funcions_article.jl"))

function medir_compar(circuito, entrada, salida, comunidades; repeticiones=10)
    esperado = inv(sqrt(2))

    calentamiento = ComParCPU(
        circuito, entrada, salida, comunidades;
        timings=false, decompose=true
    )

    @assert isapprox(calentamiento[], esperado; atol=1e-12, rtol=1e-12)

    tiempos = Float64[]

    for repeticion in 1:repeticiones
        GC.gc()

        medicion = @timed ComParCPU(
            circuito, entrada, salida, comunidades;
            timings=false, decompose=true
        )

        @assert isapprox(
            medicion.value[], esperado;
            atol=1e-12, rtol=1e-12
        )

        push!(tiempos, medicion.time)
    end

    println("Hilos de Julia: ", Threads.nthreads())
    println("Comunidades: ", comunidades)
    println("Repeticiones: ", repeticiones)
    println("Mediana: ", round(median(tiempos) * 1000; digits=3), " ms")
    println("Mínimo: ", round(minimum(tiempos) * 1000; digits=3), " ms")
    println("Máximo: ", round(maximum(tiempos) * 1000; digits=3), " ms")

    return tiempos
end

numero_qubits = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 10
numero_comunidades = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 4
println("Qubits: ", numero_qubits)


circuito = create_ghz_circuit(numero_qubits)
estado_entrada = repeat("0", numero_qubits)
estado_salida = repeat("1", numero_qubits)

tiempos = medir_compar(
    circuito,
    estado_entrada,
    estado_salida,
    numero_comunidades
);

println("\nDesglose por etapas después del calentamiento:")

resultado_etapas = ComParCPU(
    circuito,
    estado_entrada,
    estado_salida,
    numero_comunidades;
    timings=true,
    decompose=true
)

@assert isapprox(
    resultado_etapas[],
    inv(sqrt(2));
    atol=1e-12,
    rtol=1e-12
)

println("\nSegundo desglose por etapas:")

resultado_etapas = ComParCPU(
    circuito,
    estado_entrada,
    estado_salida,
    numero_comunidades;
    timings=true,
    decompose=true
)

@assert isapprox(
    resultado_etapas[],
    inv(sqrt(2));
    atol=1e-12,
    rtol=1e-12
)