class TutorialsController < ApplicationController

  def instructor_manual
    send_file("#{Rails.root}/app/views/tutorials/EDURange_for_faculty.pdf", :disposition => 'inline',:type => 'application/pdf')
  end

  def student_manual
    send_file("#{Rails.root}/app/views/tutorials/EDURange_for_students.pdf", :disposition => 'inline',:type => 'application/pdf')
  end

end
