n_coil = 4
coil_z = 0.05
coil_R = 0.07

# magnetic permeability
mu_air = 1.26e-6
mu_graphite = '${fparse 1*mu_air}'
mu_coil = '${fparse 1*mu_air}'

# electrical conducitivity
sigma_air = 1e-12 # 1e-13~1e-9 S/m
sigma_graphite = 23810 # S/m
sigma_coil = 5.96e7 # S/m

# frequency
f = 100000
omega = '${fparse 2*pi*f}'

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = '../gold/sample.msh'
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
  [q]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = ADMaterialRealAux
      property = q
      execute_on = 'TIMESTEP_END'
    []
    block = 'susceptor crucible'
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
  []
  [real_induction_y]
    type = MaterialReaction
    variable = Are_y
    coupled_variable = Aim_y
    prop = ind_coef
    coefficient = -1
  []
  [real_induction_z]
    type = MaterialReaction
    variable = Are_z
    coupled_variable = Aim_z
    prop = ind_coef
    coefficient = -1
  []
  [applied_current_x]
    type = MaterialSource
    variable = Are_x
    prop = ix
    coefficient = -1
    block = 'coil'
  []
  [applied_current_y]
    type = MaterialSource
    variable = Are_y
    prop = iy
    coefficient = -1
    block = 'coil'
  []
  [applied_current_z]
    type = MaterialSource
    variable = Are_z
    prop = iz
    coefficient = -1
    block = 'coil'
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
  []
  [imag_induction_y]
    type = MaterialReaction
    variable = Aim_y
    coupled_variable = Are_y
    prop = ind_coef
    coefficient = 1
  []
  [imag_induction_z]
    type = MaterialReaction
    variable = Aim_z
    coupled_variable = Are_z
    prop = ind_coef
    coefficient = 1
  []
[]

[Functions]
  [theta]
    type = ParsedFunction
    expression = 'atan2(z-${coil_z}, y)'
  []
  [V]
    type = PiecewiseLinear
    x = '0  110 780 960 1080 1230 1310 1380 1440 1500 2640 3060 4080 4500'
    y = '10 25  60  75  90   97   90   80   75   65   50   35   25   20'
  []
[]

[Materials]
  [theta]
    type = ADGenericFunctionMaterial
    prop_names = 'theta'
    prop_values = 'theta'
    block = 'coil'
    outputs = 'exodus'
  []
  [V]
    type = ADGenericFunctionMaterial
    prop_names = 'V'
    prop_values = 'V'
    constant_on = SUBDOMAIN
    block = 'coil'
  []
  [i]
    type = ADParsedMaterial
    property_name = i
    expression = 'sigma*V/2/3.141592653589/${coil_R}/${n_coil}'
    material_property_names = 'sigma V'
    block = 'coil'
  []
  [ix]
    type = ADParsedMaterial
    property_name = ix
    expression = 'i'
    material_property_names = 'i'
    block = 'coil'
    outputs = 'exodus'
  []
  [iy]
    type = ADParsedMaterial
    property_name = iy
    expression = '-i*sin(theta)'
    material_property_names = 'i theta'
    block = 'coil'
    outputs = 'exodus'
  []
  [iz]
    type = ADParsedMaterial
    property_name = iz
    expression = 'i*cos(theta)'
    material_property_names = 'i theta'
    block = 'coil'
    outputs = 'exodus'
  []
  [air]
    type = ADGenericConstantMaterial
    prop_names = 'mu sigma'
    prop_values = '${mu_air} ${sigma_air}'
    block = 'air'
  []
  [graphite]
    type = ADGenericConstantMaterial
    prop_names = 'mu sigma'
    prop_values = '${mu_graphite} ${sigma_graphite}'
    block = 'susceptor crucible'
  []
  [coil]
    type = ADGenericConstantMaterial
    prop_names = 'mu sigma'
    prop_values = '${mu_coil} ${sigma_coil}'
    block = 'coil'
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
  [current]
    type = EddyCurrent
    current_density = ie
    frequency = ${omega}
    electrical_conductivity = sigma
    magnetic_vector_potential_real = 'Are_x Are_y Are_z'
    magnetic_vector_potential_imaginary = 'Aim_x Aim_y Aim_z'
  []
  [heat]
    type = InductionHeating
    heat_source = q
    frequency = ${omega}
    electrical_conductivity = sigma
    magnetic_vector_potential_real = 'Are_x Are_y Are_z'
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

  dt = 100

  [Quadrature]
    order = CONSTANT
  []
[]

[Outputs]
  exodus = true
  print_linear_residuals = false
[]
