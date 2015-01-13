class Deployment::Method::Single::Base < Deployment::Method::Base
	def initialize(work_zone, coverage = nil, coverage_in_center = nil)
		super
		step_is_small = self.class.const_get(:STEP) < Deployment::Method::Base::MINIMAL_STEP
		step_is_not_multiple_of_minimal_step = (self.class.const_get(:STEP) % Deployment::Method::Base::MINIMAL_STEP) > 0
		if step_is_small or step_is_not_multiple_of_minimal_step
			raise StandardError.new("Wrong STEP value #{self.class.const_get(:STEP)}. STEP should be more than #{Deployment::Method::Base::MINIMAL_STEP} and be multiple of #{Deployment::Method::Base::MINIMAL_STEP}")
		end
	end
end