# units are in meter kelvin second (m,kg,s)

kappa_medium = 18.8 # W/m-K
kappa_steel_T = '298.15 373.15 473.15 573.15 673.15 773.15 873.15 973.15 1023.15'
kappa_steel = '14.1 15.4 16.8 18.3 19.7 21.2 22.4 23.9 24.6' # W/m-K
kappa_insul = 0.4 # W/m-K
kappa_htf = 0.03 # W/m-K

rho_foam = 96 # kg/m^3
rho_medium = '${fparse rho_foam*0.2+2300*0.8*0.7}' # kg/m^3, 80% porosity, 70% infiltration rate
rho_steel = 8030 # kg/m^3
rho_insul = 96 # kg/m^3
rho_htf = 1.29 # kg/m^3

cp_medium = 1510 # kg/m^3
cp_steel = 550 # kg/m^3
cp_insul = 1130 # kg/m^3
cp_htf = 1000 # kg/m^3

T_m = '${fparse 191+273.15}' # K, Melting point
dT_pc = 8
L = 1.7e5 # J/kg, Latent heat

htc = 1
T_inf = 300
T0 = '${fparse 220+273.15}'

Tin = 300
v = -7

kB = 5.67e-8
F = 0.6

end_time = '${fparse 8*3600}' # 8 hrs
dt = 10

[GlobalParams]
  energy_densities = 'H'
[]

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = 'gold/Tvp.msh'
  []
  [scale]
    type = TransformGenerator
    input = fmg
    transform = SCALE
    vector_value = '1e-3 1e-3 1e-3'
  []
  [inlet]
    type = SideSetsAroundSubdomainGenerator
    input = scale
    block = 'htf'
    new_boundary = 'inlet'
    normal = '0 0 1'
    fixed_normal = true
  []
  [outlet]
    type = SideSetsAroundSubdomainGenerator
    input = inlet
    block = 'htf'
    new_boundary = 'outlet'
    normal = '0 0 -1'
    fixed_normal = true
  []
[]

[Functions]
  [vz]
    type = PiecewiseLinear
    x = '0 360'
    y = '1e-10 ${v}'
  []
[]

[Variables]
  [T]
  []
  [v]
    family = LAGRANGE_VEC
    block = htf
  []
  [p]
    block = htf
  []
[]

[ICs]
  [T_solid]
    type = ConstantIC
    variable = T
    value = ${T0}
    block = 'medium pipe insulation container'
  []
  [T_fluid]
    type = ConstantIC
    variable = T
    value = ${Tin}
    block = 'htf'
  []
  [vel]
    type = VectorConstantIC
    variable = v
    x_value = 1e-10
    y_value = 1e-10
    z_value = 1e-10
    block = 'htf'
  []
[]

[AuxVariables]
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
  [vmag]
    [AuxKernel]
      type = VectorVariableMagnitudeAux
      vector_variable = v
      block = 'htf'
      execute_on = 'INITIAL TIMESTEP_END'
    []
  []
[]

[Kernels]
  [mass]
    type = INSADMass
    variable = p
    block = 'htf'
  []
  [pspg]
    type = INSADMassPSPG
    variable = p
    block = 'htf'
  []
  [momentum_convection]
    type = INSADMomentumAdvection
    variable = v
    block = 'htf'
  []
  [momentum_viscous]
    type = INSADMomentumViscous
    variable = v
    block = 'htf'
  []
  [momentum_pressure]
    type = INSADMomentumPressure
    variable = v
    pressure = p
    # integrate_p_by_parts = true
    block = 'htf'
  []
  [momentum_supg]
    type = INSADMomentumSUPG
    variable = v
    velocity = v
    block = 'htf'
  []

  [temperature_advection]
    type = INSADEnergyAdvection
    variable = T
    block = 'htf'
  []
  [temperature_supg]
    type = INSADEnergySUPG
    variable = T
    velocity = v
    block = 'htf'
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
[]

[BCs]
  [convection]
    type = ADMatNeumannBC
    variable = T
    boundary = 'insulation_outer pipe_outer'
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
  [T_inlet]
    type = DirichletBC
    variable = T
    value = ${Tin}
    boundary = 'inlet'
  []
  [velocity_inlet]
    type = VectorFunctionDirichletBC
    variable = v
    function_z = vz
    boundary = 'inlet'
  []
  [wall]
    type = VectorFunctionDirichletBC
    variable = v
    boundary = 'pipe_inner'
  []
  [p]
    type = DirichletBC
    variable = p
    value = 0
    boundary = 'outlet'
  []
[]

[Materials]
  [flow_props]
    type = ADGenericConstantMaterial
    prop_names = 'mu'
    prop_values = '1.8e-5'
  []
  [ins]
    type = INSADStabilized3Eqn
    pressure = p
    velocity = v
    temperature = T
    k_name = kappa
    block = 'htf'
  []
  [htf]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp kappa'
    prop_values = '${rho_htf} ${cp_htf} ${kappa_htf}'
    block = 'htf'
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
    starting_temperature = '${fparse T_m+dT_pc}'
    ending_temperature = ${T_m}
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
    boundary = 'insulation_outer pipe_outer'
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
    expression = 'medium_molten/medium_volume'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [medium_Tmin]
    type = NodalExtremeValue
    variable = T
    value_type = min
    block = 'medium'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [medium_Tmax]
    type = NodalExtremeValue
    variable = T
    value_type = max
    block = 'medium'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [vout]
    type = SideAverageValue
    variable = vmag
    boundary = 'outlet'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [pin]
    type = SideAverageValue
    variable = p
    boundary = 'inlet'
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = 'none'
  []
  [pout]
    type = SideAverageValue
    variable = p
    boundary = 'outlet'
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = 'none'
  []
  [pressure]
    type = ParsedPostprocessor
    expression = 'pin-pout'
    pp_names = 'pin pout'
    execute_on = 'INITIAL TIMESTEP_END'
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

[Outputs]
  exodus = true
  csv = true
  print_linear_residuals = false
[]
