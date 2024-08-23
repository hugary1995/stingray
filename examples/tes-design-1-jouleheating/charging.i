# units are in meter kelvin second (m,kg,s)

kappa_medium = 18.8 # W/m-K
kappa_steel_T = '298.15 373.15 473.15 573.15 673.15 773.15 873.15 973.15 1023.15'
kappa_steel = '14.1 15.4 16.8 18.3 19.7 21.2 22.4 23.9 24.6' # W/m-K
kappa_insul = 0.4 # W/m-K

rho_foam = 96 # kg/m^3
rho_medium = '${fparse rho_foam*0.2+1425*0.8*0.7}' # kg/m^3, 80% porosity, 70% infiltration rate
rho_steel = 8030 # kg/m^3
rho_insul = 96 # kg/m^3

cp_medium = 2115 # kg/m^3, 80% porosity, 70% infiltration rate
cp_steel = 550 # kg/m^3
cp_insul = 1130 # kg/m^3

# electrical conducitivity
sigma_medium = 23810 # S/m
sigma_steel_T = '255.2222222 366.3333333 477.4444444 588.5555556 671.8888889 699.6666667 727.4444444 810.7777778 921.8888889 1033 1144.111111 1255.222222'
sigma_steel = '1351351.351 1219512.195 1111111.111 1030927.835 980392.1569 970873.7864 961538.4615 925925.9259 892857.1429 869565.2174 854700.8547 833333.3333' # S/m
sigma_insul = 1e-12 # S/m

T_m = '${fparse 151+273.15}' # K, Melting point
dT_pc = 8
L = 2.17e5 # J/kg, Latent heat

htc = 1
T_inf = 300
T0 = 300

kB = 5.67e-8
F = 0.6

end_time = '${fparse 8*3600}' # 8 hrs
dt = 0.1
tramp = 10
V = 0.025

[GlobalParams]
  energy_densities = 'E H'
[]

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = 'gold/T.msh'
  []
  [scale]
    type = TransformGenerator
    input = fmg
    transform = SCALE
    vector_value = '1e-3 1e-3 1e-3'
  []
[]

[Variables]
  [T]
    initial_condition = ${T0}
  []
  [Phi]
  []
[]

[AuxVariables]
  [ir]
  []
  [phase]
    order = CONSTANT
    family = MONOMIAL
    block = 'medium'
    [AuxKernel]
      type = ADMaterialRealAux
      property = phi
      block = 'medium'
      execute_on = 'INITIAL TIMESTEP_END'
    []
  []
[]

[Kernels]
  [charge_balance]
    type = RankOneDivergence
    variable = Phi
    vector = i
    save_in = 'ir'
  []
  [energy_balance_local]
    type = EnergyBalanceTimeDerivative
    variable = T
    density = rho
    specific_heat = cp
  []
  [energy_balance_local_latent]
    type = EnergyBalanceTimeDerivative
    variable = T
    density = rho
    specific_heat = cpL
    block = 'medium'
  []
  [energy_balance_2]
    type = RankOneDivergence
    variable = T
    vector = h
  []
  [energy_balance_3]
    type = MaterialSource
    variable = T
    prop = r
    coefficient = -1
  []
[]

[Functions]
  [V]
    type = PiecewiseLinear
    x = '0 ${tramp}'
    y = '0 ${V}'
  []
[]

[BCs]
  [ground]
    type = DirichletBC
    variable = Phi
    boundary = 'pipe_inner'
    value = 0
  []
  [charge]
    type = FunctionDirichletBC
    variable = Phi
    boundary = 'medium_outer'
    function = 'V'
  []
  [convection]
    type = ADMatNeumannBC
    variable = T
    boundary = 'insulation_outer pipe_outer pipe_inner'
    value = -1
    boundary_material = qconv
  []
  [radiation]
    type = ADMatNeumannBC
    variable = T
    boundary = 'insulation_outer pipe_outer'
    value = -1
    boundary_material = qrad
  []
[]

[Materials]
  [steel]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp'
    prop_values = '${rho_steel} ${cp_steel}'
    block = 'pipe container'
  []
  [steel_kappa]
    type = ADPiecewiseLinearInterpolationMaterial
    property = 'kappa'
    variable = 'T'
    x = ${kappa_steel_T}
    y = ${kappa_steel}
    block = 'pipe container'
  []
  [steel_sigma]
    type = ADPiecewiseLinearInterpolationMaterial
    property = 'sigma'
    variable = 'T'
    x = ${sigma_steel_T}
    y = ${sigma_steel}
    block = 'pipe container'
  []
  [medium]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp0 kappa0 sigma'
    prop_values = '${rho_medium} ${cp_medium} ${kappa_medium} ${sigma_medium}'
    block = 'medium'
  []
  [insulation]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp kappa sigma'
    prop_values = '${rho_insul} ${cp_insul} ${kappa_insul} ${sigma_insul}'
    block = 'insulation'
  []
  # Electrical
  [charge_trasport]
    type = BulkChargeTransport
    electrical_energy_density = E
    electric_potential = Phi
    electric_conductivity = sigma
    temperature = T
  []
  [current]
    type = CurrentDensity
    current_density = i
    electric_potential = Phi
  []
  # Thermal
  [heat_conduction]
    type = FourierPotential
    thermal_energy_density = H
    thermal_conductivity = kappa
    temperature = T
  []
  [heat_flux]
    type = HeatFlux
    heat_flux = h
    temperature = T
  []
  [heat_source]
    type = JouleHeating
    electric_potential = Phi
    electric_conductivity = sigma
    heat_source = r
    outputs = 'exodus'
  []
  # For melting and solidification
  [phase_change]
    type = TwoPhaseChange
    latent_specific_heat = cpL
    temperature = T
    phase = phi
    starting_temperature = ${T_m}
    ending_temperature = '${fparse T_m+dT_pc}'
    latent_heat = ${L}
    block = 'medium'
  []
  [medium_kappa]
    type = ADParsedMaterial
    property_name = kappa
    expression = '(cp + cpL) / cp * kappa0'
    material_property_names = 'cp cpL kappa0'
    block = 'medium'
  []
  # flux for BCs
  [qconv]
    type = ADParsedMaterial
    property_name = qconv
    expression = 'htc*(T-T_inf)'
    coupled_variables = 'T'
    constant_names = 'htc T_inf'
    constant_expressions = '${htc} ${T_inf}'
    boundary = 'insulation_outer pipe_outer pipe_inner'
  []
  [qrad]
    type = ADParsedMaterial
    property_name = qrad
    expression = 'kB*F*(T^4-T_inf^4)'
    coupled_variables = 'T'
    constant_names = 'T_inf kB F'
    constant_expressions = '${T_inf} ${kB} ${F}'
    boundary = 'insulation_outer pipe_outer'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON

  petsc_options = '-ksp_converged_reason'
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'

  automatic_scaling = true
  reuse_preconditioner = true
  reuse_preconditioner_max_linear_its = 25

  end_time = ${end_time}
  dt = ${dt}
  dtmin = 1e-6
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = ${dt}
    cutback_factor = 0.2
    cutback_factor_at_failure = 0.1
    growth_factor = 1.2
    optimal_iterations = 7
    iteration_window = 2
    linear_iteration_ratio = 100000
  []
  [Predictor]
    type = SimplePredictor
    scale = 1
    skip_after_failed_timestep = true
  []

  nl_abs_tol = 1e-8
  nl_rel_tol = 1e-6
  nl_max_its = 12

  l_max_its = 100
  l_tol = 1e-06

  [Quadrature]
    order = CONSTANT
  []
[]

[Postprocessors]
  [current]
    type = NodalSum
    variable = ir
    boundary = 'pipe_inner'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [voltage]
    type = FunctionValuePostprocessor
    function = V
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [power]
    type = ParsedPostprocessor
    function = '-current * voltage'
    pp_names = 'current voltage'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [medium_volume]
    type = VolumePostprocessor
    block = 'medium'
    execute_on = 'INITIAL'
  []
  [medium_molten]
    type = ADElementIntegralMaterialProperty
    mat_prop = phi
    block = 'medium'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [medium_molten_fraction]
    type = ParsedPostprocessor
    pp_names = 'medium_molten medium_volume'
    function = 'medium_molten/medium_volume'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [medium_Tmax]
    type = NodalExtremeValue
    variable = T
    block = 'medium'
    value_type = max
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [medium_S_rate]
    type = EnthalpyRate
    density = rho
    specific_heat = cp
    temperature = T
    block = 'medium'
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = none
  []
  [medium_S]
    type = TimeIntegratedPostprocessor
    value = medium_S_rate
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [medium_L_rate]
    type = EnthalpyRate
    density = rho
    specific_heat = cpL
    temperature = T
    block = 'medium'
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = none
  []
  [medium_L]
    type = TimeIntegratedPostprocessor
    value = medium_L_rate
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[UserObjects]
  [kill]
    type = Terminator
    expression = 'medium_molten_fraction>0.999'
    message = '99.9% of PCM has molten.'
    execute_on = 'TIMESTEP_END'
  []
[]

[Outputs]
  exodus = true
  csv = true
  print_linear_residuals = false
[]
