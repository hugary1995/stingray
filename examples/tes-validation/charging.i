# units are in meter kelvin second (m,kg,s)

kappa = 24 # W/m-K
rho = 2260 # kg/m^3
cp = 720 # J/kg-K

htc = 0
T_inf = 300
T0 = 300

kB = 5.67e-8
F = 0.6

[GlobalParams]
  energy_densities = 'H'
[]

[MultiApps]
  [induction]
    type = TransientMultiApp
    input_files = 'induction.i'
    cli_args = 'schedule=${schedule}'
  []
[]

[Transfers]
  [from_q]
    type = MultiAppShapeEvaluationTransfer
    from_multi_app = 'induction'
    source_variable = 'q'
    variable = 'q'
  []
[]

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = 'gold/sample2.msh'
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
[]

[Kernels]
  [energy_balance_1]
    type = EnergyBalanceTimeDerivative
    variable = T
    density = rho
    specific_heat = cp
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
  [hconv]
    type = ADMatNeumannBC
    variable = T
    boundary = 'outer'
    value = -1
    boundary_material = q
  []
[]

[Materials]
  [tube]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp kappa'
    prop_values = '${rho} ${cp} ${kappa}'
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
  [q]
    type = ADParsedMaterial
    property_name = q
    expression = 'htc*(T-T_inf)+kB*F*(T^4-T_inf^4)'
    coupled_variables = 'T'
    constant_names = 'htc T_inf kB F'
    constant_expressions = '${htc} ${T_inf} ${kB} ${F}'
    boundary = 'outer'
  []
[]

[Postprocessors]
  [T]
    type = PointValue
    variable = T
    point = '0.015 0 0.029'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [H_rate]
    type = EnthalpyRate
    density = 'rho'
    specific_heat = 'cp'
    temperature = 'T'
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON

  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true

  end_time = 5000
  dt = 100

  nl_abs_tol = 1e-8
  nl_rel_tol = 1e-6
  nl_max_its = 12
[]

[Outputs]
  file_base = 'schedule${schedule}/out'
  exodus = true
  csv = true
  print_linear_residuals = false
[]
