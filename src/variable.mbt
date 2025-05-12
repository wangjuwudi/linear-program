struct Variable {
  name : String
  low_bound : Double
  up_bound : Double
}derive(Eq)

pub impl Show for Variable with to_string(self) -> String {
  self.name
}
pub impl Show for Variable with output(self, logger) -> Unit {
  logger.write_string(self.name)
}

pub impl Compare for Variable with compare(self, other) -> Int{
  if self.name == other.name{
    1
  }else{
    0
  }
}

pub fn Variable::new (
  n : String, l : Double , u : Double
) -> Variable {
  {
    name : n,
    low_bound : l,
    up_bound : u
  }
}

pub fn Variable::show_all (self : Variable) -> String{
  self.name +" : [\{self.low_bound}, \{self.up_bound}]"  
}