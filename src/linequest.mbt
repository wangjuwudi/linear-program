struct Lp[V] {
  vars : Array[Variable]
  obj_func : Obj_func[V]
  constraint : Constraint[V]
  matrix : Matrix[V]
}

///|
pub impl[V : Show + Eq + Semiring] Show for Lp[V] with to_string (
  self
) -> String {
  let mut s = self.obj_func.to_string() + "\n" + self.constraint.to_string()
  for x in self.vars {
    s = s + " " + x.show_all()
  }
  s + "\n"
}

///|
pub impl[V : Show + Eq + Semiring] Show for Lp[V] with output (
  self,
  l
) -> Unit {
  l.write_string(self.to_string())
}

///|
/// the variable name can't be [y1,y2,...] or [z1,z2,...]
pub fn [V : Zero] Lp::new(new_objfunc : Obj_func[V] , variable : Array[Variable]) -> Lp[V] {
  {
    vars : variable,
    obj_func : new_objfunc,
    constraint : Constraint::new(),
    matrix : Lp::get_Matrix(variable, new_objfunc, Constraint::new())
  }
}

///|
/// obj_func function: reset it by Array[V]
pub fn [V : Compare + Semiring + Zero] Lp::reset_obj_byarray (self : Lp[V], arr: Array[V]) -> Lp[V] {
  let new_objfunc = self.obj_func.set_poly(Poly::from_var_array(arr, self.vars))
  {
    vars : self.vars, 
    obj_func : new_objfunc,
    constraint : self.constraint,
    matrix : Lp::get_Matrix(self.vars, new_objfunc, self.constraint)
  }
}

///|
/// set constraint by Array
/// the lable in ineq_array must be ">=" or "<="
pub fn [V : Eq + Compare + Semiring] Lp::cons_from_Array (
  self : Lp[V], 
  eq_array~ : Array[(Array[V],V)] = [], 
  ineq_array~ : Array[(Array[V], String, V)] = []
) -> Lp[V] {
  let new_constraint = Constraint::from_array(eq_array = eq_array, ineq_array = ineq_array, self.vars)
  {
    vars : self.vars,
    obj_func : self.obj_func,
    constraint : new_constraint,
    matrix : Lp::get_Matrix(self.vars, self.obj_func, new_constraint)
  }
}

///|
/// transform Matrix to Linear-program standard model
pub fn[V: Eq + Compare + Semiring] Lp::from_matrix (
  lp_matrix : Matrix[V], 
  vars_for_matrix : Array[Variable], 
  obj_type: String
) -> Lp[V]{
  let eq_array : Array[(Array[V], V)]= []
  let row_num = lp_matrix.row()
  let col_num = lp_matrix.col()
  for i in 1..<row_num {
    eq_array.append(
      [(
        lp_matrix.row_to_array(i)[:col_num-1].to_array(), 
        lp_matrix[i][col_num-1]
      )])
  }
  {
    vars : vars_for_matrix,
    obj_func : Obj_func::from_array(
      obj_type, 
      lp_matrix.row_to_array(0)[:col_num].to_array(), 
      vars_for_matrix
    ),
    constraint : Constraint::from_array(eq_array = eq_array, vars_for_matrix),
    matrix : lp_matrix
  }
}

test "Lp_from_Matrix" {
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
    Variable::new("x3", 0.0, @double.max_value),
    Variable::new("x4", 0.0, @double.max_value),
  ] 
  let matrix = Matrix::from_2d_array(
    [
      [1,2,3,4,0],
      [4,5,0,5,1],
      [1,-4,5,1,0],
      [0,3,8,1,2]
    ]
  )
  let lp = Lp::from_matrix(matrix, vars, "min")
  println(lp)
}

///|
pub fn[V : Zero] Lp::get_coeff_matrix (self : Lp[V]) -> Matrix[V] {
  Matrix::make(
    self.matrix.row() - 1, 
    self.matrix.col() - 1,
    fn (col_index : Int, row_index : Int) -> V {
      self.matrix[col_index + 1][row_index]
    }
  )  
}

///|
pub fn[V] Lp::get_objfunc_matrix(self : Lp[V]) -> Array[V] {
  self.matrix.row_to_array(0)[:self.matrix.col() - 1].to_array()
}

///|
pub fn[V] Lp::get_b_vector(self : Lp[V]) -> Array[V] {
  self.matrix.col_to_array(self.matrix.col() - 1)[1:].to_array()
}
 
test "get A,c,b" {
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
    Variable::new("x3", 0.0, @double.max_value),
    Variable::new("x4", 0.0, @double.max_value),
    Variable::new("x5", 0.0, @double.max_value),
  ]

  let obj_func = Obj_func::from_array(
    "min",
    [1,2,3,4,5],
    vars
  )

  let eq_con = [
    ([1,2,3,0,5], 0),
    ([1,7,0,4,3], 0)
  ]

  let lp = Lp::new(obj_func, vars).cons_from_Array(eq_array = eq_con)

  println(lp.matrix)
  println(lp.get_coeff_matrix())
  println(lp.get_objfunc_matrix())
  println(lp.get_b_vector())
}

///|
/// transform Lp from (Ax "= <= >=" b) to (Ax = b)
/// this function add some Variable to Lp, they are artificial variable、remainder,relaxation variable
pub fn [V: Eq + Semiring + Compare + Neg] Lp::to_standard (self : Lp[V]) -> Lp[V] {
  let new_objfunc = self.obj_func.to_min()
  let new_vars = self.vars.copy()
  let new_cons : Constraint[V] = {
    eq_poly : [],
    ineq_poly : []
  }
  // add artificial variable for eq_constraint
  let mut count = 1
  self.constraint.eq_poly.each(
    fn (x) -> Unit {
      let (poly, b) = x
      let variable = Variable::new("z" + count.to_string(), 0, @double.max_value)
      count += 1
      new_vars.append([variable])
      let temp_poly = poly.copy()
      temp_poly.add_term_inplace(variable, V::one())
      new_cons.add_eqpoly(temp_poly, b)
    }
  )
  //add remainder,relaxation variable for ineq_constraint
  count = 1
  self.constraint.ineq_poly.each(
    fn ( x ) -> Unit {
      let (poly, s, b) = x
      let variable = Variable::new("y" + count.to_string(), 0, @double.max_value)
      count += 1
      new_vars.append([variable])
      if s == ">=" {
        let temp_poly = -poly
        temp_poly.add_term_inplace(variable, V::one())
        new_cons.add_eqpoly(temp_poly, -b)
      }else{
        let temp_poly = poly.copy()
        temp_poly.add_term_inplace(variable, V::one())
        new_cons.add_eqpoly(temp_poly, b)
      }
    }
  )
  {
    vars : new_vars,
    obj_func : new_objfunc,
    constraint : new_cons,
    matrix : Lp::get_Matrix(new_vars, new_objfunc, new_cons)
  }
}

///|
/// before use this function, Please make sure this LP have been standard
fn[V: Zero] Lp::get_Matrix(
  vars : Array[Variable], 
  obj_func : Obj_func[V],
  constraint : Constraint[V]
) -> Matrix[V] {
  let res : Array[Array[V]] = []
  let var_num = vars.length()
  res.append([obj_func.to_vector(var_num)])
  res.append(constraint.to_matrix(vars))
  Matrix::from_2d_array(res)
}

test "show" {
  //Define Vars
  //Variable::new(name, lowbound, upbound)
  let arr = [
    Variable::new("x1", 0.0, 100.0),
    Variable::new("x2", 0.0, 100.0),
    Variable::new("x3", 0.0, 100.0)
  ]
  //Define Object function
  let obj_func = Obj_func::from_array(
    "max",
    [1.0, 2.0, 3.0],
    arr
  )
  //Define equal constraint
  // (poly, b-value)
  let eqarr = [
    ([2.0, 2.0, 3.0], 100.0)
  ]
  //Define inequal constraint
  // (poly, labal, b-value)
  let ineqarr = [
    ([2.5, 0.0, 4.7], ">=", 0.0),
    ([-1.7, 2.5, 12], "<=", 0.0)
  ]
  //Define Liner Program
  let lp2 = Lp::new(obj_func, arr).cons_from_Array(eq_array = eqarr, ineq_array = ineqarr)
  let lp3 = lp2.to_standard()
  println(lp2)
  println(lp2.matrix)
  println(lp3)
  println(lp3.matrix)
}


// *** Solve Linear Program *** //
///|
pub fn[V] Lp::solve_LP_bySimplex(self : Lp[V]) -> (Array[V], Array[Variable]){
...
}