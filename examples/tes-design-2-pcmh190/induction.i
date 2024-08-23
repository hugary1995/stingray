# geometry
medium_R = 0.371475
container_t = 0.009525
insul_t = 0.0254
R = '${fparse medium_R + container_t + insul_t}'
coil_R = '${fparse R+0.005}'
coil_w = 0.05
coil_t = 0.004
n_coil = 10

# magnetic permeability
mu_air = 1.26e-6
mu_medium = '${fparse 1*mu_air}'
mu_coil = '${fparse 1*mu_air}'
mu_steel = '${fparse 1*mu_air}'
mu_insul = '${fparse 1*mu_air}'

# electrical conducitivity
sigma_air = 1e-12 # 1e-13~1e-9 S/m
sigma_medium = 23810 # S/m
sigma_coil = 8e6 # S/m, Note copper conductivity is around 6e7, but induction coil is hollow with water coolant running through
sigma_steel_T = '255.2222222 366.3333333 477.4444444 588.5555556 671.8888889 699.6666667 727.4444444 810.7777778 921.8888889 1033 1144.111111 1255.222222'
sigma_steel = '1351351.351 1219512.195 1111111.111 1030927.835 980392.1569 970873.7864 961538.4615 925925.9259 892857.1429 869565.2174 854700.8547 833333.3333' # S/m
sigma_insul = 1e-12 # S/m

# power supply
Pmax = 10000
f = 3000
omega = '${fparse 2*pi*f}'

non_coil = 'air insulation container medium pipe'

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = 'gold/EM.msh'
  []
  [scale]
    type = TransformGenerator
    input = fmg
    transform = SCALE
    vector_value = '1e-3 1e-3 1e-3'
  []
[]

[Variables]
  [Are_x]
  []
  [Aim_x]
  []
  [Are_y]
  []
  [Aim_y]
  []
  [Are_z]
  []
  [Aim_z]
  []
[]

[AuxVariables]
  [T]
    initial_condition = 300
  []
  [q]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = ADMaterialRealAux
      property = q
      execute_on = 'TIMESTEP_END'
    []
    block = 'insulation container medium pipe'
  []
[]

[Kernels]
  # Real part
  [real_Hdiv_x]
    type = RankTwoDivergence
    variable = Are_x
    tensor = Hre
    component = 0
    factor = -1
  []
  [real_Hdiv_y]
    type = RankTwoDivergence
    variable = Are_y
    tensor = Hre
    component = 1
    factor = -1
  []
  [real_Hdiv_z]
    type = RankTwoDivergence
    variable = Are_z
    tensor = Hre
    component = 2
    factor = -1
  []
  [real_induction_x]
    type = MaterialReaction
    variable = Are_x
    coupled_variable = Aim_x
    prop = ind_coef
    coefficient = -1
    block = ${non_coil}
  []
  [real_induction_y]
    type = MaterialReaction
    variable = Are_y
    coupled_variable = Aim_y
    prop = ind_coef
    coefficient = -1
    block = ${non_coil}
  []
  [real_induction_z]
    type = MaterialReaction
    variable = Are_z
    coupled_variable = Aim_z
    prop = ind_coef
    coefficient = -1
    block = ${non_coil}
  []
  [applied_current_x]
    type = MaterialSource
    variable = Are_x
    prop = ix
    coefficient = -1
    block = 'coils'
  []
  [applied_current_y]
    type = MaterialSource
    variable = Are_y
    prop = iy
    coefficient = -1
    block = 'coils'
  []
  [applied_current_z]
    type = MaterialSource
    variable = Are_z
    prop = iz
    coefficient = -1
    block = 'coils'
  []

  # Imaginary part
  [imag_Hdiv_x]
    type = RankTwoDivergence
    variable = Aim_x
    tensor = Him
    component = 0
    factor = -1
  []
  [imag_Hdiv_y]
    type = RankTwoDivergence
    variable = Aim_y
    tensor = Him
    component = 1
    factor = -1
  []
  [imag_Hdiv_z]
    type = RankTwoDivergence
    variable = Aim_z
    tensor = Him
    component = 2
    factor = -1
  []
  [imag_induction_x]
    type = MaterialReaction
    variable = Aim_x
    coupled_variable = Are_x
    prop = ind_coef
    coefficient = 1
    block = ${non_coil}
  []
  [imag_induction_y]
    type = MaterialReaction
    variable = Aim_y
    coupled_variable = Are_y
    prop = ind_coef
    coefficient = 1
    block = ${non_coil}
  []
  [imag_induction_z]
    type = MaterialReaction
    variable = Aim_z
    coupled_variable = Are_z
    prop = ind_coef
    coefficient = 1
    block = ${non_coil}
  []
[]

[Functions]
  [theta]
    type = ParsedFunction
    expression = 'atan2(y, x)'
  []
  [P]
    type = PiecewiseLinear
    x = '0 100'
    y = '0 ${Pmax}'
  []
[]

[Materials]
  [theta]
    type = ADGenericFunctionMaterial
    prop_names = 'theta'
    prop_values = 'theta'
    block = 'coils'
  []
  [P]
    type = ADGenericFunctionMaterial
    prop_names = 'P'
    prop_values = 'P'
    constant_on = SUBDOMAIN
    block = 'coils'
  []
  [p]
    type = ADParsedMaterial
    property_name = p
    expression = 'L:=2*3.141592653589*cr*nc; A:=cw*ct; P/A/L'
    constant_names = 'nc cr cw ct'
    constant_expressions = '${n_coil} ${coil_R} ${coil_w} ${coil_t}'
    material_property_names = 'P'
    block = 'coils'
  []
  [i]
    type = ADParsedMaterial
    property_name = i
    expression = 'sqrt(sigma*p)'
    material_property_names = 'sigma p'
    block = 'coils'
  []
  [ix]
    type = ADParsedMaterial
    property_name = ix
    expression = 'i*sin(theta)'
    material_property_names = 'i theta'
    block = 'coils'
    outputs = 'exodus'
  []
  [iy]
    type = ADParsedMaterial
    property_name = iy
    expression = '-i*cos(theta)'
    material_property_names = 'i theta'
    block = 'coils'
    outputs = 'exodus'
  []
  [iz]
    type = ADParsedMaterial
    property_name = iz
    expression = '0'
    block = 'coils'
    outputs = 'exodus'
  []
  [air]
    type = ADGenericConstantMaterial
    prop_names = 'mu sigma'
    prop_values = '${mu_air} ${sigma_air}'
    block = 'air'
  []
  [medium]
    type = ADGenericConstantMaterial
    prop_names = 'mu sigma'
    prop_values = '${mu_medium} ${sigma_medium}'
    block = 'medium'
  []
  [coil]
    type = ADGenericConstantMaterial
    prop_names = 'mu sigma'
    prop_values = '${mu_coil} ${sigma_coil}'
    block = 'coils'
  []
  [insulation]
    type = ADGenericConstantMaterial
    prop_names = 'mu sigma'
    prop_values = '${mu_insul} ${sigma_insul}'
    block = 'insulation'
  []
  [steel_conductivity]
    type = ADPiecewiseLinearInterpolationMaterial
    property = 'sigma'
    variable = 'T'
    x = ${sigma_steel_T}
    y = ${sigma_steel}
    block = 'pipe container'
  []
  [steel_permeability]
    type = ADGenericConstantMaterial
    prop_names = 'mu'
    prop_values = '${mu_steel}'
    block = 'pipe container'
  []
  [magnetizing_field_real]
    type = MagnetizingTensor
    magnetizing_tensor = Hre
    magnetic_vector_potential = 'Are_x Are_y Are_z'
    magnetic_permeability = mu
  []
  [magnetizing_field_imag]
    type = MagnetizingTensor
    magnetizing_tensor = Him
    magnetic_vector_potential = 'Aim_x Aim_y Aim_z'
    magnetic_permeability = mu
  []
  [induction_coef]
    type = ADParsedMaterial
    property_name = ind_coef
    expression = '${omega} * sigma'
    material_property_names = 'sigma'
  []
  [heat]
    type = InductionHeating
    heat_source = q
    frequency = ${omega}
    electrical_conductivity = sigma
    magnetic_vector_potential_real = ''
    magnetic_vector_potential_imaginary = 'Aim_x Aim_y Aim_z'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON

  petsc_options = '-ksp_converged_reason'
  petsc_options_iname = '-pc_type -pc_factor_shift_type'
  petsc_options_value = 'lu       NONZERO'

  automatic_scaling = true
  reuse_preconditioner = true
  reuse_preconditioner_max_linear_its = 25

  nl_abs_tol = 1e-10
  nl_rel_tol = 1e-08
  nl_max_its = 50

  l_max_its = 300
  l_tol = 1e-06

  dt = 1e6

  [Quadrature]
    order = CONSTANT
  []
[]

[Postprocessors]
  [Q_in]
    type = ADElementIntegralMaterialProperty
    mat_prop = p
    block = 'coils'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Q_air]
    type = ADElementIntegralMaterialProperty
    mat_prop = q
    block = 'air'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Q_insulation]
    type = ADElementIntegralMaterialProperty
    mat_prop = q
    block = 'insulation'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Q_container]
    type = ADElementIntegralMaterialProperty
    mat_prop = q
    block = 'container'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Q_medium]
    type = ADElementIntegralMaterialProperty
    mat_prop = q
    block = 'medium'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [Q_pipe]
    type = ADElementIntegralMaterialProperty
    mat_prop = q
    block = 'pipe'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [efficiency]
    type = ParsedPostprocessor
    function = '(Q_air+Q_insulation+Q_container+Q_medium+Q_pipe)/Q_in'
    pp_names = 'Q_in Q_air Q_insulation Q_container Q_medium Q_pipe'
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Outputs]
  exodus = true
  csv = true
  print_linear_residuals = false
[]
