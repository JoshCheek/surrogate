class Surrogate
  SurrogateError             = Class.new StandardError
  UnknownMethod              = Class.new SurrogateError
  QueueEmpty                 = Class.new SurrogateError
  NoMethodToCheckSignatureOf = Class.new SurrogateError
end
