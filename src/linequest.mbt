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
///  s ; choose 'min' or 'max'
/// poly ; for Example Poly::from_var_array( [1.0, 2.0, 3.0], arr)
/// var ; the array contains all variables about this LP
pub fn [V : Zero] Lp::new(s : String, poly : Poly[V], var : Array[Variable]) -> Lp[V] {
  let new_objfunc = Obj_func::new(s).set_poly(poly)
  {
    vars : var,
    obj_func : new_objfunc,
    constraint : Constraint::new(),
    matrix : Lp::get_Matrix(var, new_objfunc, Constraint::new())
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
  eq_array : Array[(Array[V],V)], 
  ineq_array : Array[(Array[V], String, V)]
) -> Lp[V] {
  let new_constraint = Constraint::from_array(eq_array, ineq_array, self.vars)
  {
    vars : self.vars,
    obj_func : self.obj_func,
    constraint : new_constraint,
    matrix : Lp::get_Matrix(self.vars, self.obj_func, new_constraint)
  }
}

///|
/// transform Matrix to Linear-program standard model
/// A: m×n 系数矩阵，b: m×1 右端项向量，c: n×1 目标函数系数向量
// pub fn Lp::from_matrix[V: Eq + Compare + Semiring] (lp_matrix : Matrix[V], vars_matrix : Array[Variable], obj_type: String) -> Lp[V]{
//   let var_num = vars_matrix.length()
//   let lp_array = lp_matrix.to_array()

//   let obj_poly = Poly::from_var_array(
//     ,
//     vars_matrix
//   )
//   let new_objfunc = Obj_func::new(obj_type).set_poly(obj_poly)
//   {
//     vars : vars_matrix,
//     obj_func : ,
//     constraint : ,
//     matrix : 
//   }
// }

///|
pub fn[V] Lp::get_coeff_matrix (lp_matrix : Matrix[V]) -> Matrix[V] {
  ...
}

///|
pub fn[V] Lp::get_objfunc_matrix(lp_matrix : Matrix[V]) -> Array[V] {
  lp_matrix.row_to_array(0)
}

///|
pub fn[V] Lp::get_b_vector(lp_matrix : Matrix[V]) -> Array[V] {
  lp_matrix.col_to_array(0)
}

///|
/// transform Lp from (Ax "= <= >=" b) to (Ax = b)
/// this function add some Variable to Lp, they are 剩余变量 and 松弛变量
pub fn [V: Eq + Semiring + Compare + Neg] Lp::to_standard (self : Lp[V]) -> Lp[V] {
  let new_objfunc = self.obj_func.to_min()
  let new_vars = self.vars.copy()
  let new_cons = {
    eq_poly : self.constraint.eq_poly.copy(),
    ineq_poly : []
  }
  
  let mut count = 1
  self.constraint.ineq_poly.each(
    fn ( x ) -> Unit {
      let (poly, s, coeff) = x
      let var = Variable::new("y" + count.to_string(), 0, @double.max_value)
      count += 1
      new_vars.append([var])

      if s == ">=" {
        let temp_poly = -poly
        temp_poly.add_term_inplace(var, V::one())
        new_cons.add_eqpoly(temp_poly, -coeff)
      }else{
        let temp_poly = poly.copy()
        temp_poly.add_term_inplace(var, V::one())
        new_cons.add_eqpoly(temp_poly, coeff)
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
  res.append(constraint.to_Matrix(vars))
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
  let obj_poly = Poly::from_var_array(
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
  let lp = Lp::new("max", obj_poly, arr)
  let lp2 = lp.cons_from_Array(eqarr, ineqarr)
  let lp3 = lp2.to_standard()
  // initial LP
  println(lp2)
  // transform to standard
  println(lp3)
  // transform to Matrix
  println(lp3.matrix)
}

///|
pub fn[V] Lp::solve_LP_bySimplex(self : Lp[V]) -> (Array[V],Array[Variable]){
...
}