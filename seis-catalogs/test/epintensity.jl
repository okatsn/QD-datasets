@testset "epintensity.jl" begin
    # Test that reference event returns EpiI == ref_ML
    @test epintensity(7.0, 20.0) ≈ 7.0

    # Test with custom reference event
    @test epintensity(6.5, 15.0; ref_ML=6.5, ref_depth=15.0) ≈ 6.5

    # Test basic calculation consistency
    epi1 = epintensity(5.0, 10.0)
    @test epi1 isa Real
    @test !isnan(epi1)
    @test !isinf(epi1)

    # Test that deeper events have lower epicentral intensity (for same magnitude)
    @test epintensity(5.0, 10.0) > epintensity(5.0, 30.0)

    # Test that higher magnitude events have higher epicentral intensity (for same depth)
    @test epintensity(6.0, 10.0) > epintensity(5.0, 10.0)
end
