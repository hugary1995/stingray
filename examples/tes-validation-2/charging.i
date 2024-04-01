# units are in meter kelvin second (m,kg,s)

kappa_medium = 18.8 # W/m-K
kappa_steel_T = '298.15 373.15 473.15 573.15 673.15 773.15 873.15 973.15 1023.15'
kappa_steel = '14.1 15.4 16.8 18.3 19.7 21.2 22.4 23.9 24.6' # W/m-K
kappa_insul = 0.45 # W/m-K
kappa_CO2_T = '223.15 1023.15'
kappa_CO2 = '11 72' # W/m-K
kappa_air = 6.7e-2 # W/m-K

rho_medium = 2050 # kg/m^3
rho_steel = 8359.33 # kg/m^3
rho_insul = 96 # kg/m^3
rho_CO2_T = '223.15 323.15 423.15 523.15 623.15 723.15 823.15 923.15 1023.15'
rho_CO2 = '2.42 1.66 1.26 0.98 0.86 0.74 0.62 0.56 0.52' # kg/m^3
rho_air = 1.293 # kg/m^3

cp_medium = 1074 # J/kg-K
cp_steel = 419 # J/kg-K
cp_insul = 1130 # J/kg-K
cp_CO2_T = '225 325 400 450 500  550  600  650  700  750  800  850  900  950  1000 1050'
cp_CO2 = '763 871 939 978 1014 1046 1075 1102 1126 1148 1168 1187 1204 1220 1234 1247' # J/kg-K
cp_air = 1005 # J/kg-K

T_m = '${fparse 718+273.15}' # K, Melting point
dT_pc = 8 # K
L = 3.739e5 # J/kg, Latent heat

htc = 5
T_inf = '${fparse 700+273.15}' # K
T0 = '${fparse 700+273.15}' # K
V = 3e-3 # m^3/s, flow rate
A = 0.00009989028 # m^2, pipe cross-sectional area
v = '${fparse V/A}'

kB = 5.67e-8
F = 0.7

end_time = '${fparse 8*3600}' # 8 hrs
dt = 100

TC1x = '${fparse 2.25/2*0.0254}'
TC2x = '${fparse 1.25/2*0.0254}'
TC3x = '${fparse 1.25/2*0.0254}'
TC4x = '${fparse 3.25/2*0.0254}'

TC1y = '${fparse (6.5-1)*0.0254}'
TC2y = '${fparse (6.5-2.5)*0.0254}'
TC3y = '${fparse (6.5-4)*0.0254}'
TC4y = '${fparse (6.5-2.5)*0.0254}'

[GlobalParams]
  energy_densities = 'H'
[]

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = 'gold/tes.msh'
  []
  [scale]
    type = TransformGenerator
    input = fmg
    transform = SCALE
    vector_value = '0.0254 0.0254 0.0254'
  []
  coord_type = RZ
[]

[Variables]
  [T]
    initial_condition = ${T0}
  []
  [v]
    family = LAGRANGE_VEC
    block = 'fluid'
    [InitialCondition]
      type = VectorConstantIC
      x_value = 1e-15
      y_value = 1e-15
      block = 'fluid'
    []
  []
  [p]
    block = 'fluid'
  []
[]

[AuxVariables]
  [Tc]
    [AuxKernel]
      type = ParsedAux
      expression = 'T-273.15'
      coupled_variables = 'T'
      execute_on = 'INITIAL TIMESTEP_END'
    []
  []
[]

[Kernels]
  [mass]
    type = INSADMass
    variable = p
    block = 'fluid'
  []
  [pspg]
    type = INSADMassPSPG
    variable = p
    block = 'fluid'
  []
  [momentum_convection]
    type = INSADMomentumAdvection
    variable = v
    block = 'fluid'
  []
  [momentum_viscous]
    type = INSADMomentumViscous
    variable = v
    block = 'fluid'
  []
  [momentum_pressure]
    type = INSADMomentumPressure
    variable = v
    pressure = p
    integrate_p_by_parts = true
    block = 'fluid'
  []
  [momentum_supg]
    type = INSADMomentumSUPG
    variable = v
    velocity = v
    block = 'fluid'
  []

  [temperature_advection]
    type = INSADEnergyAdvection
    variable = T
    block = 'fluid'
  []
  [temperature_supg]
    type = INSADEnergySUPG
    variable = T
    velocity = v
    block = 'fluid'
  []
  [energy_balance_local]
    type = EnergyBalanceTimeDerivative
    variable = T
    density = rho
    specific_heat = cp
  []
  [latent_medium]
    type = EnergyBalanceTimeDerivative
    variable = T
    density = rho
    specific_heat = cpL
    block = 'medium'
  []
  [energy_balance_nonlocal]
    type = RankOneDivergence
    variable = T
    vector = h
  []
[]

[Functions]
  [vramp]
    type = PiecewiseLinear
    x = '0 10'
    y = '1e-15 -${v}'
  []
  [Tramp]
    type = PiecewiseLinear
    x = '0 10 3600 7200'
    y = '${fparse T0} ${fparse 715+273.15} ${fparse 780+273.15}  ${fparse 800+273.15}'
  []
[]

[BCs]
  [T_inlet]
    type = FunctionDirichletBC
    variable = T
    function = Tramp
    boundary = 'outlet'
  []
  [velocity_inlet]
    type = VectorFunctionDirichletBC
    variable = v
    function_x = '1e-15'
    function_y = vramp
    boundary = 'outlet'
  []
  [wall]
    type = VectorFunctionDirichletBC
    variable = v
    boundary = 'wall'
  []
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
  [constant]
    type = ADGenericConstantMaterial
    prop_names = 'mu'
    prop_values = '4e-5'
    block = 'fluid'
  []
  [ins]
    type = INSADStabilized3Eqn
    pressure = p
    velocity = v
    temperature = T
    k_name = kappa
    block = 'fluid'
  []
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
  [CO2_kappa]
    type = ADPiecewiseLinearInterpolationMaterial
    property = 'kappa'
    variable = 'T'
    x = ${kappa_CO2_T}
    y = ${kappa_CO2}
    block = 'fluid'
  []
  [CO2_rho]
    type = ADPiecewiseLinearInterpolationMaterial
    property = 'rho'
    variable = 'T'
    x = ${rho_CO2_T}
    y = ${rho_CO2}
    block = 'fluid'
  []
  [CO2_cp]
    type = ADPiecewiseLinearInterpolationMaterial
    property = 'cp'
    variable = 'T'
    x = ${cp_CO2_T}
    y = ${cp_CO2}
    block = 'fluid'
  []
  [air]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp kappa'
    prop_values = '${rho_air} ${cp_air} ${kappa_air}'
    block = 'air'
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

[Dampers]
  [dT]
    type = MaxIncrement
    variable = T
    max_increment = ${dT_pc}
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON

  petsc_options = '-ksp_converged_reason'
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu      '

  automatic_scaling = true
  reuse_preconditioner = true
  reuse_preconditioner_max_linear_its = 25

  end_time = ${end_time}
  dt = ${dt}
  dtmax = ${dt}
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
  [TC1]
    type = PointValue
    variable = Tc
    point = '${TC1x} ${TC1y} 0'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [TC2]
    type = PointValue
    variable = Tc
    point = '${TC2x} ${TC2y} 0'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [TC3]
    type = PointValue
    variable = Tc
    point = '${TC3x} ${TC3y} 0'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [TC4]
    type = PointValue
    variable = Tc
    point = '${TC4x} ${TC4y} 0'
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Outputs]
  exodus = true
  csv = true
  print_linear_residuals = false
[]
