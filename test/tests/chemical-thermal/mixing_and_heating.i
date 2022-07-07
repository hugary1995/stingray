# This test demonstrates the simple mixing of two species. The temperature rises
# due to viscous dissipation.

[GlobalParams]
  energy_densities = 'psi_c+ psi_c-'
  dissipation_densities = 'psi_c+* psi_c-*'
[]

[Mesh]
  [gmg]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 10
    ny = 2
    nz = 2
  []
[]

[Variables]
  [T]
    [InitialCondition]
      type = ConstantIC
      value = 273.15
    []
  []
  [c+]
    [InitialCondition]
      type = FunctionIC
      function = 'x'
    []
  []
  [c-]
    [InitialCondition]
      type = FunctionIC
      function = '1-x'
    []
  []
[]

[Kernels]
  # Temperature
  [heat_td]
    type = ADHeatConductionTimeDerivative
    variable = T
    specific_heat = cv
    density_name = rho
  []
  [heat_cond]
    type = ADHeatConduction
    variable = T
    thermal_conductivity = kappa
  []
  [heat_source+]
    type = MaterialSource
    variable = T
    prop = q+
    coefficient = -1
  []
  [heat_source-]
    type = MaterialSource
    variable = T
    prop = q-
    coefficient = -1
  []
  # Concentrations
  [source+]
    type = MaterialSource
    variable = c+
    prop = mu+
  []
  [source-]
    type = MaterialSource
    variable = c-
    prop = mu-
  []
  [diffusion+]
    type = RankOneDivergence
    variable = c+
    vector = J+
  []
  [diffusion-]
    type = RankOneDivergence
    variable = c-
    vector = J-
  []
[]

[Materials]
  [diffusivity]
    type = ADGenericConstantRankTwoTensor
    tensor_name = 'D'
    tensor_values = '1 0 0 0 1 0 0 0 1'
  []
  [properties]
    type = ADGenericConstantMaterial
    prop_names = ' eta+ eta- rho cv  kappa'
    prop_values = '10   1    1   0.1 1e-2'
  []
  [viscosity+]
    type = ViscousMassTransport
    chemical_dissipation_density = psi_c+*
    concentration = c+
    viscosity = eta+
    ideal_gas_constant = 8.3145
    temperature = T
    molar_volume = 1e-4
  []
  [viscosity-]
    type = ViscousMassTransport
    chemical_dissipation_density = psi_c-*
    concentration = c-
    viscosity = eta-
    ideal_gas_constant = 8.3145
    temperature = T
    molar_volume = 1e-3
  []
  [fick+]
    type = FicksFirstLaw
    chemical_energy_density = psi_c+
    concentration = c+
    diffusivity = D
    viscosity = eta+
    ideal_gas_constant = 8.3145
    temperature = T
    molar_volume = 1e-4
  []
  [fick-]
    type = FicksFirstLaw
    chemical_energy_density = psi_c-
    concentration = c-
    diffusivity = D
    viscosity = eta-
    ideal_gas_constant = 8.3145
    temperature = T
    molar_volume = 1e-3
  []
  [mass_source+]
    type = MassSource
    mass_source = mu+
    concentration = c+
    heat = q+
  []
  [mass_source-]
    type = MassSource
    mass_source = mu-
    concentration = c-
    heat = q-
  []
  [mass_flux+]
    type = MassFlux
    mass_flux = J+
    concentration = c+
  []
  [mass_flux-]
    type = MassFlux
    mass_flux = J-
    concentration = c-
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  dt = 0.01
  end_time = 0.1
[]

[Outputs]
  exodus = true
[]
