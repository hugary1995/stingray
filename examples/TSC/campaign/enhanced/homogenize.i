sample = 0
mesh_matrix = 'RVE/${sample}/matrix.msh'
mesh_alt = 'RVE/${sample}/alt.msh'
mesh_cf = 'RVE/${sample}/cf.msh'
mesh_cnt1 = 'RVE/${sample}/cnt1.msh'
mesh_cnt2 = 'RVE/${sample}/cnt2.msh'

fibers = 'cf alt cnt1 cnt2'

sigma_resin = 50 # S/mm
sigma_cf = 500 # S/mm
sigma_alt = 100 # S/mm
sigma_cnt1 = 8000 # S/mm
sigma_cnt2 = 8000 # S/mm

ECR_cf = 72.5
ECR_alt = 74
ECR_cnt1 = 1
ECR_cnt2 = 1

r_cf = '${fparse 8.5e-3/2}' # mm
r_alt = '${fparse 1.3e-2/2}' # mm
r_cnt1 = '${fparse 7.5e-3/2}' # mm
r_cnt2 = '${fparse 7.5e-3/2}' # mm
A_cf = '${fparse pi*r_cf^2}'
A_alt = '${fparse pi*r_alt^2}'
A_cnt1 = '${fparse pi*r_cnt1^2}'
A_cnt2 = '${fparse pi*r_cnt2^2}'
C_cf = '${fparse 2*pi*r_cf}'
C_alt = '${fparse 2*pi*r_alt}'
C_cnt1 = '${fparse 2*pi*r_cnt1}'
C_cnt2 = '${fparse 2*pi*r_cnt2}'

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
  [cnt10]
    type = FileMeshGenerator
    file = '${mesh_cnt1}'
  []
  [cnt1]
    type = SubdomainBoundingBoxGenerator
    input = cnt10
    block_id = 3
    block_name = 'cnt1'
    bottom_left = '0 0 0'
    top_right = '1 1 1'
  []
  [cnt20]
    type = FileMeshGenerator
    file = '${mesh_cnt2}'
  []
  [cnt2]
    type = SubdomainBoundingBoxGenerator
    input = cnt20
    block_id = 5
    block_name = 'cnt2'
    bottom_left = '0 0 0'
    top_right = '1 1 1'
  []
  [combine]
    type = CombinerGenerator
    inputs = 'matrix alt cf cnt1 cnt2'
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
    factor = 0.40848208562
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
  [resistance_cnt1]
    type = EmbeddedMaterialConstraint
    variable = Phi
    primary = 'resin'
    secondary = 'cnt1'
    resistance = '${fparse ECR_cnt1/C_cnt1}'
    interface_id = 2
  []
  [resistance_cnt2]
    type = EmbeddedMaterialConstraint
    variable = Phi
    primary = 'resin'
    secondary = 'cnt2'
    resistance = '${fparse ECR_cnt2/C_cnt2}'
    interface_id = 3
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
  [cnt1]
    type = ADGenericConstantMaterial
    prop_names = 'sigma A'
    prop_values = '${sigma_cnt1} ${A_cnt1}'
    block = 'cnt1'
  []
  [cnt2]
    type = ADGenericConstantMaterial
    prop_names = 'sigma A'
    prop_values = '${sigma_cnt2} ${A_cnt2}'
    block = 'cnt2'
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
  [V_cnt1]
    type = VolumePostprocessor
    block = 'cnt1'
    execute_on = 'INITIAL'
    outputs = none
  []
  [V_cnt2]
    type = VolumePostprocessor
    block = 'cnt2'
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
  [volfrac_cnt1]
    type = ParsedPostprocessor
    function = '${A_cnt1}*V_cnt1/(V_RVE)'
    pp_names = 'V_cnt1 V_RVE'
    execute_on = 'INITIAL'
  []
  [volfrac_cnt2]
    type = ParsedPostprocessor
    function = '${A_cnt2}*V_cnt2/(V_RVE)'
    pp_names = 'V_cnt2 V_RVE'
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
