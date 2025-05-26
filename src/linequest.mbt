struct Lp[V] {
  vars : Array[Variable]
  obj_func : Obj_func[V]
  constraint : Constraint[V]
}

pub impl[V : Show + Eq + Semiring] Show for Lp[V] with to_string (
  self
) -> String {
  let mut s = self.obj_func.to_string() + "   " + self.constraint.to_string()
  for x in self.vars {
    s = s + " " + x.show_all()
  }
  s
}

pub impl[V : Show + Eq + Semiring] Show for Lp[V] with output (
  self,
  l
) -> Unit {
  l.write_string(self.to_string())
}

///|
/// 
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

///|
pub fn Lp::to_matrix[V] (self : Lp[V]) -> @al.Matrix[V] {
  
}


// pub fn Lp::from_matrix[V] (self : Lp[V]) -> Unit{
// ...
// }

///|
pub fn Lp::to_standard[V: Eq + Semiring + Compare + Neg + One + Show] (self : Lp[V]) -> Lp[V] {
  let new_objfunc = self.obj_func.to_min()
  let new_vars = self.vars
  let new_cons = {
    eq_poly : self.constraint.eq_poly.copy(),
    ineq_poly : []
  }
  //println(new_cons)
  let mut count = 1
  self.constraint.ineq_poly.each(
    fn ( x ) -> Unit {
      let (poly, s, coeff) = x
      if s == ">=" {
        let var = Variable::new("y" + count.to_string(), 0, @double.max_value)
        count += 1
        new_vars.append([var])
        let temp_poly = -poly
        temp_poly.add_term_inplace(var,V::one())
        new_cons.ineq_poly.append([(temp_poly, "<=", -coeff)])
      }else{
        new_cons.ineq_poly.append([x])
      }
    }
  )
  {
    vars : new_vars,
    obj_func : new_objfunc,
    constraint : new_cons,
  }
}

test "show" {
  //定义变量
  let arr = [
    Variable::new("x1", 0.0, 100.0),
    Variable::new("x2", 0.0, 100.0),
    Variable::new("x3", 0.0, 100.0)
  ]

  //目标函数
  let obj_poly = Poly::from_var_array(
    [1.0, 2.0, 3.0],
    arr
  )

  //等式约束
  let eqarr = [
    ([2.0, 2.0, 3.0], 100.0)
  ]
  //不等式约束
  let ineqarr = [
    ([2.5, 3.3, 4.7], ">=", 0.0),
    ([-1.7, 2.5, 12], "<=", 0.0)
  ]
  // PL问题定义
  // 1. 定义所有使用到的变量 
  // 2. 定义Lp的类型: "min" 或者 "max"
  // 3. 添加Lp的 目标函数、约束条件
  // 4. 标准化Lp问题：
    // 
  let lp = Lp::new("max", obj_poly, arr)
  println(lp)
  println(lp.cons_from_Array(eqarr, ineqarr))
  println(lp.cons_from_Array(eqarr,ineqarr).to_standard())
}