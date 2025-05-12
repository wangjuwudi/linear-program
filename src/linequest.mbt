struct Lp[V] {
  vars : Array[Variable]
  obj_func : Obj_func[V]
  constraint : Constraint[V]
}

pub impl[V : Show + Eq + Semiring] Show for Lp[V] with to_string (
  self
) -> String {
  let mut s = self.obj_func.to_string() + "//n" + self.constraint.to_string()
  for x in self.vars {
    s = s + "//n" + x.show_all()
  }
  s
}

pub impl[V : Show + Eq + Semiring] Show for Lp[V] with output (
  self,
  l
) -> Unit {
  l.write_string(self.to_string())
}