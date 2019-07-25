module StudentHelper
	def public_ip(scenario)
		@scenario.students_groups(current_user).each do |group|
			group.instance_groups.each do |instance_group|
	            if instance_group.instance.ip_address_public
	                return instance_group.instance.ip_address_public
	            end
	        end
	    end
	end

	def player_login(c, scenario)
		@scenario.students_groups(current_user).each do |group|
			if player = group.find_player_by_student_id(c)
				return player.login
			end
	    end	
	end

	def player_password(c, scenario)
		@scenario.students_groups(current_user).each do |group|
			if player = group.find_player_by_student_id(c)
				return player.password
			end
	    end
	end


end
