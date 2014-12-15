module Inline
	class Ruby < Inline::C
		require 'ruby_parser'
		require 'ruby_to_ruby_c'
		def initialize(mod)
			super
		end

		def run(src)

			#sexp = RubyParser.new.parse meth
			#c_src = RubyToRubyC.new.process sexp

			#src = RubyToC.translate(@mod, meth)
			#@mod.class_eval "alias :#{meth}_slow :#{meth}"
			#@mod.class_eval "remove_method :#{meth}"
			c src
		end
	end
end