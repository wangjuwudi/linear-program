priv enum Obj_type {
  Minimize
  Maximize
}

struct Obj_func[V] {
  sense : Obj_type
  obj_poly : Poly[V]
}derive()



pub impl[V : Eq + Show + Semiring] Show for Obj_func[V] with to_string (
  self
) -> String {
  match self.sense {
    Minimize => "min  " + self.obj_poly.to_string()
    Maximize => "max  " + self.obj_poly.to_string()
  }
  
}

pub impl[V : Eq + Show + Semiring] Show for Obj_func[V] with output(
  self,
  l
) {
  l.write_string(self.to_string())
}


pub fn Obj_func::new[V] (s : String) -> Obj_func[V] {
  {
    sense : match s {
      "Min" | "Minimize" | "min" | "minimize" | "MIN" => {Minimize}
      "Max" | "MAX" | "max" | "Maximize" | "maximize" => {Maximize}
      _ => abort("Error Obj_type , Please choose 'min' or 'max'!")
    },
    obj_poly : Poly::new()
  }
}

pub fn Obj_func::set_poly[V] (self : Obj_func[V], poly : Poly[V]) -> Obj_func[V] {
  {
    sense : self.sense,
    obj_poly : poly
  }
}

pub fn Obj_func::add_term_inplace[V: Eq + Semiring + Compare + Zero] (
  self : Obj_func[V],
  var : Variable, 
  coeff : V
) -> Unit {
  self.obj_poly.add_term_inplace(var, coeff)
}

pub fn Obj_func::to_min[V: Eq + Semiring + Compare + Zero + Neg](
  self : Obj_func[V]
) -> Obj_func[V] {
  match self.sense {
    Minimize => self
    Maximize => {
      sense : {Minimize} ,
      obj_poly : -(self.obj_poly)
    }
  }
}



test "show" {
  let x1 :Variable = {
    name : "x1",
    low_bound : -1.0,
    up_bound: 1.0
  }
  println(x1);
  let poly = Poly::new();
  poly.add_term_inplace(x1, 3.5)
  println(poly)

  let obj_func = Obj_func::new("max").set_poly(poly)
  
  println(obj_func)
  println(obj_func.to_min())
}

