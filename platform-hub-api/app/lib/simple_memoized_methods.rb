module SimpleMemoizedMethods

  # Provides a convenience way to declare multiple methods that need to be
  # memoized. Note:
  # 1. Only for methods with 0 arguments.
  # 2. Requires there to be a corresponding `build_<method_name>` method.
  # 3. Requires there to be a `memoize` method accessible within the class scope
  #    (e.g. using `extend Memoist` before extending with this module).
  def simple_memoized_methods *names
    names.each do |method_name|
      define_method method_name do
        self.send "build_#{method_name}"
      end
      memoize method_name
    end
  end

end
