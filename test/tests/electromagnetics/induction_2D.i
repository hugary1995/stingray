# frequency
f0 = 1000
omega0 = '${fparse 2*pi*f0}'
f = 10000
omega = '${fparse 2*pi*f}'

# magnetic permeability
mu_air = 1.26e-6
mu_workpiece = '${fparse 1*mu_air}'
mu_coil = '${fparse 1*mu_air}'

# electrical conducitivity
sigma_workpiece = 1e7
sigma_air = 1e-13 # 1e-13~1e-9
sigma_coil = 6e7

# applied current density
ix = 1e9
iy = 0

[Mesh]
  [main_domain]
    type = GeneratedMeshGenerator
    dim = 2
    xmax = 0.1
    ymax = 0.1
    nx = 400
    ny = 25
  []
  [extended_domain]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 0.1
    xmax = 1
    ymax = 0.1
    nx = 100
    ny = 25
    boundary_id_offset = 100
    boundary_name_prefix = extended
  []
  [domain]
    type = StitchedMeshGenerator
    inputs = 'main_domain extended_domain'
    clear_stitched_boundary_ids = true
    stitch_boundaries_pairs = 'right extended_left'
  []
  [air]
    type = SubdomainBoundingBoxGenerator
    input = domain
    block_id = 0
    block_name = air
    bottom_left = '0 0 0'
    top_right = '1 0.1 0'
  []
  [workpiece]
    type = SubdomainBoundingBoxGenerator
    input = air
    block_id = 1
    block_name = workpiece
    bottom_left = '0 0 0'
    top_right = '0.05 0.1 0'
  []
  [coil]
    type = SubdomainBoundingBoxGenerator
    input = workpiece
    block_id = 2
    block_name = coil
    bottom_left = '0.07 0 0'
    top_right = '0.08 0.1 0'
  []
  coord_type = RZ
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
  []
  [ie]
    family = MONOMIAL
    order = CONSTANT
    [AuxKernel]
      type = ADMaterialRealAux
      property = ie
      execute_on = 'TIMESTEP_END'
    []
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
  [real_induction_x]
    type = MaterialReaction
    variable = Are_x
    coupled_variable = Aim_x
    prop = ind_coef
    coefficient = -1
    block = 'workpiece air'
  []
  [real_induction_y]
    type = MaterialReaction
    variable = Are_y
    coupled_variable = Aim_y
    prop = ind_coef
    coefficient = -1
    block = 'workpiece air'
  []
  [applied_current_x]
    type = MaterialSource
    variable = Are_x
    prop = ${ix}
    coefficient = -1
    block = 'coil'
  []
  [applied_current_y]
    type = MaterialSource
    variable = Are_y
    prop = ${iy}
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
  [imag_induction_x]
    type = MaterialReaction
    variable = Aim_x
    coupled_variable = Are_x
    prop = ind_coef
    coefficient = 1
    block = 'workpiece air'
  []
  [imag_induction_y]
    type = MaterialReaction
    variable = Aim_y
    coupled_variable = Are_y
    prop = ind_coef
    coefficient = 1
    block = 'workpiece air'
  []
[]

[Functions]
  [omega]
    type = ParsedFunction
    expression = 'if(t<1, ${omega0}*t, (t-1)*(${omega}-${omega0})+${omega0})'
  []
[]

[Materials]
  [workpiece]
    type = ADGenericConstantMaterial
    prop_names = 'mu sigma'
    prop_values = '${mu_workpiece} ${sigma_workpiece}'
    block = 'workpiece'
  []
  [air]
    type = ADGenericConstantMaterial
    prop_names = 'mu sigma'
    prop_values = '${mu_air} ${sigma_air}'
    block = 'air'
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
    magnetic_vector_potential = 'Are_x Are_y'
    magnetic_permeability = mu
  []
  [magnetizing_field_imag]
    type = MagnetizingTensor
    magnetizing_tensor = Him
    magnetic_vector_potential = 'Aim_x Aim_y'
    magnetic_permeability = mu
  []
  [induction_coef]
    type = ADParsedMaterial
    property_name = ind_coef
    expression = 'omega * sigma'
    material_property_names = 'omega sigma'
  []
  [frequency]
    type = ADGenericFunctionMaterial
    prop_names = 'omega'
    prop_values = 'omega'
  []
  [current]
    type = EddyCurrent
    current_density = ie
    frequency = omega
    electrical_conductivity = sigma
    magnetic_vector_potential_real = 'Are_x Are_y'
    magnetic_vector_potential_imaginary = 'Aim_x Aim_y'
  []
  [heat]
    type = InductionHeating
    heat_source = q
    frequency = omega
    electrical_conductivity = sigma
    magnetic_vector_potential_real = 'Are_x Are_y'
    magnetic_vector_potential_imaginary = 'Aim_x Aim_y'
  []
[]

[VectorPostprocessors]
  [current]
    type = LineValueSampler
    variable = ie
    sort_by = x
    num_points = 1000
    start_point = '0 0 0'
    end_point = '0.05 0 0'
    execute_on = 'TIMESTEP_END'
  []
[]

[Postprocessors]
  [omega]
    type = FunctionValuePostprocessor
    function = omega
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [power_workpiece]
    type = ADElementIntegralMaterialProperty
    mat_prop = q
    block = 'workpiece'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [power_air]
    type = ADElementIntegralMaterialProperty
    mat_prop = q
    block = 'air'
    execute_on = 'INITIAL TIMESTEP_END'
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

  dt = 0.05
  end_time = 2
[]

[Outputs]
  exodus = true
  print_linear_residuals = false
  [csv]
    type = CSV
    execute_on = 'TIMESTEP_END'
  []
[]
