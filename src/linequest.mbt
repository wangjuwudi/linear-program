///|
struct Lp[V] {
  vars : Array[Variable]
  obj_func : Obj_func[V]
  constraint : Constraint[V]
  matrix : Matrix[V]
}

///|
pub impl[V : Show + Eq + Semiring] Show for Lp[V] with output(self, l) -> Unit {
  l
  ..write_object(self.obj_func)
  ..write_char('\n')
  ..write_object(self.constraint)
  for x in self.vars {
    l..write_char(' ')..write_string(x.show_all())
  }
  l.write_char('\n')
}

///|
/// the variable name can't be [y1,y2,...] or [z1,z2,...]
pub fn[V : Zero] Lp::new(
  new_objfunc : Obj_func[V],
  variable : Array[Variable],
) -> Lp[V] {
  {
    vars: variable,
    obj_func: new_objfunc,
    constraint: Constraint::new(),
    matrix: Lp::get_Matrix(variable, new_objfunc, Constraint::new()),
  }
}

///|
/// obj_func function: reset it by Array[V]
pub fn[V : Compare + Semiring + Zero] Lp::reset_obj_byarray(
  self : Lp[V],
  arr : Array[V],
) -> Lp[V] {
  let new_objfunc = self.obj_func.set_poly(Poly::from_var_array(arr, self.vars))
  {
    vars: self.vars,
    obj_func: new_objfunc,
    constraint: self.constraint,
    matrix: Lp::get_Matrix(self.vars, new_objfunc, self.constraint),
  }
}

///|
/// set constraint by Array
/// the lable in ineq_array must be ">=" or "<="
pub fn[V : Eq + Semiring] Lp::cons_from_Array(
  self : Lp[V],
  eq_array~ : Array[(Array[V], V)] = [],
  ineq_array~ : Array[(Array[V], String, V)] = [],
) -> Lp[V] {
  let new_constraint = Constraint::from_array(eq_array~, ineq_array~, self.vars)
  {
    vars: self.vars,
    obj_func: self.obj_func,
    constraint: new_constraint,
    matrix: Lp::get_Matrix(self.vars, self.obj_func, new_constraint),
  }
}

///|
/// transform Matrix to Linear-program standard model
pub fn[V : Eq + Semiring] Lp::from_matrix(
  lp_matrix : Matrix[V],
  vars_for_matrix : Array[Variable],
  obj_type : String,
) -> Lp[V] {
  let eq_array : Array[(Array[V], V)] = []
  let row_num = lp_matrix.row()
  let col_num = lp_matrix.col()
  for i in 1..<row_num {
    eq_array.push(
      (
        lp_matrix.row_to_array(i)[:col_num - 1].to_array(),
        lp_matrix[i][col_num - 1],
      ),
    )
  }
  {
    vars: vars_for_matrix,
    obj_func: Obj_func::from_array(
      obj_type,
      lp_matrix.row_to_array(0)[:col_num - 1].to_array(),
      vars_for_matrix,
    ),
    constraint: Constraint::from_array(eq_array~, vars_for_matrix),
    matrix: lp_matrix,
  }
}

///|
test "Lp_from_Matrix" {
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
    Variable::new("x3", 0.0, @double.max_value),
    Variable::new("x4", 0.0, @double.max_value),
  ]
  let matrix : Matrix[Double] = Matrix::from_2d_array([
    [1, 2, 3, 4, 0],
    [4, 5, 0, 5, 1],
    [1, -4, 5, 1, 0],
    [0, 3, 8, 1, 2],
  ])
  let lp = Lp::from_matrix(matrix, vars, "min")
  inspect(
    lp,
    content=(
      #|min  x1 + 2x2 + 3x3 + 4x4
      #|s.t. 4x1 + 5x2 + 5x4 = 1
      #|     x1 + -4x2 + 5x3 + x4 = 0
      #|     3x2 + 8x3 + x4 = 2
      #|      x1 : [0, 1.7976931348623157e+308] x2 : [0, 1.7976931348623157e+308] x3 : [0, 1.7976931348623157e+308] x4 : [0, 1.7976931348623157e+308]
      #|
    ),
  )
}

///|
pub fn[V] Lp::get_coeff_matrix(self : Lp[V]) -> Matrix[V] {
  Matrix::make(self.matrix.row() - 1, self.matrix.col() - 1, fn(
    col_index : Int,
    row_index : Int,
  ) -> V {
    self.matrix[col_index + 1][row_index]
  })
}

///| get obj_func coeff from matrix
pub fn[V] Lp::get_objfunc_vector(self : Lp[V]) -> Array[V] {
  self.matrix.row_to_array(0)[:self.matrix.col() - 1].to_array()
}

///|
pub fn[V] Lp::get_b_vector(self : Lp[V]) -> Array[V] {
  self.matrix.col_to_array(self.matrix.col() - 1)[1:].to_array()
}

///|
test "get A,c,b" {
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
    Variable::new("x3", 0.0, @double.max_value),
    Variable::new("x4", 0.0, @double.max_value),
    Variable::new("x5", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("min", [1, 2, 3, 4, 5], vars)
  let eq_con = [([1, 2, 3, 0, 5], 0), ([1, 7, 0, 4, 3], 0)]
  let lp = Lp::new(obj_func, vars).cons_from_Array(eq_array=eq_con)
  inspect(
    lp.matrix,
    content=(
      #||1, 2, 3, 4, 5, 0|
      #||1, 2, 3, 0, 5, 0|
      #||1, 7, 0, 4, 3, 0|
    ),
  )
  inspect(
    lp.get_coeff_matrix(),
    content=(
      #||1, 2, 3, 0, 5|
      #||1, 7, 0, 4, 3|
    ),
  )
  inspect(lp.get_objfunc_vector(), content="[1, 2, 3, 4, 5]")
  inspect(lp.get_b_vector(), content="[0, 0]")
}

///|
/// transform Lp from (Ax "= <= >=" b) to (Ax = b)
/// this function add some Variable to Lp, they are artificial variable、remainder,relaxation variable
/// also make sure all RHS is > 0
pub fn[V : Eq + Semiring + Compare + Neg + Zero] Lp::to_standard(
  self : Lp[V],
) -> Lp[V] {
  let new_objfunc = self.obj_func.to_min()
  let new_vars = self.vars.copy()
  let new_cons : Constraint[V] = { eq_poly: [], ineq_poly: [] }
  let mut count = 1
  self.constraint.eq_poly.each(fn(x) -> Unit {
    let (poly, b) = x
    if b < V::zero() {
      new_cons.add_eqpoly(-poly, -b)
    } else {
      new_cons.add_eqpoly(poly, b)
    }
  })
  //add remainder,relaxation variable for ineq_constraint
  count = 1
  self.constraint.ineq_poly.each(fn(x) -> Unit {
    let (poly, s, b) = x
    let variable = Variable::new("y" + count.to_string(), 0, @double.max_value)
    count += 1
    new_vars.push(variable)
    if s == ">=" {
      if b <= V::zero() {
        let temp_poly = -poly
        temp_poly.add_term_inplace(variable, V::one())
        new_cons.add_eqpoly(temp_poly, -b)
      } else {
        let temp_poly = poly.copy()
        temp_poly.add_term_inplace(variable, -V::one())
        new_cons.add_eqpoly(temp_poly, b)
      }
    } else if b >= V::zero() {
      let temp_poly = poly.copy()
      temp_poly.add_term_inplace(variable, V::one())
      new_cons.add_eqpoly(temp_poly, b)
    } else {
      let temp_poly = -poly
      temp_poly.add_term_inplace(variable, -V::one())
      new_cons.add_eqpoly(temp_poly, -b)
    }
  })
  {
    vars: new_vars,
    obj_func: new_objfunc,
    constraint: new_cons,
    matrix: Lp::get_Matrix(new_vars, new_objfunc, new_cons),
  }
}

///|
/// before use this function, Please make sure this LP have been standard
fn[V : Zero] Lp::get_Matrix(
  vars : Array[Variable],
  obj_func : Obj_func[V],
  constraint : Constraint[V],
) -> Matrix[V] {
  let res : Array[Array[V]] = []
  let var_num = vars.length()
  res.push(obj_func.to_vector(var_num))
  res.append(constraint.to_matrix(vars))
  Matrix::from_2d_array(res)
}

///|
test "show" {
  //Define Vars
  //Variable::new(name, lowbound, upbound)
  let arr = [
    Variable::new("x1", 0.0, 100.0),
    Variable::new("x2", 0.0, 100.0),
    Variable::new("x3", 0.0, 100.0),
  ]
  //Define Object function
  let obj_func = Obj_func::from_array("max", [1.0, 2.0, 3.0], arr)
  //Define equal constraint
  // (poly, b-value)
  let eqarr = [([2.0, 2.0, 3.0], 100.0)]
  //Define inequal constraint
  // (poly, labal, b-value)
  let ineqarr = [([2.5, 0.0, 4.7], ">=", 0.0), ([-1.7, 2.5, 12], "<=", 0.0)]
  //Define Liner Program
  let lp2 = Lp::new(obj_func, arr).cons_from_Array(
    eq_array=eqarr,
    ineq_array=ineqarr,
  )
  let lp3 = lp2.to_standard()
  inspect(
    lp2,
    content=(
      #|max  x1 + 2x2 + 3x3
      #|s.t. 2x1 + 2x2 + 3x3 = 100
      #|     2.5x1 + 4.7x3 >= 0
      #|    -1.7x1 + 2.5x2 + 12x3 <= 0
      #|     x1 : [0, 100] x2 : [0, 100] x3 : [0, 100]
      #|
    ),
  )
  inspect(
    lp2.matrix,
    content=(
      #||1, 2, 3, 0|
      #||2, 2, 3, 100|
    ),
  )
  inspect(
    lp3,
    content=(
      #|min  -1x1 + -2x2 + -3x3
      #|s.t. 2x1 + 2x2 + 3x3 = 100
      #|     -2.5x1 + -4.7x3 + y1 = 0
      #|     -1.7x1 + 2.5x2 + 12x3 + y2 = 0
      #|      x1 : [0, 100] x2 : [0, 100] x3 : [0, 100] y1 : [0, 1.7976931348623157e+308] y2 : [0, 1.7976931348623157e+308]
      #|
    ),
  )
  inspect(
    lp3.matrix,
    content=(
      #||-1, -2, -3, 0, 0, 0|
      #||2, 2, 3, 0, 0, 100|
      #||-2.5, 0, -4.7, 1, 0, 0|
      #||-1.7, 2.5, 12, 0, 1, 0|
    ),
  )
}

// *** Solve Linear Program *** //

///|
/// add artificial variables and get init_solve
/// return fmt (artificial_matrix, init_solve, artificial_index)
fn[V : Zero + Compare + One] Lp::add_artificial(
  self : Lp[V],
) -> (Matrix[V], Array[V], Array[Int]) {
  let coeff = self.get_coeff_matrix()
  let b_array = self.get_b_vector()
  let init_solve : Array[V] = Array::make(self.vars.length(), V::zero())
  let artificial_index = Array::make(coeff.row(), 0)
  let mut articifical_num = 0

  // Count the number of non-zero elements in each column
  let nozeronum_bycol = Array::make(coeff.col(), 0)
  for i in 0..<coeff.row() {
    for j in 0..<coeff.col() {
      if coeff[i][j] != V::zero() {
        nozeronum_bycol[j] += 1
      }
    }
  }
  // establish artificial_matrix
  // let artificial_matrix : Array[Array[V]] = Array::make(coeff.row(), Array::make(coeff.col(), V::zero())) 
  let artificial_matrix = Matrix::new(coeff.row(), coeff.row(), V::zero())
  for i in 0..<coeff.row() {
    for j in 0..<coeff.col() {
      // find unit_col in this row, need't add artificial variables in this row
      if coeff[i][j] == V::one() && nozeronum_bycol[j] == 1 {
        init_solve[j] = b_array[i] // make X(j) = b_array[i]
        break
      }
    } else {
      // need add artificial variables in this row
      for k in 0..<coeff.row() {
        if k == i {
          artificial_matrix[k][articifical_num] = V::one()
        }
      }
      init_solve.push(b_array[i])
      artificial_index[i] = coeff.col() + articifical_num
      articifical_num += 1
    }
  }
  let new_col = coeff.col() + articifical_num
  let mut obj_func = Array::make(new_col, V::zero())
  if articifical_num > 0 {
    // make new_obj_func for artificial_variables
    for i in 0..<new_col {
      if i < coeff.col() {
        obj_func[i] = V::zero()
      } else {
        obj_func[i] = V::one()
      }
    }
  } else {
    // no artificial_variables
    obj_func = self.get_objfunc_vector()
  }
  (
    // integrate self.matrix and artificial_matrix, get the full_matrix
    Matrix::make(coeff.row() + 1, coeff.col() + articifical_num + 1, fn(
      row,
      col,
    ) -> V {
      if col >= coeff.col() + articifical_num {
        if row == 0 {
          V::zero()
        } else {
          b_array[row - 1]
        }
      } else if row == 0 {
        obj_func[col]
      } else if col < coeff.col() {
        coeff[row - 1][col]
      } else {
        artificial_matrix[row - 1][col - coeff.col()]
      }
    }),
    init_solve,
    artificial_index,
  )
}

///|
test "artificial_matrix" {
  // test 1
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
    Variable::new("x3", 0.0, @double.max_value),
    Variable::new("x4", 0.0, @double.max_value),
  ]
  let matrix : Matrix[Double] = Matrix::from_2d_array([
    [1, 2, 3, 4, 0],
    [4, 1, 0, 6, 1],
    [1, 3, 1, 0, 0],
    [-1, 4, 7, 1, 2],
  ])
  let lp = Lp::from_matrix(matrix, vars, "min")
  // The matrix form of LP problem, the first line is the objective function:
  inspect(
    lp.matrix,
    content=(
      #||1, 2, 3, 4, 0|
      #||4, 1, 0, 6, 1|
      #||1, 3, 1, 0, 0|
      #||-1, 4, 7, 1, 2|
    ),
  )
  let x = lp.add_artificial()
  // LP matrix after adding artificial variables
  inspect(
    x.0,
    content=(
      #||0, 0, 0, 0, 1, 1, 1, 0|
      #||4, 1, 0, 6, 1, 0, 0, 1|
      #||1, 3, 1, 0, 0, 1, 0, 0|
      #||-1, 4, 7, 1, 0, 0, 1, 2|
    ),
  )
  // Initial Solution
  inspect(x.1, content="[0, 0, 0, 0, 1, 0, 2]")
  // Index of artificial Column
  inspect(x.2, content="[4, 5, 6]")

  //test 2
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("max", [3.0, 4.0], vars)
  let ineq = [([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)]
  let lp = Lp::new(obj_func, vars)
    .cons_from_Array(ineq_array=ineq)
    .to_standard()

  // The matrix form of LP problem, the first line is the objective function:
  inspect(
    lp.matrix,
    content=(
      #||-3, -4, 0, 0, 0|
      #||2, 1, 1, 0, 12|
      #||1, 3, 0, 1, 10|
    ),
  )
  let x = lp.add_artificial()
  // LP matrix after adding artificial variables
  inspect(
    x.0,
    content=(
      #||-3, -4, 0, 0, 0|
      #||2, 1, 1, 0, 12|
      #||1, 3, 0, 1, 10|
    ),
  )
  // Initial Solution
  inspect(x.1, content="[0, 0, 12, 10]")
  // Index of artificial Column
  inspect(x.2, content="[0, 0]")
}

///|
pub fn[V : Zero + Compare + Div + Mul + Sub] Lp::pivot(
  matrix : Matrix[V],
  row : Int,
  col : Int,
) -> Unit {
  let m_row = matrix.row()
  let m_col = matrix.col()
  guard row < m_row && col < m_col
  let pivot_val = matrix[row][col]
  if pivot_val == V::zero() {
    println("pivot error, (\{row}, \{col}) is zero!")
    abort("pivot error, (\{row}, \{col}) is zero!")
  } else {
    for j in 0..<m_col {
      matrix[row][j] = matrix[row][j] / pivot_val
    }
    for i in 0..<m_row {
      if i == row {
        continue
      }
      let factor = matrix[i][col]
      for j in 0..<m_col {
        matrix[i][j] = matrix[i][j] - factor * matrix[row][j]
      }
    }
  }
}

///|
test "pivot" {
  let matrix : Matrix[Double] = Matrix::from_2d_array([
    [1, 2, 3, 4, 0],
    [4, 1, 0, 6, 1],
    [1, 3, 1, 0, 0],
    [-1, 4, 7, 1, 2],
  ])
  Lp::pivot(matrix, 1, 1)
  inspect(
    matrix,
    content=(
      #||-7, 0, 3, -8, -2|
      #||4, 1, 0, 6, 1|
      #||-11, 0, 1, -18, -3|
      #||-17, 0, 7, -23, -2|
    ),
  )
}

///|
pub fn[V : Zero + One + Compare + Sub + Compare + Div + Mul] Lp::phase_1(
  p1_matrix : Matrix[V],
  artificial_index : Array[Int],
) -> Matrix[V] {
  // let (matrix, _, artificial_index) = self.add_artificial()
  // let p1_matrix = matrix
  let row = p1_matrix.row()
  let col = p1_matrix.col()
  for index, col_num in artificial_index {
    if p1_matrix[0][col_num] == V::one() {
      for j in 0..<col {
        p1_matrix[0][j] = p1_matrix[0][j] - p1_matrix[index + 1][j]
      }
    }
  }
  while true {

    // find in_base_var
    let mut in_base_index = 0
    let mut flag = true
    for i in 0..<(col - 1) {
      if p1_matrix[0][i] < V::zero() &&
        p1_matrix[0][i] <= p1_matrix[0][in_base_index] {
        in_base_index = i
        flag = false
      }
    } else {
      if flag {
        break
      }
    }

    // find out_base_var
    let mut per_ratio = V::zero()
    let mut out_base_index = -1
    flag = true
    for j in 1..<row {
      if p1_matrix[j][in_base_index] == V::zero() ||
        p1_matrix[j][col - 1] / p1_matrix[j][in_base_index] <= V::zero() {
        continue
      } else {
        let ratio = p1_matrix[j][col - 1] / p1_matrix[j][in_base_index]
        if flag == true || per_ratio > ratio {
          per_ratio = ratio
          out_base_index = j
          flag = false
        }
      }
    } else {
      if flag {
        println("Phase1 no_bound result")
        break
      }
    }
    Lp::pivot(p1_matrix, out_base_index, in_base_index)
  }
  p1_matrix
}

///|
test "phase1" {
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("max", [3.0, 4.0], vars)
  let ineq = [([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)]
  let lp = Lp::new(obj_func, vars)
    .cons_from_Array(ineq_array=ineq)
    .to_standard()
  let artificial = lp.add_artificial()
  let x = Lp::phase_1(artificial.0, artificial.2)
  inspect(
    x,
    content=(
      #||0, 0, 1, 1, 22|
      #||1, 0, 0.6, -0.19999999999999998, 5.199999999999999|
      #||0, 1, -0.19999999999999998, 0.39999999999999997, 1.6000000000000005|
    ),
  )
  let matrix : Matrix[Double] = Matrix::from_2d_array([
    [5, 4, 0],
    [2, 3, 7],
    [3, 2, 8],
  ])
  let lp = Lp::from_matrix(matrix, vars, "max")
  let artificial = lp.add_artificial()
  let x = Lp::phase_1(artificial.0, artificial.2)
  inspect(
    x,
    content=(
      #||0, 0, 0.9999999999999998, 1.0000000000000002, 1.3322676295501878e-15|
      #||0, 1, 0.5999999999999999, -0.39999999999999997, 1.0000000000000004|
      #||1, 0, -0.39999999999999997, 0.6, 1.9999999999999998|
    ),
  )
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
    Variable::new("x3", 0.0, @double.max_value),
  ]
  let matrix : Matrix[Double] = Matrix::from_2d_array([
    [-1, -2, -3, 0],
    [1, 2, 3, 10],
    [2, 1, 1, 8],
  ])
  let lp = Lp::from_matrix(matrix, vars, "min")
  let artificial = lp.add_artificial()
  let x = Lp::phase_1(artificial.0, artificial.2)
  inspect(
    x,
    content=(
      #||0, 0, 1.8503717077085943e-16, 1, 1, 4.440892098500627e-16|
      #||0, 1, 1.6666666666666667, 0.6666666666666666, -0.3333333333333333, 4.000000000000001|
      #||1, 0, -0.33333333333333337, -0.3333333333333333, 0.6666666666666666, 1.9999999999999991|
    ),
  )
}

///| get base_best_solve from phase1 matrix
pub fn[V : Zero + One + Eq + ApproximatelyZero] Lp::phase_2(
  var_array : Array[Variable],
  matrix : Matrix[V],
) -> Array[V] {
  let row = matrix.row()
  let col = matrix.col()
  let var_num = var_array.length()
  // W* is zero OR artificial_var_num is zero
  guard var_num == col - 1 || V::is_zero_eps(matrix[0][col - 1]) else {
    println("W* from Phase1 isn't zero, Lp doesn't have solution ")
    abort("W* from Phase1 isn't zero, Lp doesn't have solution ")
  }
  // guard var_num == col - 1 || (matrix[0][col-1] < V::one() || matrix[0][col-1] > -V::one()) else {
  //   println("W* from Phase1 isn't zero, Lp doesn't have solution ")
  //   abort("W* from Phase1 isn't zero, Lp doesn't have solution ")
  // }
  let best_base_solve = Array::make(var_num, V::zero())

  // Count the number of non-zero elements in each column
  let nozeronum_bycol = Array::make(var_num, 0)
  for i in 0..<row {
    for j in 0..<var_num {
      if matrix[i][j] != V::zero() {
        nozeronum_bycol[j] += 1
      }
    }
  }
  for i in 1..<row {
    for j in 0..<var_num {
      if matrix[i][j] == V::one() && nozeronum_bycol[j] == 1 {
        best_base_solve[j] = matrix[i][col - 1]
      }
    }
  }
  best_base_solve
}

///|
test "phase2" {
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
    Variable::new("x3", 0.0, @double.max_value),
  ]
  let matrix : Matrix[Double] = Matrix::from_2d_array([
    [-1, -2, -3, 0],
    [1, 2, 3, 10],
    [2, 1, 1, 8],
  ])
  let lp = Lp::from_matrix(matrix, vars, "min").to_standard()
  inspect(
    lp,
    content=(
      #|min  -1x1 + -2x2 + -3x3
      #|s.t. x1 + 2x2 + 3x3 = 10
      #|     2x1 + x2 + x3 = 8
      #|      x1 : [0, 1.7976931348623157e+308] x2 : [0, 1.7976931348623157e+308] x3 : [0, 1.7976931348623157e+308]
      #|
    ),
  )
  let artificial = lp.add_artificial()
  let phase1 = Lp::phase_1(artificial.0, artificial.2)
  inspect(
    phase1,
    content=(
      #||0, 0, 1.8503717077085943e-16, 1, 1, 4.440892098500627e-16|
      #||0, 1, 1.6666666666666667, 0.6666666666666666, -0.3333333333333333, 4.000000000000001|
      #||1, 0, -0.33333333333333337, -0.3333333333333333, 0.6666666666666666, 1.9999999999999991|
    ),
  )
  let phase2 = Lp::phase_2(vars, phase1)
  let obj_func = lp.get_objfunc_vector()
  let mut res = 0.0
  for index, x in obj_func {
    res = res + x * phase2[index]
  }
  inspect(
    "variables：\{vars}, The_best_base_solve：\{phase2}\nThe Object_function result：\{res}",
    content=(
      #|variables：[x1, x2, x3], The_best_base_solve：[1.9999999999999991, 4.000000000000001, 0]
      #|The Object_function result：-10
    ),
  )
}

///| make sure the to_standard() has been done
pub fn[
  V : Eq + Zero + One + Compare + Mul + Div + Sub + Add + ApproximatelyZero,
] Lp::two_stage(
  self : Lp[V],
) -> (Array[V], V) {
  let artificial = self.add_artificial()
  let phase1 = Lp::phase_1(artificial.0, artificial.2)
  let phase2 = Lp::phase_2(self.vars, phase1)
  let obj_func = self.get_objfunc_vector()
  let mut res = V::zero()
  for index, x in obj_func {
    res = res + x * phase2[index]
  }
  (phase2, res)
}

///|
test "two_stage" {
  // example 1  equal_constrains
  // min cx
  // s.t. Ax=b
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
    Variable::new("x3", 0.0, @double.max_value),
  ]
  let matrix : Matrix[Double] = Matrix::from_2d_array([
    [-1, -2, -3, 0],
    [1, 2, 3, 10],
    [2, 1, 1, 8],
  ])
  let lp = Lp::from_matrix(matrix, vars, "min").to_standard()
  let res = lp.two_stage()
  inspect(vars, content="[x1, x2, x3]")
  inspect(res.0, content="[1.9999999999999991, 4.000000000000001, 0]")
  inspect(res.1, content="-10")

  // example 2  constrains'labels are '<=' 
  // max cx
  // s.t.  Ax <= b
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("max", [3.0, 4.0], vars)
  let ineq = [([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)]
  let lp = Lp::new(obj_func, vars)
    .cons_from_Array(ineq_array=ineq)
    .to_standard()
  let res = lp.two_stage()
  inspect(vars, content="[x1, x2]")
  inspect(res.0, content="[5.199999999999999, 1.6000000000000005, 0, 0]")
  inspect(-res.1, content="22") //because source problem is "MAX", so real_res = -res
  // example 3  constrains'labels are '>=' 
  // min cx
  // s.t.  Ax >= b
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("min", [3.0, 4.0], vars)
  let ineq = [([2.0, 1.0], ">=", 12.0), ([1.0, 3.0], ">=", 10.0)]
  let lp = Lp::new(obj_func, vars)
    .cons_from_Array(ineq_array=ineq)
    .to_standard()
  let res = lp.two_stage()
  inspect(vars, content="[x1, x2]")
  inspect(res.0, content="[5.199999999999999, 1.6000000000000005, 0, 0]")
  inspect(res.1, content="22")

  // special example 1
  // min cx
  // s.t. Ax <= b
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("min", [3.0, 4.0], vars)
  let ineq = [([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)]
  let lp = Lp::new(obj_func, vars)
    .cons_from_Array(ineq_array=ineq)
    .to_standard()
  inspect(
    lp,
    content=(
      #|min  3x1 + 4x2
      #|s.t. 2x1 + x2 + y1 = 12
      #|     x1 + 3x2 + y2 = 10
      #|      x1 : [0, 1.7976931348623157e+308] x2 : [0, 1.7976931348623157e+308] y1 : [0, 1.7976931348623157e+308] y2 : [0, 1.7976931348623157e+308]
      #|
    ),
  )
  let res = lp.two_stage()
  inspect(vars, content="[x1, x2]")
  inspect(res.0, content="[0, 0, 12, 10]")
  inspect(res.1, content="0")

  // special example 2
  // max cx
  // s.t. Ax >= b
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("max", [3.0, 4.0], vars)
  let ineq = [([2.0, 1.0], ">=", 12.0), ([1.0, 3.0], ">=", 10.0)]
  let lp = Lp::new(obj_func, vars)
    .cons_from_Array(ineq_array=ineq)
    .to_standard()
  inspect(
    lp,
    content=(
      #|min  -3x1 + -4x2
      #|s.t. 2x1 + x2 + -1y1 = 12
      #|     x1 + 3x2 + -1y2 = 10
      #|      x1 : [0, 1.7976931348623157e+308] x2 : [0, 1.7976931348623157e+308] y1 : [0, 1.7976931348623157e+308] y2 : [0, 1.7976931348623157e+308]
      #|
    ),
  )
  let res = lp.two_stage()
  inspect(vars, content="[x1, x2]")
  inspect(res.0, content="[5.199999999999999, 1.6000000000000005, 0, 0]")
  inspect(res.1, content="-22")

  // no-solve example 1; this example will make abort()
  // let vars = [
  //   Variable::new("x1", 0.0, @double.max_value),
  //   Variable::new("x2", 0.0, @double.max_value)
  // ]
  // let obj_func = Obj_func::from_array(
  //   "min",
  //   [3.0, 4.0],
  //   vars
  // ) 
  // let ineq = [
  //   ([2.0, 1.0], ">=", 12.0),
  //   ([2.0, 1.0], "<=", 10.0)
  // ]
  // let lp = Lp::new(obj_func, vars).cons_from_Array(ineq_array = ineq).to_standard()
  // inspect(lp)
  // let res = lp.two_stage()
  // inspect(vars)
  // inspect(res.0)
  // inspect(res.1)
  // inspect("\n")

}

///| test ApproxomatelyZero
pub fn[V : ApproximatelyZero] double_equal_to_zero(x : V) -> Bool {
  V::is_zero_eps(x)
}

///|
test "equal_to_0" {
  let x = 1.5e-17
  inspect(double_equal_to_zero(x), content = "true")
}
