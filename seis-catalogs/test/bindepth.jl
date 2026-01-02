@testset "bindepth.jl" begin
    # Test with bin_size=5
    f = bindepth(5)
    @test f(0) == 0
    @test f(4) == 0
    @test f(4.9) == 0
    @test f(5) == 5
    @test f(9) == 5
    @test f(9.9) == 5
    @test f(10) == 10

    # Test with bin_size=10
    g = bindepth(10)
    @test g(0) == 0
    @test g(9) == 0
    @test g(9.9) == 0
    @test g(10) == 10
    @test g(19) == 10
    @test g(90) == 90
end
