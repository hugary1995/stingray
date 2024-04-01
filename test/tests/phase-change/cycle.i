cp = 1000
Ts_melting = '${fparse 70+273.15}'
Te_melting = '${fparse 80+273.15}'
Ts_freezing = '${fparse 60+273.15}'
Te_freezing = '${fparse 50+273.15}'
T0 = 300
L = 2e5
kappa = 20
rho = 1400

[Mesh]
  [gmg]
    type = GeneratedMeshGenerator
    dim = 3
  []
[]

[Variables]
  [T]
    initial_condition = ${T0}
  []
[]

[Kernels]
  [local]
    type = ADHeatConductionTimeDerivative
    variable = T
    density_name = rho
    specific_heat = cp
  []
  [latent]
    type = EnergyBalanceTimeDerivative
    variable = T
    density = rho
    specific_heat = cpL
  []
  [hcond]
    type = RankOneDivergence
    variable = T
    vector = h
  []
  [source]
    type = ADBodyForce
    variable = T
    function = q
  []
[]

[Functions]
  [q]
    type = ParsedFunction
    expression = 'if(t<500,1,-1) * 7.8e5'
  []
  [Ts]
    type = ParsedFunction
    expression = 'if(t<500,${Ts_melting},${Ts_freezing})'
  []
  [Te]
    type = ParsedFunction
    expression = 'if(t<500,${Te_melting},${Te_freezing})'
  []
[]

[Materials]
  [props]
    type = ADGenericConstantMaterial
    prop_names = 'rho kappa cp L'
    prop_values = '${rho} ${kappa} ${cp} ${L}'
  []
  [phase_change_T]
    type = ADGenericFunctionMaterial
    prop_names = 'Ts Te'
    prop_values = 'Ts Te'
    constant_on = SUBDOMAIN
  []
  [phase_change]
    type = TwoPhaseChange
    latent_specific_heat = cpL
    temperature = T
    phase = phi
    starting_temperature = Ts
    ending_temperature = Te
    latent_heat = L
  []
  [heat_conduction]
    type = FourierPotential
    thermal_energy_density = H
    thermal_conductivity = kappa
    temperature = T
  []
  [heat_flux]
    type = HeatFlux
    energy_densities = H
    heat_flux = h
    temperature = T
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true
  dt = 1
  end_time = 1000
  nl_abs_tol = 1e-8
  nl_rel_tol = 1e-6
  [Predictor]
    type = SimplePredictor
    scale = 1
    skip_after_failed_timestep = true
  []
[]

[Postprocessors]
  [T]
    type = ElementAverageValue
    variable = T
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [phi]
    type = ADElementAverageMaterialProperty
    mat_prop = phi
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [cpL]
    type = ADElementAverageMaterialProperty
    mat_prop = cpL
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Lrate]
    type = EnthalpyRate
    density = rho
    specific_heat = cpL
    temperature = T
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Srate]
    type = EnthalpyRate
    density = rho
    specific_heat = cp
    temperature = T
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Hrate]
    type = ParsedPostprocessor
    pp_names = 'Lrate Srate'
    function = 'Lrate + Srate'
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = none
  []
  [H]
    type = TimeIntegratedPostprocessor
    value = Hrate
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Outputs]
  csv = true
[]
