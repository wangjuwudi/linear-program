struct Lp[V] {
  vars : Array[Variable]
  obj_func : Obj_func[V]
  constraint : Constraint[V]
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
pub fn Lp::new[V] (s : String, poly : Poly[V], var : Array[Variable]) -> Lp[V] {
  {
    vars : var,
    obj_func : Obj_func::new(s).set_poly(poly),
    constraint : Constraint::new()
  }
}

///|
/// obj_func function: reset it by Array[V]
pub fn Lp::reset_obj_byarray[V : Eq + Compare + Semiring] (self : Lp[V], arr: Array[V]) -> Lp[V] {
  {
    vars : self.vars, 
    obj_func : self.obj_func.set_poly(Poly::from_var_array(arr, self.vars)),
    constraint : self.constraint
  }
}

///|
/// set constraint by Array
/// the lable in ineq_array must be ">=" or "<="
pub fn Lp::cons_from_Array[V : Eq + Compare + Semiring] (
  self : Lp[V], 
  eq_array : Array[(Array[V],V)], 
  ineq_array : Array[(Array[V], String, V)]
) -> Lp[V] {
  {
    vars : self.vars,
    obj_func : self.obj_func,
    constraint : Constraint::from_array(eq_array, ineq_array, self.vars)
  }
}


// pub fn Lp::from_matrix[V] (self : Lp[V]) -> Unit{
// ...
// }

///|
/// thansform Lp from (Ax "= <= >=" b) to (Ax = b)
/// this function add some Variable to Lp, they are 剩余变量 and 松弛变量
pub fn Lp::to_standard[V: Eq + Semiring + Compare + Neg + One + Show] (self : Lp[V]) -> Lp[V] {
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
  }
}

///|
/// before use this function, Please make sure this LP have been standard
pub fn Lp::to_Matrix[V: Zero](self : Lp[V]) -> Array[Array[V]] {
  let res : Array[Array[V]] = []
  let var_num = self.vars.length()
  res.append([self.obj_func.to_vector(var_num)])
  res.append(self.constraint.to_Matrix(self.vars))
  res
}

// ///|
// pub fn Lp::get_b_vector[V: Zero] (
//   self : Array[Array[V]]
// ) -> Array[V] {
//   let res :Array[V] = []
//   let row_num = self[0].length()
//   for arr in self {
//     res.append([arr[row_num - 1]])
//   } 
//   res
// }

// ///|
// pub fn Lp::get_c_vector[V: Zero] (
//   self : Array[Array[V]]
// ) -> Array[V] {
//   let row_num = self[0].length()
//   self[0][0:row_num-1].to_array()
// }



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
  let array = lp3.to_Matrix()
  println(array)
}