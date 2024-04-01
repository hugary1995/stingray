sample = 0
mesh_matrix = 'RVE/${sample}/matrix.msh'
mesh_alt = 'RVE/${sample}/alt.msh'
mesh_cf = 'RVE/${sample}/cf.msh'

fibers = 'cf alt'

sigma_resin = 50 # S/mm
sigma_cf = 500 # S/mm
sigma_alt = 100 # S/mm

ECR_cf = 1
ECR_alt = 1

r_cf = '${fparse 8.5e-3/2}' # mm
r_alt = '${fparse 1.3e-2/2}' # mm
A_cf = '${fparse pi*r_cf^2}'
A_alt = '${fparse pi*r_alt^2}'
C_cf = '${fparse 2*pi*r_cf}'
C_alt = '${fparse 2*pi*r_alt}'

E = 1
matrix_x = 0.5 # mm

[GlobalParams]
  energy_densities = 'E'
[]

[Mesh]
  [matrix]
    type = FileMeshGenerator
    file = '${mesh_matrix}'
  []
  [alt0]
    type = FileMeshGenerator
    file = '${mesh_alt}'
  []
  [alt]
    type = SubdomainBoundingBoxGenerator
    input = alt0
    block_id = 1
    block_name = 'alt'
    bottom_left = '0 0 0'
    top_right = '1 1 1'
  []
  [cf0]
    type = FileMeshGenerator
    file = '${mesh_cf}'
  []
  [cf]
    type = SubdomainBoundingBoxGenerator
    input = cf0
    block_id = 2
    block_name = 'cf'
    bottom_left = '0 0 0'
    top_right = '1 1 1'
  []
  [combine]
    type = CombinerGenerator
    inputs = 'matrix alt cf'
  []
[]

[Variables]
  [Phi]
  []
[]

[AuxVariables]
  [ir]
    block = 'resin'
  []
  [i_x]
    order = CONSTANT
    family = MONOMIAL
    [AuxKernel]
      type = ADMaterialRealVectorValueAux
      property = 'i'
      component = 0
      execute_on = 'INITIAL TIMESTEP_END'
    []
  []
  [i_y]
    order = CONSTANT
    family = MONOMIAL
    [AuxKernel]
      type = ADMaterialRealVectorValueAux
      property = 'i'
      component = 1
      execute_on = 'INITIAL TIMESTEP_END'
    []
  []
  [i_z]
    order = CONSTANT
    family = MONOMIAL
    [AuxKernel]
      type = ADMaterialRealVectorValueAux
      property = 'i'
      component = 2
      execute_on = 'INITIAL TIMESTEP_END'
    []
  []
[]

[Kernels]
  [charge_balance_matrix]
    type = RankOneDivergence
    variable = Phi
    vector = i
    save_in = ir
    block = 'resin'
  []
  [charge_balance_fiber]
    type = RankOneDivergence
    variable = Phi
    vector = i
    factor = 'A'
    block = '${fibers}'
  []
[]

[BCs]
  [ground]
    type = DirichletBC
    variable = Phi
    value = 0
    boundary = 'resin_left'
  []
  [CV]
    type = FunctionDirichletBC
    variable = Phi
    function = '${fparse E*matrix_x}*t'
    boundary = 'resin_right'
  []
[]

[Constraints]
  [resistance_cf]
    type = EmbeddedMaterialConstraint
    variable = Phi
    primary = 'resin'
    secondary = 'cf'
    resistance = '${fparse ECR_cf/C_cf}'
    interface_id = 0
  []
  [resistance_alt]
    type = EmbeddedMaterialConstraint
    variable = Phi
    primary = 'resin'
    secondary = 'alt'
    resistance = '${fparse ECR_alt/C_alt}'
    interface_id = 1
  []
[]

[Materials]
  [resin]
    type = ADGenericConstantMaterial
    prop_names = 'sigma'
    prop_values = '${sigma_resin}'
    block = 'resin'
  []
  [cf]
    type = ADGenericConstantMaterial
    prop_names = 'sigma A'
    prop_values = '${sigma_cf} ${A_cf}'
    block = 'cf'
  []
  [alt]
    type = ADGenericConstantMaterial
    prop_names = 'sigma A'
    prop_values = '${sigma_alt} ${A_alt}'
    block = 'alt'
  []
  [charge_transport]
    type = BulkChargeTransport
    electrical_energy_density = E
    electric_potential = Phi
    electric_conductivity = sigma
  []
  [current]
    type = CurrentDensity
    current_density = i
    electric_potential = Phi
  []
[]

[Postprocessors]
  [I]
    type = NodalSum
    variable = ir
    boundary = 'resin_right'
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = none
  []
  [A]
    type = AreaPostprocessor
    boundary = 'resin_right'
    execute_on = 'INITIAL'
    outputs = none
  []
  [i]
    type = ParsedPostprocessor
    pp_names = 'I A'
    function = 'I / A'
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = none
  []
  [sigma]
    type = ParsedPostprocessor
    pp_names = 'i'
    function = 'i / ${E}'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [V_cf]
    type = VolumePostprocessor
    block = 'cf'
    execute_on = 'INITIAL'
    outputs = none
  []
  [V_alt]
    type = VolumePostprocessor
    block = 'alt'
    execute_on = 'INITIAL'
    outputs = none
  []
  [V_RVE]
    type = VolumePostprocessor
    block = 'resin'
    execute_on = 'INITIAL'
    outputs = none
  []
  [volfrac_cf]
    type = ParsedPostprocessor
    function = '${A_cf}*V_cf/(V_RVE)'
    pp_names = 'V_cf V_RVE'
    execute_on = 'INITIAL'
  []
  [volfrac_alt]
    type = ParsedPostprocessor
    function = '${A_alt}*V_alt/(V_RVE)'
    pp_names = 'V_alt V_RVE'
    execute_on = 'INITIAL'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON

  petsc_options = '-ksp_converged_reason'
  # petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold -pc_hypre_boomeramg_interp_type -pc_hypre_boomeramg_coarsen_type -pc_hypre_boomeramg_agg_nl -pc_hypre_boomeramg_agg_num_paths -pc_hypre_boomeramg_truncfactor'
  # petsc_options_value = 'hypre boomeramg 301 0.7 ext+i PMIS 4 2 0.4'
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -pc_factor_shift_type'
  petsc_options_value = 'lu       superlu_dist                  NONZERO'
  automatic_scaling = true

  l_max_its = 300
  nl_abs_tol = 1e-10
  nl_rel_tol = 1e-08

  end_time = 1
  dt = 1

  abort_on_solve_fail = true
[]

[Outputs]
  csv = true
  exodus = true
  print_linear_residuals = true
[]
