cp = 1000
Tm = '${fparse 50+273.15}'
Ts = '${fparse 40+273.15}'
dT = 10
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
    initial_condition = 300
  []
[]

[Kernels]
  [htime]
    type = ADHeatConductionTimeDerivative
    variable = T
    density_name = rho
    specific_heat = cp
  []
  [hcond]
    type = ADHeatConduction
    variable = T
    thermal_conductivity = kappa
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
    expression = 'if(t<600,1e5,-1e5)'
  []
[]

[Materials]
  [props]
    type = ADGenericConstantMaterial
    prop_names = 'rho kappa'
    prop_values = '${rho} ${kappa}'
  []
  [time]
    type = ADGenericFunctionMaterial
    prop_names = 't'
    prop_values = 't'
    constant_on = SUBDOMAIN
  []
  [gaussian_function]
    type = ADParsedMaterial
    property_name = D
    expression = 'if(t<600, exp(-T*(T-Tm)^2/dT^2)/sqrt(3.1415926*dT^2), exp(-T*(T-Ts)^2/dT^2)/sqrt(3.1415926*dT^2))'
    coupled_variables = 'T'
    constant_names = 'Tm Ts dT'
    constant_expressions = '${Tm} ${Ts} ${dT}'
    material_property_names = 't'
  []
  [cp]
    type = ADParsedMaterial
    property_name = cp
    expression = 'cp0 + L * D'
    material_property_names = 'D'
    constant_names = 'L cp0'
    constant_expressions = '${L} ${cp}'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true
  dt = 1
  end_time = 1200
  nl_abs_tol = 1e-10
  nl_rel_tol = 1e-8
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
  [cp]
    type = ADElementAverageMaterialProperty
    mat_prop = cp
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Hrate]
    type = EnthalpyRate
    density = rho
    specific_heat = cp
    temperature = T
    execute_on = 'INITIAL TIMESTEP_END'
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
