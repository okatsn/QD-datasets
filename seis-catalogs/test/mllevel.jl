@testset "mllevel.jl" begin
    # Test basic binning with increment 0.5
    f = mllevel(0.5)
    @test f(0.0) == 0.0
    @test f(0.2) == 0.0
    @test f(0.49) == 0.0
    @test f(0.5) == 0.5
    @test f(0.75) == 0.5
    @test f(0.99) == 0.5
    @test f(1.0) == 1.0
    @test f(2.3) == 2.0
    @test f(7.19) == 7.0

    # Test with increment 1.0
    g = mllevel(1.0)
    @test g(0.0) == 0.0
    @test g(0.9) == 0.0
    @test g(1.0) == 1.0
    @test g(1.5) == 1.0
    @test g(2.0) == 2.0
    @test g(3.7) == 3.0

    # Test with increment 0.1
    h = mllevel(0.1)
    @test h(0.05) == 0.0
    @test h(0.15) ≈ 0.1
    @test h(0.25) ≈ 0.2
    @test h(1.23) ≈ 1.2

    # Test with negative values
    @test f(-0.3) == -0.5
    @test f(-0.5) == -0.5
    @test f(-1.0) == -1.0

    # Test edge cases
    @test f(0.0) == 0.0
    @test mllevel(2)(5.9) == 4.0
    @test mllevel(2)(6.0) == 6.0
end
