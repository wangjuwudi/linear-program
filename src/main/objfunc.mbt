enum Obj_type {
  Minimize
  Maximize
}
type Coeffs[V] @sorted_map.T[String, V] derive(Eq)
struct Obj_func {
  sense : Obj_type
  coeffs : Coeffs[Double]
}



