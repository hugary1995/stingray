# units are in meter kelvin second (m,kg,s)

kappa_medium = 18.8 # W/m-K
kappa_steel_T = '298.15 373.15 473.15 573.15 673.15 773.15 873.15 973.15 1023.15'
kappa_steel = '14.1 15.4 16.8 18.3 19.7 21.2 22.4 23.9 24.6' # W/m-K
kappa_insul = 0.4 # W/m-K

rho_foam = 96 # kg/m^3
rho_medium = '${fparse rho_foam*0.2+2050*0.8*0.7}' # kg/m^3, 80% porosity, 70% infiltration rate
rho_steel = 8030 # kg/m^3
rho_insul = 96 # kg/m^3

cp_medium = 1074 # kg/m^3, 80% porosity, 70% infiltration rate
cp_steel = 550 # kg/m^3
cp_insul = 1130 # kg/m^3

T_m = '${fparse 714+273.15}' # K, Melting point
dT_pc = 8
L = 3.739e5 # J/kg, Latent heat

htc = 1
T_inf = 300
T0 = 300

kB = 5.67e-8
F = 0.6

end_time = '${fparse 24*3600}' # 8 hrs
dt = 100

[GlobalParams]
  energy_densities = 'H'
[]

[MultiApps]
  [induction]
    type = TransientMultiApp
    input_files = 'induction.i'
  []
[]

[Transfers]
  [to_T]
    type = MultiAppGeneralFieldShapeEvaluationTransfer
    to_multi_app = 'induction'
    source_variable = 'T'
    variable = 'T'
  []
  [from_q]
    type = MultiAppGeneralFieldShapeEvaluationTransfer
    from_multi_app = 'induction'
    source_variable = 'q'
    variable = 'q'
  []
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
[]

[AuxVariables]
  [q]
    order = CONSTANT
    family = MONOMIAL
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
  [heat_source]
    type = CoupledForce
    variable = T
    v = q
  []
[]

[BCs]
  [convection]
    type = ADMatNeumannBC
    variable = T
    boundary = 'insulation_outer'
    value = -1
    boundary_material = qconv
  []
  [radiation]
    type = ADMatNeumannBC
    variable = T
    boundary = 'insulation_outer'
    value = -1
    boundary_material = qrad
  []
[]

[Materials]
  [steel]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp'
    prop_values = '${rho_steel} ${cp_steel}'
    block = 'container'
  []
  [steel_kappa]
    type = ADPiecewiseLinearInterpolationMaterial
    property = 'kappa'
    variable = 'T'
    x = ${kappa_steel_T}
    y = ${kappa_steel}
    block = 'container'
  []
  [medium]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp kappa0'
    prop_values = '${rho_medium} ${cp_medium} ${kappa_medium}'
    block = 'medium'
  []
  [insulation]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp kappa'
    prop_values = '${rho_insul} ${cp_insul} ${kappa_insul}'
    block = 'insulation'
  []
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
    boundary = 'insulation_outer'
  []
  [qrad]
    type = ADParsedMaterial
    property_name = qrad
    expression = 'kB*F*(T^4-T_inf^4)'
    coupled_variables = 'T'
    constant_names = 'T_inf kB F'
    constant_expressions = '${T_inf} ${kB} ${F}'
    boundary = 'insulation_outer'
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
[]

[Postprocessors]
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
